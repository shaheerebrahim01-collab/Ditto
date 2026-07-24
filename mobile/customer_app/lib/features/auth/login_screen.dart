import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_repository.dart';
import 'phone_otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showEmailForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final canUseApple = !kIsWeb && Platform.isIOS;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ditto',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              if (auth.errorMessage != null) ...[
                Text(
                  auth.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              if (canUseApple)
                ElevatedButton(
                  onPressed: auth.isLoading ? null : auth.signInWithApple,
                  child: const Text('Continue with Apple'),
                ),
              if (canUseApple) const SizedBox(height: 12),
              ElevatedButton(
                onPressed: auth.isLoading ? null : auth.signInWithGoogle,
                child: const Text('Continue with Google'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: auth.isLoading
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PhoneOtpScreen()),
                      ),
                child: const Text('Continue with Phone'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: auth.isLoading ? null : () => setState(() => _showEmailForm = !_showEmailForm),
                child: const Text('Continue with Email'),
              ),
              if (_showEmailForm) ..._buildEmailForm(auth),
              if (auth.isLoading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEmailForm(AuthRepository auth) {
    return [
      const SizedBox(height: 16),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email'),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _passwordController,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Password'),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: auth.isLoading ? null : () => _submitEmail(auth, register: false),
              child: const Text('Sign in'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : () => _submitEmail(auth, register: true),
              child: const Text('Sign up'),
            ),
          ),
        ],
      ),
    ];
  }

  void _submitEmail(AuthRepository auth, {required bool register}) {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (register) {
      auth.registerWithEmail(email, password);
    } else {
      auth.signInWithEmail(email, password);
    }
  }
}
