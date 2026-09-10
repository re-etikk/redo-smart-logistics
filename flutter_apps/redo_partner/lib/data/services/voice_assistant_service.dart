import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/config.dart';

enum VoiceAssistantState { idle, listening, processing, speaking, error }

class VoiceAssistantAction {
  final String type; // 'search_route', 'check_earnings', 'open_profile', 'register_truck', 'open_trips', 'chat', 'unknown'
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
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final VoiceAssistantAction? action;

  ChatMessage({
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
  String _transcribedText = '';
  String _lastResponse = '';
  VoiceAssistantAction? _lastAction;
  bool _isAvailable = false;

  // Continuous multi-turn conversation mode: stays listening until user stops
  bool _continuousMode = false;

  // Chat message history for text-to-text chat
  final List<ChatMessage> _chatHistory = [
    ChatMessage(
      text: 'Namaste! I am your REDO AI Assistant. You can talk to me in Hindi, English, Tamil, Telugu, Marathi, Bengali, or any language. How can I help you today?',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  VoiceAssistantState get state => _state;
  String get transcribedText => _transcribedText;
  String get lastResponse => _lastResponse;
  VoiceAssistantAction? get lastAction => _lastAction;
  bool get isListening => _state == VoiceAssistantState.listening;
  bool get isAvailable => _isAvailable;
  bool get continuousMode => _continuousMode;
  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);

  VoiceAssistantService() {
    _initTts();
    _initStt();
  }

  Future<void> _initStt() async {
    _isAvailable = await _stt.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_state == VoiceAssistantState.listening) {
            _processTranscript();
          }
        }
      },
      onError: (error) {
        _state = VoiceAssistantState.error;
        _lastResponse = 'Could not hear you. Please try again.';
        notifyListeners();
        // If continuous mode, try to recover after a brief delay
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

  /// Starts listening. If [continuous] is true, it keeps listening after speaking
  /// until user explicitly taps Stop or says a stop phrase.
  Future<void> startListening({bool continuous = true}) async {
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

  /// Manually stops listening or stops continuous conversation
  Future<void> stopListening() async {
    await _stt.stop();
    await _processTranscript();
  }

  /// Completely stops the continuous conversation loop
  Future<void> stopContinuousConversation() async {
    _continuousMode = false;
    await _stt.stop();
    await _tts.stop();
    _state = VoiceAssistantState.idle;
    _transcribedText = '';
    notifyListeners();
  }

  Future<void> _processTranscript() async {
    if (_transcribedText.trim().isEmpty) {
      _state = VoiceAssistantState.idle;
      notifyListeners();
      return;
    }

    final input = _transcribedText.trim();
    final lower = input.toLowerCase();

    // Check if user spoke a command to stop continuous conversation
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

    // Add to chat history
    _chatHistory.add(ChatMessage(
      text: input,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    try {
      final action = await _parseIntent(input);
      _lastAction = action;
      _lastResponse = action.responseText;

      _chatHistory.add(ChatMessage(
        text: action.responseText,
        isUser: false,
        timestamp: DateTime.now(),
        action: action,
      ));

      _state = VoiceAssistantState.speaking;
      notifyListeners();
      await _speak(action.responseText, langCode: action.langCode);
    } catch (e) {
      _lastResponse = 'Could not process that. Please try again.';
      _state = VoiceAssistantState.error;
      notifyListeners();
    }
  }

  /// Send text query via Text-to-Text Chat
  Future<void> sendTextMessage(String userText) async {
    final text = userText.trim();
    if (text.isEmpty) return;

    _chatHistory.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _state = VoiceAssistantState.processing;
    notifyListeners();

    try {
      final action = await _parseIntent(text);
      _lastAction = action;
      _lastResponse = action.responseText;

      _chatHistory.add(ChatMessage(
        text: action.responseText,
        isUser: false,
        timestamp: DateTime.now(),
        action: action,
      ));

      _state = VoiceAssistantState.idle;
      notifyListeners();
    } catch (e) {
      _chatHistory.add(ChatMessage(
        text: 'Sorry, I could not process that request. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _state = VoiceAssistantState.idle;
      notifyListeners();
    }
  }

  /// Automatically detects Indian language code from text using script heuristics
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

  Future<VoiceAssistantAction> _parseIntent(String userInput) async {
    // 1. Try Sarvam AI first with multilingual prompt
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
                  'You are REDO Smart Logistics Multilingual AI Assistant for truck drivers and cargo owners in India. '
                  'CRITICAL RULE: Detect the exact language used by the user (Hindi, English, Tamil, Telugu, Kannada, Marathi, Gujarati, Punjabi, Bengali, Odia, Malayalam, Urdu, Hinglish). '
                  'You MUST formulate your response in the EXACT SAME LANGUAGE as the user query. '
                  'Respond with ONLY a raw JSON object: '
                  '{"type":"search_route"|"check_earnings"|"open_profile"|"register_truck"|"open_trips"|"chat","from":"city_or_null","to":"city_or_null","lang":"hi-IN|ta-IN|te-IN|kn-IN|mr-IN|gu-IN|pa-IN|bn-IN|ml-IN|en-IN","response":"Natural response in the detected user language"}. '
                  'Keep response concise, professional and helpful. Return ONLY valid JSON.',
            },
            {
              'role': 'user',
              'content': userInput,
            }
          ],
          'temperature': 0.1,
          'max_tokens': 160,
        }),
      ).timeout(const Duration(seconds: 8));

      if (sarvamRes.statusCode == 200) {
        final data = jsonDecode(sarvamRes.body);
        final content = data['choices']?[0]?['message']?['content']?.toString() ?? '';
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(content);
        if (jsonMatch != null) {
          final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
          final respText = parsed['response'] as String? ?? 'Showing results';
          final detectedLang = (parsed['lang'] as String?) ?? detectLanguageCode(respText);

          return VoiceAssistantAction(
            type: parsed['type'] as String? ?? 'unknown',
            fromCity: parsed['from'] as String?,
            toCity: parsed['to'] as String?,
            responseText: respText,
            langCode: detectedLang,
          );
        }
      }
    } catch (_) {}

    // 2. HuggingFace fallback
    try {
      const systemPrompt =
          'You are REDO Logistics Assistant. Auto-detect user language and reply in the EXACT SAME language. '
          'Respond with ONLY JSON: {"type":"search_route","from":"city","to":"city","response":"text"}';
      final prompt = '<s>[INST] $systemPrompt\\n\\nUser said: "$userInput" [/INST]';

      final response = await http.post(
        Uri.parse('https://api-inference.huggingface.co/models/${AppConfig.hfModelId}'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.huggingFaceApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {
            'max_new_tokens': 150,
            'temperature': 0.1,
            'return_full_text': false,
          },
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String generatedText = '';
        if (data is List && data.isNotEmpty) {
          generatedText = (data[0] as Map<String, dynamic>)['generated_text'] as String? ?? '';
        } else if (data is Map) {
          generatedText = (data as Map<String, dynamic>)['generated_text'] as String? ?? '';
        }
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(generatedText);
        if (jsonMatch != null) {
          final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
          final respText = parsed['response'] as String? ?? 'Done!';
          return VoiceAssistantAction(
            type: parsed['type'] as String? ?? 'unknown',
            fromCity: parsed['from'] as String?,
            toCity: parsed['to'] as String?,
            responseText: respText,
            langCode: detectLanguageCode(respText),
          );
        }
      }
    } catch (_) {}

    // 3. Rule-based multilingual fallback
    return _parseIntentLocally(userInput);
  }

  VoiceAssistantAction _parseIntentLocally(String input) {
    final lower = input.toLowerCase();
    final lang = detectLanguageCode(input);

    final routeKeywords = ['load', 'trip', 'route', 'se', 'from', 'cargo', 'freight', 'माल', 'गाड़ी', 'लोड', 'सफर', 'பயணம்', 'சுமை', 'లోడ్', 'బాట'];
    final cities = [
      'delhi', 'mumbai', 'pune', 'jaipur', 'ahmedabad', 'surat',
      'lucknow', 'kanpur', 'hyderabad', 'chennai', 'kolkata', 'bengaluru', 'bangalore',
      'indore', 'nagpur', 'bhopal', 'patna', 'agra', 'varanasi'
    ];

    if (routeKeywords.any((k) => lower.contains(k))) {
      String? fromCity, toCity;
      for (final city in cities) {
        if (lower.contains(city)) {
          if (fromCity == null) {
            fromCity = city[0].toUpperCase() + city.substring(1);
          } else if (toCity == null) {
            toCity = city[0].toUpperCase() + city.substring(1);
            break;
          }
        }
      }
      if (fromCity != null) {
        final dest = toCity != null ? ' to $toCity' : '';
        final resp = lang == 'hi-IN'
            ? '$fromCity se ${toCity ?? ''} ke return loads dikha raha hoon.'
            : 'Searching return loads from $fromCity$dest.';
        return VoiceAssistantAction(
          type: 'search_route',
          fromCity: fromCity,
          toCity: toCity,
          responseText: resp,
          langCode: lang,
        );
      }
    }

    if (lower.contains('earning') || lower.contains('kamai') || lower.contains('income') || lower.contains('कमाई') || lower.contains('पैसा')) {
      final resp = lang == 'hi-IN'
          ? 'Aapka earnings dashboard khol raha hoon.'
          : 'Opening your earnings dashboard.';
      return VoiceAssistantAction(
        type: 'check_earnings',
        responseText: resp,
        langCode: lang,
      );
    }

    if (lower.contains('profile') || lower.contains('kyc') || lower.contains('document') || lower.contains('कागजात')) {
      return VoiceAssistantAction(
        type: 'open_profile',
        responseText: lang == 'hi-IN' ? 'Aapka profile khol raha hoon.' : 'Opening your profile.',
        langCode: lang,
      );
    }

    if (lower.contains('truck') || lower.contains('register') || lower.contains('ट्रक')) {
      return VoiceAssistantAction(
        type: 'register_truck',
        responseText: lang == 'hi-IN' ? 'Commercial truck registration form khol raha hoon.' : 'Opening truck registration form.',
        langCode: lang,
      );
    }

    if (lower.contains('trip') || lower.contains('booking') || lower.contains('सवारी')) {
      return VoiceAssistantAction(
        type: 'open_trips',
        responseText: lang == 'hi-IN' ? 'Aapki active trips dikha raha hoon.' : 'Opening your active trips.',
        langCode: lang,
      );
    }

    final defaultResp = lang == 'hi-IN'
        ? 'Main return loads search karne, kamai check karne aur profile manage karne me madad kar sakta hoon. Boliye: Delhi se Mumbai ka load dhundho.'
        : 'I can help you search return loads, check earnings, or manage your profile. Try saying: Find loads from Delhi to Mumbai.';

    return VoiceAssistantAction(
      type: 'chat',
      responseText: defaultResp,
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

  Future<void> speakMessage(String text) async {
    await _speak(text);
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
