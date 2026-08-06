import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../models/custom_order.dart';
import '../../models/order_summary.dart'; // OrderStageX (summaryColor/summaryStatus)
import 'order_tracking_screen.dart';

// GET /orders/me — the signed-in customer's own custom orders.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _api = ApiClient();
  List<CustomOrder>? _orders;
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
      final orders = await _api.listMyOrders(accessToken);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        children: [Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(_error!)))],
      );
    }
    if (_orders == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders!.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: Text('No orders yet', style: TextStyle(color: DittoColors.mutedInk))),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _orders!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _OrderCard(order: _orders![index]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final CustomOrder order;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
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
            Text(order.tailorBusinessName ?? 'Unknown tailor', style: const TextStyle(color: DittoColors.mutedInk)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ordered ${_formatDate(order.createdAt)}',
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
