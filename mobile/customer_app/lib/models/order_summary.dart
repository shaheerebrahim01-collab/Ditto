import 'package:flutter/material.dart';

// Mirrors backend/prisma/schema.prisma's OrderStage enum exactly, in order.
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
  static OrderStage fromJson(String value) => switch (value) {
    'ORDER_CONFIRMED' => OrderStage.orderConfirmed,
    'FABRIC_SELECTED' => OrderStage.fabricSelected,
    'CUTTING' => OrderStage.cutting,
    'STITCHING' => OrderStage.stitching,
    'EMBROIDERY' => OrderStage.embroidery,
    'QUALITY_CHECK' => OrderStage.qualityCheck,
    'PACKED' => OrderStage.packed,
    'OUT_FOR_DELIVERY' => OrderStage.outForDelivery,
    'DELIVERED' => OrderStage.delivered,
    _ => throw ArgumentError('Unknown OrderStage: $value'),
  };

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
