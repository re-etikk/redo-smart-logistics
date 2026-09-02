import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/services/supabase_service.dart';

class PartnerTripsViewModel extends ChangeNotifier {
  List<AvailableLoad> _availableLoads = [];
  List<ActiveTrip> _activeTrips = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AvailableLoad> get availableLoads => _availableLoads;
  List<ActiveTrip> get activeTrips => _activeTrips;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAll() async {
    _isLoading = true;
    notifyListeners();

    try {
      _availableLoads = await SupabaseService.getAvailableLoads();
      _activeTrips = await SupabaseService.getActiveTrips();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptLoad(AvailableLoad load) async {
    _isLoading = true;
    notifyListeners();

    try {
      final trip = ActiveTrip(
        bookingId: 'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        cargoId: load.cargoId,
        origin: load.origin,
        destination: load.destination,
        cargoType: load.cargoType,
        weightTons: load.weightTons,
        payoutInr: load.offeredPriceInr,
        status: 'confirmed',
        shipperName: load.smeName,
        shipperPhone: '+91 98765 11223',
      );

      _activeTrips.insert(0, trip);
      _availableLoads.removeWhere((l) => l.cargoId == load.cargoId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> advanceTripStatus(ActiveTrip trip) async {
    String nextStatus;
    switch (trip.status) {
      case 'confirmed':
        nextStatus = 'pickup_ready';
        break;
      case 'pickup_ready':
        nextStatus = 'in_transit';
        break;
      case 'in_transit':
        nextStatus = 'delivered';
        break;
      default:
        return;
    }

    trip.status = nextStatus;
    notifyListeners();

    await SupabaseService.updateTripStatus(trip.bookingId, nextStatus);
  }
}
