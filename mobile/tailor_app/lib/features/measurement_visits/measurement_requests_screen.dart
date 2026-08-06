import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../models/measurement_visit_request.dart';
import '../../models/visit_request_status.dart';
import '../messages/chat_screen.dart';

// Tailor-side dispatch: GET /measurement-visits/available (open pool, same
// for every tailor until one claims it), GET /measurement-visits/assigned
// (this tailor's own claims), POST :id/claim, POST :id/complete — all real
// endpoints. Three sections, same pending/active/history shape
// RentalShopBookingsScreen already uses for its own claim-then-fulfill flow.
class MeasurementRequestsScreen extends StatefulWidget {
  const MeasurementRequestsScreen({super.key});

  @override
  State<MeasurementRequestsScreen> createState() => _MeasurementRequestsScreenState();
}

class _MeasurementRequestsScreenState extends State<MeasurementRequestsScreen> {
  final _api = ApiClient();
  List<MeasurementVisitRequest>? _available;
  List<MeasurementVisitRequest>? _assigned;
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
      final results = await Future.wait([
        _api.listAvailableVisitRequests(accessToken),
        _api.listAssignedVisitRequests(accessToken),
      ]);
      if (!mounted) return;
      setState(() {
        _available = results[0];
        _assigned = results[1];
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load measurement requests');
    }
  }

  Future<void> _claim(MeasurementVisitRequest request) => _runAction(
    request.id,
    (accessToken) => _api.claimVisitRequest(accessToken, request.id),
  );

  Future<void> _complete(MeasurementVisitRequest request) => _runAction(
    request.id,
    (accessToken) => _api.completeVisitRequest(accessToken, request.id),
  );

  Future<void> _messageCustomer(MeasurementVisitRequest request) async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    try {
      final conversationId = await _api.startConversation(accessToken, request.customerId);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            otherUserName: request.customerName ?? 'Customer',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to start conversation')));
    }
  }

  Future<void> _runAction(String id, Future<MeasurementVisitRequest> Function(String) action) async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    setState(() => _busyIds.add(id));
    try {
      await action(accessToken);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action failed')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Requests')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: DittoColors.mutedInk)));
    }
    final available = _available;
    final assigned = _assigned;
    if (available == null || assigned == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final needsVisit = assigned.where((r) => r.status == VisitRequestStatus.assigned).toList();
    final history = assigned
        .where((r) => r.status == VisitRequestStatus.completed || r.status == VisitRequestStatus.cancelled)
        .toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Available to claim', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (available.isEmpty)
            const Text('No open requests right now', style: TextStyle(color: DittoColors.mutedInk))
          else
            ...available.map(
              (r) => _RequestCard(
                request: r,
                busy: _busyIds.contains(r.id),
                actionLabel: 'Claim',
                onAction: () => _claim(r),
              ),
            ),
          const SizedBox(height: 28),
          Text('Needs visit', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (needsVisit.isEmpty)
            const Text('Nothing assigned to you right now', style: TextStyle(color: DittoColors.mutedInk))
          else
            ...needsVisit.map(
              (r) => _RequestCard(
                request: r,
                busy: _busyIds.contains(r.id),
                actionLabel: 'Mark complete',
                onAction: () => _complete(r),
                onMessage: () => _messageCustomer(r),
              ),
            ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...history.map(
              (r) => _RequestCard(request: r, busy: false, onMessage: () => _messageCustomer(r)),
            ),
          ],
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.busy,
    this.actionLabel,
    this.onAction,
    this.onMessage,
  });

  final MeasurementVisitRequest request;
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
                  request.customerName ?? request.location,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: request.status.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status.label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: request.status.color),
                ),
              ),
              if (onMessage != null)
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  onPressed: onMessage,
                  tooltip: 'Message customer',
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(request.location, style: const TextStyle(fontSize: 12, color: DittoColors.mutedInk)),
          const SizedBox(height: 2),
          Text(_formatDateTime(request.preferredAt), style: const TextStyle(fontSize: 12, color: DittoColors.mutedInk)),
          if (request.customerPhone != null && request.customerPhone!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(request.customerPhone!, style: const TextStyle(fontSize: 12, color: DittoColors.mutedInk)),
          ],
          if (request.notes != null && request.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(request.notes!, style: const TextStyle(fontSize: 12, color: DittoColors.mutedInk)),
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

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, $hour:$minute $suffix';
  }
}
