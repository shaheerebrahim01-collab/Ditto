import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/shell_navigation.dart';
import '../../core/theme.dart';
import '../../core/widgets/tag.dart';
import '../../data/mock_tailor_details.dart';
import '../../models/tailor_detail.dart';

// A tailor's public profile: cover photo, name, specialties, rating,
// working hours, portfolio grid, and the CTA into Create. Renders against
// local mock data — GET /tailors/:id doesn't exist yet (Phase 5+).
class TailorProfileScreen extends StatelessWidget {
  const TailorProfileScreen({super.key, required this.tailorId});

  final String tailorId;

  static const _createTabIndex = 2;

  @override
  Widget build(BuildContext context) {
    final tailor = mockTailorDetails[tailorId];
    if (tailor == null) {
      return const Scaffold(body: Center(child: Text('Tailor not found')));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: DittoColors.cream,
            foregroundColor: DittoColors.ink,
            flexibleSpace: FlexibleSpaceBar(background: _CoverPhoto()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(tailor.businessName, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: tailor.specialties.map((s) => Tag(label: s)).toList()),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: DittoColors.gold),
                    const SizedBox(width: 4),
                    Text(
                      '${tailor.ratingAvg} (${tailor.ratingCount} reviews)',
                      style: const TextStyle(color: DittoColors.mutedInk),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(tailor.bio, style: const TextStyle(color: DittoColors.mutedInk, height: 1.4)),
                const SizedBox(height: 28),
                Text('Working Hours', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                ...tailor.workingHours.map((entry) => _WorkingHoursRow(entry: entry)),
                const SizedBox(height: 28),
                Text('Portfolio', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tailor.portfolio.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) => _PortfolioTile(item: tailor.portfolio[index]),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<ShellNavigation>().goTo(_createTabIndex);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Start customizing'),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverPhoto extends StatelessWidget {
  const _CoverPhoto();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DittoColors.brown, Color(0xFF5F4128)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.storefront_outlined, size: 56, color: DittoColors.cream),
      ),
    );
  }
}

class _WorkingHoursRow extends StatelessWidget {
  const _WorkingHoursRow({required this.entry});

  final WorkingHoursEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(entry.days, style: const TextStyle(color: DittoColors.ink, fontWeight: FontWeight.w500)),
          Text(entry.hours, style: const TextStyle(color: DittoColors.mutedInk)),
        ],
      ),
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({required this.item});

  final PortfolioItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DittoColors.brown.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, color: DittoColors.brown.withValues(alpha: 0.5)),
          const SizedBox(height: 4),
          Text(item.category, style: const TextStyle(fontSize: 11, color: DittoColors.mutedInk)),
        ],
      ),
    );
  }
}
