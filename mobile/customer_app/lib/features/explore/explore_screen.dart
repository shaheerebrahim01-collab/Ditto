import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets/tag.dart';
import '../../data/mock_tailors.dart';
import '../../models/tailor_summary.dart';
import '../tailor_profile/tailor_profile_screen.dart';

enum _Filter { nearby, highestRated, fastDelivery, luxury, budget }

extension on _Filter {
  String get label => switch (this) {
    _Filter.nearby => 'Nearby',
    _Filter.highestRated => 'Highest Rated',
    _Filter.fastDelivery => 'Fast Delivery',
    _Filter.luxury => 'Luxury',
    _Filter.budget => 'Budget',
  };
}

// Search + discovery: search bar, filter chips, list of tailor cards.
// Renders against local mock data — GET /tailors doesn't exist yet (Phase 5+).
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _searchQuery = '';
  final _activeFilters = <_Filter>{};

  List<TailorSummary> get _results {
    var results = mockTailors.where((tailor) {
      final matchesSearch = _searchQuery.isEmpty ||
          tailor.businessName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFastDelivery = !_activeFilters.contains(_Filter.fastDelivery) || tailor.fastDelivery;
      final matchesLuxury = !_activeFilters.contains(_Filter.luxury) || tailor.priceTier == PriceTier.luxury;
      final matchesBudget = !_activeFilters.contains(_Filter.budget) || tailor.priceTier == PriceTier.budget;
      return matchesSearch && matchesFastDelivery && matchesLuxury && matchesBudget;
    }).toList();

    // Nearby and Highest Rated are sort modes rather than filters; Nearby wins if both are on.
    if (_activeFilters.contains(_Filter.nearby)) {
      results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else if (_activeFilters.contains(_Filter.highestRated)) {
      results.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Search tailors, styles...',
                  prefixIcon: Icon(Icons.search, color: DittoColors.brown),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _Filter.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = _Filter.values[index];
                  final isSelected = _activeFilters.contains(filter);
                  return FilterChip(
                    label: Text(
                      filter.label,
                      style: TextStyle(
                        color: isSelected ? DittoColors.cream : DittoColors.ink,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _activeFilters.add(filter);
                      } else {
                        _activeFilters.remove(filter);
                      }
                    }),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Text('No tailors match', style: TextStyle(color: DittoColors.mutedInk)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _TailorListCard(tailor: _results[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TailorListCard extends StatelessWidget {
  const _TailorListCard({required this.tailor});

  final TailorSummary tailor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TailorProfileScreen(tailorId: tailor.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DittoColors.brown.withValues(alpha: 0.12)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 84,
              width: 84,
              decoration: BoxDecoration(
                color: DittoColors.brown.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.storefront_outlined, size: 32, color: DittoColors.brown.withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tailor.businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: DittoColors.ink),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tailor.specialties.map((s) => Tag(label: s)).toList(),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 15, color: DittoColors.gold),
                      const SizedBox(width: 4),
                      Text(
                        '${tailor.ratingAvg} (${tailor.ratingCount})',
                        style: const TextStyle(color: DittoColors.mutedInk, fontSize: 13),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.place_outlined, size: 15, color: DittoColors.mutedInk),
                      const SizedBox(width: 2),
                      Text(
                        '${tailor.distanceKm} km',
                        style: const TextStyle(color: DittoColors.mutedInk, fontSize: 13),
                      ),
                      if (tailor.fastDelivery) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.bolt, size: 15, color: DittoColors.brown),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
