import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/config.dart';

class VoiceAssistantAction {
  final String type; // book_shipment, track_shipment, open_profile, open_bookings, unknown
  final String? from;
  final String? to;
  final String? responseText;

  VoiceAssistantAction({required this.type, this.from, this.to, this.responseText});
}

class VoiceAssistantService extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isListening = false;
  bool get isListening => _isListening;
  
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String _currentText = '';
  String get currentText => _currentText;

  Future<void> init() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> startListening(Function(VoiceAssistantAction) onResult) async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;

    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          if (_isListening) {
            _stopAndProcess(onResult);
          }
        }
      },
      onError: (val) => _stopListening(),
    );

    if (available) {
      _isListening = true;
      _currentText = '';
      notifyListeners();
      _speech.listen(
        onResult: (val) {
          _currentText = val.recognizedWords;
          notifyListeners();
        },
        localeId: 'en_IN',
      );
    }
  }

  void _stopListening() {
    _isListening = false;
    _speech.stop();
    notifyListeners();
  }

  Future<void> _stopAndProcess(Function(VoiceAssistantAction) onResult) async {
    _stopListening();
    if (_currentText.isEmpty) return;

    _isProcessing = true;
    notifyListeners();

    try {
      final action = await _processTextWithLLM(_currentText);
      if (action.responseText != null) {
        await speak(action.responseText!);
      }
      onResult(action);
    } catch (e) {
      await speak("Sorry, I didn't catch that.");
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<VoiceAssistantAction> _processTextWithLLM(String text) async {
    // 1. Try Sarvam AI first
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
              'content': 'You are a smart multilingual logistics voice assistant for REDO Customer app in India. Parse user request (can be Hindi, Hinglish, English, Tamil, Telugu, etc.) and respond with ONLY a JSON object: {"type":"book_shipment","from":"Delhi","to":"Mumbai","response":"Delhi se Mumbai ke trucks search kar raha hoon."}. Possible types: book_shipment, track_shipment, open_profile, open_bookings, unknown. Keep response concise and conversational in the same language. Return ONLY raw JSON.',
            },
            {
              'role': 'user',
              'content': text,
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
          final result = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
          return VoiceAssistantAction(
            type: result['type'] ?? 'unknown',
            from: result['from'],
            to: result['to'],
            responseText: result['response'],
          );
        }
      }
    } catch (_) {
      // Fall through to HuggingFace
    }

    // 2. Try Hugging Face fallback
    try {
      final systemPrompt = '''You are a logistics voice assistant for REDO Customer app in India.
Parse the user's request and respond with ONLY a JSON object:
{"type":"book_shipment","from":"Delhi","to":"Mumbai","response":"Booking shipment from Delhi to Mumbai"}
Possible types: book_shipment, track_shipment, open_profile, open_bookings, unknown''';

      final response = await http.post(
        Uri.parse('https://api-inference.huggingface.co/models/${AppConfig.hfModelId}/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.huggingFaceApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": text}
          ],
          "max_tokens": 100,
          "temperature": 0.1,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].toString().trim();
        final startIndex = content.indexOf('{');
        final endIndex = content.lastIndexOf('}');
        if (startIndex != -1 && endIndex != -1) {
          final jsonStr = content.substring(startIndex, endIndex + 1);
          final result = jsonDecode(jsonStr);
          return VoiceAssistantAction(
            type: result['type'] ?? 'unknown',
            from: result['from'],
            to: result['to'],
            responseText: result['response'],
          );
        }
      }
    } catch (_) {}

    // 3. Fallback: simple heuristic
    final lower = text.toLowerCase();
    if (lower.contains('track') || lower.contains('kahan') || lower.contains('status')) {
      return VoiceAssistantAction(type: 'track_shipment', responseText: 'Opening shipment tracking.');
    }
    if (lower.contains('booking') || lower.contains('order') || lower.contains('history')) {
      return VoiceAssistantAction(type: 'open_bookings', responseText: 'Opening your bookings.');
    }
    if (lower.contains('profile') || lower.contains('account')) {
      return VoiceAssistantAction(type: 'open_profile', responseText: 'Opening your profile.');
    }
    return VoiceAssistantAction(type: 'unknown', responseText: "I can help you book trucks or track shipments.");
  }

  Future<void> speak(String text) async {
    await _tts.speak(text);
  }
}
