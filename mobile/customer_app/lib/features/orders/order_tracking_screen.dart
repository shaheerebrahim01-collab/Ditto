import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/custom_order.dart';
import '../../models/order_summary.dart';

// Full production-stage timeline for one order — the CustomOrder is passed
// in directly from OrdersScreen rather than re-fetched by id, since the
// caller already has it.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.order});

  final CustomOrder order;

  @override
  Widget build(BuildContext context) {
    final currentIndex = order.stage.index;

    return Scaffold(
      appBar: AppBar(title: Text(order.garmentType)),
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
                Text(order.tailorBusinessName ?? 'Unknown tailor', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  order.estDeliveryDate != null
                      ? 'Estimated delivery: ${_formatDate(order.estDeliveryDate!)}'
                      : 'Estimated delivery: not set yet',
                  style: const TextStyle(color: DittoColors.mutedInk, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${order.price.toStringAsFixed(0)}',
                  style: const TextStyle(color: DittoColors.brown, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Order Progress', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          for (var i = 0; i < OrderStage.values.length; i++)
            _TimelineTile(
              stage: OrderStage.values[i],
              isDone: i < currentIndex,
              isCurrent: i == currentIndex,
              isLast: i == OrderStage.values.length - 1,
            ),
        ],
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

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.stage,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  final OrderStage stage;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isReached = isDone || isCurrent;
    final dotColor = isReached ? DittoColors.brown : DittoColors.brown.withValues(alpha: 0.2);
    final textColor = isReached ? DittoColors.ink : DittoColors.mutedInk;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? DittoColors.brown : Colors.white,
                  border: Border.all(color: dotColor, width: 2),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 14, color: DittoColors.cream)
                    : isCurrent
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: DittoColors.brown),
                            ),
                          )
                        : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? DittoColors.brown : DittoColors.brown.withValues(alpha: 0.15),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                stage.label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
