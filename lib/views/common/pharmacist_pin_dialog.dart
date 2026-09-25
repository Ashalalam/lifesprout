import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';

class PharmacistPinDialog extends StatefulWidget {
  final VoidCallback onApproved;

  const PharmacistPinDialog({super.key, required onApproved}) : onApproved = onApproved;

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PharmacistPinDialog(
        onApproved: () {},
      ),
    );
    return result ?? false;
  }

  @override
  State<PharmacistPinDialog> createState() => _PharmacistPinDialogState();
}

class _PharmacistPinDialogState extends State<PharmacistPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  String? _errorMessage;

  void _verifyPin() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isValid = authProvider.verifyPharmacistPin(_pinController.text.trim());
    if (isValid) {
      widget.onApproved();
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = 'Invalid Pharmacist PIN! Default demo PIN is 1234';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.verified_user, color: AppTheme.errorRed, size: 28),
          SizedBox(width: 10),
          Text(
            'Pharmacist Authorization',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: const Text(
              '⚠️ RESTRICTED DRUG WARNING:\nThis transaction contains Schedule H / H1 / Narcotic medications. An authorized pharmacist PIN is legally required to approve dispensing.',
              style: TextStyle(fontSize: 12, color: AppTheme.errorRed, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Enter Pharmacist Security PIN (Demo: 1234)',
              prefixIcon: const Icon(Icons.lock),
              errorText: _errorMessage,
            ),
            onSubmitted: (_) => _verifyPin(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel Transaction'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
          onPressed: _verifyPin,
          child: const Text('Authorize & Dispense'),
        ),
      ],
    );
  }
}
