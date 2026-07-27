import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/rental_shop.dart';
import 'my_rentals_screen.dart';
import 'rental_shop_detail_screen.dart';

// Browse approved rental shops — GET /rental-shops, public, no auth needed.
// "My Rentals" (the renter's own bookings) is a step away via the AppBar
// action rather than a second bottom-nav tab, same relationship Explore has
// to Orders for the tailoring side.
class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
  final _api = ApiClient();
  List<RentalShop>? _shops;
  String? _error;
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final result = await _api.listRentalShops(q: _query.isEmpty ? null : _query);
      if (!mounted) return;
      setState(() {
        _shops = result.data;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load rental shops');
    }
  }

  void _onSearchChanged(String value) {
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rentals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'My rentals',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyRentalsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search rental shops...',
                  prefixIcon: Icon(Icons.search, color: DittoColors.brown),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: DittoColors.mutedInk)));
    }
    if (_shops == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_shops!.isEmpty) {
      return const Center(
        child: Text('No rental shops match', style: TextStyle(color: DittoColors.mutedInk)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: _shops!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _RentalShopCard(shop: _shops![index]),
    );
  }
}

class _RentalShopCard extends StatelessWidget {
  const _RentalShopCard({required this.shop});

  final RentalShop shop;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RentalShopDetailScreen(shopId: shop.id)),
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
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: DittoColors.brown.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.checkroom_outlined, size: 30, color: DittoColors.brown.withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: DittoColors.ink),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 15, color: DittoColors.gold),
                      const SizedBox(width: 4),
                      Text(
                        shop.ratingCount > 0 ? '${shop.ratingAvg.toStringAsFixed(1)} (${shop.ratingCount})' : 'New',
                        style: const TextStyle(color: DittoColors.mutedInk, fontSize: 13),
                      ),
                      if (shop.itemCount != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.inventory_2_outlined, size: 15, color: DittoColors.mutedInk),
                        const SizedBox(width: 2),
                        Text(
                          '${shop.itemCount} items',
                          style: const TextStyle(color: DittoColors.mutedInk, fontSize: 13),
                        ),
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
