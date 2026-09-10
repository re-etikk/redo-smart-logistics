import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/services/supabase_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, onboardingRequired }

class AuthViewModel extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  DriverProfile? _profile;
  String? _errorMessage;

  AuthStatus get status => _status;
  DriverProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;

  AuthViewModel() {
    _initAuthListener();
  }

  void _initAuthListener() {
    SupabaseService.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session == null) {
        _status = AuthStatus.unauthenticated;
        _profile = null;
        notifyListeners();
      } else {
        await checkProfileStatus();
      }
    });
  }

  Future<void> checkProfileStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    final user = SupabaseService.currentUser;
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      await SupabaseService.ensurePartnerRole();
      _profile = await SupabaseService.getProfile();
      if (_profile != null && _profile!.partnerOnboardingComplete) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.onboardingRequired;
      }
    } catch (e) {
      _status = AuthStatus.onboardingRequired;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.signIn(email: email, password: password);
      await checkProfileStatus();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String fullName) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.signUp(email: email, password: password, fullName: fullName);
      await checkProfileStatus();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      return await SupabaseService.signInWithGoogle();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> onOnboardingCompleted() async {
    _profile = await SupabaseService.getProfile();
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
    required String city,
    String? avatarUrl,
    String? dlNumber,
    String? bankAccountNumber,
    String? bankIfsc,
    bool? faceBiometricVerified,
  }) async {
    final uid = SupabaseService.currentUser?.id ?? _profile?.id ?? '';
    _profile = DriverProfile(
      id: uid,
      fullName: fullName.trim(),
      phone: phone.trim().isNotEmpty ? phone.trim() : _profile?.phone,
      role: 'truck_owner',
      companyName: city.trim().isNotEmpty ? city.trim() : _profile?.companyName,
      avatarUrl: (avatarUrl != null && avatarUrl.trim().isNotEmpty) ? avatarUrl.trim() : _profile?.avatarUrl,
      onboardingComplete: true,
      partnerOnboardingComplete: true,
      dlNumber: (dlNumber != null && dlNumber.trim().isNotEmpty) ? dlNumber.trim().toUpperCase() : _profile?.dlNumber,
      dlVerified: dlNumber != null ? true : (_profile?.dlVerified ?? false),
      bankAccountNumber: (bankAccountNumber != null && bankAccountNumber.trim().isNotEmpty) ? bankAccountNumber.trim() : _profile?.bankAccountNumber,
      bankIfsc: (bankIfsc != null && bankIfsc.trim().isNotEmpty) ? bankIfsc.trim().toUpperCase() : _profile?.bankIfsc,
      faceBiometricVerified: faceBiometricVerified ?? (_profile?.faceBiometricVerified ?? false),
    );
    notifyListeners();

    try {
      await SupabaseService.saveDriverStep(
        fullName: fullName,
        phone: phone,
        city: city,
        avatarUrl: avatarUrl,
        dlNumber: dlNumber,
        bankAccountNumber: bankAccountNumber,
        bankIfsc: bankIfsc,
        faceBiometricVerified: faceBiometricVerified,
      );
    } catch (_) {}
    notifyListeners();
  }

  Future<void> updateAvatar(String avatarUrl) async {
    await updateProfile(
      fullName: _profile?.fullName ?? 'Driver',
      phone: _profile?.phone ?? '',
      city: _profile?.companyName ?? '',
      avatarUrl: avatarUrl,
      dlNumber: _profile?.dlNumber,
      bankAccountNumber: _profile?.bankAccountNumber,
      bankIfsc: _profile?.bankIfsc,
      faceBiometricVerified: _profile?.faceBiometricVerified,
    );
  }

  Future<void> updateDlDetails({
    required String dlNumber,
    String? dlClass,
    String? issuingRto,
    String? expiryDate,
    String? rto,
  }) async {
    await updateProfile(
      fullName: _profile?.fullName ?? 'Driver',
      phone: _profile?.phone ?? '',
      city: _profile?.companyName ?? '',
      avatarUrl: _profile?.avatarUrl,
      dlNumber: dlNumber,
      bankAccountNumber: _profile?.bankAccountNumber,
      bankIfsc: _profile?.bankIfsc,
      faceBiometricVerified: _profile?.faceBiometricVerified,
    );
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    _status = AuthStatus.unauthenticated;
    _profile = null;
    notifyListeners();
  }
}
