import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets/tag.dart';
import '../../data/mock_profile_data.dart';
import '../../data/mock_tailors.dart';
import '../tailor_profile/tailor_profile_screen.dart';

class FavoriteTailorsScreen extends StatelessWidget {
  const FavoriteTailorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = mockTailors.where((t) => favoriteTailorIds.contains(t.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Tailors')),
      body: favorites.isEmpty
          ? const Center(child: Text('No favorites yet', style: TextStyle(color: DittoColors.mutedInk)))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tailor = favorites[index];
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TailorProfileScreen(tailorId: tailor.id)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DittoColors.brown.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 56,
                          width: 56,
                          decoration: BoxDecoration(
                            color: DittoColors.brown.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.storefront_outlined, color: DittoColors.brown.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tailor.businessName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                children: tailor.specialties.map((s) => Tag(label: s)).toList(),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.favorite, color: DittoColors.gold, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
