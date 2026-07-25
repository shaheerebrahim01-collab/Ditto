import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/mock_tailor_data.dart';
import '../../models/incoming_request.dart';
import '../../models/tailor_order.dart';

// Renders against local mock data — no incoming-request or orders endpoint
// exists yet (Phase 5+, see docs/ROADMAP.md). Accept/decline only updates
// local state; nothing is persisted.
class TailorOrdersScreen extends StatefulWidget {
  const TailorOrdersScreen({super.key});

  @override
  State<TailorOrdersScreen> createState() => _TailorOrdersScreenState();
}

class _TailorOrdersScreenState extends State<TailorOrdersScreen> {
  late final List<IncomingRequest> _pending = List.of(mockIncomingRequests);
  late final List<TailorOrder> _active = List.of(mockActiveOrders);

  void _accept(IncomingRequest request) {
    setState(() {
      _pending.remove(request);
      _active.insert(
        0,
        TailorOrder(
          id: request.id,
          customerName: request.customerName,
          garmentType: request.garmentType,
          price: request.price,
          stage: OrderStage.orderConfirmed,
          dueDate: DateTime.now().add(const Duration(days: 14)),
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Accepted ${request.customerName}\'s request')),
    );
  }

  void _decline(IncomingRequest request) {
    setState(() => _pending.remove(request));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Declined ${request.customerName}\'s request')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Incoming Requests', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (_pending.isEmpty)
            const Text('No new requests', style: TextStyle(color: DittoColors.mutedInk))
          else
            ..._pending.map((request) => _RequestCard(
                  request: request,
                  onAccept: () => _accept(request),
                  onDecline: () => _decline(request),
                )),
          const SizedBox(height: 28),
          Text('Active Orders', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (_active.isEmpty)
            const Text('No active orders', style: TextStyle(color: DittoColors.mutedInk))
          else
            ..._active.map((order) => _ActiveOrderCard(order: order)),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onAccept, required this.onDecline});

  final IncomingRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DittoColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${request.garmentType} — ${request.customerName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text('\$${request.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Fabric: ${request.fabric}', style: const TextStyle(color: DittoColors.mutedInk, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: onDecline, child: const Text('Decline')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(onPressed: onAccept, child: const Text('Accept')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order});

  final TailorOrder order;

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
                  '${order.garmentType} — ${order.customerName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(order.stage.label, style: const TextStyle(color: DittoColors.mutedInk, fontSize: 12)),
              ],
            ),
          ),
          Text('\$${order.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
