import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_repository.dart';

// Shared by both dashboards (TailorShell and RentalShopShell) — the one
// sign-out entry point this app had been missing entirely (see
// docs/ROADMAP.md Phase 7's "no sign-out UI" gap). AuthGate in main.dart
// already reacts to AuthRepository.signOut()'s notifyListeners() call, so
// this only needs to confirm and call it.
Future<void> signOutWithConfirmation(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Sign out?'),
      content: const Text("You'll need to sign back in to access your account."),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Sign out')),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await context.read<AuthRepository>().signOut();
  }
}
