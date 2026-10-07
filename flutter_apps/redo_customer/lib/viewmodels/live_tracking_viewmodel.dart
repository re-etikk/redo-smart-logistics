import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/models.dart';
import '../data/services/driver_location_stream_service.dart';
import '../data/services/routing_service.dart';
import '../data/services/supabase_service.dart';

/// Presentation state for real-time shipment tracking.
/// Decouples telemetry data from map rendering and screen widgets.
class LiveTrackingViewModel extends ChangeNotifier {
  final IDriverLocationStreamService _locationService;

  BookingItem? _booking;
  LatLng? _driverLocation;
  LatLng? _pickupLocation;
  LatLng? _dropLocation;
  List<LatLng> _routePoints = [];
  String _shipmentStatus = 'in_transit';
  String _etaText = '4h 20m';
  String _remainingDistanceText = '540 km';
  double _speedKmh = 68.0;
  double _progressPct = 52.0;
  DriverConnectionStatus _connectionStatus = DriverConnectionStatus.reconnecting;
  bool _isGpsUnavailable = false;
  String _lastUpdatedText = 'Waiting for signal...';

  StreamSubscription<DriverLocationUpdate>? _locSub;
  StreamSubscription<DriverConnectionStatus>? _connSub;
  RealtimeChannel? _bookingStatusChannel;

  LiveTrackingViewModel({IDriverLocationStreamService? locationService})
      : _locationService = locationService ?? DriverLocationStreamService();

  BookingItem? get booking => _booking;
  LatLng? get driverLocation => _driverLocation;
  LatLng? get pickupLocation => _pickupLocation;
  LatLng? get dropLocation => _dropLocation;
  List<LatLng> get routePoints => _routePoints;
  String get shipmentStatus => _shipmentStatus;
  String get etaText => _etaText;
  String get remainingDistanceText => _remainingDistanceText;
  double get speedKmh => _speedKmh;
  double get progressPct => _progressPct;
  DriverConnectionStatus get connectionStatus => _connectionStatus;
  bool get isGpsUnavailable => _isGpsUnavailable;
  bool get isDriverOffline => _connectionStatus == DriverConnectionStatus.offline;
  bool get isStale => _connectionStatus == DriverConnectionStatus.stale;
  bool get isShipmentCompleted =>
      ['delivered', 'completed'].contains(_shipmentStatus.toLowerCase());
  String get lastUpdatedText => _lastUpdatedText;

  Future<void> init(BookingItem b) async {
    _booking = b;
    _shipmentStatus = b.status.toLowerCase();
    notifyListeners();

    // 1. Resolve Pickup and Drop Locations
    await _resolveCoordinates(b);

    // 2. Fetch road corridor route polyline
    if (_pickupLocation != null && _dropLocation != null) {
      try {
        final route = await RoutingService.getDrivingRoute(_pickupLocation!, _dropLocation!);
        if (route != null) {
          _routePoints = route.points;
          if (_shipmentStatus != 'in_transit' && _shipmentStatus != 'out_for_delivery') {
            _remainingDistanceText = '${route.distanceKm.round()} km';
            final h = route.durationMinutes ~/ 60;
            final m = route.durationMinutes % 60;
            _etaText = h > 0 ? '${h}h ${m}m' : '$m mins';
          }
          notifyListeners();
        } else {
          _routePoints = [_pickupLocation!, _dropLocation!];
        }
      } catch (_) {
        _routePoints = [_pickupLocation!, _dropLocation!];
      }
    }

    // 3. Connect driver location stream
    _locSub?.cancel();
    _connSub?.cancel();

    _connSub = _locationService.connectionStream.listen((status) {
      _connectionStatus = status;
      if (status == DriverConnectionStatus.offline) {
        _lastUpdatedText = 'Driver is currently offline';
      } else if (status == DriverConnectionStatus.stale) {
        _lastUpdatedText = 'Signal delayed (>1m ago)';
      } else if (status == DriverConnectionStatus.reconnecting) {
        _lastUpdatedText = 'Reconnecting to GPS...';
      }
      notifyListeners();
    });

    _locSub = _locationService.locationStream.listen((update) {
      _handleLocationUpdate(update);
    });

    final initLat = b.currentLat;
    final initLng = b.currentLng;

    await _locationService.startTracking(
      b.id,
      truckId: b.truckId,
      initialLat: initLat,
      initialLng: initLng,
    );

    // 4. Subscribe to booking status updates (e.g. accepted -> confirmed -> in_transit -> delivered)
    _bookingStatusChannel?.unsubscribe();
    try {
      _bookingStatusChannel = SupabaseService.subscribeBookings(() async {
        final refreshed = await SupabaseService.getBookingByIdOrSearch(b.id);
        if (refreshed != null) {
          _booking = refreshed;
          _shipmentStatus = refreshed.status.toLowerCase();
          notifyListeners();
        }
      });
    } catch (_) {}
  }

