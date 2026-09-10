import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/models/models.dart';
import '../data/services/supabase_service.dart';
import '../data/services/routing_service.dart';

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
  PlaceSuggestion _originPlace = PlaceSuggestion(
    name: '',
    description: '',
    latLng: const LatLng(22.9734, 78.6569),
  );

  PlaceSuggestion _destPlace = PlaceSuggestion(
    name: '',
    description: '',
    latLng: const LatLng(22.9734, 78.6569),
  );

  String _cargoType = 'Industrial Goods';
  double _weightTons = 6.0;
  bool _isLoading = false;
  bool _isRouting = false;
  RouteInfo? _currentRoute;
  List<TruckMatch> _matches = [];
  CargoRequest? _lastPostedCargo;
  BookingItem? _lastBooking;
  String? _errorMessage;

  // Professional Scheduling & Load Details
  bool _isInstant = false;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  String _timeSlot = 'Morning (08:00 - 12:00)';
  String _pickupAddress = '';
  String _dropAddress = '';
  String _gstin = '';

  PlaceSuggestion get originPlace => _originPlace;
  PlaceSuggestion get destPlace => _destPlace;
  String get origin => _originPlace.name;
  String get destination => _destPlace.name;
  LatLng get originLatLng => _originPlace.latLng;
  LatLng get destinationLatLng => _destPlace.latLng;

  String get cargoType => _cargoType;
  double get weightTons => _weightTons;
  bool get isLoading => _isLoading;
  bool get isRouting => _isRouting;
  RouteInfo? get currentRoute => _currentRoute;
  List<LatLng> get routePoints =>
      _currentRoute?.points ?? [_originPlace.latLng, _destPlace.latLng];
  double get roadDistanceKm => _currentRoute?.distanceKm ?? 0;
  String get roadDistanceText =>
      _currentRoute?.distanceText ?? '${roadDistanceKm.round()} km';
  String get roadDurationText => _currentRoute?.durationText ?? 'Route not calculated';

  List<TruckMatch> get matches => _matches;
  CargoRequest? get lastPostedCargo => _lastPostedCargo;
  BookingItem? get lastBooking => _lastBooking;
  String? get errorMessage => _errorMessage;

  bool get isInstant => _isInstant;
  DateTime get scheduledDate => _scheduledDate;
  String get timeSlot => _timeSlot;
  String get pickupAddress => _pickupAddress;
  String get dropAddress => _dropAddress;
  String get gstin => _gstin;

  void setIsInstant(bool value) {
    _isInstant = value;
    _lastPostedCargo = null;
    notifyListeners();
  }

  void setScheduledDate(DateTime date) {
    _scheduledDate = date;
    _lastPostedCargo = null;
    notifyListeners();
  }

  void setTimeSlot(String slot) {
    _timeSlot = slot;
    _lastPostedCargo = null;
    notifyListeners();
  }

  void setPickupAddress(String address) {
    _pickupAddress = address;
    notifyListeners();
  }

  void setDropAddress(String address) {
    _dropAddress = address;
    notifyListeners();
  }

  void setGstin(String gstin) {
    _gstin = gstin;
    notifyListeners();
  }

  BookingViewModel() {
    // A route is calculated only after the shipper selects both locations.
  }

  Future<void> fetchRoute() async {
    if (_originPlace.name.isEmpty || _destPlace.name.isEmpty) return;
    _isRouting = true;
    notifyListeners();
    try {
      final route = await RoutingService.getDrivingRoute(
        _originPlace.latLng,
        _destPlace.latLng,
      );
      if (route != null) {
        _currentRoute = route;
      }
    } catch (e) {
      debugPrint('Error fetching driving route: $e');
    } finally {
      _isRouting = false;
      notifyListeners();
    }
  }

  void setOriginPlace(PlaceSuggestion place) {
    _originPlace = place;
    _lastPostedCargo = null;
    _matches = [];
    notifyListeners();
    fetchRoute();
  }

  void setDestinationPlace(PlaceSuggestion place) {
    _destPlace = place;
    _lastPostedCargo = null;
    _matches = [];
    notifyListeners();
    fetchRoute();
  }

  void setOrigin(String cityName) {
    _originPlace = PlaceSuggestion(
      name: cityName,
      description: '$cityName Hub',
      latLng: _originPlace.latLng,
    );
    _lastPostedCargo = null;
    _matches = [];
    notifyListeners();
    fetchRoute();
  }

  void setDestination(String cityName) {
    _destPlace = PlaceSuggestion(
      name: cityName,
      description: '$cityName Hub',
      latLng: _destPlace.latLng,
    );
    _lastPostedCargo = null;
    _matches = [];
    notifyListeners();
    fetchRoute();
  }

  void swapLocations() {
    final temp = _originPlace;
    _originPlace = _destPlace;
    _destPlace = temp;
    _lastPostedCargo = null;
    _matches = [];
    notifyListeners();
    fetchRoute();
  }

  Future<bool> useCurrentLocationForPickup() async {
    _isRouting = true;
    notifyListeners();
    final place = await RoutingService.getCurrentLocation();
    if (place != null) {
      _originPlace = place;
      _isRouting = false;
      notifyListeners();
      await fetchRoute();
      return true;
    }
    _isRouting = false;
    notifyListeners();
    return false;
  }

  void setCargoType(String type) {
    _cargoType = type;
    _lastPostedCargo = null;
    _matches = [];
    notifyListeners();
  }

  void setWeightTons(double weight) {
    _weightTons = weight;
    _lastPostedCargo = null;
    _matches = [];
    notifyListeners();
  }

  Future<bool> searchMatchingTrucks() async {
    if (_originPlace.name.trim().isEmpty || _destPlace.name.trim().isEmpty) {
      _errorMessage = 'Choose both pickup and drop locations first.';
      notifyListeners();
      return false;
    }
    if (_originPlace.name == _destPlace.name) {
      _errorMessage = 'Pickup and Drop locations cannot be the same.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pickup = _isInstant
          ? DateTime.now().add(const Duration(hours: 1))
          : _scheduledDate;
      final pDate = '${pickup.year}-${pickup.month.toString().padLeft(2, '0')}-${pickup.day.toString().padLeft(2, '0')}';

      _lastPostedCargo ??= await SupabaseService.postCargoRequest(
        origin: _originPlace.name,
        destination: _destPlace.name,
        cargoType: _cargoType,
        weightTons: _weightTons,
        distanceKm: roadDistanceKm,
        pickupAt: pickup,
        pickupDate: pDate,
        urgency: _isInstant ? 'instant' : 'scheduled',
        pickupAddress: _pickupAddress,
        dropAddress: _dropAddress,
        gstin: _gstin,
      );

      _matches = await SupabaseService.getMatchesForCargo(
        cargoId: _lastPostedCargo!.cargoId,
        origin: _originPlace.name,
        destination: _destPlace.name,
        weightTons: _weightTons,
      );

      if (_matches.isEmpty) {
        _errorMessage =
            'No suitable return capacity found for this route yet. Try another pickup window.';
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register scheduled load without immediately booking a truck (enters open pool on corridor)
  Future<bool> registerScheduledLoad() async {
    if (_originPlace.name.trim().isEmpty || _destPlace.name.trim().isEmpty) {
      _errorMessage = 'Choose both pickup and drop locations first.';
      notifyListeners();
      return false;
    }
    if (_originPlace.name == _destPlace.name) {
      _errorMessage = 'Pickup and Drop locations cannot be the same.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pickup = _isInstant
          ? DateTime.now().add(const Duration(hours: 1))
          : _scheduledDate;
      final pDate = '${pickup.year}-${pickup.month.toString().padLeft(2, '0')}-${pickup.day.toString().padLeft(2, '0')}';

      _lastPostedCargo = await SupabaseService.postCargoRequest(
        origin: _originPlace.name,
        destination: _destPlace.name,
        cargoType: _cargoType,
        weightTons: _weightTons,
        distanceKm: roadDistanceKm,
        pickupAt: pickup,
        pickupDate: pDate,
        urgency: _isInstant ? 'instant' : 'scheduled',
        pickupAddress: _pickupAddress,
        dropAddress: _dropAddress,
        gstin: _gstin,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmBooking(TruckMatch match) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cargoId = _lastPostedCargo?.cargoId;
      if (cargoId == null) {
        throw Exception('Cargo not posted yet - search for trucks first.');
      }
      _lastBooking = await SupabaseService.createBooking(
        cargoId: cargoId,
        truckId: match.truckId,
        agreedPriceInr: match.finalPriceInr,
        matchScore: match.matchScore,
        origin: _originPlace.name,
        destination: _destPlace.name,
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
