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

  // Route / Corridor Search & Filter State
  String _searchFilter = '';
  String _searchFrom = '';
  String _searchTo = '';
  bool _myCorridorOnly = false;
  String _categoryFilter = 'all'; // 'all', 'instant', 'scheduled', 'best_match'
  String _tonnageFilter = 'all'; // 'all', 'mini', 'medium', 'heavy'

  // Instant Load Dispatch Alert (Rapido style)
  AvailableLoad? _instantAlertLoad;
  Timer? _instantCountdownTimer;
  int _instantSecondsLeft = 45;
  final Set<String> _declinedInstantIds = {};

  String get searchFilter => _searchFilter;
  String get searchFrom => _searchFrom;
  String get searchTo => _searchTo;
  bool get myCorridorOnly => _myCorridorOnly;
  String get categoryFilter => _categoryFilter;
  String get tonnageFilter => _tonnageFilter;
  AvailableLoad? get instantAlertLoad => _instantAlertLoad;
  int get instantSecondsLeft => _instantSecondsLeft;

  List<AvailableLoad> get allAvailableLoads => _availableLoads;

  static String _normCity(String raw) {
    var s = raw.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'\b(hub|junction|station|terminal|city|ncr|depot|wharf|port)\b', caseSensitive: false), ' ');
    s = s.replaceAll(RegExp(r'[^\w\s]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.contains('delhi') || s.contains('new delhi') || s.contains('gurugram') || s.contains('noida')) return 'delhi';
    if (s.contains('mumbai') || s.contains('bombay') || s.contains('navi mumbai') || s.contains('thane')) return 'mumbai';
    if (s.contains('bengaluru') || s.contains('bangalore')) return 'bengaluru';
    if (s.contains('hyderabad') || s.contains('secunderabad')) return 'hyderabad';
    if (s.contains('kolkata') || s.contains('calcutta')) return 'kolkata';
    if (s.contains('chennai') || s.contains('madras')) return 'chennai';
    if (s.contains('pune')) return 'pune';
    if (s.contains('jaipur')) return 'jaipur';
    if (s.contains('ahmedabad')) return 'ahmedabad';
    if (s.contains('surat')) return 'surat';
    if (s.contains('lucknow')) return 'lucknow';
    if (s.contains('kanpur')) return 'kanpur';
    if (s.contains('nagpur')) return 'nagpur';
    if (s.contains('indore')) return 'indore';
    return s;
  }

  List<AvailableLoad> get availableLoads {
    var list = List<AvailableLoad>.from(_availableLoads);

    // Apply explicit route search if From or To is filled
    if (_searchFrom.isNotEmpty || _searchTo.isNotEmpty) {
      final nFrom = _normCity(_searchFrom);
      final nTo = _normCity(_searchTo);

      list = list.where((l) {
        final lOrigin = _normCity(l.origin);
        final lDest = _normCity(l.destination);

        // When BOTH From & To are provided: STRICT CORRIDOR MATCH ONLY!
        if (nFrom.isNotEmpty && nTo.isNotEmpty) {
          // 1. Forward corridor (e.g. Delhi -> Hyderabad)
          final forward = (lOrigin.contains(nFrom) || nFrom.contains(lOrigin)) &&
                          (lDest.contains(nTo) || nTo.contains(lDest));
          if (forward) return true;

          // 2. Return / Backhaul load (e.g. Hyderabad -> Delhi)
          final returnLoad = (lOrigin.contains(nTo) || nTo.contains(lOrigin)) &&
                             (lDest.contains(nFrom) || nFrom.contains(lDest));
          if (returnLoad) return true;

          // DO NOT match loads to third-party cities when both From & To are given!
          return false;
        } else if (nFrom.isNotEmpty) {
          // Only From provided: match origin
          return lOrigin.contains(nFrom) || nFrom.contains(lOrigin);
        } else if (nTo.isNotEmpty) {
          // Only To provided: match destination
          return lDest.contains(nTo) || nTo.contains(lDest);
        }

        // Cargo type keyword match
        if (_searchFilter.trim().isNotEmpty) {
          final q = _searchFilter.toLowerCase().trim();
          if (l.cargoType.toLowerCase().contains(q)) return true;
        }

        return false;
      }).toList();
    } else if (_searchFilter.trim().isNotEmpty) {
      final q = _searchFilter.toLowerCase().trim();
      final nq = _normCity(q);
      list = list.where((l) {
        final lOrigin = _normCity(l.origin);
        final lDest = _normCity(l.destination);
        return lOrigin.contains(nq) ||
               nq.contains(lOrigin) ||
               lDest.contains(nq) ||
               nq.contains(lDest) ||
               l.origin.toLowerCase().contains(q) ||
               l.destination.toLowerCase().contains(q) ||
               l.cargoType.toLowerCase().contains(q);
      }).toList();
    } else if (_myCorridorOnly && _myTrucks.isNotEmpty) {
      final truck = _myTrucks.first;
      final home = _normCity(truck.homeOrigin);
      list = list
          .where(
            (l) =>
                _normCity(l.origin).contains(home) ||
                _normCity(l.destination).contains(home),
          )
          .toList();
    }

    if (_tonnageFilter == 'mini') {
      list = list.where((l) => l.weightTons < 3.0).toList();
    } else if (_tonnageFilter == 'medium') {
      list = list.where((l) => l.weightTons >= 3.0 && l.weightTons <= 10.0).toList();
    } else if (_tonnageFilter == 'heavy') {
      list = list.where((l) => l.weightTons > 10.0).toList();
    }

    if (_categoryFilter == 'instant') {
      list = list.where((l) => l.isInstant).toList();
    } else if (_categoryFilter == 'scheduled') {
      list = list.where((l) => !l.isInstant).toList();
    } else if (_categoryFilter == 'best_match') {
      list.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    }

    return list;
  }

  List<ActiveTrip> get activeTrips => _activeTrips;
  List<TruckModel> get myTrucks => _myTrucks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasTruck => _myTrucks.isNotEmpty;
  String? get gpsSharingForBooking => _gpsBookingId;

  PartnerTripsViewModel() {
    _cargoCh = SupabaseService.subscribeCargo(() => _refreshLoads());
    _bookingsCh = SupabaseService.subscribeBookings(() => _refreshTrips());
  }

  void setSearchFilter(String query) {
    _searchFilter = query;
    _searchFrom = '';
    _searchTo = '';
    notifyListeners();
  }

  void setRouteSearch({String from = '', String to = ''}) {
    _searchFrom = from.trim();
    _searchTo = to.trim();
    if (from.isNotEmpty && to.isNotEmpty) {
      _searchFilter = '$from ➔ $to';
    } else if (from.isNotEmpty) {
      _searchFilter = from;
    } else {
      _searchFilter = to;
    }
    notifyListeners();
  }

  void setCategoryFilter(String cat) {
    _categoryFilter = cat;
    notifyListeners();
  }

  void setTonnageFilter(String filter) {
    _tonnageFilter = filter;
    notifyListeners();
  }

  void toggleMyCorridorOnly() {
    _myCorridorOnly = !_myCorridorOnly;
    notifyListeners();
  }

  void clearFilters() {
    _searchFilter = '';
    _searchFrom = '';
    _searchTo = '';
    _myCorridorOnly = false;
    _categoryFilter = 'all';
    _tonnageFilter = 'all';
    notifyListeners();
  }

  void triggerInstantAlert(AvailableLoad load) {
    _instantCountdownTimer?.cancel();
    _instantAlertLoad = load;
    _instantSecondsLeft = 45;
    notifyListeners();

    _instantCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_instantSecondsLeft > 1) {
        _instantSecondsLeft--;
        notifyListeners();
      } else {
        dismissInstantAlert(declined: true);
      }
    });
  }

  void dismissInstantAlert({bool declined = true}) {
    _instantCountdownTimer?.cancel();
    if (declined && _instantAlertLoad != null) {
      _declinedInstantIds.add(_instantAlertLoad!.cargoId);
    }
    _instantAlertLoad = null;
    notifyListeners();
  }

  void _checkForInstantAlerts() {
    if (_instantAlertLoad != null) return;
    for (final load in _availableLoads) {
      if (load.isInstant && !_declinedInstantIds.contains(load.cargoId)) {
        triggerInstantAlert(load);
        break;
      }
    }
  }

  @override
  void dispose() {
    _instantCountdownTimer?.cancel();
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
      _checkForInstantAlerts();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshLoads() async {
    try {
      _availableLoads = await SupabaseService.getAvailableLoads();
      _checkForInstantAlerts();
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
  Future<String?> advanceTripStatus(
    ActiveTrip trip, {
    Uint8List? photoBytes,
    String? otp,
  }) async {
    try {
      switch (trip.status) {
        case 'confirmed':
          await SupabaseService.updateTripStatus(
            trip.bookingId,
            'pickup_ready',
          );
          break;
        case 'pickup_ready':
          if (otp == null || otp.isEmpty) return 'Pickup OTP is required.';
          await SupabaseService.verifyTripOtp(
            bookingId: trip.bookingId,
            type: 'pickup',
            otp: otp,
          );
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
            bookingId: trip.bookingId,
            type: 'delivery',
            otp: otp,
          );
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
        bookingId: trip.bookingId,
        type: type,
        otp: otp.trim(),
      );
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
    _gps =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 80,
          ),
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