  Future<LatLng?> _resolveAddress(String address) async {
    final cached = RoutingService.getCoordinatesForCity(address);
    if (cached != null) return cached;
    try {
      final suggestions = await RoutingService.searchPlaces(address);
      if (suggestions.isNotEmpty) return suggestions.first.latLng;
    } catch (_) {}
    return null;
  }

  Future<void> _resolveCoordinates(BookingItem b) async {
    // Pickup
    if (b.pickupAddress != null && b.pickupAddress!.isNotEmpty) {
      final p = await _resolveAddress(b.pickupAddress!);
      if (p != null) _pickupLocation = p;
    }
    _pickupLocation ??= await _resolveAddress(b.origin) ??
        const LatLng(28.6139, 77.2090); // Delhi default

    // Drop
    if (b.dropAddress != null && b.dropAddress!.isNotEmpty) {
      final d = await _resolveAddress(b.dropAddress!);
      if (d != null) _dropLocation = d;
    }
    _dropLocation ??= await _resolveAddress(b.destination) ??
        const LatLng(25.5941, 85.1376); // Patna default
  }

  void _handleLocationUpdate(DriverLocationUpdate update) {
    if (update.latitude == 0.0 && update.longitude == 0.0) {
      _isGpsUnavailable = true;
      notifyListeners();
      return;
    }

    _isGpsUnavailable = false;
    _driverLocation = LatLng(update.latitude, update.longitude);
    _lastUpdatedText = 'Live • Updated just now';

    if (update.status != null && update.status!.isNotEmpty) {
      _shipmentStatus = update.status!.toLowerCase();
    }

    // Recalculate remaining distance and ETA to dropLocation
    if (_dropLocation != null) {
      final distKm = _calculateDistanceKm(_driverLocation!, _dropLocation!);
      _remainingDistanceText = '${distKm.round()} km';

      final speed = (update.speedKmh != null && update.speedKmh! > 10)
          ? update.speedKmh!
          : 45.0; // Average commercial freight speed
      _speedKmh = speed;
      final hours = distKm / speed;
      final totalMinutes = (hours * 60).round();

      if (totalMinutes < 60) {
        _etaText = '$totalMinutes mins';
      } else {
        final h = totalMinutes ~/ 60;
        final m = totalMinutes % 60;
        _etaText = '${h}h ${m}m';
      }

      if (_pickupLocation != null) {
        final totalDist = _calculateDistanceKm(_pickupLocation!, _dropLocation!);
        if (totalDist > 0) {
          final completedDist = totalDist - distKm;
          _progressPct = (completedDist / totalDist).clamp(0.05, 0.98);
        }
      }
    }

    notifyListeners();
  }

  double _calculateDistanceKm(LatLng a, LatLng b) {
    const p = 0.017453292519943295; // Math.PI / 180
    final c = cos;
    final aa = 0.5 -
        c((b.latitude - a.latitude) * p) / 2 +
        c(a.latitude * p) * c(b.latitude * p) * (1 - c((b.longitude - a.longitude) * p)) / 2;
    return 12742 * asin(sqrt(aa)); // 2 * R; R = 6371 km
  }

  @override
  void dispose() {
    _locSub?.cancel();
    _connSub?.cancel();
    _bookingStatusChannel?.unsubscribe();
    _locationService.dispose();
    super.dispose();
  }
}
