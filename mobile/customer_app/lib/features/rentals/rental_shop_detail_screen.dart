import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../models/rental_item.dart';
import '../../models/rental_shop.dart';
import '../messages/chat_screen.dart';
import 'book_item_screen.dart';

// A rental shop's public detail: name, rating, and its bookable items.
// GET /rental-shops/:id, public — 404s if the shop isn't APPROVED.
class RentalShopDetailScreen extends StatefulWidget {
  const RentalShopDetailScreen({super.key, required this.shopId});

  final String shopId;

  @override
  State<RentalShopDetailScreen> createState() => _RentalShopDetailScreenState();
}

class _RentalShopDetailScreenState extends State<RentalShopDetailScreen> {
  final _api = ApiClient();
  RentalShop? _shop;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final shop = await _api.getRentalShop(widget.shopId);
      if (!mounted) return;
      setState(() => _shop = shop);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load rental shop');
    }
  }

  Future<void> _messageShop(RentalShop shop) async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    try {
      final conversationId = await _api.startConversation(accessToken, shop.userId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversationId: conversationId, otherUserName: shop.businessName),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to start conversation')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(body: Center(child: Text(_error!, style: const TextStyle(color: DittoColors.mutedInk))));
    }
    final shop = _shop;
    if (shop == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final items = shop.items ?? const <RentalItem>[];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: DittoColors.cream,
            foregroundColor: DittoColors.ink,
            flexibleSpace: FlexibleSpaceBar(background: _CoverBanner()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(shop.businessName, style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _messageShop(shop),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Message'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, size: 18, color: DittoColors.gold),
                    const SizedBox(width: 4),
                    Text(
                      shop.ratingCount > 0
                          ? '${shop.ratingAvg.toStringAsFixed(1)} (${shop.ratingCount} reviews)'
                          : 'No reviews yet',
                      style: const TextStyle(color: DittoColors.mutedInk),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Available for rent', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Text('No items listed yet', style: TextStyle(color: DittoColors.mutedInk))
                else
                  ...items.map((item) => _RentalItemRow(item: item)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverBanner extends StatelessWidget {
  const _CoverBanner();

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
        child: Icon(Icons.checkroom_outlined, size: 56, color: DittoColors.cream),
      ),
    );
  }
}

class _RentalItemRow extends StatelessWidget {
  const _RentalItemRow({required this.item});

  final RentalItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BookItemScreen(item: item)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DittoColors.brown.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: DittoColors.brown.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.checkroom_outlined, size: 24, color: DittoColors.brown.withValues(alpha: 0.5)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(item.category, style: const TextStyle(color: DittoColors.mutedInk, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${item.pricePerDay.toStringAsFixed(0)}/day',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: DittoColors.brown),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${item.depositAmount.toStringAsFixed(0)} deposit',
                  style: const TextStyle(color: DittoColors.mutedInk, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
