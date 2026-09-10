import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/config.dart';

enum VoiceAssistantState { idle, listening, processing, speaking, error }

class VoiceAssistantAction {
  final String type; // book_shipment, track_shipment, open_profile, open_bookings, chat, unknown
  final String? fromCity;
  final String? toCity;
  final String responseText;
  final String? langCode;

  const VoiceAssistantAction({
    required this.type,
    this.fromCity,
    this.toCity,
    required this.responseText,
    this.langCode,
  });

  String? get from => fromCity;
  String? get to => toCity;

  Map<String, dynamic> toJson() => {
    'type': type,
    'fromCity': fromCity,
    'toCity': toCity,
    'responseText': responseText,
    'langCode': langCode,
  };

  factory VoiceAssistantAction.fromJson(Map<String, dynamic> j) => VoiceAssistantAction(
    type: j['type'] as String? ?? 'unknown',
    fromCity: (j['fromCity'] ?? j['from']) as String?,
    toCity: (j['toCity'] ?? j['to']) as String?,
    responseText: j['responseText'] as String? ?? '',
    langCode: j['langCode'] as String?,
  );
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final VoiceAssistantAction? action;
  // True only for the message just added in THIS app session — drives the
  // one-time typewriter reveal animation in the chat UI.
  bool isNew;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.action,
    this.isNew = false,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
    'action': action?.toJson(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    text: j['text'] as String? ?? '',
    isUser: j['isUser'] as bool? ?? false,
    timestamp: DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
    action: j['action'] != null ? VoiceAssistantAction.fromJson(j['action'] as Map<String, dynamic>) : null,
    isNew: false,
  );
}

typedef CustomerChatMessage = ChatMessage;

