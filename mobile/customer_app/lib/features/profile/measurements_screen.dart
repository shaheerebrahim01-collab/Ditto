import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../models/measurement.dart';
import 'measurement_visit_screen.dart';

// CRUD against GET/POST /measurements and PATCH/DELETE /measurements/:id —
// all real endpoints. Mirrors the bottom-sheet form pattern
// RentalShopInventoryScreen already uses for the same shape of problem
// (a self-owned list with add/edit/delete).
class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  final _api = ApiClient();
  List<Measurement>? _measurements;
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
      final measurements = await _api.listMeasurements(accessToken);
      if (!mounted) return;
      setState(() {
        _measurements = measurements;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load measurements');
    }
  }

  Future<void> _openForm({Measurement? existing}) async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MeasurementFormSheet(accessToken: accessToken, api: _api, existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Measurement measurement) async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    try {
      await _api.deleteMeasurement(accessToken, measurement.id);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.statusCode == 409 ? 'Cannot delete a measurement an order references' : 'Failed to delete';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Measurements')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _VisitRequestBanner(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MeasurementVisitScreen()),
            ),
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: DittoColors.mutedInk))
          else if (_measurements == null)
            const Center(child: CircularProgressIndicator())
          else if (_measurements!.isEmpty)
            const Text('No saved measurements yet', style: TextStyle(color: DittoColors.mutedInk))
          else
            ..._measurements!.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MeasurementCard(
                  measurement: m,
                  onEdit: () => _openForm(existing: m),
                  onDelete: () => _delete(m),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _VisitRequestBanner extends StatelessWidget {
  const _VisitRequestBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DittoColors.brown.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DittoColors.brown.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.event_available_outlined, color: DittoColors.brown),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Get your right size today', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text(
                    'Request an in-person measurement visit',
                    style: TextStyle(fontSize: 12, color: DittoColors.mutedInk),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: DittoColors.mutedInk),
          ],
        ),
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({required this.measurement, required this.onEdit, required this.onDelete});

  final Measurement measurement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
          Row(
            children: [
              Expanded(
                child: Text(measurement.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
              IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: onDelete),
            ],
          ),
          if (measurement.values.isEmpty)
            const Text('No values recorded yet', style: TextStyle(color: DittoColors.mutedInk))
          else
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: measurement.values.entries
                  .map(
                    (e) => Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '${e.key}: ', style: const TextStyle(color: DittoColors.mutedInk)),
                          TextSpan(
                            text: '${e.value} in',
                            style: const TextStyle(fontWeight: FontWeight.w500, color: DittoColors.ink),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          if (measurement.notes != null && measurement.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(measurement.notes!, style: const TextStyle(fontSize: 12, color: DittoColors.mutedInk)),
          ],
        ],
      ),
    );
  }
}

class _MeasurementFormSheet extends StatefulWidget {
  const _MeasurementFormSheet({required this.accessToken, required this.api, this.existing});

  final String accessToken;
  final ApiClient api;
  final Measurement? existing;

  @override
  State<_MeasurementFormSheet> createState() => _MeasurementFormSheetState();
}

class _MeasurementFormSheetState extends State<_MeasurementFormSheet> {
  late final _labelController = TextEditingController(text: widget.existing?.label ?? '');
  late final _chestController = TextEditingController(text: _fmt(widget.existing?.chest));
  late final _waistController = TextEditingController(text: _fmt(widget.existing?.waist));
  late final _hipController = TextEditingController(text: _fmt(widget.existing?.hip));
  late final _shoulderController = TextEditingController(text: _fmt(widget.existing?.shoulder));
  late final _sleeveController = TextEditingController(text: _fmt(widget.existing?.sleeve));
  late final _neckController = TextEditingController(text: _fmt(widget.existing?.neck));
  late final _inseamController = TextEditingController(text: _fmt(widget.existing?.inseam));
  late final _notesController = TextEditingController(text: widget.existing?.notes ?? '');
  bool _submitting = false;
  String? _error;

  static String _fmt(double? v) => v == null ? '' : v.toString();

  @override
  void dispose() {
    _labelController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _shoulderController.dispose();
    _sleeveController.dispose();
    _neckController.dispose();
    _inseamController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) => c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());

  Future<void> _submit() async {
    final label = _labelController.text.trim();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (widget.existing == null) {
        await widget.api.createMeasurement(
          widget.accessToken,
          label: label.isEmpty ? null : label,
          chest: _parse(_chestController),
          waist: _parse(_waistController),
          hip: _parse(_hipController),
          shoulder: _parse(_shoulderController),
          sleeve: _parse(_sleeveController),
          neck: _parse(_neckController),
          inseam: _parse(_inseamController),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      } else {
        await widget.api.updateMeasurement(
          widget.accessToken,
          widget.existing!.id,
          label: label.isEmpty ? null : label,
          chest: _parse(_chestController),
          waist: _parse(_waistController),
          hip: _parse(_hipController),
          shoulder: _parse(_shoulderController),
          sleeve: _parse(_sleeveController),
          neck: _parse(_neckController),
          inseam: _parse(_inseamController),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = 'Failed to save measurement');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: const BoxDecoration(
          color: DittoColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null ? 'Add measurement' : 'Edit measurement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(hintText: 'Label, e.g. Wedding Sherwani'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _numberField(_chestController, 'Chest (in)')),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField(_waistController, 'Waist (in)')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _numberField(_hipController, 'Hip (in)')),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField(_shoulderController, 'Shoulder (in)')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _numberField(_sleeveController, 'Sleeve (in)')),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField(_neckController, 'Neck (in)')),
                ],
              ),
              const SizedBox(height: 12),
              _numberField(_inseamController, 'Inseam (in)'),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(hintText: 'Notes (optional)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Color(0xFFB3452C))),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'Saving...' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(hintText: hint),
    );
  }
}
