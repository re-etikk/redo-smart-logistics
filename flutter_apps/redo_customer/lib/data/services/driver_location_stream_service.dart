import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Telemetry update event emitted by the driver location stream.
class DriverLocationUpdate {
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speedKmh;
  final DateTime timestamp;
  final double? progressPct;
  final int? etaMinutes;
  final bool isSimulated;
  final String? status;

  const DriverLocationUpdate({
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speedKmh,
    required this.timestamp,
    this.progressPct,
    this.etaMinutes,
    this.isSimulated = false,
    this.status,
  });

  factory DriverLocationUpdate.fromMap(Map<String, dynamic> map) {
    final lat = (map['lat'] as num?)?.toDouble() ??
        (map['current_lat'] as num?)?.toDouble() ??
        0.0;
    final lng = (map['lng'] as num?)?.toDouble() ??
        (map['current_lng'] as num?)?.toDouble() ??
        0.0;
    final progress = (map['progress_pct'] as num?)?.toDouble();
    final eta = (map['eta_minutes'] as num?)?.toInt();
    final isSim = map['is_simulated'] as bool? ?? false;
    final timeStr = map['timestamp'] as String? ?? map['created_at'] as String?;
    final time = timeStr != null ? DateTime.tryParse(timeStr) ?? DateTime.now() : DateTime.now();

    return DriverLocationUpdate(
      latitude: lat,
      longitude: lng,
      heading: (map['heading'] as num?)?.toDouble(),
      speedKmh: (map['speed_kmh'] as num?)?.toDouble(),
      timestamp: time,
      progressPct: progress,
      etaMinutes: eta,
      isSimulated: isSim,
      status: map['status'] as String?,
    );
  }
}

/// Connection health of the driver's real-time telemetry stream.
enum DriverConnectionStatus {
  connected,
  reconnecting,
  offline,
  stale,
}

/// Abstract contract for driver location streaming.
/// This abstraction decouples telemetry delivery (Supabase Realtime, WebSockets, MQTT)
/// from the tracking state and the UI.
abstract class IDriverLocationStreamService {
  Stream<DriverLocationUpdate> get locationStream;
  Stream<DriverConnectionStatus> get connectionStream;
  DriverConnectionStatus get currentConnectionStatus;
  DriverLocationUpdate? get lastKnownLocation;
  Future<void> startTracking(String bookingId, {String? truckId, double? initialLat, double? initialLng});
  Future<void> stopTracking();
  void dispose();
}

/// Production implementation of [IDriverLocationStreamService] leveraging
/// Supabase Realtime on `tracking_events` with truck GPS heartbeat verification.
class DriverLocationStreamService implements IDriverLocationStreamService {
  final _locationController = StreamController<DriverLocationUpdate>.broadcast();
  final _connectionController = StreamController<DriverConnectionStatus>.broadcast();

  RealtimeChannel? _trackingChannel;
  Timer? _heartbeatTimer;
  Timer? _periodicFallbackTimer;

  DriverConnectionStatus _currentStatus = DriverConnectionStatus.reconnecting;
  DriverLocationUpdate? _lastLocation;
  DateTime? _lastReceivedAt;

  @override
  Stream<DriverLocationUpdate> get locationStream => _locationController.stream;

  @override
  Stream<DriverConnectionStatus> get connectionStream => _connectionController.stream;

  @override
  DriverConnectionStatus get currentConnectionStatus => _currentStatus;

  @override
  DriverLocationUpdate? get lastKnownLocation => _lastLocation;

