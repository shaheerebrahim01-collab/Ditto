// Mirrors backend/prisma/schema.prisma's OrderStage enum exactly, in order.
// No GET /tailor/orders endpoint exists yet (Phase 5+, see docs/ROADMAP.md),
// so this app renders against local mock data for now.
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
}

class TailorOrder {
  const TailorOrder({
    required this.id,
    required this.customerName,
    required this.garmentType,
    required this.price,
    required this.stage,
    required this.dueDate,
  });

  final String id;
  final String customerName;
  final String garmentType;
  final double price;
  final OrderStage stage;
  final DateTime dueDate;
}
