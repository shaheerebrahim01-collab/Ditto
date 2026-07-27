// Mirrors backend/prisma/schema.prisma's RentalItem model. `shopName` is
// only present when the backend nests `shop: { businessName }` on the item
// (RentalsService's bookingInclude, on renter-side booking responses) —
// null on every other endpoint that returns a bare RentalItem.
class RentalItem {
  const RentalItem({
    required this.id,
    required this.shopId,
    required this.name,
    required this.category,
    required this.pricePerDay,
    required this.depositAmount,
    this.imageUrl,
    this.shopName,
  });

  factory RentalItem.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'] as Map<String, dynamic>?;
    return RentalItem(
      id: json['id'] as String,
      shopId: json['shopId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      pricePerDay: (json['pricePerDay'] as num).toDouble(),
      depositAmount: (json['depositAmount'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      shopName: shop?['businessName'] as String?,
    );
  }

  final String id;
  final String shopId;
  final String name;
  final String category;
  final double pricePerDay;
  final double depositAmount;
  final String? imageUrl;
  final String? shopName;
}
