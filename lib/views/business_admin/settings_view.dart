import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../providers/pos_provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primaryBlue,
              tabs: const [
                Tab(icon: Icon(Icons.security), text: 'Pharmacist PIN'),
                Tab(icon: Icon(Icons.store), text: 'Branch Management'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PharmacistPinTab(),
                _BranchManagementTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Pharmacist PIN Management
// ─────────────────────────────────────────────────────────────────────────────
class _PharmacistPinTab extends StatefulWidget {
  @override
  State<_PharmacistPinTab> createState() => _PharmacistPinTabState();
}

class _PharmacistPinTabState extends State<_PharmacistPinTab> {
  final _currentPinCtrl = TextEditingController();
  final _newPinCtrl     = TextEditingController();
  final _confirmCtrl    = TextEditingController();
  bool _obscureCurrent  = true;
  bool _obscureNew      = true;
  bool _obscureConfirm  = true;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _currentPinCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePin() async {
    setState(() { _error = null; _success = null; });

    final current = _currentPinCtrl.text.trim();
    final newPin  = _newPinCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (current.isEmpty || newPin.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'All fields are required.');
      return;
    }
    if (newPin != confirm) {
      setState(() => _error = 'New PIN and Confirm PIN do not match.');
      return;
    }
    if (newPin.length < 4 || newPin.length > 6) {
      setState(() => _error = 'PIN must be 4–6 digits.');
      return;
    }
    if (!RegExp(r'^\d+$').hasMatch(newPin)) {
      setState(() => _error = 'PIN must contain digits only.');
      return;
    }

    final ok = await AppConfig.setPharmacistPin(
        currentPin: current, newPin: newPin);

    if (ok) {
      _currentPinCtrl.clear();
      _newPinCtrl.clear();
      _confirmCtrl.clear();
      setState(() => _success =
          '✅ Pharmacist PIN updated successfully! New PIN: $newPin');
    } else {
      setState(() => _error =
          'Incorrect current PIN. Current PIN is ${AppConfig.pharmacistPin}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.security, color: AppTheme.primaryBlue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Pharmacist Security PIN',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                          fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'This PIN is required to authorize dispensing of Schedule H, '
                  'Schedule H1, and Narcotic medicines at the POS checkout.\n\n'
                  'Only authorized pharmacists should know this PIN.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppTheme.accentOrange, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Current PIN is set (${AppConfig.pharmacistPin.length} digits). '
                        'Change it below.',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.accentOrange,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Change PIN form
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Pharmacist PIN',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primaryBlue),
                ),
                const SizedBox(height: 16),

                // Current PIN
                TextField(
                  controller: _currentPinCtrl,
                  obscureText: _obscureCurrent,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Current PIN',
                    prefixIcon: const Icon(Icons.lock_outline),
                    counterText: '',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // New PIN
                TextField(
                  controller: _newPinCtrl,
                  obscureText: _obscureNew,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'New PIN (4–6 digits)',
                    prefixIcon: const Icon(Icons.lock_reset),
                    counterText: '',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Confirm PIN
                TextField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Confirm New PIN',
                    prefixIcon: const Icon(Icons.lock),
                    counterText: '',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  onSubmitted: (_) => _changePin(),
                ),
                const SizedBox(height: 8),
                const Text(
                  'PIN must be 4–6 digits. Use a number only the dispensing '
                  'pharmacist knows.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),

                // Error / success
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.errorRed.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.errorRed, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppTheme.errorRed, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_success != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              AppTheme.successGreen.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            color: AppTheme.successGreen, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_success!,
                              style: const TextStyle(
                                  color: AppTheme.successGreen,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue),
                    onPressed: _changePin,
                    icon: const Icon(Icons.save),
                    label: const Text('Update Pharmacist PIN'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Branch Management
// ─────────────────────────────────────────────────────────────────────────────
class _BranchManagementTab extends StatefulWidget {
  @override
  State<_BranchManagementTab> createState() => _BranchManagementTabState();
}

class _BranchManagementTabState extends State<_BranchManagementTab> {
  final _newBranchCtrl = TextEditingController();

  @override
  void dispose() {
    _newBranchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = Provider.of<PosProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Store Branches',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 4),
          const Text(
            'Each branch is selectable at POS checkout. '
            'The selected branch appears on the printed invoice.',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),

          // Add new branch
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newBranchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'New Branch Name',
                    hintText: 'e.g. Airport Road Branch',
                    prefixIcon: Icon(Icons.add_business),
                  ),
                  onSubmitted: (_) => _addBranch(pos),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _addBranch(pos),
                icon: const Icon(Icons.add),
                label: const Text('Add Branch'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Existing branches
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: pos.branches.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final b = pos.branches[i];
                  final isActive = pos.branch == b;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive
                          ? AppTheme.primaryBlue
                          : AppTheme.primaryBlue.withValues(alpha: 0.1),
                      child: Icon(Icons.store,
                          color:
                              isActive ? Colors.white : AppTheme.primaryBlue,
                          size: 20),
                    ),
                    title: Text(b,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? AppTheme.primaryBlue
                                : AppTheme.textDark)),
                    trailing: isActive
                        ? Chip(
                            label: const Text('Active'),
                            backgroundColor: AppTheme.successGreen
                                .withValues(alpha: 0.1),
                            labelStyle: const TextStyle(
                                color: AppTheme.successGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          )
                        : TextButton(
                            onPressed: () => pos.setBranch(b),
                            child: const Text('Set Active'),
                          ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addBranch(PosProvider pos) {
    final name = _newBranchCtrl.text.trim();
    if (name.isEmpty) return;
    pos.addBranch(name);
    _newBranchCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Branch "$name" added!'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }
}
