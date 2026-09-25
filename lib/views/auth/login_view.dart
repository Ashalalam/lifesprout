import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../config/responsive_layout.dart';
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

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  bool _otpSent = false;
  final _otpCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    setState(() { _isLoading = true; _errorMessage = null; });
    final auth = Provider.of<AuthProvider>(context, listen: false);
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
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSendOtp() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (AppConfig.supabaseConfigured) await auth.sendOtp(_emailCtrl.text.trim());
      if (mounted) setState(() => _otpSent = true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Failed to send OTP: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (AppConfig.supabaseConfigured) {
        await auth.verifyOtp(
          email: _emailCtrl.text.trim(),
          token: _otpCtrl.text.trim(),
          role: UserRole.customer,
        );
      } else {
        if (_otpCtrl.text.trim().length == 6) {
          auth.login(email: _emailCtrl.text.trim(), role: UserRole.customer);
        } else {
          throw Exception('Enter a 6-digit OTP code (demo: any 6 digits)');
        }
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = !context.isMobile;

    return Scaffold(
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  // ── Desktop / tablet — side-by-side hero + form ───────────────────────────
  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(flex: 5, child: _HeroPanel(onSupportTap: () => SupportContactModal.show(context))),
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _LoginForm(
                  selectedRole: _selectedRole,
                  onRoleSelected: _onRoleSelected,
                  emailCtrl: _emailCtrl,
                  passwordCtrl: _passwordCtrl,
                  otpCtrl: _otpCtrl,
                  obscurePassword: _obscurePassword,
                  onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                  isLoading: _isLoading,
                  errorMessage: _errorMessage,
                  otpSent: _otpSent,
                  onLogin: _handleLogin,
                  onSendOtp: _handleSendOtp,
                  onVerifyOtp: _handleVerifyOtp,
                  onOtpBack: () => setState(() { _otpSent = false; _otpCtrl.clear(); _errorMessage = null; }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile — single scrollable column ────────────────────────────────────
  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Compact hero header
          Container(
            width: double.infinity,
            color: AppTheme.primaryBlue,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/lifesprout_logo.jpg',
                      height: 48,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.medical_services, size: 48, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConfig.appName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Smart ERP & POS Billing',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.headset_mic, color: AppTheme.accentOrange),
                      tooltip: 'Support',
                      onPressed: () => SupportContactModal.show(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Login form
          Padding(
            padding: const EdgeInsets.all(20),
            child: _LoginForm(
              selectedRole: _selectedRole,
              onRoleSelected: _onRoleSelected,
              emailCtrl: _emailCtrl,
              passwordCtrl: _passwordCtrl,
              otpCtrl: _otpCtrl,
              obscurePassword: _obscurePassword,
              onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              otpSent: _otpSent,
              onLogin: _handleLogin,
              onSendOtp: _handleSendOtp,
              onVerifyOtp: _handleVerifyOtp,
              onOtpBack: () => setState(() { _otpSent = false; _otpCtrl.clear(); _errorMessage = null; }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Panel (desktop left side)
// ─────────────────────────────────────────────────────────────────────────────
class _HeroPanel extends StatelessWidget {
  final VoidCallback onSupportTap;
  const _HeroPanel({required this.onSupportTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.primaryBlue,
      padding: const EdgeInsets.all(40),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/lifesprout_logo.jpg',
              height: 72,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.medical_services, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              AppConfig.appName,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Smart ERP & Fast POS Billing System\nby LIFESPROUT Care',
              style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 28),
            _bullet(Icons.offline_bolt, 'Hybrid Offline-to-Online Zero Latency Engine'),
            _bullet(Icons.medication, 'FEFO Batch Selection & Schedule H/H1 Regulatory Logs'),
            _bullet(Icons.receipt_long, 'Dual Thermal & PDF Printing + WhatsApp Receipt Sharing'),
            _bullet(Icons.system_update, 'Over-The-Air (OTA) Enterprise Updates'),
            _bullet(Icons.cloud_sync, 'Supabase PostgreSQL Real-time Cloud Sync'),
            const SizedBox(height: 28),
            if (!AppConfig.supabaseConfigured)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.accentOrange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'DEMO MODE — configure Supabase credentials in app_config.dart.',
                        style: TextStyle(color: AppTheme.accentOrange, fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            InkWell(
              onTap: onSupportTap,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.headset_mic, color: AppTheme.accentOrange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Support: ${AppConfig.whatsappSupportNumber}\n${AppConfig.technicalSupportEmail}',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                  ],
                ),
              ),
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
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Login Form — shared between wide and narrow layouts
// ─────────────────────────────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final UserRole selectedRole;
  final void Function(UserRole) onRoleSelected;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController otpCtrl;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool isLoading;
  final String? errorMessage;
  final bool otpSent;
  final VoidCallback onLogin;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onOtpBack;

  const _LoginForm({
    required this.selectedRole,
    required this.onRoleSelected,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.otpCtrl,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.isLoading,
    required this.errorMessage,
    required this.otpSent,
    required this.onLogin,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onOtpBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portal Access Login',
          style: TextStyle(
            fontSize: context.isMobile ? 22 : 26,
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

        _RoleCard(
          role: UserRole.businessAdmin,
          title: 'Business Admin & Staff',
          subtitle: 'POS · FEFO Stock · GST · Regulatory',
          icon: Icons.store,
          selectedRole: selectedRole,
          onTap: onRoleSelected,
        ),
        const SizedBox(height: 10),
        _RoleCard(
          role: UserRole.superAdmin,
          title: 'Super Admin Portal',
          subtitle: 'Global SaaS Tenants · Metrics · OTA',
          icon: Icons.admin_panel_settings,
          selectedRole: selectedRole,
          onTap: onRoleSelected,
        ),
        const SizedBox(height: 10),
        _RoleCard(
          role: UserRole.customer,
          title: 'Customer / Patient Portal',
          subtitle: 'Invoice History · Refill Reminders · Rx',
          icon: Icons.person_pin,
          selectedRole: selectedRole,
          onTap: onRoleSelected,
        ),
        const SizedBox(height: 24),

        if (selectedRole == UserRole.customer)
          _OtpForm(
            emailCtrl: emailCtrl,
            otpCtrl: otpCtrl,
            otpSent: otpSent,
            isLoading: isLoading,
            onSendOtp: onSendOtp,
            onVerifyOtp: onVerifyOtp,
            onBack: onOtpBack,
          )
        else
          _PasswordForm(
            emailCtrl: emailCtrl,
            passwordCtrl: passwordCtrl,
            obscurePassword: obscurePassword,
            onToggleObscure: onToggleObscure,
            isLoading: isLoading,
            selectedRole: selectedRole,
            onLogin: onLogin,
          ),

        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: AppTheme.errorRed, fontSize: 12),
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
            icon: const Icon(Icons.help_outline, size: 16),
            label: const Text(
              'Need Help? Contact Lifesprout Care Support',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Password form
// ─────────────────────────────────────────────────────────────────────────────
class _PasswordForm extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final bool isLoading;
  final UserRole selectedRole;
  final VoidCallback onLogin;

  const _PasswordForm({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.isLoading,
    required this.selectedRole,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordCtrl,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
              onPressed: onToggleObscure,
            ),
          ),
          onSubmitted: (_) => onLogin(),
        ),
        const SizedBox(height: 6),
        if (!AppConfig.supabaseConfigured)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Demo: any password works.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : onLogin,
            child: isLoading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_portalLabel(selectedRole)),
          ),
        ),
      ],
    );
  }

  String _portalLabel(UserRole role) {
    switch (role) {
      case UserRole.superAdmin: return 'Sign In — Super Admin Portal';
      case UserRole.businessAdmin: return 'Sign In — Business Portal';
      default: return 'Sign In';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OTP form (Customer portal)
// ─────────────────────────────────────────────────────────────────────────────
class _OtpForm extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController otpCtrl;
  final bool otpSent;
  final bool isLoading;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onBack;

  const _OtpForm({
    required this.emailCtrl,
    required this.otpCtrl,
    required this.otpSent,
    required this.isLoading,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          enabled: !otpSent,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        if (otpSent) ...[
          const SizedBox(height: 12),
          TextField(
            controller: otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '6-digit OTP Code',
              prefixIcon: Icon(Icons.pin),
              counterText: '',
            ),
            onSubmitted: (_) => onVerifyOtp(),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Check your email for the code.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isLoading ? null : (otpSent ? onVerifyOtp : onSendOtp),
            child: isLoading
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(otpSent ? 'Verify OTP & Enter Portal' : 'Send OTP to Email'),
          ),
        ),
        if (otpSent)
          TextButton(
            onPressed: onBack,
            child: const Text('← Change email / Resend'),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Role selector card
// ─────────────────────────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final UserRole role;
  final String title;
  final String subtitle;
  final IconData icon;
  final UserRole selectedRole;
  final void Function(UserRole) onTap;

  const _RoleCard({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selectedRole,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedRole == role;
    return InkWell(
      onTap: () => onTap(role),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSelected ? AppTheme.primaryBlue : Colors.grey.shade200,
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? AppTheme.primaryBlue : AppTheme.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
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
}
