import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../data/garment_builder_options.dart';
import '../../models/custom_order.dart';
import '../../models/measurement.dart';
import '../../models/tailor.dart';

// 6-step garment builder: tailor -> garment -> fabric -> details ->
// measurement -> review. POST /orders is real (price is computed
// server-side, never trusted from here); payment is attempted right after
// via POST /payments/orders/:id/intent, which cleanly 503s until
// STRIPE_SECRET_KEY exists (see docs/ROADMAP.md Phase 10) — the order
// itself is still placed for real either way.
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final _api = ApiClient();
  int _currentStep = 0;

  Tailor? _tailor;
  String? _garmentId;
  String? _fabricId;
  String _lapelStyle = lapelStyles.keys.first;
  String _buttonStyle = buttonStyles.keys.first;
  bool _monogramEnabled = false;
  final _monogramController = TextEditingController();
  Measurement? _selectedMeasurement;

  bool _placingOrder = false;

  @override
  void dispose() {
    _monogramController.dispose();
    super.dispose();
  }

  GarmentType? get _garment =>
      _garmentId == null ? null : garmentTypes.firstWhere((g) => g.id == _garmentId);
  FabricSwatch? get _fabric =>
      _fabricId == null ? null : fabricSwatches.firstWhere((f) => f.id == _fabricId);

  double get _basePrice => _garment?.basePrice ?? 0;
  double get _fabricPrice => _fabric?.priceAddOn ?? 0;
  double get _lapelPrice => lapelStyles[_lapelStyle] ?? 0;
  double get _buttonPrice => buttonStyles[_buttonStyle] ?? 0;
  double get _monogramFee => (_monogramEnabled && _monogramController.text.trim().isNotEmpty) ? monogramPrice : 0;
  double get _total => _basePrice + _fabricPrice + _lapelPrice + _buttonPrice + _monogramFee;

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _tailor != null;
      case 1:
        return _garmentId != null;
      case 2:
        return _fabricId != null;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepTapped: (index) => setState(() => _currentStep = index),
        onStepContinue: _canContinue
            ? () => setState(() {
                if (_currentStep < 5) _currentStep++;
              })
            : null,
        onStepCancel: _currentStep > 0 ? () => setState(() => _currentStep--) : null,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                if (_currentStep < 5)
                  ElevatedButton(onPressed: details.onStepContinue, child: const Text('Next'))
                else
                  ElevatedButton(
                    onPressed: _placingOrder ? null : _placeOrder,
                    child: Text(_placingOrder ? 'Placing order...' : 'Place Order'),
                  ),
                if (details.onStepCancel != null) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(onPressed: details.onStepCancel, child: const Text('Back')),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Tailor'),
            isActive: _currentStep >= 0,
            state: _tailor != null ? StepState.complete : StepState.indexed,
            content: _TailorStep(selected: _tailor, onSelect: (t) => setState(() => _tailor = t)),
          ),
          Step(
            title: const Text('Garment'),
            isActive: _currentStep >= 1,
            state: _garmentId != null ? StepState.complete : StepState.indexed,
            content: _GarmentStep(selectedId: _garmentId, onSelect: (id) => setState(() => _garmentId = id)),
          ),
          Step(
            title: const Text('Fabric'),
            isActive: _currentStep >= 2,
            state: _fabricId != null ? StepState.complete : StepState.indexed,
            content: _FabricStep(selectedId: _fabricId, onSelect: (id) => setState(() => _fabricId = id)),
          ),
          Step(
            title: const Text('Details'),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            content: _DetailsStep(
              lapelStyle: _lapelStyle,
              buttonStyle: _buttonStyle,
              monogramEnabled: _monogramEnabled,
              monogramController: _monogramController,
              onLapelChanged: (v) => setState(() => _lapelStyle = v),
              onButtonChanged: (v) => setState(() => _buttonStyle = v),
              onMonogramToggled: (v) => setState(() => _monogramEnabled = v),
            ),
          ),
          Step(
            title: const Text('Measurement'),
            isActive: _currentStep >= 4,
            state: _currentStep > 4 ? StepState.complete : StepState.indexed,
            content: _MeasurementStep(
              selected: _selectedMeasurement,
              onSelect: (m) => setState(() => _selectedMeasurement = m),
            ),
          ),
          Step(
            title: const Text('Review'),
            isActive: _currentStep >= 5,
            content: _ReviewStep(
              tailor: _tailor,
              garment: _garment,
              fabric: _fabric,
              lapelStyle: _lapelStyle,
              buttonStyle: _buttonStyle,
              monogramText: _monogramEnabled ? _monogramController.text.trim() : '',
              measurement: _selectedMeasurement,
              basePrice: _basePrice,
              fabricPrice: _fabricPrice,
              lapelPrice: _lapelPrice,
              buttonPrice: _buttonPrice,
              monogramFee: _monogramFee,
              total: _total,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    final tailor = _tailor;
    final garmentId = _garmentId;
    final fabricId = _fabricId;
    if (tailor == null || garmentId == null || fabricId == null) return;

    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;

    setState(() => _placingOrder = true);
    CustomOrder order;
    try {
      order = await _api.createOrder(
        accessToken,
        tailorId: tailor.id,
        garmentTypeId: garmentId,
        fabricId: fabricId,
        lapelStyle: _lapelStyle,
        buttonStyle: _buttonStyle,
        monogram: _monogramEnabled ? _monogramController.text.trim() : null,
        measurementId: _selectedMeasurement?.id,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _placingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to place order — please try again.')),
      );
      return;
    }

    // Order is placed for real regardless of what happens next — payment
    // is a separate step that cleanly 503s until Stripe is configured.
    String paymentMessage;
    try {
      await _api.createOrderPaymentIntent(accessToken, order.id);
      paymentMessage = 'Order placed! Proceed to payment.';
    } on ApiException catch (e) {
      paymentMessage = e.statusCode == 503
          ? 'Order placed! Payment isn\'t set up yet — the tailor will follow up with you directly.'
          : 'Order placed! (payment setup failed — the tailor will follow up with you directly)';
    } catch (e) {
      paymentMessage = 'Order placed! (payment setup failed — the tailor will follow up with you directly)';
    }

    if (!mounted) return;
    setState(() => _placingOrder = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(paymentMessage)));
    Navigator.of(context).pop();
  }
}

