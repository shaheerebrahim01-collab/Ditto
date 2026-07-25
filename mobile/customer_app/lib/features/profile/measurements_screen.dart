import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/mock_profile_data.dart';

class MeasurementsScreen extends StatelessWidget {
  const MeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Measurements')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: mockMeasurements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final measurement = mockMeasurements[index];
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
                Text(measurement.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
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
              ],
            ),
          );
        },
      ),
    );
  }
}
