import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_repository.dart';

class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  String? _verificationId;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final auth = context.read<AuthRepository>();
    setState(() {
      _sending = true;
      _error = null;
    });
    await auth.startPhoneVerification(
      phoneNumber: _phoneController.text.trim(),
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _sending = false;
        });
      },
      onError: (message) {
        if (!mounted) return;
        setState(() {
          _error = message;
          _sending = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();

    // AuthGate (main.dart) swaps to MainShell once status flips to
    // authenticated, but that happens underneath this pushed route — pop
    // back to it so the user actually sees it.
    if (auth.status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with phone')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null || auth.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error ?? auth.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: _verificationId == null,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '+15551234567',
              ),
            ),
            const SizedBox(height: 16),
            if (_verificationId == null)
              ElevatedButton(
                onPressed: _sending ? null : _sendCode,
                child: Text(_sending ? 'Sending...' : 'Send code'),
              )
            else ...[
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '6-digit code'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : () => auth.submitPhoneCode(_verificationId!, _codeController.text.trim()),
                child: const Text('Verify'),
              ),
            ],
            if (auth.isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
