import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../models/rental_booking.dart';
import '../../models/rental_status.dart';
import '../messages/chat_screen.dart';

// Shop-side bookings against GET /rentals/shop, POST /rentals/:id/pickup,
// POST /rentals/:id/return — all real endpoints. Split into "Needs pickup"
// (RESERVED), "Out for rental" (PICKED_UP, flags overdue), and "History"
// (RETURNED/CANCELLED), same shape as TailorOrdersScreen's
// pending/active split.
class RentalShopBookingsScreen extends StatefulWidget {
  const RentalShopBookingsScreen({super.key});

  @override
  State<RentalShopBookingsScreen> createState() => _RentalShopBookingsScreenState();
}

class _RentalShopBookingsScreenState extends State<RentalShopBookingsScreen> {
  final _api = ApiClient();
  List<RentalBooking>? _bookings;
  String? _error;
  final _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    try {
      final bookings = await _api.listShopBookings(accessToken);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load bookings');
    }
  }

  Future<void> _markPickedUp(RentalBooking booking) => _runAction(
    booking,
    (accessToken) => _api.markRentalPickedUp(accessToken, booking.id),
  );

  Future<void> _markReturned(RentalBooking booking) => _runAction(
    booking,
    (accessToken) => _api.markRentalReturned(accessToken, booking.id),
  );

  Future<void> _messageRenter(RentalBooking booking) async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    try {
      final conversationId = await _api.startConversation(accessToken, booking.renterId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            otherUserName: booking.renter?.fullName ?? 'Renter',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to start conversation')));
    }
  }

  Future<void> _runAction(RentalBooking booking, Future<RentalBooking> Function(String) action) async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    setState(() => _busyIds.add(booking.id));
    try {
      final updated = await action(accessToken);
      if (!mounted) return;
      setState(() {
        _bookings = _bookings?.map((b) => b.id == booking.id ? updated : b).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action failed')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(booking.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: DittoColors.mutedInk)));
    }
    final bookings = _bookings;
    if (bookings == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final needsPickup = bookings.where((b) => b.status == RentalStatus.reserved).toList();
    final outForRental = bookings.where((b) => b.status == RentalStatus.pickedUp).toList();
    final history = bookings
        .where((b) => b.status != RentalStatus.reserved && b.status != RentalStatus.pickedUp)
        .toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Needs pickup', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (needsPickup.isEmpty)
            const Text('Nothing to hand over', style: TextStyle(color: DittoColors.mutedInk))
          else
            ...needsPickup.map(
              (b) => _BookingCard(
                booking: b,
                busy: _busyIds.contains(b.id),
                actionLabel: 'Mark picked up',
                onAction: () => _markPickedUp(b),
                onMessage: () => _messageRenter(b),
              ),
            ),
          const SizedBox(height: 28),
          Text('Out for rental', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (outForRental.isEmpty)
            const Text('Nothing out right now', style: TextStyle(color: DittoColors.mutedInk))
          else
            ...outForRental.map(
              (b) => _BookingCard(
                booking: b,
                busy: _busyIds.contains(b.id),
                actionLabel: 'Mark returned',
                onAction: () => _markReturned(b),
                onMessage: () => _messageRenter(b),
              ),
            ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...history.map((b) => _BookingCard(booking: b, busy: false, onMessage: () => _messageRenter(b))),
          ],
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.busy,
    this.actionLabel,
    this.onAction,
    this.onMessage,
  });

  final RentalBooking booking;
  final bool busy;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: booking.overdue ? const Color(0xFFB3452C).withValues(alpha: 0.4) : DittoColors.brown.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${booking.item.name} — ${booking.renter?.fullName ?? 'Unknown renter'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (booking.overdue ? const Color(0xFFB3452C) : booking.status.color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.overdue ? 'Overdue' : booking.status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: booking.overdue ? const Color(0xFFB3452C) : booking.status.color,
                  ),
                ),
              ),
              if (onMessage != null)
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  onPressed: onMessage,
                  tooltip: 'Message renter',
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDate(booking.pickupDate)} — ${_formatDate(booking.returnDate)}',
            style: const TextStyle(fontSize: 12, color: DittoColors.mutedInk),
          ),
          if (booking.lateFee > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Late fee: \$${booking.lateFee.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFB3452C), fontWeight: FontWeight.w600),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy ? null : onAction,
                child: Text(busy ? 'Working...' : actionLabel!),
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
