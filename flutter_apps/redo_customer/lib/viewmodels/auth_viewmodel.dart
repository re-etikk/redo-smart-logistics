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

  Future<bool> demoLogin() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await SupabaseService.demoLogin();
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
      _errorMessage = e.toString();
      _status = AuthStatus.onboardingRequired;
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await SupabaseService.signOut();
    _status = AuthStatus.unauthenticated;
    _profile = null;
    notifyListeners();
  }
}
