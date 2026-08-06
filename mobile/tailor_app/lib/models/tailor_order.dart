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

  String get value => switch (this) {
    OrderStage.orderConfirmed => 'ORDER_CONFIRMED',
    OrderStage.fabricSelected => 'FABRIC_SELECTED',
    OrderStage.cutting => 'CUTTING',
    OrderStage.stitching => 'STITCHING',
    OrderStage.embroidery => 'EMBROIDERY',
    OrderStage.qualityCheck => 'QUALITY_CHECK',
    OrderStage.packed => 'PACKED',
    OrderStage.outForDelivery => 'OUT_FOR_DELIVERY',
    OrderStage.delivered => 'DELIVERED',
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

  // null once already at the last stage — OrdersService.updateStage only
  // allows moving forward, never past DELIVERED.
  OrderStage? get next {
    final nextIndex = index + 1;
    return nextIndex < OrderStage.values.length ? OrderStage.values[nextIndex] : null;
  }
}

// Mirrors backend/prisma/schema.prisma's CustomOrder model, tailor-side
// shape — `customer` (name/email/phone) is only present because
// OrdersService.listForTailor includes it (tailorViewInclude).
class TailorOrder {
  const TailorOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.garmentType,
    required this.fabric,
    required this.price,
    required this.stage,
    required this.createdAt,
    this.customerPhone,
    this.estDeliveryDate,
  });

  factory TailorOrder.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    return TailorOrder(
      id: json['id'] as String,
      // Always present on the raw response (Prisma scalar) even though
      // `customer` (name/phone) is a separate include — used to start a
      // conversation with the customer.
      customerId: json['customerId'] as String,
      customerName: customer?['fullName'] as String? ?? 'Unknown customer',
      customerPhone: customer?['phone'] as String?,
      garmentType: json['garmentType'] as String,
      fabric: json['fabric'] as String,
      price: (json['price'] as num).toDouble(),
      stage: OrderStageX.fromJson(json['stage'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      estDeliveryDate: json['estDeliveryDate'] == null
          ? null
          : DateTime.parse(json['estDeliveryDate'] as String),
    );
  }

  final String id;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String garmentType;
  final String fabric;
  final double price;
  final OrderStage stage;
  final DateTime createdAt;
  final DateTime? estDeliveryDate;
}
