import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../messages/messages_list_screen.dart';
import 'address_book_screen.dart';
import 'favorite_tailors_screen.dart';
import 'measurements_screen.dart';
import 'payment_methods_screen.dart';
import 'wishlist_screen.dart';

// Proves the auth chain end to end: Firebase sign-in -> POST /auth/firebase
// -> stored JWT -> GET /users/me. Menu rows below render against local mock
// data until their respective endpoints exist (see docs/ROADMAP.md).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: DittoColors.brown.withValues(alpha: 0.12),
                      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                      child: user.avatarUrl == null
                          ? Text(
                              user.fullName.isNotEmpty ? user.fullName.substring(0, 1) : '?',
                              style: const TextStyle(fontSize: 24, color: DittoColors.brown),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 2),
                          Text(
                            user.email ?? user.phone ?? user.role,
                            style: const TextStyle(color: DittoColors.mutedInk),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _MenuRow(
                  icon: Icons.straighten,
                  label: 'Saved Measurements',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MeasurementsScreen()),
                  ),
                ),
                _MenuRow(
                  icon: Icons.chat_bubble_outline,
                  label: 'Messages',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MessagesListScreen()),
                  ),
                ),
                _MenuRow(
                  icon: Icons.place_outlined,
                  label: 'Address Book',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AddressBookScreen()),
                  ),
                ),
                _MenuRow(
                  icon: Icons.favorite_border,
                  label: 'Wishlist',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WishlistScreen()),
                  ),
                ),
                _MenuRow(
                  icon: Icons.credit_card,
                  label: 'Payment Methods',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
                  ),
                ),
                _MenuRow(
                  icon: Icons.storefront_outlined,
                  label: 'Favorite Tailors',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FavoriteTailorsScreen()),
                  ),
                ),
                const SizedBox(height: 20),
                _MenuRow(
                  icon: Icons.logout,
                  label: 'Sign Out',
                  color: Colors.red.shade600,
                  showChevron: false,
                  onTap: auth.signOut,
                ),
              ],
            ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final rowColor = color ?? DittoColors.ink;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color ?? DittoColors.brown, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: rowColor)),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right, color: DittoColors.mutedInk),
          ],
        ),
      ),
    );
  }
}
