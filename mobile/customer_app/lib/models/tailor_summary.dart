// Shape a future GET /tailors list endpoint is expected to return, based on
// backend/prisma/schema.prisma's TailorProfile (businessName, specialties,
// ratingAvg, ratingCount). No such endpoint exists yet (see docs/ROADMAP.md,
// Phase 5+), so HomeScreen renders this against local mock data for now.
class TailorSummary {
  const TailorSummary({
    required this.id,
    required this.businessName,
    required this.specialties,
    required this.ratingAvg,
    required this.ratingCount,
    this.photoUrl,
  });

  final String id;
  final String businessName;
  final List<String> specialties;
  final double ratingAvg;
  final int ratingCount;
  final String? photoUrl;
}
