class AppConfig {
  static const String appName = 'BillSprout';
  static const String appSubtitle = 'Smart ERP & Billing System';
  static const String companyName = 'LIFESPROUT Care';
  static const String version = 'v1.2.0+1 (OTA Ready)';

  // Official Support Channels
  static const String customerCareEmail = 'info@lifesproutcare.com';
  static const String technicalSupportEmail = 'Support@billsprout.online';
  static const String whatsappSupportNumber = '+44 7747 571513';
  static const String whatsappLink = 'https://wa.me/447747571513';

  // Demo Credentials
  static const String superAdminEmail = 'superadmin@billsprout.online';
  static const String storeAdminEmail = 'admin@lifesproutcare.com';
  static const String customerEmail = 'patient@lifesproutcare.com';
  static const String defaultPharmacistPin = '1234';

  // ── Supabase Configuration ─────────────────────────────────────────────
  static const String supabaseUrl =
      'https://juvbhjqaioevpusnmonz.supabase.co';

  /// The Supabase publishable (anon) key — safe for client-side use.
  /// This is also the value previously known as "anonKey".
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp1dmJoanFhaW9ldnB1c25tb256Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAzMjE2MDYsImV4cCI6MjEwNTg5NzYwNn0.D1bXZHEAnkdsSpWOeMpFlKOdhL-V8zpeficOneLPY0U';

  /// Returns true if real Supabase credentials have been configured.
  static bool get supabaseConfigured =>
      !supabaseUrl.contains('your-project-ref') &&
      !supabaseAnonKey.contains('YOUR_ANON_KEY');
}
