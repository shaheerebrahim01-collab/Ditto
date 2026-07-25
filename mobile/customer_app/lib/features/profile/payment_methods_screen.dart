import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/mock_profile_data.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: mockPaymentMethods.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final method = mockPaymentMethods[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DittoColors.brown.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.credit_card, color: DittoColors.brown),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${method.brand} •••• ${method.last4}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('Expires ${method.expiry}', style: const TextStyle(color: DittoColors.mutedInk)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
