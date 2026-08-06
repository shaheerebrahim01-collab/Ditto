import 'rental_item.dart';

// Mirrors backend/prisma/schema.prisma's RentalShopProfile model.
// `itemCount` only comes back from GET /rental-shops (list); `items` only
// comes back from GET /rental-shops/:id (detail) — never both at once.
class RentalShop {
  const RentalShop({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.status,
    required this.ratingAvg,
    required this.ratingCount,
    this.itemCount,
    this.items,
  });

  factory RentalShop.fromJson(Map<String, dynamic> json) {
    return RentalShop(
      id: json['id'] as String,
      userId: json['userId'] as String,
      businessName: json['businessName'] as String,
      status: json['status'] as String,
      ratingAvg: (json['ratingAvg'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      itemCount: json['itemCount'] as int?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => RentalItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  // The shop owner's User.id — always present on the raw API response
  // (Prisma includes all scalars), used to start a conversation with the
  // shop from RentalShopDetailScreen.
  final String userId;
  final String businessName;
  final String status;
  final double ratingAvg;
  final int ratingCount;
  final int? itemCount;
  final List<RentalItem>? items;
}
