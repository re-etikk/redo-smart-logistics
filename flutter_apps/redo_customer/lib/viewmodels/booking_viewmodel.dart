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
  CityLocation('Delhi NCR', LatLng(28.6139, 77.2090)),
  CityLocation('Mumbai', LatLng(19.0760, 72.8777)),
  CityLocation('Patna', LatLng(25.5941, 85.1376)),
  CityLocation('Lucknow', LatLng(26.8467, 80.9462)),
  CityLocation('Kanpur', LatLng(26.4499, 80.3319)),
  CityLocation('Varanasi', LatLng(25.3176, 82.9739)),
  CityLocation('Kolkata', LatLng(22.5726, 88.3639)),
  CityLocation('Hyderabad', LatLng(17.3850, 78.4867)),
  CityLocation('Bengaluru', LatLng(12.9716, 77.5946)),
  CityLocation('Chennai', LatLng(13.0827, 80.2707)),
  CityLocation('Ahmedabad', LatLng(23.0225, 72.5714)),
  CityLocation('Surat', LatLng(21.1702, 72.8311)),
  CityLocation('Pune', LatLng(18.5204, 73.8567)),
  CityLocation('Jaipur', LatLng(26.9124, 75.7873)),
  CityLocation('Indore', LatLng(22.7196, 75.8577)),
  CityLocation('Nagpur', LatLng(21.1458, 79.0882)),
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
  double _volumeCft = 0.0;
  bool _isLoading = false;
  bool _isRouting = false;
  RouteInfo? _currentRoute;
  List<TruckMatch> _matches = [];
  CargoRequest? _lastPostedCargo;
  BookingItem? _lastBooking;
  String? _errorMessage;
  PriceQuote? _currentQuote;
  bool _isFetchingQuote = false;

  // Professional Scheduling & Load Details
  bool _isInstant = false;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  String _timeSlot = 'Morning (08:00 - 12:00)';
  String _pickupAddress = '';
  String _dropAddress = '';
  String _gstin = '';
  bool _pickupCoordinatesVerified = false;

  // Detailed cargo specification for native UI flow
  int _packageCount = 2;
  double _lengthCm = 30;
  double _widthCm = 20;
  double _heightCm = 15;
  bool _isFragile = false;
  bool _isTemperatureSensitive = false;
  double _declaredValueInr = 50000;

  PlaceSuggestion get originPlace => _originPlace;
  PlaceSuggestion get destPlace => _destPlace;
  String get origin => _originPlace.name;
  String get destination => _destPlace.name;
  LatLng get originLatLng => _originPlace.latLng;
  bool get hasVerifiedPickupCoordinates => _pickupCoordinatesVerified;

  bool get _hasUsablePickupCoordinates =>
      _pickupCoordinatesVerified &&
      _originPlace.latLng.latitude >= -90 &&
      _originPlace.latLng.latitude <= 90 &&
      _originPlace.latLng.longitude >= -180 &&
      _originPlace.latLng.longitude <= 180;
  LatLng get destinationLatLng => _destPlace.latLng;

  String get cargoType => _cargoType;
  double get weightTons => _weightTons;
  double get volumeCft => _volumeCft;

  void setVolumeCft(double cft) {
    _volumeCft = cft;
    notifyListeners();
  }

  double get volumetricWeightTons =>
      _volumeCft > 0 ? (_volumeCft / 120.0) : 0.0;
  double get billableWeightTons =>
      volumetricWeightTons > _weightTons ? volumetricWeightTons : _weightTons;

  int get packageCount => _packageCount;
  double get lengthCm => _lengthCm;
  double get widthCm => _widthCm;
  double get heightCm => _heightCm;
  bool get isFragile => _isFragile;
  bool get isTemperatureSensitive => _isTemperatureSensitive;
  double get declaredValueInr => _declaredValueInr;
  double get weightKg => (_weightTons * 1000.0).clamp(0.5, 99999.0);

  void setWeightKg(double kg) {
    _weightTons = kg / 1000.0;
    _lastPostedCargo = null;
    _matches = [];
    notifyListeners();
  }

  void setPackageCount(int count) {
    _packageCount = count.clamp(1, 999);
    notifyListeners();
  }

  void setDimensions({
    required double length,
    required double width,
    required double height,
  }) {
    _lengthCm = length;
    _widthCm = width;
    _heightCm = height;
    _volumeCft = (length * width * height) / 28316.8;
    notifyListeners();
  }

  void setFragile(bool val) {
    _isFragile = val;
    notifyListeners();
  }

  void setTemperatureSensitive(bool val) {
    _isTemperatureSensitive = val;
    notifyListeners();
  }

  void setDeclaredValueInr(double val) {
    _declaredValueInr = val;
    notifyListeners();
  }

  PriceQuote? get currentQuote => _currentQuote;
  bool get isFetchingQuote => _isFetchingQuote;

  Future<PriceQuote> fetchPriceQuote({bool silent = false}) async {
    if (!silent) {
      _isFetchingQuote = true;
      notifyListeners();
    }

    final orig = origin.isNotEmpty ? origin : 'Delhi, DL';
    final dest = destination.isNotEmpty ? destination : 'Patna, BR';
    final dist = roadDistanceKm > 0 ? roadDistanceKm : 500.0;
    final wTons = billableWeightTons > 0 ? billableWeightTons : 0.5;

    final quote = await SupabaseService.getPriceQuote(
      origin: orig,
      destination: dest,
      weightTons: wTons,
      cargoType: _cargoType,
      distanceKm: dist,
      volumeCft: _volumeCft,
      urgency: _isInstant ? 'express' : 'standard',
    );

    _currentQuote = quote;
    _isFetchingQuote = false;
    notifyListeners();
    return quote;
  }

  double get estimatedFareInr {
    if (_currentQuote != null) return _currentQuote!.finalPriceInr;
    final dist = roadDistanceKm > 0 ? roadDistanceKm : 350.0;
    final w = billableWeightTons > 0 ? billableWeightTons : 2.5;
    return (dist * w * 2.4 * 1.08).clamp(1800.0, 999999.0).roundToDouble();
  }

  // Itemized breakdown matching ReDo Screen 04 design
  double get priceBaseFareInr {
    if (_currentQuote != null) return _currentQuote!.estimatedPriceInr;
    final fare = estimatedFareInr;
    return (fare * 0.77).roundToDouble();
  }

  double get priceDistanceChargeInr {
    if (_currentQuote != null) return 0.0;
    final fare = estimatedFareInr;
    return (fare * 0.15).roundToDouble();
  }

  double get priceCargoHandlingInr {
    if (_currentQuote != null) return 0.0;
    final extra = (_isFragile ? 80.0 : 0.0) + (_isTemperatureSensitive ? 100.0 : 0.0);
    return (180.0 + extra).roundToDouble();
  }

  double get priceServiceFeeInr => _currentQuote?.applicableFeesInr ?? 50.0;

  double get priceTotalInr {
    if (_currentQuote != null) return _currentQuote!.finalPriceInr;
    return priceBaseFareInr + priceDistanceChargeInr + priceCargoHandlingInr + priceServiceFeeInr;
  }

  double get dedicatedTruckBenchmarkInr {
    if (_currentQuote != null) return _currentQuote!.estimatedDedicatedTruckPriceInr;
    final dist = roadDistanceKm > 0 ? roadDistanceKm : 350.0;
    return (dist * 18.0 + 1500.0).clamp(4500.0, 999999.0).roundToDouble();
  }

  int get savingsPct {
    if (_currentQuote != null) return _currentQuote!.savingsPct;
    if (dedicatedTruckBenchmarkInr <= estimatedFareInr) return 42;
    return (((dedicatedTruckBenchmarkInr - estimatedFareInr) /
                dedicatedTruckBenchmarkInr) *
            100)
        .round()
        .clamp(15, 80);
  }

  double get savingsAmountInr {
    if (_currentQuote != null) return _currentQuote!.savingsAmountInr;
    return (dedicatedTruckBenchmarkInr - priceTotalInr).clamp(0.0, 999999.0);
  }

  PricingConditions? get pricingConditions => _currentQuote?.conditions;

  bool get isLoading => _isLoading;
  bool get isRouting => _isRouting;
  RouteInfo? get currentRoute => _currentRoute;
  List<LatLng> get routePoints =>
      _currentRoute?.points ?? [_originPlace.latLng, _destPlace.latLng];
  double get roadDistanceKm => _currentRoute?.distanceKm ?? 0;
  String get roadDistanceText =>
      _currentRoute?.distanceText ?? '${roadDistanceKm.round()} km';
  String get roadDurationText =>
      _currentRoute?.durationText ?? 'Route not calculated';

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
    _pickupCoordinatesVerified = true;
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
    _pickupCoordinatesVerified = false;
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
      _pickupCoordinatesVerified = true;
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

  /// Creates the actual shipment/order record on the backend.
  /// Validates all parameters and persists customer, pickup, delivery, cargo,
  /// dimensions, weight, quantity, special handling, estimated price, status,
  /// and timestamp.
  Future<CargoRequest?> createShipmentOrder({double? estimatedPrice}) async {
    // 1. Rigorous data validation before submitting to backend
    if (_originPlace.name.trim().isEmpty) {
      _errorMessage = 'Please select a pickup location.';
      notifyListeners();
      return null;
    }
    if (_destPlace.name.trim().isEmpty) {
      _errorMessage = 'Please select a delivery location.';
      notifyListeners();
      return null;
    }
    if (_originPlace.name.trim().toLowerCase() == _destPlace.name.trim().toLowerCase()) {
      _errorMessage = 'Pickup and delivery locations cannot be identical.';
      notifyListeners();
      return null;
    }
    if (weightKg <= 0) {
      _errorMessage = 'Cargo weight must be positive.';
      notifyListeners();
      return null;
    }
    if (_packageCount < 1) {
      _errorMessage = 'Package quantity must be at least 1.';
      notifyListeners();
      return null;
    }
    if (_lengthCm <= 0 || _widthCm <= 0 || _heightCm <= 0) {
      _errorMessage = 'Cargo dimensions must be positive.';
      notifyListeners();
      return null;
    }
    if (_declaredValueInr <= 0) {
      _errorMessage = 'Please enter a valid estimated cargo value.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pickup = _isInstant
          ? DateTime.now().add(const Duration(hours: 1))
          : _scheduledDate;
      final pDate =
          '${pickup.year}-${pickup.month.toString().padLeft(2, '0')}-${pickup.day.toString().padLeft(2, '0')}';

      final finalEstimatedPrice = (estimatedPrice != null && estimatedPrice > 0)
          ? estimatedPrice
          : (priceTotalInr > 0 ? priceTotalInr : estimatedFareInr);

      final cargo = await SupabaseService.postCargoRequest(
        origin: _originPlace.name.trim(),
        destination: _destPlace.name.trim(),
        cargoType: _cargoType.trim(),
        weightTons: _weightTons,
        distanceKm: roadDistanceKm > 0 ? roadDistanceKm : 350.0,
        pickupAt: pickup,
        pickupDate: pDate,
        urgency: _isInstant ? 'instant' : 'scheduled',
        pickupAddress: _pickupAddress.isNotEmpty ? _pickupAddress : _originPlace.name,
        pickupLat: _pickupCoordinatesVerified
            ? _originPlace.latLng.latitude
            : null,
        pickupLng: _pickupCoordinatesVerified
            ? _originPlace.latLng.longitude
            : null,
        dropAddress: _dropAddress.isNotEmpty ? _dropAddress : _destPlace.name,
        gstin: _gstin,
        packageCount: _packageCount,
        lengthCm: _lengthCm,
        widthCm: _widthCm,
        heightCm: _heightCm,
        dimensions: '${_lengthCm.round()} x ${_widthCm.round()} x ${_heightCm.round()} cm',
        isFragile: _isFragile,
        isTemperatureSensitive: _isTemperatureSensitive,
        declaredValueInr: _declaredValueInr,
        estimatedPriceInr: finalEstimatedPrice,
      );

      _lastPostedCargo = cargo;
      _isLoading = false;
      notifyListeners();
      return cargo;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> searchMatchingTrucks() async {
    final targetCargoId = _lastPostedCargo?.cargoId;
    if (targetCargoId == null) {
      _errorMessage = 'Shipment must be confirmed before finding trucks.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _matches = await SupabaseService.getMatchesForCargo(
        cargoId: targetCargoId,
        origin: _originPlace.name,
        destination: _destPlace.name,
        weightTons: _weightTons,
      );

      if (_matches.isEmpty) {
        _errorMessage =
            'No matching trucks found for this route yet. Searching network...';
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
    if (!_hasUsablePickupCoordinates) {
      _errorMessage =
          'Select a pickup point from the map or use your current location to notify nearby drivers.';
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
      final pDate =
          '${pickup.year}-${pickup.month.toString().padLeft(2, '0')}-${pickup.day.toString().padLeft(2, '0')}';

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
        pickupLat: _pickupCoordinatesVerified
            ? _originPlace.latLng.latitude
            : null,
        pickupLng: _pickupCoordinatesVerified
            ? _originPlace.latLng.longitude
            : null,
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

  Future<bool> retryDispatch() async {
    final cargoId = _lastPostedCargo?.cargoId;
    if (cargoId == null) return false;
    _isLoading = true;
    notifyListeners();
    final ok = await SupabaseService.retryDispatch(cargoId);
    _isLoading = false;
    notifyListeners();
    return ok;
  }

  Future<bool> cancelCurrentCargo() async {
    final cargoId = _lastPostedCargo?.cargoId;
    if (cargoId == null) return false;
    _isLoading = true;
    notifyListeners();
    final ok = await SupabaseService.cancelCargoRequest(cargoId);
    _lastPostedCargo = null;
    _isLoading = false;
    notifyListeners();
    return ok;
  }
}
