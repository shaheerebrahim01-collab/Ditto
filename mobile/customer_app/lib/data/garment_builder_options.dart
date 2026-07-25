import 'package:flutter/material.dart';

// Placeholder pricing/options for the Create flow — mirrors the fields
// CustomOrder expects (garmentType, fabric, detailsJson, measurement) so
// wiring this to a real POST /orders is a drop-in change once it exists
// (Phase 7+, see docs/ROADMAP.md).
class GarmentType {
  const GarmentType({required this.id, required this.label, required this.icon, required this.basePrice});

  final String id;
  final String label;
  final IconData icon;
  final double basePrice;
}

const garmentTypes = [
  GarmentType(id: 'suit', label: 'Suit', icon: Icons.checkroom, basePrice: 250),
  GarmentType(id: 'sherwani', label: 'Sherwani', icon: Icons.celebration, basePrice: 320),
  GarmentType(id: 'kurta', label: 'Kurta', icon: Icons.style, basePrice: 90),
  GarmentType(id: 'waistcoat', label: 'Waistcoat', icon: Icons.diamond_outlined, basePrice: 70),
  GarmentType(id: 'trousers', label: 'Trousers', icon: Icons.straighten, basePrice: 60),
  GarmentType(id: 'blazer', label: 'Blazer', icon: Icons.work_outline, basePrice: 180),
  GarmentType(id: 'shirt', label: 'Shirt', icon: Icons.iron_outlined, basePrice: 50),
  GarmentType(id: 'tuxedo', label: 'Tuxedo', icon: Icons.star_outline, basePrice: 380),
];

class FabricSwatch {
  const FabricSwatch({required this.id, required this.name, required this.color, required this.priceAddOn});

  final String id;
  final String name;
  final Color color;
  final double priceAddOn;
}

const fabricSwatches = [
  FabricSwatch(id: 'charcoal_wool', name: 'Charcoal Wool', color: Color(0xFF3A3A3A), priceAddOn: 0),
  FabricSwatch(id: 'navy_twill', name: 'Navy Twill', color: Color(0xFF1F2D4A), priceAddOn: 15),
  FabricSwatch(id: 'ivory_linen', name: 'Ivory Linen', color: Color(0xFFF2ECDD), priceAddOn: 20),
  FabricSwatch(id: 'slate_grey', name: 'Slate Grey', color: Color(0xFF6E7276), priceAddOn: 10),
  FabricSwatch(id: 'beige_cotton', name: 'Beige Cotton', color: Color(0xFFD8C6A8), priceAddOn: 10),
  FabricSwatch(id: 'burgundy_silk', name: 'Burgundy Silk', color: Color(0xFF6E1E2C), priceAddOn: 60),
  FabricSwatch(id: 'midnight_velvet', name: 'Midnight Velvet', color: Color(0xFF1B1224), priceAddOn: 75),
  FabricSwatch(id: 'herringbone_black', name: 'Black Herringbone', color: Color(0xFF161616), priceAddOn: 35),
];

const lapelStyles = {
  'Notch': 0.0,
  'Peak': 15.0,
  'Shawl': 15.0,
};

const buttonStyles = {
  '2-Button': 0.0,
  '3-Button': 5.0,
  'Double-Breasted': 20.0,
};

const monogramPrice = 10.0;
