import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/auth_repository.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/shell/tailor_shell.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const DittoTailorApp());
}

class DittoTailorApp extends StatelessWidget {
  const DittoTailorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthRepository()..restoreSession(),
      child: MaterialApp(
        title: 'Ditto for Tailors',
        theme: DittoTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    switch (auth.status) {
      case AuthStatus.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthStatus.authenticated:
        return const TailorShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
