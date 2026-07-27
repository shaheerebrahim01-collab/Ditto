import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../models/rental_item.dart';

// Pick a pickup/return date range and submit POST /rentals. Overlap and
// date-sanity checks are enforced server-side (RentalsService.createBooking);
// this screen just surfaces whatever error comes back.
class BookItemScreen extends StatefulWidget {
  const BookItemScreen({super.key, required this.item});

  final RentalItem item;

  @override
  State<BookItemScreen> createState() => _BookItemScreenState();
}

class _BookItemScreenState extends State<BookItemScreen> {
  final _api = ApiClient();
  DateTime? _pickupDate;
  DateTime? _returnDate;
  bool _submitting = false;
  String? _error;

  int get _days {
    if (_pickupDate == null || _returnDate == null) return 0;
    return _returnDate!.difference(_pickupDate!).inDays;
  }

  double get _estimatedTotal => _days * widget.item.pricePerDay;

  Future<void> _pickDate({required bool isPickup}) async {
    final now = DateTime.now();
    final initial = isPickup ? (_pickupDate ?? now) : (_returnDate ?? _pickupDate?.add(const Duration(days: 1)) ?? now.add(const Duration(days: 1)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isPickup ? now : (_pickupDate ?? now),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isPickup) {
        _pickupDate = picked;
        if (_returnDate != null && !_returnDate!.isAfter(picked)) _returnDate = null;
      } else {
        _returnDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    final auth = context.read<AuthRepository>();
    final accessToken = auth.accessToken;
    if (_pickupDate == null || _returnDate == null || accessToken == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _api.createRentalBooking(
        accessToken,
        itemId: widget.item.id,
        pickupDate: _pickupDate!,
        returnDate: _returnDate!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booked ${widget.item.name}')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Failed to book this item');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final canSubmit = _pickupDate != null && _returnDate != null && !_submitting;

    return Scaffold(
      appBar: AppBar(title: Text(item.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DittoColors.brown.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.category, style: const TextStyle(color: DittoColors.mutedInk)),
                const SizedBox(height: 6),
                Text(
                  '\$${item.pricePerDay.toStringAsFixed(0)} / day · \$${item.depositAmount.toStringAsFixed(0)} deposit',
                  style: const TextStyle(color: DittoColors.brown, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Rental dates', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _DateRow(label: 'Pickup', date: _pickupDate, onTap: () => _pickDate(isPickup: true)),
          const SizedBox(height: 10),
          _DateRow(label: 'Return', date: _returnDate, onTap: () => _pickDate(isPickup: false)),
          if (_days > 0) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_days day${_days == 1 ? '' : 's'}', style: const TextStyle(color: DittoColors.mutedInk)),
                Text(
                  'Est. \$${_estimatedTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: DittoColors.brown, fontSize: 16),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Color(0xFFB3452C))),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSubmit ? _submit : null,
              child: Text(_submitting ? 'Booking...' : 'Confirm booking'),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.date, required this.onTap});

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DittoColors.brown.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Row(
              children: [
                Text(
                  date == null ? 'Select date' : _formatDate(date!),
                  style: TextStyle(color: date == null ? DittoColors.mutedInk : DittoColors.ink),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_today_outlined, size: 16, color: DittoColors.brown),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
