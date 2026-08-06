import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../models/rental_booking.dart';
import '../../models/rental_item.dart';
import '../../models/rental_shop.dart';
import '../../models/rental_status.dart';
import '../messages/messages_list_screen.dart';
import '../notifications/notifications_screen.dart';

// Shop-owner overview: shop profile, inventory/booking counts, and bookings
// currently in flight (reserved or picked up). GET /rental-shops/me,
// GET /rental-shops/me/items, GET /rentals/shop all exist and are real.
class RentalShopDashboardScreen extends StatefulWidget {
  const RentalShopDashboardScreen({super.key});

  @override
  State<RentalShopDashboardScreen> createState() => _RentalShopDashboardScreenState();
}

class _RentalShopDashboardScreenState extends State<RentalShopDashboardScreen> {
  final _api = ApiClient();
  RentalShop? _shop;
  List<RentalItem>? _items;
  List<RentalBooking>? _bookings;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    try {
      final shop = await _api.getMyRentalShop(accessToken);
      final items = await _api.listMyRentalItems(accessToken);
      final bookings = await _api.listShopBookings(accessToken);
      if (!mounted) return;
      setState(() {
        _shop = shop;
        _items = items;
        _bookings = bookings;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(child: Text(_error!, style: const TextStyle(color: DittoColors.mutedInk))),
      );
    }
    final shop = _shop;
    final items = _items;
    final bookings = _bookings;
    if (shop == null || items == null || bookings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final active = bookings
        .where((b) => b.status == RentalStatus.reserved || b.status == RentalStatus.pickedUp)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MessagesListScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Welcome back, ${shop.businessName}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
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
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Inventory', value: '${items.length}')),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(label: 'Active Bookings', value: '${active.length}')),
              ],
            ),
            const SizedBox(height: 28),
            Text('Active Bookings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (active.isEmpty)
              const Text('Nothing active right now', style: TextStyle(color: DittoColors.mutedInk))
            else
              ...active.map((b) => _BookingRow(booking: b)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DittoColors.brown.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: DittoColors.mutedInk, fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: DittoColors.brown),
          ),
        ],
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking});

  final RentalBooking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DittoColors.brown.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking.item.name} — ${booking.renter?.fullName ?? 'Unknown renter'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  booking.overdue ? 'Overdue' : booking.status.label,
                  style: TextStyle(
                    color: booking.overdue ? const Color(0xFFB3452C) : DittoColors.mutedInk,
                    fontSize: 12,
                    fontWeight: booking.overdue ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${booking.item.pricePerDay.toStringAsFixed(0)}/day',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
