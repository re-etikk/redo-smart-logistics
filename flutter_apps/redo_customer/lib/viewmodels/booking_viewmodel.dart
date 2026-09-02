import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/models/models.dart';
import '../data/services/supabase_service.dart';

class CityLocation {
  final String name;
  final LatLng latLng;
  const CityLocation(this.name, this.latLng);
}

const List<CityLocation> majorCities = [
  CityLocation('Mumbai', LatLng(19.0760, 72.8777)),
  CityLocation('Delhi NCR', LatLng(28.6139, 77.2090)),
  CityLocation('Pune', LatLng(18.5204, 73.8567)),
  CityLocation('Jaipur', LatLng(26.9124, 75.7873)),
  CityLocation('Surat', LatLng(21.1702, 72.8311)),
  CityLocation('Ahmedabad', LatLng(23.0225, 72.5714)),
  CityLocation('Bengaluru', LatLng(12.9716, 77.5946)),
];

class BookingViewModel extends ChangeNotifier {
  String _origin = 'Mumbai';
  String _destination = 'Delhi NCR';
  String _cargoType = 'Industrial Goods';
  double _weightTons = 6.0;
  bool _isLoading = false;
  List<TruckMatch> _matches = [];
  CargoRequest? _lastPostedCargo;
  BookingItem? _lastBooking;
  String? _errorMessage;

  String get origin => _origin;
  String get destination => _destination;
  String get cargoType => _cargoType;
  double get weightTons => _weightTons;
  bool get isLoading => _isLoading;
  List<TruckMatch> get matches => _matches;
  CargoRequest? get lastPostedCargo => _lastPostedCargo;
  BookingItem? get lastBooking => _lastBooking;
  String? get errorMessage => _errorMessage;

  LatLng get originLatLng => majorCities.firstWhere((c) => c.name == _origin, orElse: () => majorCities[0]).latLng;
  LatLng get destinationLatLng => majorCities.firstWhere((c) => c.name == _destination, orElse: () => majorCities[1]).latLng;

  void setOrigin(String city) {
    _origin = city;
    notifyListeners();
  }

  void setDestination(String city) {
    _destination = city;
    notifyListeners();
  }

  void setCargoType(String type) {
    _cargoType = type;
    notifyListeners();
  }

  void setWeightTons(double weight) {
    _weightTons = weight;
    notifyListeners();
  }

  Future<bool> searchMatchingTrucks() async {
    if (_origin == _destination) {
      _errorMessage = 'Pickup and Drop cities cannot be the same.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Post or register cargo
      _lastPostedCargo = await SupabaseService.postCargoRequest(
        origin: _origin,
        destination: _destination,
        cargoType: _cargoType,
        weightTons: _weightTons,
        distanceKm: 1420.0,
      );

      // 2. Fetch matches
      _matches = await SupabaseService.getMatchesForCargo(
        origin: _origin,
        destination: _destination,
        weightTons: _weightTons,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmBooking(TruckMatch match) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cargoId = _lastPostedCargo?.cargoId ?? 'CRG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      _lastBooking = await SupabaseService.createBooking(
        cargoId: cargoId,
        truckId: match.truckId,
        agreedPriceInr: match.finalPriceInr,
        origin: _origin,
        destination: _destination,
        cargoType: _cargoType,
        weightTons: _weightTons,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
