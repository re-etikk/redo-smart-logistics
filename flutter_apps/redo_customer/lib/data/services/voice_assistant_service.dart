import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/config.dart';

enum VoiceAssistantState { idle, listening, processing, speaking, error }

class VoiceAssistantAction {
  final String type; // rate_quote, track_shipment, recommend_vehicle, highway_advisory, book_shipment, open_bookings, open_profile, chat
  final String? fromCity;
  final String? toCity;
  final double? weightTons;
  final double? estimatedPriceInr;
  final double? basePrice;
  final double? fuelTollSurcharge;
  final double? distanceKm;
  final int? transitHours;
  final double? tollEstimateInr;
  final double? dieselLiters;
  final String? recommendedVehicle;
  final String? highwayName;
  final String? bookingId;
  final String? status;
  final String? driverName;
  final String? driverPhone;
  final String? truckNumber;
  final String responseText;
  final String? langCode;
  final String? aiEngineUsed;

  const VoiceAssistantAction({
    required this.type,
    this.fromCity,
    this.toCity,
    this.weightTons,
    this.estimatedPriceInr,
    this.basePrice,
    this.fuelTollSurcharge,
    this.distanceKm,
    this.transitHours,
    this.tollEstimateInr,
    this.dieselLiters,
    this.recommendedVehicle,
    this.highwayName,
    this.bookingId,
    this.status,
    this.driverName,
    this.driverPhone,
    this.truckNumber,
    required this.responseText,
    this.langCode,
    this.aiEngineUsed,
  });

  String? get from => fromCity;
  String? get to => toCity;

  Map<String, dynamic> toJson() => {
    'type': type,
    'fromCity': fromCity,
    'toCity': toCity,
    'weightTons': weightTons,
    'estimatedPriceInr': estimatedPriceInr,
    'basePrice': basePrice,
    'fuelTollSurcharge': fuelTollSurcharge,
    'distanceKm': distanceKm,
    'transitHours': transitHours,
    'tollEstimateInr': tollEstimateInr,
    'dieselLiters': dieselLiters,
    'recommendedVehicle': recommendedVehicle,
    'highwayName': highwayName,
    'bookingId': bookingId,
    'status': status,
    'driverName': driverName,
    'driverPhone': driverPhone,
    'truckNumber': truckNumber,
    'responseText': responseText,
    'langCode': langCode,
    'aiEngineUsed': aiEngineUsed,
  };

  factory VoiceAssistantAction.fromJson(Map<String, dynamic> j) => VoiceAssistantAction(
    type: j['type'] as String? ?? 'chat',
    fromCity: (j['fromCity'] ?? j['from']) as String?,
    toCity: (j['toCity'] ?? j['to']) as String?,
    weightTons: (j['weightTons'] as num?)?.toDouble(),
    estimatedPriceInr: (j['estimatedPriceInr'] as num?)?.toDouble(),
    basePrice: (j['basePrice'] as num?)?.toDouble(),
    fuelTollSurcharge: (j['fuelTollSurcharge'] as num?)?.toDouble(),
    distanceKm: (j['distanceKm'] as num?)?.toDouble(),
    transitHours: (j['transitHours'] as num?)?.toInt(),
    tollEstimateInr: (j['tollEstimateInr'] as num?)?.toDouble(),
    dieselLiters: (j['dieselLiters'] as num?)?.toDouble(),
    recommendedVehicle: j['recommendedVehicle'] as String?,
    highwayName: j['highwayName'] as String?,
    bookingId: j['bookingId'] as String?,
    status: j['status'] as String?,
    driverName: j['driverName'] as String?,
    driverPhone: j['driverPhone'] as String?,
    truckNumber: j['truckNumber'] as String?,
    responseText: j['responseText'] as String? ?? '',
    langCode: j['langCode'] as String?,
    aiEngineUsed: j['aiEngineUsed'] as String?,
  );
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final VoiceAssistantAction? action;
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

class _HubCoordinates {
  final double lat;
  final double lng;
  final String primaryHighway;
  const _HubCoordinates(this.lat, this.lng, this.primaryHighway);
}

class VoiceAssistantService extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  static const _prefsKey = 'redo_customer_chat_history_v2';
  static const _maxStoredMessages = 80;

