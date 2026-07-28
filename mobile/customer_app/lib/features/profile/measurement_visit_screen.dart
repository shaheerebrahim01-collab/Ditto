import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../models/measurement_visit_request.dart';
import '../../models/visit_request_status.dart';

// "Get your right size today" — request an in-person measurement visit
// instead of self-reporting measurements. Submits against real
// POST /measurement-visits and lists the caller's own requests via
// GET /measurement-visits/me; cancel calls POST :id/cancel. No tailor is
// chosen here — the request goes into an open pool any tailor can claim
// (measurement-visits.service.ts's listAvailable/claim).
class MeasurementVisitScreen extends StatefulWidget {
  const MeasurementVisitScreen({super.key});

  @override
  State<MeasurementVisitScreen> createState() => _MeasurementVisitScreenState();
}

class _MeasurementVisitScreenState extends State<MeasurementVisitScreen> {
  final _api = ApiClient();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _preferredAt;
  bool _submitting = false;
  String? _error;

  List<MeasurementVisitRequest>? _requests;
  final _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    try {
      final requests = await _api.listMyVisitRequests(accessToken);
      if (!mounted) return;
      setState(() => _requests = requests);
    } catch (e) {
      // Non-fatal — the submission form above still works even if this list fails to load.
    }
  }

  Future<void> _pickPreferredAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _preferredAt ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _preferredAt != null ? TimeOfDay.fromDateTime(_preferredAt!) : const TimeOfDay(hour: 11, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _preferredAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    final accessToken = context.read<AuthRepository>().accessToken;
    final location = _locationController.text.trim();
    if (accessToken == null || location.isEmpty || _preferredAt == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _api.createVisitRequest(
        accessToken,
        location: location,
        preferredAt: _preferredAt!,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (!mounted) return;
      _locationController.clear();
      _notesController.clear();
      setState(() => _preferredAt = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit requested')));
      _load();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Failed to submit the request');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cancel(MeasurementVisitRequest request) async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    setState(() => _busyIds.add(request.id));
    try {
      await _api.cancelVisitRequest(accessToken, request.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to cancel')));
    } finally {
      if (mounted) setState(() => _busyIds.remove(request.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_submitting && _locationController.text.trim().isNotEmpty && _preferredAt != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Measurement Visit')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Request a visit', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text(
              'A tailor will come to you with a tape measure.',
              style: TextStyle(color: DittoColors.mutedInk, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Location, e.g. 221B Baker Street, Karachi'),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickPreferredAt,
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
                    const Text('Preferred time', style: TextStyle(fontWeight: FontWeight.w500)),
                    Row(
                      children: [
                        Text(
                          _preferredAt == null ? 'Select date & time' : _formatDateTime(_preferredAt!),
                          style: TextStyle(color: _preferredAt == null ? DittoColors.mutedInk : DittoColors.ink),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.calendar_today_outlined, size: 16, color: DittoColors.brown),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(hintText: 'Notes (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFB3452C))),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canSubmit ? _submit : null,
                child: Text(_submitting ? 'Submitting...' : 'Request visit'),
              ),
            ),
            const SizedBox(height: 32),
            Text('Your requests', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_requests == null)
              const Center(child: CircularProgressIndicator())
            else if (_requests!.isEmpty)
              const Text('No visit requests yet', style: TextStyle(color: DittoColors.mutedInk))
            else
              ..._requests!.map(
                (r) => _RequestCard(
                  request: r,
                  busy: _busyIds.contains(r.id),
                  onCancel: () => _cancel(r),
                ),
              ),
          ],
        ),
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

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.busy, required this.onCancel});

  final MeasurementVisitRequest request;
  final bool busy;
  final VoidCallback onCancel;

  bool get _cancellable =>
      request.status == VisitRequestStatus.pending || request.status == VisitRequestStatus.assigned;

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
                child: Text(request.location, style: const TextStyle(fontWeight: FontWeight.w600)),
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
            ],
          ),
          const SizedBox(height: 4),
          Text(_formatDate(request.preferredAt), style: const TextStyle(fontSize: 12, color: DittoColors.mutedInk)),
          if (request.notes != null && request.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(request.notes!, style: const TextStyle(fontSize: 12, color: DittoColors.mutedInk)),
          ],
          if (_cancellable) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: busy ? null : onCancel,
                child: Text(busy ? 'Cancelling...' : 'Cancel'),
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
