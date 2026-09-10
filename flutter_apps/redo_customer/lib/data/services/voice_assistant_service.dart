import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/config.dart';

enum VoiceAssistantState { idle, listening, processing, speaking, error }

class VoiceAssistantAction {
  final String type; // book_shipment, track_shipment, open_profile, open_bookings, chat, unknown
  final String? from;
  final String? to;
  final String? responseText;
  final String? langCode;

  VoiceAssistantAction({
    required this.type,
    this.from,
    this.to,
    this.responseText,
    this.langCode,
  });
}

class CustomerChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final VoiceAssistantAction? action;

  CustomerChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.action,
  });
}

class VoiceAssistantService extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  VoiceAssistantState _state = VoiceAssistantState.idle;
  String _currentText = '';
  String _lastResponse = '';
  VoiceAssistantAction? _lastAction;
  bool _isAvailable = false;
  bool _continuousMode = false;
  Function(VoiceAssistantAction)? _currentCallback;

  final List<CustomerChatMessage> _chatHistory = [
    CustomerChatMessage(
      text: 'Namaste! How can I help you book freight or track shipments today? You can speak or write in any Indian language.',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  VoiceAssistantState get state => _state;
  bool get isListening => _state == VoiceAssistantState.listening;
  bool get isProcessing => _state == VoiceAssistantState.processing;
  bool get continuousMode => _continuousMode;
  String get currentText => _currentText;
  String get transcribedText => _currentText;
  String get lastResponse => _lastResponse;
  VoiceAssistantAction? get lastAction => _lastAction;
  List<CustomerChatMessage> get chatHistory => List.unmodifiable(_chatHistory);

  Future<void> init() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      _state = VoiceAssistantState.idle;
      notifyListeners();

      if (_continuousMode && _currentCallback != null) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (_continuousMode && _currentCallback != null) {
            startListening(onResult: _currentCallback, continuous: true);
          }
        });
      }
    });

    _isAvailable = await _stt.initialize(
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          if (_state == VoiceAssistantState.listening) {
            _stopAndProcess();
          }
        }
      },
      onError: (val) {
        _state = VoiceAssistantState.error;
        notifyListeners();
        if (_continuousMode) {
          Future.delayed(const Duration(seconds: 2), () {
            if (_continuousMode && _currentCallback != null) {
              startListening(onResult: _currentCallback, continuous: true);
            }
          });
        }
      },
    );
  }

  Future<void> startListening({Function(VoiceAssistantAction)? onResult, bool continuous = true}) async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _lastResponse = 'Microphone permission denied.';
      notifyListeners();
      return;
    }

    if (!_isAvailable) {
      await init();
    }

    _continuousMode = continuous;
    if (onResult != null) _currentCallback = onResult;

    _state = VoiceAssistantState.listening;
    _currentText = '';
    notifyListeners();

    await _stt.listen(
      onResult: (val) {
        _currentText = val.recognizedWords;
        notifyListeners();
      },
      localeId: 'en_IN',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      listenMode: ListenMode.confirmation,
    );
  }

  void stopListening() {
    _stt.stop();
    _stopAndProcess();
  }

  void stopContinuousConversation() {
    _continuousMode = false;
    _currentCallback = null;
    _stt.stop();
    _tts.stop();
    _state = VoiceAssistantState.idle;
    _currentText = '';
    notifyListeners();
  }

  Future<void> _stopAndProcess() async {
    _stt.stop();
    if (_currentText.trim().isEmpty) {
      _state = VoiceAssistantState.idle;
      notifyListeners();
      return;
    }

    final input = _currentText.trim();
    final lower = input.toLowerCase();

    // Check if user spoke stop command
    if (lower == 'stop' ||
        lower == 'ruko' ||
        lower.contains('band karo') ||
        lower.contains('stop listening') ||
        lower == 'close' ||
        lower == 'bye') {
      stopContinuousConversation();
      await speak('Assistant stopped.');
      return;
    }

    _state = VoiceAssistantState.processing;
    notifyListeners();

    _chatHistory.add(CustomerChatMessage(
      text: input,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    try {
      final action = await _processTextWithLLM(input);
      _lastAction = action;
      _lastResponse = action.responseText ?? '';

      _chatHistory.add(CustomerChatMessage(
        text: action.responseText ?? 'Done',
        isUser: false,
        timestamp: DateTime.now(),
        action: action,
      ));

      _state = VoiceAssistantState.speaking;
      notifyListeners();

      if (action.responseText != null) {
        await speak(action.responseText!, langCode: action.langCode);
      }
      if (_currentCallback != null) {
        _currentCallback!(action);
      }
    } catch (e) {
      _state = VoiceAssistantState.error;
      _lastResponse = 'Could not process that. Please try again.';
      notifyListeners();
      await speak("Sorry, I could not process that.");
    }
  }

  Future<void> sendTextMessage(String userText, [Function(VoiceAssistantAction)? onResult]) async {
    final text = userText.trim();
    if (text.isEmpty) return;

    _chatHistory.add(CustomerChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _state = VoiceAssistantState.processing;
    notifyListeners();

    try {
      final action = await _processTextWithLLM(text);
      _lastAction = action;
      _lastResponse = action.responseText ?? '';

      _chatHistory.add(CustomerChatMessage(
        text: action.responseText ?? 'Done',
        isUser: false,
        timestamp: DateTime.now(),
        action: action,
      ));

      _state = VoiceAssistantState.idle;
      notifyListeners();

      if (onResult != null) {
        onResult(action);
      } else if (_currentCallback != null) {
        _currentCallback!(action);
      }
    } catch (_) {
      _chatHistory.add(CustomerChatMessage(
        text: 'Sorry, could not process that request. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _state = VoiceAssistantState.idle;
      notifyListeners();
    }
  }

  static String detectLanguageCode(String text) {
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code >= 0x0900 && code <= 0x097F) return 'hi-IN';
      if (code >= 0x0980 && code <= 0x09FF) return 'bn-IN';
      if (code >= 0x0A00 && code <= 0x0A7F) return 'pa-IN';
      if (code >= 0x0A80 && code <= 0x0AFF) return 'gu-IN';
      if (code >= 0x0B80 && code <= 0x0BFF) return 'ta-IN';
      if (code >= 0x0C00 && code <= 0x0C7F) return 'te-IN';
      if (code >= 0x0C80 && code <= 0x0CFF) return 'kn-IN';
      if (code >= 0x0D00 && code <= 0x0D7F) return 'ml-IN';
      if (code >= 0x0600 && code <= 0x06FF) return 'ur-IN';
    }
    return 'en-IN';
  }

  Future<VoiceAssistantAction> _processTextWithLLM(String text) async {
    // 1. Sarvam AI first
    try {
      final sarvamRes = await http.post(
        Uri.parse('https://api.sarvam.ai/v1/chat/completions'),
        headers: {
          'api-subscription-key': AppConfig.sarvamApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'sarvam-105b-conversations',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are REDO Smart Logistics Customer Assistant in India. '
                  'CRITICAL: Auto-detect the exact language spoken by the user (Hindi, English, Tamil, Telugu, Kannada, Marathi, Gujarati, Punjabi, Bengali, Odia, Malayalam, Urdu, Hinglish). '
                  'Formulate your response in the EXACT SAME LANGUAGE as the user query. '
                  'Respond with ONLY a raw JSON object: '
                  '{"type":"book_shipment"|"track_shipment"|"open_profile"|"open_bookings"|"chat","from":"city_or_null","to":"city_or_null","lang":"hi-IN|ta-IN|te-IN|etc.","response":"Natural response in user language"}. Return raw JSON only.',
            },
            {
              'role': 'user',
              'content': text,
            }
          ],
          'temperature': 0.1,
          'max_tokens': 150,
        }),
      ).timeout(const Duration(seconds: 8));

      if (sarvamRes.statusCode == 200) {
        final data = jsonDecode(sarvamRes.body);
        final content = data['choices']?[0]?['message']?['content']?.toString() ?? '';
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(content);
        if (jsonMatch != null) {
          final result = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
          final resp = result['response'] as String? ?? 'Showing results';
          final lang = (result['lang'] as String?) ?? detectLanguageCode(resp);
          return VoiceAssistantAction(
            type: result['type'] ?? 'unknown',
            from: result['from'],
            to: result['to'],
            responseText: resp,
            langCode: lang,
          );
        }
      }
    } catch (_) {}

    // 2. Fallback heuristic
    final lower = text.toLowerCase();
    final lang = detectLanguageCode(text);

    if (lower.contains('track') || lower.contains('kahan') || lower.contains('status') || lower.contains('ट्रैक')) {
      return VoiceAssistantAction(
        type: 'track_shipment',
        responseText: lang == 'hi-IN' ? 'Shipment tracking khol raha hoon.' : 'Opening shipment tracking.',
        langCode: lang,
      );
    }
    if (lower.contains('booking') || lower.contains('order') || lower.contains('history') || lower.contains('बुक')) {
      return VoiceAssistantAction(
        type: 'open_bookings',
        responseText: lang == 'hi-IN' ? 'Aapki bookings khol raha hoon.' : 'Opening your bookings.',
        langCode: lang,
      );
    }
    if (lower.contains('profile') || lower.contains('account') || lower.contains('खाता')) {
      return VoiceAssistantAction(
        type: 'open_profile',
        responseText: lang == 'hi-IN' ? 'Customer business profile khol raha hoon.' : 'Opening your business profile.',
        langCode: lang,
      );
    }

    final cities = ['delhi', 'mumbai', 'pune', 'jaipur', 'ahmedabad', 'surat', 'lucknow', 'kanpur', 'bengaluru', 'chennai', 'hyderabad'];
    String? fCity, tCity;
    for (final c in cities) {
      if (lower.contains(c)) {
        if (fCity == null) {
          fCity = c[0].toUpperCase() + c.substring(1);
        } else if (tCity == null) {
          tCity = c[0].toUpperCase() + c.substring(1);
          break;
        }
      }
    }

    if (fCity != null) {
      return VoiceAssistantAction(
        type: 'book_shipment',
        from: fCity,
        to: tCity,
        responseText: lang == 'hi-IN'
            ? '$fCity se ${tCity ?? ""} ke liye truck dhundh raha hoon.'
            : 'Finding trucks from $fCity to ${tCity ?? ""}.',
        langCode: lang,
      );
    }

    return VoiceAssistantAction(
      type: 'chat',
      responseText: lang == 'hi-IN'
          ? 'Main parcel book karne ya shipment track karne me madad kar sakta hoon. Boliye: Delhi se Jaipur truck chahiye.'
          : 'I can help you find trucks or track shipments. Try saying: Book truck from Delhi to Mumbai.',
      langCode: lang,
    );
  }

  Future<void> speak(String text, {String? langCode}) async {
    try {
      final code = langCode ?? detectLanguageCode(text);
      await _tts.setLanguage(code);
      await _tts.speak(text);
    } catch (_) {
      await _tts.speak(text);
    }
  }

  Future<void> speakMessage(String text) async {
    await speak(text);
  }

  Future<void> cancelSpeaking() async {
    await _tts.stop();
    _state = VoiceAssistantState.idle;
    notifyListeners();
  }

  void clearChat() {
    _chatHistory.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    super.dispose();
  }
}