class _TailorStep extends StatefulWidget {
  const _TailorStep({required this.selected, required this.onSelect});

  final Tailor? selected;
  final ValueChanged<Tailor> onSelect;

  @override
  State<_TailorStep> createState() => _TailorStepState();
}

class _TailorStepState extends State<_TailorStep> {
  final _api = ApiClient();
  List<Tailor>? _tailors;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load([String? q]) async {
    try {
      final result = await _api.listTailors(q: q);
      if (!mounted) return;
      setState(() {
        _tailors = result.data;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load tailors');
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _load(value.isEmpty ? null : value));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search tailors...',
            prefixIcon: Icon(Icons.search, color: DittoColors.brown),
          ),
        ),
        const SizedBox(height: 12),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: DittoColors.mutedInk))
        else if (_tailors == null)
          const Center(child: CircularProgressIndicator())
        else if (_tailors!.isEmpty)
          const Text('No tailors match', style: TextStyle(color: DittoColors.mutedInk))
        else
          RadioGroup<String>(
            groupValue: widget.selected?.id,
            onChanged: (id) {
              for (final tailor in _tailors!) {
                if (tailor.id == id) {
                  widget.onSelect(tailor);
                  break;
                }
              }
            },
            child: Column(
              children: _tailors!
                  .map(
                    (t) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      value: t.id,
                      title: Text(t.businessName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        t.ratingCount > 0 ? '${t.ratingAvg.toStringAsFixed(1)} (${t.ratingCount})' : 'New',
                        style: const TextStyle(color: DittoColors.mutedInk),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

class _GarmentStep extends StatelessWidget {
  const _GarmentStep({required this.selectedId, required this.onSelect});

  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: garmentTypes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        final garment = garmentTypes[index];
        final isSelected = garment.id == selectedId;
        return GestureDetector(
          onTap: () => onSelect(garment.id),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? DittoColors.brown : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isSelected ? DittoColors.brown : DittoColors.brown.withValues(alpha: 0.15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(garment.icon, size: 28, color: isSelected ? DittoColors.cream : DittoColors.brown),
                const SizedBox(height: 8),
                Text(
                  garment.label,
                  style: TextStyle(
                    color: isSelected ? DittoColors.cream : DittoColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'from \$${garment.basePrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? DittoColors.cream.withValues(alpha: 0.8) : DittoColors.mutedInk,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FabricStep extends StatelessWidget {
  const _FabricStep({required this.selectedId, required this.onSelect});

  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fabricSwatches.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final fabric = fabricSwatches[index];
        final isSelected = fabric.id == selectedId;
        return GestureDetector(
          onTap: () => onSelect(fabric.id),
          child: Column(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: fabric.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? DittoColors.gold : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                fabric.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: DittoColors.ink),
              ),
              if (fabric.priceAddOn > 0)
                Text(
                  '+\$${fabric.priceAddOn.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 10, color: DittoColors.mutedInk),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.lapelStyle,
    required this.buttonStyle,
    required this.monogramEnabled,
    required this.monogramController,
    required this.onLapelChanged,
    required this.onButtonChanged,
    required this.onMonogramToggled,
  });

  final String lapelStyle;
  final String buttonStyle;
  final bool monogramEnabled;
  final TextEditingController monogramController;
  final ValueChanged<String> onLapelChanged;
  final ValueChanged<String> onButtonChanged;
  final ValueChanged<bool> onMonogramToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lapel Style', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: lapelStyles.entries.map((entry) {
            final label = entry.value > 0 ? '${entry.key} (+\$${entry.value.toStringAsFixed(0)})' : entry.key;
            return ChoiceChip(
              label: Text(label),
              selected: lapelStyle == entry.key,
              onSelected: (_) => onLapelChanged(entry.key),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('Buttons', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: buttonStyles.entries.map((entry) {
            final label = entry.value > 0 ? '${entry.key} (+\$${entry.value.toStringAsFixed(0)})' : entry.key;
            return ChoiceChip(
              label: Text(label),
              selected: buttonStyle == entry.key,
              onSelected: (_) => onButtonChanged(entry.key),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text('Monogram', style: Theme.of(context).textTheme.titleSmall),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Add monogram (+\$${monogramPrice.toStringAsFixed(0)})'),
          value: monogramEnabled,
          onChanged: onMonogramToggled,
        ),
        if (monogramEnabled)
          TextField(
            controller: monogramController,
            maxLength: 3,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'Initials, e.g. A.K.'),
          ),
      ],
    );
  }
}

// Picks from the customer's real saved measurements (GET /measurements,
// Phase 8) rather than collecting ad-hoc numbers here — CreateOrderDto's
// measurementId points at a real saved Measurement, so this step needs to
// choose one, not invent one.
class _MeasurementStep extends StatefulWidget {
  const _MeasurementStep({required this.selected, required this.onSelect});

  final Measurement? selected;
  final ValueChanged<Measurement?> onSelect;

  @override
  State<_MeasurementStep> createState() => _MeasurementStepState();
}

class _MeasurementStepState extends State<_MeasurementStep> {
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
      setState(() => _error = 'Failed to load saved measurements');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: DittoColors.mutedInk));
    }
    if (_measurements == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_measurements!.isEmpty) {
      return const Text(
        'No saved measurements yet — add one from Profile > Saved Measurements, '
        'or skip and share measurements with your tailor directly.',
        style: TextStyle(color: DittoColors.mutedInk),
      );
    }
    return RadioGroup<String?>(
      groupValue: widget.selected?.id,
      onChanged: (id) {
        if (id == null) {
          widget.onSelect(null);
          return;
        }
        for (final measurement in _measurements!) {
          if (measurement.id == id) {
            widget.onSelect(measurement);
            break;
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RadioListTile<String?>(
            contentPadding: EdgeInsets.zero,
            value: null,
            title: Text('Skip for now'),
          ),
          ..._measurements!.map(
            (m) => RadioListTile<String?>(
              contentPadding: EdgeInsets.zero,
              value: m.id,
              title: Text(m.label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.tailor,
    required this.garment,
    required this.fabric,
    required this.lapelStyle,
    required this.buttonStyle,
    required this.monogramText,
    required this.measurement,
    required this.basePrice,
    required this.fabricPrice,
    required this.lapelPrice,
    required this.buttonPrice,
    required this.monogramFee,
    required this.total,
  });

  final Tailor? tailor;
  final GarmentType? garment;
  final FabricSwatch? fabric;
  final String lapelStyle;
  final String buttonStyle;
  final String monogramText;
  final Measurement? measurement;
  final double basePrice;
  final double fabricPrice;
  final double lapelPrice;
  final double buttonPrice;
  final double monogramFee;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryRow(label: 'Tailor', value: tailor?.businessName ?? '—'),
        _SummaryRow(label: 'Garment', value: garment?.label ?? '—'),
        _SummaryRow(label: 'Fabric', value: fabric?.name ?? '—'),
        _SummaryRow(label: 'Lapel', value: lapelStyle),
        _SummaryRow(label: 'Buttons', value: buttonStyle),
        if (monogramText.isNotEmpty) _SummaryRow(label: 'Monogram', value: monogramText),
        _SummaryRow(label: 'Measurement', value: measurement?.label ?? 'Not selected'),
        const Divider(height: 32),
        _PriceRow(label: 'Base (${garment?.label ?? '—'})', amount: basePrice),
        if (fabricPrice > 0) _PriceRow(label: 'Fabric upgrade', amount: fabricPrice),
        if (lapelPrice > 0) _PriceRow(label: 'Lapel upgrade', amount: lapelPrice),
        if (buttonPrice > 0) _PriceRow(label: 'Button upgrade', amount: buttonPrice),
        if (monogramFee > 0) _PriceRow(label: 'Monogram', amount: monogramFee),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: Theme.of(context).textTheme.titleLarge),
            Text(
              '\$${total.toStringAsFixed(0)}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: DittoColors.brown, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: DittoColors.mutedInk))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: DittoColors.mutedInk)),
          Text('\$${amount.toStringAsFixed(0)}'),
        ],
      ),
    );
  }
}
