import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../config/app_config.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isPinVerified = false;
  bool _isLoading = false;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isPinVerified => _isPinVerified;
  bool get isLoading => _isLoading;

  AuthProvider() {
    if (AppConfig.supabaseConfigured) {
      _restoreSession();
      SupabaseService().authStateStream.listen(_onAuthStateChange);
    }
  }

  // ── Demo login (no backend) ───────────────────────────────────────────────
  void login({required String email, required UserRole role}) {
    _currentUser = AppUser(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: role == UserRole.superAdmin
          ? 'Lifesprout Super Admin'
          : role == UserRole.customer
              ? 'Patient User'
              : 'Dr. Sarah Connor (Pharmacist)',
      email: email,
      phone: '+44 7747 571513',
      role: role,
      companyId: role == UserRole.superAdmin ? null : 'comp_lifesprout_01',
      licenseNo: role == UserRole.pharmacist || role == UserRole.businessAdmin
          ? 'PH-UK-984721'
          : null,
    );
    notifyListeners();
  }

  // ── Sign in ───────────────────────────────────────────────────────────────
  Future<void> signInWithSupabase({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await SupabaseService()
          .signInWithPassword(email: email, password: password);
      final user = response.user;
      if (user == null) throw Exception('Sign-in failed — no user returned.');
      _currentUser = _userFromSupabase(user, role);
      notifyListeners();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Customer self-registration ────────────────────────────────────────────
  Future<void> registerCustomer({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Demo mode — create local account instantly
    if (!AppConfig.supabaseConfigured) {
      await Future.delayed(const Duration(milliseconds: 500));
      _currentUser = AppUser(
        id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        phone: phone,
        role: UserRole.customer,
        companyId: null,
        licenseNo: null,
      );
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Live Supabase registration
    try {
      final response = await SupabaseService().signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'role': UserRole.customer.name,
        },
      );
      final user = response.user;
      if (user == null) {
        // Supabase returns null user when email confirmation is required
        throw Exception(
            'Account created! Check your email to confirm, then sign in.');
      }
      _currentUser = _userFromSupabase(user, UserRole.customer);
      notifyListeners();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  void logout() {
    if (AppConfig.supabaseConfigured) {
      SupabaseService().signOut().catchError((_) {});
    }
    _currentUser = null;
    _isPinVerified = false;
    notifyListeners();
  }

  // ── PIN verification ──────────────────────────────────────────────────────
  bool verifyPharmacistPin(String pin) {
    if (pin == AppConfig.pharmacistPin) {
      _isPinVerified = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  // ── Internal ──────────────────────────────────────────────────────────────
  void _restoreSession() {
    final session = SupabaseService().currentSession;
    if (session != null) {
      final meta     = session.user.userMetadata;
      final roleName = meta?['role'] as String? ?? 'businessAdmin';
      final role     = UserRole.values.firstWhere(
        (r) => r.name == roleName,
        orElse: () => UserRole.businessAdmin,
      );
      _currentUser = _userFromSupabase(session.user, role);
      notifyListeners();
    }
  }

  void _onAuthStateChange(AuthState state) {
    if (state.event == AuthChangeEvent.signedOut) {
      _currentUser = null;
      _isPinVerified = false;
      notifyListeners();
    } else if (state.event == AuthChangeEvent.tokenRefreshed ||
        state.event == AuthChangeEvent.signedIn) {
      final user = state.session?.user;
      if (user != null && _currentUser == null) {
        _restoreSession();
      }
    }
  }

  AppUser _userFromSupabase(User user, UserRole role) {
    final meta = user.userMetadata ?? {};
    return AppUser(
      id: user.id,
      name: (meta['name'] as String?) ??
          (meta['full_name'] as String?) ??
          user.email ??
          'User',
      email: user.email ?? '',
      phone: (meta['phone'] as String?) ?? '',
      role: role,
      companyId: meta['companyId'] as String?,
      licenseNo: meta['licenseNo'] as String?,
    );
  }
}
