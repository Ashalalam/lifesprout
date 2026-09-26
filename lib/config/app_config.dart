import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String appName      = 'BillSprout';
  static const String appSubtitle  = 'Smart ERP & Billing System';
  static const String companyName  = 'LIFESPROUT Care';
  static const String version      = 'v1.3.0+1 (OTA Ready)';

  // Official Support Channels
  static const String customerCareEmail      = 'info@lifesproutcare.com';
  static const String technicalSupportEmail  = 'Support@billsprout.online';
  static const String whatsappSupportNumber  = '+44 7747 571513';
  static const String whatsappLink           = 'https://wa.me/447747571513';

  // Demo Credentials
  static const String superAdminEmail = 'superadmin@billsprout.online';
  static const String storeAdminEmail = 'admin@lifesproutcare.com';
  static const String customerEmail   = 'patient@lifesproutcare.com';

  /// Fallback PIN used only when no custom PIN has been saved.
  static const String _fallbackPin = '1234';
  static const String _pinKey = 'pharmacist_pin_v1';

  // ── Dynamic PIN management ────────────────────────────────────────────────
  static String _cachedPin = _fallbackPin;

  /// Call once at startup to load the saved PIN from SharedPreferences.
  static Future<void> loadPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedPin = prefs.getString(_pinKey) ?? _fallbackPin;
    } catch (_) {
      _cachedPin = _fallbackPin;
    }
  }

  /// Current pharmacist PIN (loaded from SharedPreferences).
  static String get pharmacistPin => _cachedPin;

  /// Save a new PIN (4–6 digits). Returns true on success.
  static Future<bool> setPharmacistPin({
    required String currentPin,
    required String newPin,
  }) async {
    if (currentPin != _cachedPin) return false;
    if (newPin.length < 4 || newPin.length > 6) return false;
    if (!RegExp(r'^\d+$').hasMatch(newPin)) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pinKey, newPin);
      _cachedPin = newPin;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reset to fallback (emergency use — requires old PIN verification).
  static Future<bool> resetPin(String currentPin) =>
      setPharmacistPin(currentPin: currentPin, newPin: _fallbackPin);

  // ── Supabase Configuration ────────────────────────────────────────────────
  static const String supabaseUrl =
      'https://juvbhjqaioevpusnmonz.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1dmJoanFhaW9ldnB1c25tb256Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAzMjE2MDYsImV4cCI6MjEwNTg5NzYwNn0.D1bXZHEAnkdsSpWOeMpFlKOdhL-V8zpeficOneLPY0U';

  static bool get supabaseConfigured =>
      !supabaseUrl.contains('your-project-ref') &&
      !supabaseAnonKey.contains('YOUR_ANON_KEY');
}