  void _setStatus(DriverConnectionStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      if (!_connectionController.isClosed) {
        _connectionController.add(status);
      }
    }
  }

  void _emitLocation(DriverLocationUpdate update) {
    _lastLocation = update;
    _lastReceivedAt = DateTime.now();
    _setStatus(DriverConnectionStatus.connected);
    if (!_locationController.isClosed) {
      _locationController.add(update);
    }
  }

  @override
  Future<void> startTracking(
    String bookingId, {
    String? truckId,
    double? initialLat,
    double? initialLng,
  }) async {
    await stopTracking();

    if (initialLat != null && initialLng != null && initialLat != 0.0) {
      _emitLocation(DriverLocationUpdate(
        latitude: initialLat,
        longitude: initialLng,
        timestamp: DateTime.now(),
      ));
    }

    _setStatus(DriverConnectionStatus.reconnecting);

    // 1. Fetch initial latest tracking event from backend / Supabase
    try {
      final events = await SupabaseService.getTrackingHistory(bookingId);
      if (events.isNotEmpty) {
        _emitLocation(DriverLocationUpdate.fromMap(events.first));
      }
    } catch (_) {}

    // 2. Fallback check on truck record if events empty
    if (_lastLocation == null && truckId != null && truckId.isNotEmpty) {
      try {
        final truck = await SupabaseService.client
            .from('trucks')
            .select('current_lat, current_lng, status, updated_at')
            .eq('truck_id', truckId)
            .maybeSingle();
        if (truck != null && truck['current_lat'] != null && truck['current_lng'] != null) {
          final lat = (truck['current_lat'] as num).toDouble();
          final lng = (truck['current_lng'] as num).toDouble();
          if (lat != 0.0 && lng != 0.0) {
            _emitLocation(DriverLocationUpdate(
              latitude: lat,
              longitude: lng,
              timestamp: DateTime.tryParse(truck['updated_at']?.toString() ?? '') ?? DateTime.now(),
              status: truck['status'] as String?,
            ));
          }
        }
      } catch (_) {}
    }

    // 3. Connect Supabase Realtime channel on tracking_events
    try {
      _trackingChannel = SupabaseService.subscribeTracking(bookingId, (payload) {
        final update = DriverLocationUpdate.fromMap(payload);
        if (update.latitude != 0.0 && update.longitude != 0.0) {
          _emitLocation(update);
        }
      });
    } catch (_) {
      _setStatus(DriverConnectionStatus.reconnecting);
    }

    // 4. Periodic polling fallback every 12 seconds in case socket drops
    _periodicFallbackTimer = Timer.periodic(const Duration(seconds: 12), (_) async {
      try {
        if (truckId != null && truckId.isNotEmpty) {
          final truck = await SupabaseService.client
              .from('trucks')
              .select('current_lat, current_lng, status, updated_at')
              .eq('truck_id', truckId)
              .maybeSingle();
          if (truck != null && truck['current_lat'] != null && truck['current_lng'] != null) {
            final lat = (truck['current_lat'] as num).toDouble();
            final lng = (truck['current_lng'] as num).toDouble();
            if (lat != 0.0 && lng != 0.0) {
              final isNew = _lastLocation == null ||
                  _lastLocation!.latitude != lat ||
                  _lastLocation!.longitude != lng;
              if (isNew) {
                _emitLocation(DriverLocationUpdate(
                  latitude: lat,
                  longitude: lng,
                  timestamp: DateTime.now(),
                  status: truck['status'] as String?,
                ));
              }
            }
          }
        }
      } catch (_) {
        if (_lastReceivedAt == null || DateTime.now().difference(_lastReceivedAt!).inSeconds > 30) {
          _setStatus(DriverConnectionStatus.reconnecting);
        }
      }
    });

    // 5. Heartbeat monitoring: detect stale and offline driver
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_lastReceivedAt == null) {
        _setStatus(DriverConnectionStatus.reconnecting);
        return;
      }

      final diffSec = DateTime.now().difference(_lastReceivedAt!).inSeconds;
      if (diffSec > 180) {
        _setStatus(DriverConnectionStatus.offline);
      } else if (diffSec > 60) {
        _setStatus(DriverConnectionStatus.stale);
      } else {
        _setStatus(DriverConnectionStatus.connected);
      }
    });
  }

  @override
  Future<void> stopTracking() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _periodicFallbackTimer?.cancel();
    _periodicFallbackTimer = null;
    if (_trackingChannel != null) {
      SupabaseService.removeChannel(_trackingChannel!);
      _trackingChannel = null;
    }
  }

  @override
  void dispose() {
    stopTracking();
    _locationController.close();
    _connectionController.close();
  }
}
