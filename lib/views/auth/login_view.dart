import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../common/support_contact_modal.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserRole _selectedRole = UserRole.businessAdmin;
  bool _isLoading = false;
  String? _errorMessage;

  // Controllers — credential form
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  // OTP flow (Customer Portal)
  bool _otpSent = false;
  final _otpCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Pre-fill demo credentials
    _emailCtrl.text = AppConfig.storeAdminEmail;
    _passwordCtrl.text = 'demo1234';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _onRoleSelected(UserRole role) {
    setState(() {
      _selectedRole = role;
      _errorMessage = null;
      _otpSent = false;
      _otpCtrl.clear();
      // Pre-fill demo email for the selected portal
      if (role == UserRole.superAdmin) {
        _emailCtrl.text = AppConfig.superAdminEmail;
      } else if (role == UserRole.customer) {
        _emailCtrl.text = AppConfig.customerEmail;
      } else {
        _emailCtrl.text = AppConfig.storeAdminEmail;
      }
    });
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);

    // If Supabase is not configured, use demo login
    if (!AppConfig.supabaseConfigured) {
      await Future.delayed(const Duration(milliseconds: 400));
      auth.login(email: _emailCtrl.text.trim(), role: _selectedRole);
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      await auth.signInWithSupabase(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        role: _selectedRole,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendOtp() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (AppConfig.supabaseConfigured) {
        await auth.sendOtp(_emailCtrl.text.trim());
      }
      if (mounted) setState(() => _otpSent = true);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to send OTP: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (AppConfig.supabaseConfigured) {
        await auth.verifyOtp(
          email: _emailCtrl.text.trim(),
          token: _otpCtrl.text.trim(),
          role: UserRole.customer,
        );
      } else {
        // Demo mode — any 6-digit OTP works
        if (_otpCtrl.text.trim().length == 6) {
          auth.login(email: _emailCtrl.text.trim(), role: UserRole.customer);
        } else {
          throw Exception('Enter a 6-digit OTP code (demo: any 6 digits)');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── Left Hero Branding Panel ──────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              color: AppTheme.primaryBlue,
              padding: const EdgeInsets.all(40),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/lifesprout_logo.jpg',
                      height: 80,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.medical_services,
                          size: 70,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppConfig.appName,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'Smart ERP & Fast POS Billing System\nby LIFESPROUT Care',
                      style: TextStyle(fontSize: 15, color: Colors.white70),
                    ),
                    const SizedBox(height: 30),
                    _bullet(Icons.offline_bolt,
                        'Hybrid Offline-to-Online Zero Latency Engine'),
                    _bullet(Icons.medication,
                        'FEFO Batch Selection & Schedule H/H1 Regulatory Logs'),
                    _bullet(Icons.receipt_long,
                        'Dual Thermal & PDF Printing + WhatsApp Receipt Sharing'),
                    _bullet(Icons.system_update,
                        'Over-The-Air (OTA) Enterprise Updates'),
                    _bullet(Icons.cloud_sync,
                        'Supabase PostgreSQL Real-time Cloud Sync'),
                    const SizedBox(height: 30),

                    // Demo mode notice
                    if (!AppConfig.supabaseConfigured)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.accentOrange.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: AppTheme.accentOrange, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'DEMO MODE — Configure AppConfig.supabaseUrl '
                                '& supabaseAnonKey to connect live backend.',
                                style: TextStyle(
                                    color: AppTheme.accentOrange,
                                    fontSize: 11,
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Support contact strip
                    InkWell(
                      onTap: () => SupportContactModal.show(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.headset_mic,
                                color: AppTheme.accentOrange),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Support: ${AppConfig.whatsappSupportNumber}\n'
                                '${AppConfig.technicalSupportEmail}',
                                style:
                                    TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Right Login Panel ─────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Portal Access Login',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select your portal, then sign in.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 20),

                      // Role selector cards
                      _roleCard(
                        role: UserRole.businessAdmin,
                        title: 'Business Admin & Staff',
                        subtitle:
                            'POS Billing · FEFO Stock · GST · Regulatory',
                        icon: Icons.store,
                      ),
                      const SizedBox(height: 10),
                      _roleCard(
                        role: UserRole.superAdmin,
                        title: 'Super Admin Portal',
                        subtitle:
                            'Global SaaS Tenants · System Metrics · OTA',
                        icon: Icons.admin_panel_settings,
                      ),
                      const SizedBox(height: 10),
                      _roleCard(
                        role: UserRole.customer,
                        title: 'Customer / Patient Portal',
                        subtitle:
                            'Invoice History · Refill Reminders · Rx Upload',
                        icon: Icons.person_pin,
                      ),
                      const SizedBox(height: 24),

                      // Auth form — password for Admin/Super, OTP for Customer
                      if (_selectedRole == UserRole.customer)
                        _buildOtpForm()
                      else
                        _buildPasswordForm(),

                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color:
                                    AppTheme.errorRed.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppTheme.errorRed, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      color: AppTheme.errorRed, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => SupportContactModal.show(context),
                          icon: const Icon(Icons.help_outline, size: 18),
                          label: const Text(
                              'Need Help? Contact Lifesprout Care Support'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Password form (Business Admin / Super Admin) ──────────────────────────
  Widget _buildPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 6),
        if (!AppConfig.supabaseConfigured)
          const Text(
            'Demo: any password works when Supabase is not configured.',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('Sign In — ${_portalLabel(_selectedRole)}'),
          ),
        ),
      ],
    );
  }

  // ── OTP form (Customer Portal) ────────────────────────────────────────────
  Widget _buildOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          enabled: !_otpSent,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        if (_otpSent) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Enter 6-digit OTP code',
              prefixIcon: Icon(Icons.pin),
              counterText: '',
            ),
            onSubmitted: (_) => _handleVerifyOtp(),
          ),
          const SizedBox(height: 4),
          const Text(
            'Check your email for the one-time code.',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : (_otpSent ? _handleVerifyOtp : _handleSendOtp),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(_otpSent ? 'Verify OTP & Enter Portal' : 'Send OTP to Email'),
          ),
        ),
        if (_otpSent)
          TextButton(
            onPressed: () => setState(() {
              _otpSent = false;
              _otpCtrl.clear();
              _errorMessage = null;
            }),
            child: const Text('← Change email / Resend'),
          ),
      ],
    );
  }

  // ── Role card ─────────────────────────────────────────────────────────────
  Widget _roleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => _onRoleSelected(role),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSelected
                  ? AppTheme.primaryBlue
                  : Colors.grey.shade200,
              child: Icon(
                icon,
                color:
                    isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryBlue
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected
                    ? AppTheme.primaryBlue
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentOrange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _portalLabel(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Super Admin Portal';
      case UserRole.businessAdmin:
        return 'Business Portal';
      default:
        return 'Portal';
    }
  }
}
