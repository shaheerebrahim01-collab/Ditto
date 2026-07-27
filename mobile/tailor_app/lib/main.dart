import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/auth_repository.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/rental_shop/rental_shop_shell.dart';
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
        // This app is shared by both business-owner roles: Role.TAILOR gets
        // TailorShell, Role.RENTAL_SHOP gets RentalShopShell. No other role
        // should ever reach here — every other client-facing role has its
        // own app or, for ADMIN, its own dashboard.
        return auth.currentUser?.role == 'RENTAL_SHOP' ? const RentalShopShell() : const TailorShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
