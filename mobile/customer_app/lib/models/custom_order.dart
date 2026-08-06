import 'order_summary.dart';

// Mirrors backend/prisma/schema.prisma's CustomOrder model. `tailor` (just
// businessName) is only present because OrdersService includes it — see
// customerViewInclude in orders.service.ts.
class CustomOrder {
  const CustomOrder({
    required this.id,
    required this.garmentType,
    required this.fabric,
    required this.price,
    required this.stage,
    required this.createdAt,
    this.tailorBusinessName,
    this.estDeliveryDate,
  });

  factory CustomOrder.fromJson(Map<String, dynamic> json) {
    final tailor = json['tailor'] as Map<String, dynamic>?;
    return CustomOrder(
      id: json['id'] as String,
      garmentType: json['garmentType'] as String,
      fabric: json['fabric'] as String,
      price: (json['price'] as num).toDouble(),
      stage: OrderStageX.fromJson(json['stage'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      tailorBusinessName: tailor?['businessName'] as String?,
      estDeliveryDate: json['estDeliveryDate'] == null
          ? null
          : DateTime.parse(json['estDeliveryDate'] as String),
    );
  }

  final String id;
  final String garmentType;
  final String fabric;
  final double price;
  final OrderStage stage;
  final DateTime createdAt;
  final String? tailorBusinessName;
  final DateTime? estDeliveryDate;
}
