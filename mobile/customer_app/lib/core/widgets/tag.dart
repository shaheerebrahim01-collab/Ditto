import 'package:flutter/material.dart';

import '../theme.dart';

// Small gold pill used for specialty/category labels (tailor cards, profile).
class Tag extends StatelessWidget {
  const Tag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: DittoColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: DittoColors.ink)),
    );
  }
}
