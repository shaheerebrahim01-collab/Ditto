// Shape a future GET /tailors list endpoint is expected to return, based on
// backend/prisma/schema.prisma's TailorProfile (businessName, specialties,
// ratingAvg, ratingCount). No such endpoint exists yet (see docs/ROADMAP.md,
// Phase 5+), so Home/Explore render this against local mock data for now.
//
// distanceKm, priceTier and fastDelivery back the Explore filters (Nearby /
// Fast Delivery / Luxury / Budget) and don't exist on TailorProfile yet
// either — placeholders until the backend has a real notion of location,
// pricing tier and turnaround time.
enum PriceTier { budget, mid, luxury }

class TailorSummary {
  const TailorSummary({
    required this.id,
    required this.businessName,
    required this.specialties,
    required this.ratingAvg,
    required this.ratingCount,
    required this.distanceKm,
    required this.priceTier,
    required this.fastDelivery,
    this.photoUrl,
  });

  final String id;
  final String businessName;
  final List<String> specialties;
  final double ratingAvg;
  final int ratingCount;
  final double distanceKm;
  final PriceTier priceTier;
  final bool fastDelivery;
  final String? photoUrl;
}
