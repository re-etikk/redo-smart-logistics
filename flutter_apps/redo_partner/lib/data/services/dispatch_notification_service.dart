import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/models.dart';

class DispatchNotificationAction {
  final String action;
  final String offerId;

  const DispatchNotificationAction({required this.action, required this.offerId});
}

class DispatchNotificationService {
  DispatchNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
    static final StreamController<DispatchNotificationAction> _actions =
      StreamController<DispatchNotificationAction>.broadcast();
    static final List<DispatchNotificationAction> _pendingActions = [];
    static Stream<DispatchNotificationAction> get actions => _actions.stream;

    static List<DispatchNotificationAction> takePendingActions() {
      final pending = List<DispatchNotificationAction>.from(_pendingActions);
      _pendingActions.clear();
      return pending;
    }
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'instant_load_dispatch',
    'Instant load dispatches',
    description: 'Urgent load offers for active REDO partners',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize({bool requestPermission = true}) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('launcher_icon'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleResponse,
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channel);
    if (requestPermission) await android?.requestNotificationsPermission();
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final response = launchDetails?.notificationResponse;
      if (response != null) _handleResponse(response);
    }
  }

  static void _handleResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final offerId = data['offer_id'] as String?;
      if (offerId == null || offerId.isEmpty) return;
      final action = DispatchNotificationAction(
        action: response.actionId ?? 'open',
        offerId: offerId,
      );
      if (_actions.hasListener) {
        _actions.add(action);
      } else {
        _pendingActions.add(action);
      }
    } catch (_) {}
  }

  static Future<void> showInstantLoad(AvailableLoad load) async {
    if (load.dispatchOfferId == null) return;
    await _showDispatchNotification(
      offerId: load.dispatchOfferId!,
      cargoId: load.cargoId,
      title: 'Nearby load: ${load.origin} to ${load.destination}',
      body: '₹${load.offeredPriceInr.round()} payout · ${load.distanceFromDriverKm?.toStringAsFixed(1) ?? '?'} km away · 45 seconds',
    );
  }

  static Future<void> showRemoteDispatch(Map<String, dynamic> data) async {
    final offerId = data['offer_id']?.toString();
    if (offerId == null || offerId.isEmpty) return;
    await _showDispatchNotification(
      offerId: offerId,
      cargoId: data['cargo_id']?.toString() ?? offerId,
      title: 'Nearby load: ${data['origin'] ?? 'Pickup'} to ${data['destination'] ?? 'Drop'}',
      body: '₹${data['payout_inr'] ?? '0'} payout · ${data['distance_from_driver_km'] ?? '?'} km away · 45 seconds',
    );
  }

  static Future<void> _showDispatchNotification({
    required String offerId,
    required String cargoId,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(const [0, 500, 250, 500]),
      ticker: 'New instant load dispatch',
      actions: const [
        AndroidNotificationAction(
          'dispatch_accept',
          'Accept',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'dispatch_skip',
          'Skip',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );
    await _plugin.show(
      id: cargoId.hashCode & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: jsonEncode({
        'offer_id': offerId,
        'cargo_id': cargoId,
      }),
    );
  }
}
