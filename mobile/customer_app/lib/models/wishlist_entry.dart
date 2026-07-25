import 'package:flutter/material.dart';

// Mirrors backend/prisma/schema.prisma's WishlistItem model (itemType +
// refId) with the display fields a list needs already resolved. No
// GET /wishlist endpoint exists yet, so ProfileScreen renders this against
// local mock data.
enum WishlistItemType { tailor, rentalItem, style }

extension WishlistItemTypeX on WishlistItemType {
  IconData get icon => switch (this) {
    WishlistItemType.tailor => Icons.storefront_outlined,
    WishlistItemType.rentalItem => Icons.checkroom,
    WishlistItemType.style => Icons.auto_awesome_outlined,
  };

  String get label => switch (this) {
    WishlistItemType.tailor => 'Tailor',
    WishlistItemType.rentalItem => 'Rental',
    WishlistItemType.style => 'Style',
  };
}

class WishlistEntry {
  const WishlistEntry({required this.id, required this.itemType, required this.title, required this.subtitle});

  final String id;
  final WishlistItemType itemType;
  final String title;
  final String subtitle;
}