  VoiceAssistantState _state = VoiceAssistantState.idle;
  String _transcribedText = '';
  String _lastResponse = '';
  VoiceAssistantAction? _lastAction;
  bool _isAvailable = false;
  bool _continuousMode = false;
  String _activeAiEngine = 'Sarvam AI 105B';

  void Function(VoiceAssistantAction action)? onActionReady;
  List<dynamic> Function()? realShipmentsProvider;

  static const Map<String, _HubCoordinates> _indianHubs = {
    'delhi': _HubCoordinates(28.6139, 77.2090, 'NH-48 / NH-44'),
    'mumbai': _HubCoordinates(19.0760, 72.8777, 'NH-48 Western Corridor'),
    'pune': _HubCoordinates(18.5204, 73.8567, 'Mumbai-Pune Expressway / NH-48'),
    'bengaluru': _HubCoordinates(12.9716, 77.5946, 'NH-44 / NH-48'),
    'bangalore': _HubCoordinates(12.9716, 77.5946, 'NH-44 / NH-48'),
    'chennai': _HubCoordinates(13.0827, 80.2707, 'NH-16 / NH-48'),
    'kolkata': _HubCoordinates(22.5726, 88.3639, 'NH-19 / NH-16'),
    'hyderabad': _HubCoordinates(17.3850, 78.4867, 'NH-44 / NH-65'),
    'ahmedabad': _HubCoordinates(23.0225, 72.5714, 'NE-1 / NH-48'),
    'jaipur': _HubCoordinates(26.9124, 75.7873, 'Delhi-Mumbai Expressway / NH-48'),
    'surat': _HubCoordinates(21.1702, 72.8311, 'NH-48 Industrial Corridor'),
    'lucknow': _HubCoordinates(26.8467, 80.9462, 'Agra-Lucknow Expressway / NH-27'),
    'kanpur': _HubCoordinates(26.4499, 80.3319, 'NH-19 Industrial Hub'),
    'indore': _HubCoordinates(22.7196, 75.8577, 'NH-52 Logistics Corridor'),
    'nagpur': _HubCoordinates(21.1458, 79.0882, 'Zero Mile / NH-44 & NH-53'),
    'ludhiana': _HubCoordinates(30.9010, 75.8573, 'NH-44 Northern Freight Corridor'),
    'chandigarh': _HubCoordinates(30.7333, 76.7794, 'NH-152 / NH-5'),
    'patna': _HubCoordinates(25.5941, 85.1376, 'NH-19 / NH-31'),
    'bhopal': _HubCoordinates(23.2599, 77.4126, 'NH-46 Central Hub'),
    'coimbatore': _HubCoordinates(11.0168, 76.9558, 'NH-544 Southern Textile Belt'),
    'kochi': _HubCoordinates(9.9312, 76.2673, 'NH-66 / NH-544'),
  };

  ChatMessage _welcomeMessage() => ChatMessage(
    text: 'Namaste! I am your Redo AI Logistics Co-Pilot, powered by Sarvam AI (105B Indic) and Hugging Face. Ask me for freight rates, live tracking, vehicle advice, or road conditions in any Indian language.',
    isUser: false,
    timestamp: DateTime.now(),
    action: const VoiceAssistantAction(
      type: 'chat',
      responseText: 'Namaste! How can I assist with your logistics today?',
      aiEngineUsed: 'Sarvam AI 105B & Hugging Face',
    ),
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
  String get activeAiEngine => _activeAiEngine;
  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);

  VoiceAssistantService() {
    _initTts();
    _initStt();
    _loadHistory();
  }

