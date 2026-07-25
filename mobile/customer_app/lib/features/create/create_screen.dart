import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/garment_builder_options.dart';

// 5-step garment builder: garment -> fabric -> details -> measurements ->
// review (with a live running price total). Doesn't submit anywhere yet —
// POST /orders doesn't exist (Phase 7+, see docs/ROADMAP.md).
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  int _currentStep = 0;

  String? _garmentId;
  String? _fabricId;
  String _lapelStyle = lapelStyles.keys.first;
  String _buttonStyle = buttonStyles.keys.first;
  bool _monogramEnabled = false;
  final _monogramController = TextEditingController();

  final _measurementControllers = {
    'Chest': TextEditingController(),
    'Waist': TextEditingController(),
    'Hip': TextEditingController(),
    'Shoulder': TextEditingController(),
    'Sleeve': TextEditingController(),
    'Neck': TextEditingController(),
    'Inseam': TextEditingController(),
  };

  @override
  void dispose() {
    _monogramController.dispose();
    for (final controller in _measurementControllers.values) {
      controller.dispose();
    }
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
        return _garmentId != null;
      case 1:
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
                if (_currentStep < 4) _currentStep++;
              })
            : null,
        onStepCancel: _currentStep > 0 ? () => setState(() => _currentStep--) : null,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                if (_currentStep < 4)
                  ElevatedButton(onPressed: details.onStepContinue, child: const Text('Next'))
                else
                  ElevatedButton(onPressed: _placeOrder, child: const Text('Place Order')),
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
            title: const Text('Garment'),
            isActive: _currentStep >= 0,
            state: _garmentId != null ? StepState.complete : StepState.indexed,
            content: _GarmentStep(selectedId: _garmentId, onSelect: (id) => setState(() => _garmentId = id)),
          ),
          Step(
            title: const Text('Fabric'),
            isActive: _currentStep >= 1,
            state: _fabricId != null ? StepState.complete : StepState.indexed,
            content: _FabricStep(selectedId: _fabricId, onSelect: (id) => setState(() => _fabricId = id)),
          ),
          Step(
            title: const Text('Details'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
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
            title: const Text('Measurements'),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
            content: _MeasurementsStep(controllers: _measurementControllers),
          ),
          Step(
            title: const Text('Review'),
            isActive: _currentStep >= 4,
            content: _ReviewStep(
              garment: _garment,
              fabric: _fabric,
              lapelStyle: _lapelStyle,
              buttonStyle: _buttonStyle,
              monogramText: _monogramEnabled ? _monogramController.text.trim() : '',
              measurements: _measurementControllers,
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

  void _placeOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order flow not wired to a backend yet — nothing was submitted.')),
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

class _MeasurementsStep extends StatelessWidget {
  const _MeasurementsStep({required this.controllers});

  final Map<String, TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: controllers.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: entry.value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: '${entry.key} (in)'),
          ),
        );
      }).toList(),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.garment,
    required this.fabric,
    required this.lapelStyle,
    required this.buttonStyle,
    required this.monogramText,
    required this.measurements,
    required this.basePrice,
    required this.fabricPrice,
    required this.lapelPrice,
    required this.buttonPrice,
    required this.monogramFee,
    required this.total,
  });

  final GarmentType? garment;
  final FabricSwatch? fabric;
  final String lapelStyle;
  final String buttonStyle;
  final String monogramText;
  final Map<String, TextEditingController> measurements;
  final double basePrice;
  final double fabricPrice;
  final double lapelPrice;
  final double buttonPrice;
  final double monogramFee;
  final double total;

  @override
  Widget build(BuildContext context) {
    final filledMeasurements = measurements.entries.where((e) => e.value.text.trim().isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SummaryRow(label: 'Garment', value: garment?.label ?? '—'),
        _SummaryRow(label: 'Fabric', value: fabric?.name ?? '—'),
        _SummaryRow(label: 'Lapel', value: lapelStyle),
        _SummaryRow(label: 'Buttons', value: buttonStyle),
        if (monogramText.isNotEmpty) _SummaryRow(label: 'Monogram', value: monogramText),
        if (filledMeasurements.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Measurements', style: Theme.of(context).textTheme.titleSmall),
          for (final entry in filledMeasurements)
            _SummaryRow(label: entry.key, value: '${entry.value.text} in'),
        ],
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
