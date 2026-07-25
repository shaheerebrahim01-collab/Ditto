import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../data/mock_tailor_data.dart';
import '../../models/tailor_order.dart';

// Renders against local mock data — no tailor dashboard endpoint exists yet
// (Phase 5+, see docs/ROADMAP.md).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthRepository>().currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Welcome back${user != null ? ', ${user.fullName}' : ''}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.star, size: 18, color: DittoColors.gold),
              SizedBox(width: 4),
              Text(
                '$mockRatingAvg ($mockRatingCount reviews)',
                style: TextStyle(color: DittoColors.mutedInk),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(label: "Today's Income", value: '\$${mockTodayIncome.toStringAsFixed(0)}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(label: 'This Week', value: '\$${mockWeekIncome.toStringAsFixed(0)}'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text("Today's Orders", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (mockTodaysOrders.isEmpty)
            const Text('Nothing scheduled for today', style: TextStyle(color: DittoColors.mutedInk))
          else
            ...mockTodaysOrders.map((order) => _OrderRow(order: order)),
        ],
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

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

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
