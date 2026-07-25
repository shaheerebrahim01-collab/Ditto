import 'package:flutter/material.dart';

// Mirrors backend/prisma/schema.prisma's OrderStage enum exactly, in order.
// No GET /orders endpoint exists yet (Phase 7+, see docs/ROADMAP.md), so
// OrdersScreen renders this against local mock data for now.
enum OrderStage {
  orderConfirmed,
  fabricSelected,
  cutting,
  stitching,
  embroidery,
  qualityCheck,
  packed,
  outForDelivery,
  delivered,
}

extension OrderStageX on OrderStage {
  String get label => switch (this) {
    OrderStage.orderConfirmed => 'Order Confirmed',
    OrderStage.fabricSelected => 'Fabric Selected',
    OrderStage.cutting => 'Cutting',
    OrderStage.stitching => 'Stitching',
    OrderStage.embroidery => 'Embroidery',
    OrderStage.qualityCheck => 'Quality Check',
    OrderStage.packed => 'Packed',
    OrderStage.outForDelivery => 'Out for Delivery',
    OrderStage.delivered => 'Delivered',
  };

  // Coarser status for the order list — the tracking screen shows every stage.
  String get summaryStatus => switch (this) {
    OrderStage.outForDelivery => 'Out for Delivery',
    OrderStage.delivered => 'Delivered',
    _ => 'In Production',
  };

  Color get summaryColor => switch (this) {
    OrderStage.delivered => const Color(0xFF3F7D4A),
    OrderStage.outForDelivery => const Color(0xFFC7A363),
    _ => const Color(0xFF8A6244),
  };
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.garmentType,
    required this.tailorName,
    required this.stage,
    required this.price,
    required this.orderedAt,
    required this.estDeliveryDate,
  });

  final String id;
  final String garmentType;
  final String tailorName;
  final OrderStage stage;
  final double price;
  final DateTime orderedAt;
  final DateTime estDeliveryDate;
}
