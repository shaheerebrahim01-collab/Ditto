import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/mock_orders.dart';
import '../../models/order_summary.dart';
import 'order_tracking_screen.dart';

// Order list — renders against local mock data. GET /orders doesn't exist
// yet (Phase 7+, see docs/ROADMAP.md).
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: mockOrders.isEmpty
          ? const Center(child: Text('No orders yet', style: TextStyle(color: DittoColors.mutedInk)))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: mockOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _OrderCard(order: mockOrders[index]),
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: order.id)),
      ),
      child: Container(
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
                Text(
                  order.garmentType,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: DittoColors.ink, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.stage.summaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.stage.summaryStatus,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: order.stage.summaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(order.tailorName, style: const TextStyle(color: DittoColors.mutedInk)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ordered ${_formatDate(order.orderedAt)}',
                  style: const TextStyle(fontSize: 12, color: DittoColors.mutedInk),
                ),
                Text(
                  '\$${order.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: DittoColors.brown),
                ),
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
    return '${months[date.month - 1]} ${date.day}';
  }
}
