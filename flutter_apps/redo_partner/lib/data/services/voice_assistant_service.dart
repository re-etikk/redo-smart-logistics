import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/config.dart';

enum VoiceAssistantState { idle, listening, processing, speaking, error }

class VoiceAssistantAction {
  final String type; // 'search_route', 'check_earnings', 'open_profile', 'accept_load', 'unknown'
  final String? fromCity;
  final String? toCity;
  final String responseText;

  const VoiceAssistantAction({
    required this.type,
    this.fromCity,
    this.toCity,
    required this.responseText,
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

  VoiceAssistantState get state => _state;
  String get transcribedText => _transcribedText;
  String get lastResponse => _lastResponse;
  VoiceAssistantAction? get lastAction => _lastAction;
  bool get isListening => _state == VoiceAssistantState.listening;
  bool get isAvailable => _isAvailable;

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
    });
  }

  Future<void> startListening() async {
    if (!_isAvailable) {
      _isAvailable = await _stt.initialize();
    }
    if (!_isAvailable) {
      _lastResponse = 'Microphone not available.';
      notifyListeners();
      return;
    }
    _transcribedText = '';
    _lastResponse = '';
    _lastAction = null;
    _state = VoiceAssistantState.listening;
    notifyListeners();

    await _stt.listen(
      onResult: (result) {
        _transcribedText = result.recognizedWords;
        notifyListeners();
      },
      localeId: 'en_IN',
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
    await _processTranscript();
  }

  Future<void> _processTranscript() async {
    if (_transcribedText.trim().isEmpty) {
      _state = VoiceAssistantState.idle;
      notifyListeners();
      return;
    }
    _state = VoiceAssistantState.processing;
    notifyListeners();

    try {
      final action = await _parseIntentWithHF(_transcribedText);
      _lastAction = action;
      _lastResponse = action.responseText;
      _state = VoiceAssistantState.speaking;
      notifyListeners();
      await _speak(action.responseText);
    } catch (e) {
      _lastResponse = 'Sorry, I could not process that. Please try again.';
      _state = VoiceAssistantState.error;
      notifyListeners();
    }
  }

  Future<VoiceAssistantAction> _parseIntentWithHF(String userInput) async {
    // 1. Try Sarvam AI first (State-of-the-art Indian Multilingual LLM)
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
              'content': 'You are a smart multilingual logistics voice assistant for REDO Partner app in India. Parse user request (can be Hindi, Hinglish, English, Tamil, Telugu, etc.) and respond with ONLY a JSON object: {"type":"search_route","from":"Delhi","to":"Jaipur","response":"Delhi se Jaipur ke loads dikha raha hoon."}. Possible types: search_route, check_earnings, open_profile, register_truck, open_trips, unknown. Keep response concise and conversational in the same language. Return ONLY raw JSON.',
            },
            {
              'role': 'user',
              'content': userInput,
            }
          ],
          'temperature': 0.1,
          'max_tokens': 150,
        }),
      ).timeout(const Duration(seconds: 10));

      if (sarvamRes.statusCode == 200) {
        final data = jsonDecode(sarvamRes.body);
        final content = data['choices']?[0]?['message']?['content']?.toString() ?? '';
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(content);
        if (jsonMatch != null) {
          final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
          return VoiceAssistantAction(
            type: parsed['type'] as String? ?? 'unknown',
            fromCity: parsed['from'] as String?,
            toCity: parsed['to'] as String?,
            responseText: parsed['response'] as String? ?? 'Showing results',
          );
        }
      }
    } catch (_) {
      // Fall through to HuggingFace
    }

    // 2. Try Hugging Face fallback
    try {
      const systemPrompt = '''
You are a logistics voice assistant for REDO Freight app in India. 
Parse the user's request and respond with ONLY a JSON object like:
{"type":"search_route","from":"Delhi","to":"Mumbai","response":"Searching loads from Delhi to Mumbai"}
Possible types: search_route, check_earnings, open_profile, register_truck, open_trips, unknown. Return ONLY valid JSON.''';

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
      ).timeout(const Duration(seconds: 10));

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
          return VoiceAssistantAction(
            type: parsed['type'] as String? ?? 'unknown',
            fromCity: parsed['from'] as String?,
            toCity: parsed['to'] as String?,
            responseText: parsed['response'] as String? ?? 'Done!',
          );
        }
      }
    } catch (_) {
      // Fall through to local regex
    }

    // 3. Offline rule-based parsing
    return _parseIntentLocally(userInput);
  }

  VoiceAssistantAction _parseIntentLocally(String input) {
    final lower = input.toLowerCase();
    // Search route patterns
    final routeKeywords = ['load', 'trip', 'route', 'se', 'from', 'cargo', 'freight'];
    final cities = ['delhi', 'mumbai', 'pune', 'jaipur', 'ahmedabad', 'surat',
        'lucknow', 'kanpur', 'hyderabad', 'chennai', 'kolkata', 'bengaluru', 'bangalore',
        'indore', 'nagpur', 'bhopal', 'patna', 'agra', 'varanasi'];
    
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
        return VoiceAssistantAction(
          type: 'search_route',
          fromCity: fromCity,
          toCity: toCity,
          responseText: 'Searching loads from $fromCity$dest',
        );
      }
    }
    if (lower.contains('earning') || lower.contains('kamai') || lower.contains('income')) {
      return const VoiceAssistantAction(
        type: 'check_earnings',
        responseText: 'Opening your earnings dashboard.',
      );
    }
    if (lower.contains('profile') || lower.contains('kyc') || lower.contains('document')) {
      return const VoiceAssistantAction(
        type: 'open_profile',
        responseText: 'Opening your profile.',
      );
    }
    if (lower.contains('truck') || lower.contains('register')) {
      return const VoiceAssistantAction(
        type: 'register_truck',
        responseText: 'Opening truck registration.',
      );
    }
    if (lower.contains('trip') || lower.contains('booking')) {
      return const VoiceAssistantAction(
        type: 'open_trips',
        responseText: 'Opening your active trips.',
      );
    }
    return const VoiceAssistantAction(
      type: 'unknown',
      responseText: 'I can help you search loads, check earnings, or manage your profile. Try saying: Delhi se Mumbai ka load dhundho.',
    );
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  Future<void> cancelSpeaking() async {
    await _tts.stop();
    _state = VoiceAssistantState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    super.dispose();
  }
}
