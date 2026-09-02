import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/models.dart';
import '../data/services/supabase_service.dart';

class PartnerTripsViewModel extends ChangeNotifier {
  List<AvailableLoad> _availableLoads = [];
  List<ActiveTrip> _activeTrips = [];
  List<TruckModel> _myTrucks = [];
  bool _isLoading = false;
  String? _errorMessage;
  RealtimeChannel? _cargoCh;
  RealtimeChannel? _bookingsCh;
  StreamSubscription<Position>? _gps;
  String? _gpsBookingId;

  List<AvailableLoad> get availableLoads => _availableLoads;
  List<ActiveTrip> get activeTrips => _activeTrips;
  List<TruckModel> get myTrucks => _myTrucks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasTruck => _myTrucks.isNotEmpty;
  String? get gpsSharingForBooking => _gpsBookingId;

  PartnerTripsViewModel() {
    // LIVE wiring: new shipper cargo (web or customer app) pops in instantly;
    // shipper confirming/completing a booking updates trips instantly.
    _cargoCh = SupabaseService.subscribeCargo(() => _refreshLoads());
    _bookingsCh = SupabaseService.subscribeBookings(() => _refreshTrips());
  }

  @override
  void dispose() {
    _gps?.cancel();
    if (_cargoCh != null) SupabaseService.removeChannel(_cargoCh!);
    if (_bookingsCh != null) SupabaseService.removeChannel(_bookingsCh!);
    super.dispose();
  }

  Future<void> fetchAll() async {
    _isLoading = true;
    notifyListeners();
    try {
      _myTrucks = await SupabaseService.getMyTrucks();
      _availableLoads = await SupabaseService.getAvailableLoads();
      _activeTrips = await SupabaseService.getActiveTrips();
      _errorMessage = null;
    } catch (e) {
      // Honest error - no fake sample loads/trips.
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshLoads() async {
    try {
      _availableLoads = await SupabaseService.getAvailableLoads();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _refreshTrips() async {
    try {
      _activeTrips = await SupabaseService.getActiveTrips();
      notifyListeners();
    } catch (_) {}
  }

  /// REAL accept: booking is created on the backend (owner_initiated) — the
  /// shipper gets notified and sees it on their app/website immediately.
  Future<String?> acceptLoad(AvailableLoad load) async {
    if (_myTrucks.isEmpty) {
      try {
        _myTrucks = await SupabaseService.getMyTrucks();
      } catch (_) {}
    }
    if (_myTrucks.isEmpty) {
      return 'Register your truck first (Profile → complete onboarding).';
    }
    _isLoading = true;
    notifyListeners();
    try {
      await SupabaseService.acceptLoad(
        cargoId: load.cargoId,
        truckId: _myTrucks.first.truckId,
        payoutInr: load.offeredPriceInr,
      );
      await _refreshLoads();
      await _refreshTrips();
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  /// Walk the REAL state machine. Proof photos are mandatory where the
  /// backend requires them:
  ///   confirmed      → pickup_ready                    (no photo)
  ///   pickup_ready   → picked_up → in_transit          (pickup e-POD photo)
  ///   in_transit     → delivered                       (delivery e-POD photo)
  /// delivered → completed is the SHIPPER's action, never the driver's.
  Future<String?> advanceTripStatus(ActiveTrip trip,
      {Uint8List? photoBytes, String? otp}) async {
    try {
      switch (trip.status) {
        case 'confirmed':
          await SupabaseService.updateTripStatus(trip.bookingId, 'pickup_ready');
          break;
        case 'pickup_ready':
          if (otp == null || otp.isEmpty) return 'Pickup OTP is required.';
          await SupabaseService.verifyTripOtp(
              bookingId: trip.bookingId, type: 'pickup', otp: otp);
          if (photoBytes == null) return 'Pickup photo (e-POD) is required.';
          await SupabaseService.uploadTripProof(
            bookingId: trip.bookingId,
            proofType: 'pickup',
            photoBytes: photoBytes,
            lat: await _tryLat(),
            lng: await _tryLng(),
          );
          await SupabaseService.updateTripStatus(trip.bookingId, 'picked_up');
          await SupabaseService.updateTripStatus(trip.bookingId, 'in_transit');
          break;
        case 'in_transit':
          if (otp == null || otp.isEmpty) return 'Delivery OTP is required.';
          await SupabaseService.verifyTripOtp(
              bookingId: trip.bookingId, type: 'delivery', otp: otp);
          if (photoBytes == null) return 'Delivery photo (e-POD) is required.';
          await SupabaseService.uploadTripProof(
            bookingId: trip.bookingId,
            proofType: 'delivery',
            photoBytes: photoBytes,
            lat: await _tryLat(),
            lng: await _tryLng(),
          );
          await SupabaseService.updateTripStatus(trip.bookingId, 'delivered');
          await stopGps();
          break;
        default:
          return null;
      }
      await _refreshTrips();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> verifyOtp(ActiveTrip trip, String type, String otp) async {
    try {
      await SupabaseService.verifyOtp(
          bookingId: trip.bookingId, type: type, otp: otp.trim());
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> rateShipper(ActiveTrip trip, int stars) async {
    try {
      await SupabaseService.submitRating(trip.bookingId, stars);
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Position? _lastPos;
  Future<double?> _tryLat() async {
    try {
      _lastPos = await Geolocator.getCurrentPosition();
      return _lastPos!.latitude;
    } catch (_) {
      return null;
    }
  }

  Future<double?> _tryLng() async => _lastPos?.longitude;

  /// REAL GPS stream → tracking_events (is_simulated: false).
  /// The shipper's tracking map moves live.
  Future<String?> toggleGps(ActiveTrip trip) async {
    if (_gpsBookingId == trip.bookingId) {
      await stopGps();
      return null;
    }
    final perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return 'Location permission is required to share live GPS.';
    }
    await _gps?.cancel();
    _gps = Geolocator.getPositionStream(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 80),
    ).listen((pos) {
      SupabaseService.broadcastDriverGps(
        bookingId: trip.bookingId,
        lat: pos.latitude,
        lng: pos.longitude,
      ).catchError((_) {});
    });
    _gpsBookingId = trip.bookingId;
    notifyListeners();
    return null;
  }

  Future<void> stopGps() async {
    await _gps?.cancel();
    _gps = null;
    _gpsBookingId = null;
    notifyListeners();
  }
}
