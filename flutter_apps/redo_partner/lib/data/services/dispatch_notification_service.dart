import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/models.dart';

class DispatchNotificationService {
  DispatchNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'instant_load_dispatch',
    'Instant load dispatches',
    description: 'Urgent load offers for active REDO partners',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('launcher_icon'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
    await android?.requestNotificationsPermission();
  }

  static Future<void> showInstantLoad(AvailableLoad load) async {
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
    );
    await _plugin.show(
      id: load.cargoId.hashCode & 0x7fffffff,
      title: 'New instant load: ${load.origin} to ${load.destination}',
      body: '₹${load.offeredPriceInr.round()} estimated payout · 45 seconds to respond',
      notificationDetails: NotificationDetails(android: androidDetails),
      payload: load.cargoId,
    );
  }
}