class VoiceAssistantService extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  static const _prefsKey = 'redo_customer_chat_history_v1';
  static const _maxStoredMessages = 60;

  VoiceAssistantState _state = VoiceAssistantState.idle;
  String _transcribedText = '';
  String _lastResponse = '';
  VoiceAssistantAction? _lastAction;
  bool _isAvailable = false;
  bool _continuousMode = false;

  void Function(VoiceAssistantAction action)? onActionReady;

  ChatMessage _welcomeMessage() => ChatMessage(
    text: 'Namaste! How can I help you book freight or track shipments today? You can speak or write in Hindi, English, Tamil, Telugu, or any language.',
    isUser: false,
    timestamp: DateTime.now(),
  );

  late final List<ChatMessage> _chatHistory = [_welcomeMessage()];

  VoiceAssistantState get state => _state;
  String get transcribedText => _transcribedText;
  String get currentText => _transcribedText;
  String get lastResponse => _lastResponse;
  VoiceAssistantAction? get lastAction => _lastAction;
  bool get isListening => _state == VoiceAssistantState.listening;
  bool get isProcessing => _state == VoiceAssistantState.processing;
  bool get isAvailable => _isAvailable;
  bool get continuousMode => _continuousMode;
  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);

  VoiceAssistantService() {
    _initTts();
    _initStt();
    _loadHistory();
  }

  Future<void> init() async {
    // Kept for backward compatibility
    _initTts();
    _initStt();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List;
      final restored = list
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
      if (restored.isNotEmpty) {
        _chatHistory
          ..clear()
          ..addAll(restored);
      }
    } catch (_) {
      // Corrupt cache — keep welcome message
    }
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = _chatHistory.length > _maxStoredMessages
          ? _chatHistory.sublist(_chatHistory.length - _maxStoredMessages)
          : _chatHistory;
      await prefs.setString(_prefsKey, jsonEncode(toSave.map((m) => m.toJson()).toList()));
    } catch (_) {}
  }

  /// Clears saved + in-memory chat history (e.g. a "New chat" button).
  Future<void> clearHistory() async {
    _chatHistory
      ..clear()
      ..add(_welcomeMessage());
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }

  Future<void> _initStt() async {
    _isAvailable = await _stt.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_state == VoiceAssistantState.listening) {
            _stopAndProcess();
          }
        }
      },
      onError: (error) {
        _state = VoiceAssistantState.error;
        _lastResponse = 'Could not hear you. Please try again.';
        notifyListeners();
        if (_continuousMode) {
          Future.delayed(const Duration(seconds: 2), () {
            if (_continuousMode && _state == VoiceAssistantState.error) {
              startListening(continuous: true);
            }
          });
        }
      },
    );
    notifyListeners();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      _state = VoiceAssistantState.idle;
      notifyListeners();

      // In continuous mode, restart listening automatically after speaking!
      if (_continuousMode) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (_continuousMode) {
            startListening(continuous: true);
          }
        });
      }
    });
  }

  Future<void> startListening({Function(VoiceAssistantAction)? onResult, bool continuous = true}) async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _lastResponse = 'Microphone permission denied.';
      notifyListeners();
      return;
    }

    if (!_isAvailable) {
      _isAvailable = await _stt.initialize();
    }
    if (!_isAvailable) {
      _lastResponse = 'Microphone not available.';
      notifyListeners();
      return;
    }

    _continuousMode = continuous;
    _transcribedText = '';
    _lastAction = null;
    _state = VoiceAssistantState.listening;
    notifyListeners();

    await _stt.listen(
      onResult: (result) {
        _transcribedText = result.recognizedWords;
        notifyListeners();
      },
      localeId: 'en_IN',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 2),
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
    await _stopAndProcess();
  }

  Future<void> stopContinuousConversation() async {
    _continuousMode = false;
    await _stt.stop();
    await _tts.stop();
    _state = VoiceAssistantState.idle;
    _transcribedText = '';
    notifyListeners();
  }

  Future<void> _stopAndProcess() async {
    await _stt.stop();
    if (_transcribedText.trim().isEmpty) {
      _state = VoiceAssistantState.idle;
      notifyListeners();
      return;
    }

    final input = _transcribedText.trim();
    final lower = input.toLowerCase();

    // Check if user spoke stop command
    if (lower == 'stop' ||
        lower == 'ruko' ||
        lower.contains('band karo') ||
        lower.contains('stop listening') ||
        lower == 'close' ||
        lower == 'bye') {
      _continuousMode = false;
      _state = VoiceAssistantState.idle;
      _lastResponse = 'Assistant stopped. Tap microphone anytime to start again.';
      notifyListeners();
      await _speak('Assistant stopped.');
      return;
    }

    _state = VoiceAssistantState.processing;
    notifyListeners();

    _chatHistory.add(ChatMessage(
      text: input,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    unawaited(_saveHistory());

    try {
      final action = await _processTextWithLLM(input);
      _lastAction = action;
      _lastResponse = action.responseText;

      _chatHistory.add(ChatMessage(
        text: action.responseText,
        isUser: false,
        timestamp: DateTime.now(),
        action: action,
        isNew: true,
      ));
      unawaited(_saveHistory());

      // Fire navigation/UI side-effects immediately — don't wait for TTS.
      onActionReady?.call(action);

      _state = VoiceAssistantState.speaking;
      notifyListeners();
      await _speak(action.responseText, langCode: action.langCode);
    } catch (e) {
      _lastResponse = 'Could not process that. Please try again.';
      _state = VoiceAssistantState.error;
      notifyListeners();
    }
  }

  Future<void> sendTextMessage(String userText, [Function(VoiceAssistantAction)? onResult]) async {
    final text = userText.trim();
    if (text.isEmpty) return;

    _chatHistory.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    unawaited(_saveHistory());
    _state = VoiceAssistantState.processing;
    notifyListeners();

    try {
      final action = await _processTextWithLLM(text);
      _lastAction = action;
      _lastResponse = action.responseText;

      _chatHistory.add(ChatMessage(
        text: action.responseText,
        isUser: false,
        timestamp: DateTime.now(),
        action: action,
        isNew: true,
      ));
      unawaited(_saveHistory());

      onActionReady?.call(action);
      onResult?.call(action);

      _state = VoiceAssistantState.idle;
      notifyListeners();
    } catch (_) {
      _chatHistory.add(ChatMessage(
        text: 'Sorry, could not process that request. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      unawaited(_saveHistory());
      _state = VoiceAssistantState.idle;
      notifyListeners();
    }
  }

  static String detectLanguageCode(String text) {
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      // Devanagari (Hindi, Marathi)
      if (code >= 0x0900 && code <= 0x097F) return 'hi-IN';
      // Bengali
      if (code >= 0x0980 && code <= 0x09FF) return 'bn-IN';
      // Gurmukhi (Punjabi)
      if (code >= 0x0A00 && code <= 0x0A7F) return 'pa-IN';
      // Gujarati
      if (code >= 0x0A80 && code <= 0x0AFF) return 'gu-IN';
      // Tamil
      if (code >= 0x0B80 && code <= 0x0BFF) return 'ta-IN';
      // Telugu
      if (code >= 0x0C00 && code <= 0x0C7F) return 'te-IN';
      // Kannada
      if (code >= 0x0C80 && code <= 0x0CFF) return 'kn-IN';
      // Malayalam
      if (code >= 0x0D00 && code <= 0x0D7F) return 'ml-IN';
      // Arabic / Urdu
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
            type: result['type'] as String? ?? 'unknown',
            fromCity: result['from'] as String?,
            toCity: result['to'] as String?,
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
        fromCity: fCity,
        toCity: tCity,
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

  Future<void> _speak(String text, {String? langCode}) async {
    try {
      final code = langCode ?? detectLanguageCode(text);
      await _tts.setLanguage(code);
      await _tts.speak(text);
    } catch (_) {
      await _tts.speak(text);
    }
  }

  Future<void> speak(String text, {String? langCode}) async {
    await _speak(text, langCode: langCode);
  }

  Future<void> speakMessage(String text) async {
    await _speak(text);
  }

  Future<void> cancelSpeaking() async {
    await _tts.stop();
    _state = VoiceAssistantState.idle;
    notifyListeners();
  }

  void clearChat() {
    clearHistory();
  }

  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    super.dispose();
  }
}
