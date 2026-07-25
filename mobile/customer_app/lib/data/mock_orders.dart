import '../models/order_summary.dart';

// Placeholder data until GET /orders exists.
final mockOrders = [
  OrderSummary(
    id: 'o1',
    garmentType: 'Suit',
    tailorName: 'Al-Karam Tailors',
    stage: OrderStage.stitching,
    price: 265,
    orderedAt: DateTime(2026, 7, 10),
    estDeliveryDate: DateTime(2026, 7, 28),
  ),
  OrderSummary(
    id: 'o2',
    garmentType: 'Sherwani',
    tailorName: 'Heritage Sherwani Co.',
    stage: OrderStage.outForDelivery,
    price: 335,
    orderedAt: DateTime(2026, 6, 30),
    estDeliveryDate: DateTime(2026, 7, 25),
  ),
  OrderSummary(
    id: 'o3',
    garmentType: 'Kurta',
    tailorName: 'Modern Cuts',
    stage: OrderStage.delivered,
    price: 90,
    orderedAt: DateTime(2026, 6, 12),
    estDeliveryDate: DateTime(2026, 6, 24),
  ),
  OrderSummary(
    id: 'o4',
    garmentType: 'Tuxedo',
    tailorName: 'Zaman Bespoke',
    stage: OrderStage.orderConfirmed,
    price: 380,
    orderedAt: DateTime(2026, 7, 22),
    estDeliveryDate: DateTime(2026, 8, 12),
  ),
];
