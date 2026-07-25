import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/mock_profile_data.dart';
import '../../models/wishlist_entry.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: mockWishlist.isEmpty
          ? const Center(child: Text('Nothing saved yet', style: TextStyle(color: DittoColors.mutedInk)))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: mockWishlist.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = mockWishlist[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DittoColors.brown.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DittoColors.brown.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(entry.itemType.icon, color: DittoColors.brown),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(entry.subtitle, style: const TextStyle(color: DittoColors.mutedInk)),
                          ],
                        ),
                      ),
                      const Icon(Icons.favorite, color: DittoColors.gold, size: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
