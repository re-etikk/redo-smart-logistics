import 'package:flutter/foundation.dart';
import '../data/models/models.dart';
import '../data/services/supabase_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, onboardingRequired }

class AuthViewModel extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserProfile? _profile;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserProfile? get profile => _profile;
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
      await SupabaseService.ensureCustomerRole();
      _profile = await SupabaseService.getProfile();
      if (_profile != null && _profile!.onboardingComplete) {
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

  Future<void> completeOnboarding({
    required String companyName,
    String? fullName,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.saveProfile(
        companyName: companyName,
        fullName: fullName,
        phone: phone,
        onboardingComplete: true,
      );
      _profile = await SupabaseService.getProfile();
      _status = AuthStatus.authenticated;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('23505') || msg.contains('unique') || msg.contains('duplicate')) {
        _errorMessage = 'This phone number is already registered with another account.';
      } else if (msg.contains('23502') || msg.contains('not-null')) {
        _errorMessage = 'Please fill in all required fields.';
      } else {
        _errorMessage = msg.replaceAll('Exception: ', '');
      }
      _status = AuthStatus.onboardingRequired;
    }
    notifyListeners();
  }

  Future<void> updateProfile({
    required String companyName,
    String? fullName,
    String? phone,
    String? gstin,
    String? panNumber,
    String? businessAddress,
    String? avatarUrl,
  }) async {
    final user = SupabaseService.currentUser;
    final uid = user?.id ?? _profile?.id ?? '';
    final resolvedName = (fullName != null && fullName.trim().isNotEmpty)
        ? fullName.trim()
        : (_profile?.fullName ?? user?.email?.split('@').first ?? 'User');

    // Immediately update local in-memory profile and notify listeners
    _profile = UserProfile(
      id: uid,
      fullName: resolvedName,
      phone: (phone != null && phone.trim().isNotEmpty) ? phone.trim() : _profile?.phone,
      role: 'sme',
      companyName: companyName.trim(),
      avatarUrl: (avatarUrl != null && avatarUrl.trim().isNotEmpty) ? avatarUrl.trim() : _profile?.avatarUrl,
      onboardingComplete: true,
      gstin: (gstin != null && gstin.trim().isNotEmpty) ? gstin.trim().toUpperCase() : _profile?.gstin,
      panNumber: (panNumber != null && panNumber.trim().isNotEmpty) ? panNumber.trim().toUpperCase() : _profile?.panNumber,
      businessAddress: (businessAddress != null && businessAddress.trim().isNotEmpty) ? businessAddress.trim() : _profile?.businessAddress,
    );
    notifyListeners();

    try {
      await SupabaseService.saveProfile(
        companyName: companyName,
        fullName: fullName,
        phone: phone,
        gstin: gstin,
        panNumber: panNumber,
        businessAddress: businessAddress,
        avatarUrl: avatarUrl,
        onboardingComplete: true,
      );
    } catch (_) {}
    notifyListeners();
  }

  Future<void> updateAvatar(String avatarUrl) async {
    if (_profile == null) return;
    await updateProfile(
      companyName: _profile!.companyName ?? 'Shipper Business',
      fullName: _profile!.fullName,
      phone: _profile!.phone,
      gstin: _profile!.gstin,
      panNumber: _profile!.panNumber,
      businessAddress: _profile!.businessAddress,
      avatarUrl: avatarUrl,
    );
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    _status = AuthStatus.unauthenticated;
    _profile = null;
    notifyListeners();
  }
}
