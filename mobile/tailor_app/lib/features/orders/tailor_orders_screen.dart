import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../models/tailor_order.dart';
import '../messages/chat_screen.dart';

Future<void> _messageCustomer(BuildContext context, TailorOrder order) async {
  final api = ApiClient();
  final accessToken = context.read<AuthRepository>().accessToken;
  if (accessToken == null) return;
  try {
    final conversationId = await api.startConversation(accessToken, order.customerId);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(conversationId: conversationId, otherUserName: order.customerName),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to start conversation')));
  }
}

// GET /orders/tailor, PATCH /orders/:id/stage — real endpoints. There's no
// "incoming request" / accept-decline queue here: CustomOrder only starts
// at ORDER_CONFIRMED (same self-service-booking shape RentalsService uses
// for bookings), so every order a tailor sees is already confirmed —
// there's nothing to accept or decline.
class TailorOrdersScreen extends StatefulWidget {
  const TailorOrdersScreen({super.key});

  @override
  State<TailorOrdersScreen> createState() => _TailorOrdersScreenState();
}

class _TailorOrdersScreenState extends State<TailorOrdersScreen> {
  final _api = ApiClient();
  List<TailorOrder>? _orders;
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
      final orders = await _api.listMyTailorOrders(accessToken);
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

  Future<void> _advance(TailorOrder order) async {
    final nextStage = order.stage.next;
    if (nextStage == null) return;
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;

    setState(() => _busyIds.add(order.id));
    try {
      final updated = await _api.advanceOrderStage(accessToken, order.id, nextStage);
      if (!mounted) return;
      setState(() {
        _orders = _orders?.map((o) => o.id == order.id ? updated : o).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update order')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(order.id));
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
    final orders = _orders;
    if (orders == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (orders.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: Text('No orders yet', style: TextStyle(color: DittoColors.mutedInk))),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: orders
          .map(
            (order) => _OrderCard(
              order: order,
              busy: _busyIds.contains(order.id),
              onAdvance: () => _advance(order),
            ),
          )
          .toList(),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.busy, required this.onAdvance});

  final TailorOrder order;
  final bool busy;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final nextStage = order.stage.next;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  '${order.garmentType} — ${order.customerName}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text('\$${order.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                onPressed: () => _messageCustomer(context, order),
                tooltip: 'Message customer',
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(order.stage.label, style: const TextStyle(color: DittoColors.mutedInk, fontSize: 12)),
          if (order.customerPhone != null && order.customerPhone!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(order.customerPhone!, style: const TextStyle(color: DittoColors.mutedInk, fontSize: 12)),
          ],
          if (nextStage != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: busy ? null : onAdvance,
                child: Text(busy ? 'Working...' : 'Move to ${nextStage.label}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