  void setActiveShipmentsProvider(List<dynamic> Function() provider) {
    realShipmentsProvider = provider;
  }

  Future<void> _initTts() async {
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.48);
      await _tts.setLanguage('hi-IN');
      _tts.setCompletionHandler(() {
        if (_state == VoiceAssistantState.speaking) {
          _state = VoiceAssistantState.idle;
          notifyListeners();
        }
      });
      _tts.setErrorHandler((_) {
        if (_state == VoiceAssistantState.speaking) {
          _state = VoiceAssistantState.idle;
          notifyListeners();
        }
      });
    } catch (_) {}
  }

  Future<void> _initStt() async {
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        _isAvailable = false;
        return;
      }
      _isAvailable = await _stt.initialize(
        onError: (err) {
          if (_state == VoiceAssistantState.listening) {
            _state = VoiceAssistantState.idle;
            notifyListeners();
          }
        },
        onStatus: (status) {
          if (status == 'notListening' && _state == VoiceAssistantState.listening) {
            _state = VoiceAssistantState.idle;
            notifyListeners();
          }
        },
      );
      notifyListeners();
    } catch (_) {
      _isAvailable = false;
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefsKey);
      if (list != null && list.isNotEmpty) {
        _chatHistory.clear();
        for (final item in list) {
          try {
            final json = jsonDecode(item) as Map<String, dynamic>;
            _chatHistory.add(ChatMessage.fromJson(json));
          } catch (_) {}
        }
        if (_chatHistory.isEmpty) {
          _chatHistory.add(_welcomeMessage());
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = _chatHistory.length > _maxStoredMessages
          ? _chatHistory.sublist(_chatHistory.length - _maxStoredMessages)
          : _chatHistory;
      final list = toSave.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList(_prefsKey, list);
    } catch (_) {}
  }

  void clearHistory() {
    _chatHistory.clear();
    _chatHistory.add(_welcomeMessage());
    _saveHistory();
    notifyListeners();
  }

  Future<void> stopContinuousConversation() async {
    _continuousMode = false;
    await stopListening();
  }

  Future<void> startListening({String? localeId, bool continuous = false}) async {
    _continuousMode = continuous;
    if (!_isAvailable) {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        _lastResponse = 'Microphone permission is required.';
        _state = VoiceAssistantState.error;
        notifyListeners();
        return;
      }
      await _initStt();
      if (!_isAvailable) {
        _lastResponse = 'Speech recognition unavailable on this device.';
        _state = VoiceAssistantState.error;
        notifyListeners();
        return;
      }
    }

    await cancelSpeaking();
    _transcribedText = '';
    _state = VoiceAssistantState.listening;
    notifyListeners();

    final targetLocale = localeId ?? 'hi_IN';
    final options = SpeechListenOptions(
      localeId: targetLocale,
      listenFor: const Duration(seconds: 25),
      pauseFor: const Duration(seconds: 3),
      listenMode: ListenMode.confirmation,
    );

    try {
      await _stt.listen(
        onResult: (result) {
          _transcribedText = result.recognizedWords;
          notifyListeners();
          if (result.finalResult) {
            stopListeningAndProcess();
          }
        },
        listenOptions: options,
      );
    } catch (_) {
      _state = VoiceAssistantState.idle;
      notifyListeners();
    }
  }

  Future<void> stopListeningAndProcess() async {
    await _stt.stop();
    if (_transcribedText.trim().isEmpty) {
      _state = VoiceAssistantState.idle;
      notifyListeners();
      return;
    }
    await _handleInputText(_transcribedText.trim());
  }

  Future<void> stopListening() async {
    await _stt.stop();
    _state = VoiceAssistantState.idle;
    notifyListeners();
  }

  Future<void> _handleInputText(String input) async {
    final lower = input.toLowerCase().trim();
    if (lower.contains('chup') ||
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
      final action = await _processQueryWithDualAi(input);
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

      _state = VoiceAssistantState.speaking;
      notifyListeners();
      await _speak(action.responseText, langCode: action.langCode);
    } catch (_) {
      _lastResponse = 'Network timeout. Please tap again.';
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
      final action = await _processQueryWithDualAi(text);
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
        text: 'Apologies, could not process that request. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      unawaited(_saveHistory());
      _state = VoiceAssistantState.idle;
      notifyListeners();
    }
  }

  Future<VoiceAssistantAction> _processQueryWithDualAi(String text) async {
    final lang = detectLanguageCode(text);
    final lower = text.toLowerCase();

    // 1. Check real shipment tracking request
    if (lower.contains('track') ||
        lower.contains('kahan hai') ||
        lower.contains('kaha hai') ||
        lower.contains('where is') ||
        lower.contains('status') ||
        lower.contains('ट्रैक') ||
        lower.contains('कहाँ')) {
      final realShipmentAction = _checkRealShipmentTracking(text, lang);
      if (realShipmentAction != null) {
        return realShipmentAction;
      }
    }

    // 2. Extract Indian cities and weight from query
    final extracted = _extractCorridorAndWeight(lower);
    final fromCity = extracted['from'] as String?;
    final toCity = extracted['to'] as String?;
    final weightTons = extracted['weight'] as double?;

    // 3. Fast corridor computation
    double distanceKm = 0;
    int transitHours = 0;
    double estimatedPrice = 0;
    double basePrice = 0;
    double fuelToll = 0;
    double tollEstimate = 0;
    double dieselLiters = 0;
    String highway = 'National Highway Corridor';
    String truck = '32ft Multi-Axle Container (18 Ton)';

    if (fromCity != null && toCity != null) {
      final metrics = _calculateCorridorMetrics(fromCity, toCity, weightTons ?? 10.0);
      distanceKm = metrics['distanceKm'] as double;
      transitHours = metrics['transitHours'] as int;
      estimatedPrice = metrics['estimatedPrice'] as double;
      basePrice = metrics['basePrice'] as double;
      fuelToll = metrics['fuelToll'] as double;
      tollEstimate = metrics['tollEstimate'] as double;
      dieselLiters = metrics['dieselLiters'] as double;
      highway = metrics['highway'] as String;
      truck = metrics['recommendedTruck'] as String;
    } else if (weightTons != null) {
      truck = _recommendVehicleForWeight(weightTons);
    }

    // 4. Try Primary Engine: Sarvam AI 105B Indic Conversational Model
    try {
      final sarvamResponse = await _callSarvamAi(text, fromCity, toCity, weightTons, lang);
      if (sarvamResponse != null && sarvamResponse.trim().isNotEmpty) {
        _activeAiEngine = 'Sarvam AI 105B';
        return VoiceAssistantAction(
          type: (fromCity != null && toCity != null)
              ? 'rate_quote'
              : (weightTons != null ? 'recommend_vehicle' : 'chat'),
          fromCity: fromCity,
          toCity: toCity,
          weightTons: weightTons,
          estimatedPriceInr: estimatedPrice > 0 ? estimatedPrice : null,
          basePrice: basePrice > 0 ? basePrice : null,
          fuelTollSurcharge: fuelToll > 0 ? fuelToll : null,
          distanceKm: distanceKm > 0 ? distanceKm : null,
          transitHours: transitHours > 0 ? transitHours : null,
          tollEstimateInr: tollEstimate > 0 ? tollEstimate : null,
          dieselLiters: dieselLiters > 0 ? dieselLiters : null,
          recommendedVehicle: truck,
          highwayName: highway,
          responseText: sarvamResponse,
          langCode: lang,
          aiEngineUsed: 'Sarvam AI (105B Indic)',
        );
      }
    } catch (_) {}

    // 5. Try Secondary Engine: Hugging Face Fast Llama-3.1 Router
    try {
      final hfResponse = await _callHuggingFace(text, fromCity, toCity, weightTons);
      if (hfResponse != null && hfResponse.trim().isNotEmpty) {
        _activeAiEngine = 'Hugging Face (Llama-3.1)';
        return VoiceAssistantAction(
          type: (fromCity != null && toCity != null)
              ? 'rate_quote'
              : (weightTons != null ? 'recommend_vehicle' : 'chat'),
          fromCity: fromCity,
          toCity: toCity,
          weightTons: weightTons,
          estimatedPriceInr: estimatedPrice > 0 ? estimatedPrice : null,
          basePrice: basePrice > 0 ? basePrice : null,
          fuelTollSurcharge: fuelToll > 0 ? fuelToll : null,
          distanceKm: distanceKm > 0 ? distanceKm : null,
          transitHours: transitHours > 0 ? transitHours : null,
          tollEstimateInr: tollEstimate > 0 ? tollEstimate : null,
          dieselLiters: dieselLiters > 0 ? dieselLiters : null,
          recommendedVehicle: truck,
          highwayName: highway,
          responseText: hfResponse,
          langCode: lang,
          aiEngineUsed: 'Hugging Face (Llama-3.1)',
        );
      }
    } catch (_) {}

    // 6. Instant Fallback: REDO Intelligent Logistics Core (< 5ms)
    _activeAiEngine = 'REDO Logistics Core';
    return _buildLogisticsCoreFallback(text, fromCity, toCity, weightTons, distanceKm, estimatedPrice, transitHours, highway, truck, lang);
  }

  Future<String?> _callSarvamAi(String userQuery, String? from, String? to, double? weight, String lang) async {
    const systemPrompt = 'You are REDO Smart Logistics AI Assistant in India. Answer in user language (Hindi, Hinglish, English, Tamil, Telugu, etc.). Keep reply friendly, concise (2-3 sentences), practical for Indian freight operations.';

    final res = await http.post(
      Uri.parse(AppConfig.sarvamChatUrl),
      headers: {
        'api-subscription-key': AppConfig.sarvamApiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'sarvam-105b-conversations',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userQuery},
        ],
        'temperature': 0.3,
        'max_tokens': 160,
      }),
    ).timeout(const Duration(milliseconds: 3800));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final raw = data['choices']?[0]?['message']?['content']?.toString();
      if (raw != null && raw.trim().isNotEmpty) {
        return raw.trim();
      }
    }
    return null;
  }

  Future<String?> _callHuggingFace(String userQuery, String? from, String? to, double? weight) async {
    final res = await http.post(
      Uri.parse(AppConfig.hfRouterUrl),
      headers: {
        'Authorization': 'Bearer ${AppConfig.huggingFaceApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': AppConfig.hfModelId,
        'messages': [
          {
            'role': 'system',
            'content': 'You are REDO Logistics AI Assistant in India. Answer in user language (Hindi/English). Concise (2-3 sentences) with freight price, vehicle, and corridor transit info.',
          },
          {'role': 'user', 'content': userQuery},
        ],
        'max_tokens': 150,
      }),
    ).timeout(const Duration(milliseconds: 4000));

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final raw = data['choices']?[0]?['message']?['content']?.toString();
      if (raw != null && raw.trim().isNotEmpty) {
        return raw.trim();
      }
    }
    return null;
  }

  VoiceAssistantAction? _checkRealShipmentTracking(String query, String lang) {
    if (realShipmentsProvider == null) return null;
    final shipments = realShipmentsProvider!();

    if (shipments.isEmpty) {
      final isHindi = lang.startsWith('hi');
      return VoiceAssistantAction(
        type: 'track_shipment',
        responseText: isHindi
            ? 'Aapke account me abhi koi active shipment nahi hai. Naya load book karne ke liye "Book a Truck" tap karein.'
            : 'No active shipments found for your account right now. Tap "Book a Truck" to create a new booking.',
        langCode: lang,
        aiEngineUsed: 'REDO Core Telemetry',
      );
    }

    dynamic target;
    for (final s in shipments) {
      final st = (s.status as String? ?? '').toLowerCase();
      if (['in_transit', 'picked_up', 'confirmed', 'pickup_ready', 'assigned'].contains(st)) {
        target = s;
        break;
      }
    }
    target ??= shipments.first;

    final id = target.bookingId as String? ?? 'RDL-1001';
    final origin = target.originAddress as String? ?? 'Origin';
    final dest = target.destAddress as String? ?? 'Destination';
    final status = target.status as String? ?? 'in_transit';
    final driver = target.assignedDriverName as String? ?? 'Verified Partner Driver';
    final phone = target.assignedDriverPhone as String?;
    final truckNum = target.assignedTruckNumber as String? ?? 'MH-04-AB-1234';

    final isHindi = lang.startsWith('hi');
    final resp = isHindi
        ? 'Aapka shipment #$id ($origin se $dest) abhi "$status" status par hai. Truck: $truckNum, Driver: $driver. Live location dekhne ke liye card par tap karein.'
        : 'Your shipment #$id ($origin to $dest) is currently "$status". Truck: $truckNum, Driver: $driver. Tap the card below to view live GPS.';

    return VoiceAssistantAction(
      type: 'track_shipment',
      bookingId: id,
      fromCity: origin,
      toCity: dest,
      status: status,
      driverName: driver,
      driverPhone: phone,
      truckNumber: truckNum,
      responseText: resp,
      langCode: lang,
      aiEngineUsed: 'REDO Live Telemetry',
    );
  }

  Map<String, dynamic> _extractCorridorAndWeight(String lower) {
    String? from;
    String? to;
    double? weight;

    final cities = _indianHubs.keys.toList();
    for (final c in cities) {
      if (lower.contains(c)) {
        if (from == null) {
          from = c[0].toUpperCase() + c.substring(1);
        } else if (to == null && c != from.toLowerCase()) {
          to = c[0].toUpperCase() + c.substring(1);
          break;
        }
      }
    }

    final weightRegex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:ton|t|टन|tonne|mt)', caseSensitive: false);
    final m = weightRegex.firstMatch(lower);
    if (m != null) {
      weight = double.tryParse(m.group(1) ?? '');
    }

    return {'from': from, 'to': to, 'weight': weight};
  }

  Map<String, dynamic> _calculateCorridorMetrics(String from, String to, double weight) {
    final fromCoord = _indianHubs[from.toLowerCase()] ?? const _HubCoordinates(28.61, 77.20, 'NH-48');
    final toCoord = _indianHubs[to.toLowerCase()] ?? const _HubCoordinates(19.07, 72.87, 'NH-48');

    const r = 6371.0;
    final dLat = (toCoord.lat - fromCoord.lat) * (pi / 180.0);
    final dLon = (toCoord.lng - fromCoord.lng) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(fromCoord.lat * (pi / 180.0)) * cos(toCoord.lat * (pi / 180.0)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final rawDist = r * c;
    final roadDist = (rawDist * 1.28).clamp(80.0, 3200.0);

    final hours = (roadDist / 48.0 + (roadDist > 500 ? 4 : 0)).round();

    final ratePerTonKm = weight <= 2.5 ? 4.8 : (weight <= 7.0 ? 3.2 : 2.4);
    final basePrice = max(roadDist * weight * ratePerTonKm, 1800.0);
    final dieselLiters = (roadDist / (weight > 10 ? 3.8 : 6.5));
    final tollEstimate = roadDist * (weight > 10 ? 3.4 : 1.8);
    final fuelToll = (dieselLiters * 92.0 * 0.15) + tollEstimate;
    final totalFreight = basePrice + fuelToll;

    final truck = _recommendVehicleForWeight(weight);

    return {
      'distanceKm': roadDist.roundToDouble(),
      'transitHours': hours,
      'estimatedPrice': ((totalFreight / 100).round() * 100).toDouble(),
      'basePrice': ((basePrice / 100).round() * 100).toDouble(),
      'fuelToll': ((fuelToll / 100).round() * 100).toDouble(),
      'tollEstimate': ((tollEstimate / 100).round() * 100).toDouble(),
      'dieselLiters': dieselLiters.roundToDouble(),
      'highway': fromCoord.primaryHighway,
      'recommendedTruck': truck,
    };
  }

  String _recommendVehicleForWeight(double weight) {
    if (weight <= 1.5) return 'Tata Ace (1.5 Ton • Intra-City)';
    if (weight <= 2.5) return 'Bolero Maxi Truck (2.5 Ton • Regional)';
    if (weight <= 7.5) return '17ft Eicher / Canter (7.0 Ton • Industrial)';
    if (weight <= 18.0) return '32ft Multi-Axle Container (18 Ton • Heavy)';
    return '40ft Heavy Trailer (35 Ton • Over-Dimensional)';
  }

  VoiceAssistantAction _buildLogisticsCoreFallback(
    String text,
    String? from,
    String? to,
    double? weight,
    double dist,
    double price,
    int hours,
    String highway,
    String truck,
    String lang,
  ) {
    final isHindi = lang.startsWith('hi');

    if (from != null && to != null) {
      final formattedPrice = '₹${price.round()}';
      final resp = isHindi
          ? '$from se $to (${dist.round()} km) ke liye anumanit bhaada $formattedPrice hai. Transit samay lagbhag $hours ghante hai, aur $truck sabse upyukt vikalp hai.'
          : 'Freight estimate for $from to $to (${dist.round()} km) is $formattedPrice. Estimated transit is $hours hours via $highway. Best vehicle: $truck.';

      return VoiceAssistantAction(
        type: 'rate_quote',
        fromCity: from,
        toCity: to,
        weightTons: weight ?? 10.0,
        estimatedPriceInr: price,
        distanceKm: dist,
        transitHours: hours,
        recommendedVehicle: truck,
        highwayName: highway,
        responseText: resp,
        langCode: lang,
        aiEngineUsed: 'REDO Logistics Core',
      );
    }

    if (weight != null) {
      final resp = isHindi
          ? '$weight ton cargo ke liye hum $truck suggest karte hain. Isme optimal mileage aur secure container protection milta hai.'
          : 'For $weight ton cargo, we recommend $truck for optimal cost efficiency and payload safety.';
      return VoiceAssistantAction(
        type: 'recommend_vehicle',
        weightTons: weight,
        recommendedVehicle: truck,
        responseText: resp,
        langCode: lang,
        aiEngineUsed: 'REDO Logistics Core',
      );
    }

    final lower = text.toLowerCase();
    if (lower.contains('profile') || lower.contains('account')) {
      return VoiceAssistantAction(
        type: 'open_profile',
        responseText: isHindi ? 'Customer business profile khol raha hoon.' : 'Opening your business profile.',
        langCode: lang,
        aiEngineUsed: 'REDO Logistics Core',
      );
    }

    if (lower.contains('booking') || lower.contains('order') || lower.contains('shipment')) {
      return VoiceAssistantAction(
        type: 'open_bookings',
        responseText: isHindi ? 'Aapki bookings directory khol raha hoon.' : 'Opening your bookings directory.',
        langCode: lang,
        aiEngineUsed: 'REDO Logistics Core',
      );
    }

    return VoiceAssistantAction(
      type: 'chat',
      responseText: isHindi
          ? 'Namaste! Main Sarvam AI & Hugging Face dwara chalit REDO logistics assistant hoon. Aap kisi bhi route ka rate (jaise Delhi se Mumbai 10 ton), tracking, ya truck recommendation pooch sakte hain.'
          : 'Hello! I am your REDO logistics co-pilot powered by Sarvam AI & Hugging Face. Ask me for corridor freight rates, live tracking, or commercial truck options.',
      langCode: lang,
      aiEngineUsed: 'REDO Logistics Core',
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

  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    super.dispose();
  }
}
