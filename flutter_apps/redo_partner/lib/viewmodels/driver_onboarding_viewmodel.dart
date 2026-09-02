import 'package:flutter/foundation.dart';
import '../data/services/supabase_service.dart';

class DriverOnboardingViewModel extends ChangeNotifier {
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1: Driver Details
  String _fullName = '';
  String _phone = '';
  String _city = 'Delhi NCR';

  // Step 2: Truck Details
  String _registrationNumber = '';
  String _truckType = '22FT Multi-Axle';
  String _bodyType = 'Closed container';
  double _capacityTons = 9.0;
  String _emptyReturnFrom = 'Mumbai';

  // Step 3: Documents Uploaded Map
  final Map<String, bool> _uploadedDocs = {
    'driving_licence': false,
    'vehicle_rc': false,
    'aadhaar_card': false,
  };

  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get fullName => _fullName;
  String get phone => _phone;
  String get city => _city;
  String get registrationNumber => _registrationNumber;
  String get truckType => _truckType;
  String get bodyType => _bodyType;
  double get capacityTons => _capacityTons;
  String get emptyReturnFrom => _emptyReturnFrom;
  Map<String, bool> get uploadedDocs => _uploadedDocs;

  bool get isDocsCompleted => _uploadedDocs.values.every((uploaded) => uploaded);

  void setDriverInfo(String name, String phone, String city) {
    _fullName = name;
    _phone = phone;
    _city = city;
    notifyListeners();
  }

  void setTruckInfo({
    required String reg,
    required String type,
    required String body,
    required double capacity,
    required String returnFrom,
  }) {
    _registrationNumber = reg;
    _truckType = type;
    _bodyType = body;
    _capacityTons = capacity;
    _emptyReturnFrom = returnFrom;
    notifyListeners();
  }

  Future<bool> saveDriverStep() async {
    if (_fullName.isEmpty || _phone.isEmpty) {
      _errorMessage = 'Please enter driver name and phone number.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.saveDriverStep(
        fullName: _fullName,
        phone: _phone,
        city: _city,
      );
      _currentStep = 1;
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

  Future<bool> saveTruckStep() async {
    if (_registrationNumber.isEmpty) {
      _errorMessage = 'Please enter truck registration number.';
      notifyListeners();
      return false;
    }

    if (_emptyReturnFrom == _city) {
      _errorMessage = 'Empty Return route cannot start and end in the same city.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.saveTruckStep(
        registrationNumber: _registrationNumber,
        truckType: _truckType,
        bodyType: _bodyType,
        capacityTons: _capacityTons,
        homeOrigin: _city,
        emptyReturnFrom: _emptyReturnFrom,
      );
      _currentStep = 2;
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

  Future<void> uploadDoc(String docType, Uint8List fileBytes) async {
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.uploadDocument(
        docType: docType,
        fileBytes: fileBytes,
      );
      _uploadedDocs[docType] = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> finishOnboarding() async {
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.finishOnboarding();
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

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }
}
