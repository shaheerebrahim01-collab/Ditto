// Extends TailorSummary's shape with what a tailor's own profile page needs:
// bio, workingHours (mirrors TailorProfile.workingHours Json? in the Prisma
// schema — modeled here as ordered day-range/hours pairs) and portfolio
// (mirrors PortfolioItem: category + image). No GET /tailors/:id endpoint
// exists yet (Phase 5+), so this renders against local mock data for now.
class WorkingHoursEntry {
  const WorkingHoursEntry({required this.days, required this.hours});

  final String days;
  final String hours;
}

class PortfolioItem {
  const PortfolioItem({required this.category, this.imageUrl});

  final String category;
  final String? imageUrl;
}

class TailorDetail {
  const TailorDetail({
    required this.id,
    required this.businessName,
    required this.specialties,
    required this.ratingAvg,
    required this.ratingCount,
    required this.bio,
    required this.workingHours,
    required this.portfolio,
    this.coverPhotoUrl,
  });

  final String id;
  final String businessName;
  final List<String> specialties;
  final double ratingAvg;
  final int ratingCount;
  final String bio;
  final List<WorkingHoursEntry> workingHours;
  final List<PortfolioItem> portfolio;
  final String? coverPhotoUrl;
}
