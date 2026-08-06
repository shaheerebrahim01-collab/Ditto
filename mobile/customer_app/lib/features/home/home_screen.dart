import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/tailor_summary.dart';
import '../notifications/notifications_screen.dart';
import '../tailor_profile/tailor_profile_screen.dart';
import 'home_mock_data.dart';

// Browse feed: header, search, category chips, hero banner, top tailors.
// Renders against local mock data — GET /tailors doesn't exist yet (Phase 5+).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<TailorSummary> get _filteredTailors {
    return mockTailors.where((tailor) {
      final matchesCategory = _selectedCategory == 'All' || tailor.specialties.contains(_selectedCategory);
      final matchesSearch = _searchQuery.isEmpty ||
          tailor.businessName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 12),
                  _SearchBar(onChanged: (value) => setState(() => _searchQuery = value)),
                  const SizedBox(height: 20),
                  _CategoryChips(
                    selected: _selectedCategory,
                    onSelected: (category) => setState(() => _selectedCategory = category),
                  ),
                  const SizedBox(height: 20),
                  const _HeroBanner(),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Top Tailors', style: Theme.of(context).textTheme.titleLarge),
                      TextButton(onPressed: () {}, child: const Text('See all')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: _filteredTailors.isEmpty
                        ? const Center(
                            child: Text('No tailors match', style: TextStyle(color: DittoColors.mutedInk)),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filteredTailors.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) => _TailorCard(tailor: _filteredTailors[index]),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Ditto',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: DittoColors.brown),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: const InputDecoration(
        hintText: 'Search tailors, styles...',
        prefixIcon: Icon(Icons.search, color: DittoColors.brown),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: homeCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = homeCategories[index];
          final isSelected = selected == category;
          return ChoiceChip(
            label: Text(
              category,
              style: TextStyle(
                color: isSelected ? DittoColors.cream : DittoColors.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(category),
          );
        },
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DittoColors.brown, Color(0xFF5F4128)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bespoke, for your big day.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: DittoColors.cream, height: 1.3),
          ),
          const SizedBox(height: 8),
          const Text(
            'Book a tailor and get a perfect fit without leaving home.',
            style: TextStyle(color: Color(0xFFE3D5C4)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: DittoColors.gold,
              foregroundColor: DittoColors.ink,
            ),
            child: const Text('Explore'),
          ),
        ],
      ),
    );
  }
}

class _TailorCard extends StatelessWidget {
  const _TailorCard({required this.tailor});

  final TailorSummary tailor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TailorProfileScreen(tailorId: tailor.id)),
      ),
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              width: 160,
              decoration: BoxDecoration(
                color: DittoColors.brown.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.storefront_outlined, size: 36, color: DittoColors.brown.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 8),
            Text(
              tailor.businessName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, color: DittoColors.ink),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: DittoColors.gold),
                const SizedBox(width: 4),
                Text(
                  '${tailor.ratingAvg} (${tailor.ratingCount})',
                  style: const TextStyle(color: DittoColors.mutedInk),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
