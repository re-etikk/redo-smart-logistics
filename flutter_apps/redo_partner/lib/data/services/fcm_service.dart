import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_service.dart';
import 'dispatch_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data['type'] != 'dispatch_offer') return;
  await DispatchNotificationService.initialize(requestPermission: false);
  await DispatchNotificationService.showRemoteDispatch(message.data);
}

class FcmService {
  FcmService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<AuthState>? _authSubscription;
  static bool _initialized = false;

  static Stream<RemoteMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage;

  static Future<void> initializeFirebase() async {
    if (_initialized || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    if (_initialized) return;

    await DispatchNotificationService.initialize();
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await _messaging.getToken();
    if (token != null) await _registerToken(token);

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(_registerToken);
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.session != null) {
        unawaited(_messaging.getToken().then((token) async {
          if (token != null) await _registerToken(token);
        }));
      }
    });
    _initialized = true;
  }

  static Future<void> _registerToken(String token) async {
    if (Supabase.instance.client.auth.currentSession == null) return;
    try {
      await ApiService.post('/devices/fcm-token', {
        'token': token,
        'platform': 'android',
      });
      final suffix = token.length <= 6 ? token : token.substring(token.length - 6);
      debugPrint('FCM device token registered with REDO backend (…$suffix).');
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
    }
  }

  static Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _authSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _authSubscription = null;
    _initialized = false;
  }
}