import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_repository.dart';

// The first authenticated screen — proves the whole chain (Firebase sign-in
// -> POST /auth/firebase -> stored JWT -> GET /users/me) works end to end.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ditto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: auth.signOut,
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                  child: user.avatarUrl == null ? Text(user.fullName.substring(0, 1)) : null,
                ),
                const SizedBox(height: 16),
                Text(user.fullName, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(user.role, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                if (user.email != null) _InfoRow(label: 'Email', value: user.email!),
                if (user.phone != null) _InfoRow(label: 'Phone', value: user.phone!),
                _InfoRow(label: 'Signed in via', value: user.authProvider),
              ],
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
