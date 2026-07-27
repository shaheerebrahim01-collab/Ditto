import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../models/rental_booking.dart';
import '../../models/rental_status.dart';

// GET /rentals/me — the signed-in renter's own bookings, with a cancel
// action that only shows for RentalStatus.reserved (the only status the
// backend allows cancelling from).
class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  final _api = ApiClient();
  List<RentalBooking>? _bookings;
  String? _error;
  final _cancellingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    try {
      final bookings = await _api.getMyRentalBookings(accessToken);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load your rentals');
    }
  }

  Future<void> _cancel(RentalBooking booking) async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    setState(() => _cancellingIds.add(booking.id));
    try {
      final updated = await _api.cancelRentalBooking(accessToken, booking.id);
      if (!mounted) return;
      setState(() {
        _bookings = _bookings?.map((b) => b.id == booking.id ? updated : b).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to cancel')));
    } finally {
      if (mounted) setState(() => _cancellingIds.remove(booking.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Rentals')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: DittoColors.mutedInk)));
    }
    if (_bookings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_bookings!.isEmpty) {
      return const Center(child: Text('No rentals yet', style: TextStyle(color: DittoColors.mutedInk)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _bookings!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booking = _bookings![index];
        return _BookingCard(
          booking: booking,
          cancelling: _cancellingIds.contains(booking.id),
          onCancel: () => _cancel(booking),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.cancelling, required this.onCancel});

  final RentalBooking booking;
  final bool cancelling;
  final VoidCallback onCancel;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  booking.item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: DittoColors.ink, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: booking.status.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.status.label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: booking.status.color),
                ),
              ),
            ],
          ),
          if (booking.item.shopName != null) ...[
            const SizedBox(height: 4),
            Text(booking.item.shopName!, style: const TextStyle(color: DittoColors.mutedInk)),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_formatDate(booking.pickupDate)} — ${_formatDate(booking.returnDate)}',
                style: const TextStyle(fontSize: 12, color: DittoColors.mutedInk),
              ),
              Text(
                booking.lateFee > 0
                    ? '+\$${booking.lateFee.toStringAsFixed(0)} late fee'
                    : '\$${booking.item.pricePerDay.toStringAsFixed(0)}/day',
                style: const TextStyle(fontWeight: FontWeight.w600, color: DittoColors.brown),
              ),
            ],
          ),
          if (booking.status == RentalStatus.reserved) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: cancelling ? null : onCancel,
                child: Text(cancelling ? 'Cancelling...' : 'Cancel booking'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
