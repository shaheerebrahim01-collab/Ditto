// Mirrors backend/prisma/schema.prisma's Measurement model. No
// GET /measurements endpoint exists yet (Phase 8+, see docs/ROADMAP.md), so
// ProfileScreen renders this against local mock data for now.
class SavedMeasurement {
  const SavedMeasurement({
    required this.id,
    required this.label,
    this.chest,
    this.waist,
    this.hip,
    this.shoulder,
    this.sleeve,
    this.neck,
    this.inseam,
  });

  final String id;
  final String label;
  final double? chest;
  final double? waist;
  final double? hip;
  final double? shoulder;
  final double? sleeve;
  final double? neck;
  final double? inseam;

  Map<String, double> get values => {
    if (chest != null) 'Chest': chest!,
    if (waist != null) 'Waist': waist!,
    if (hip != null) 'Hip': hip!,
    if (shoulder != null) 'Shoulder': shoulder!,
    if (sleeve != null) 'Sleeve': sleeve!,
    if (neck != null) 'Neck': neck!,
    if (inseam != null) 'Inseam': inseam!,
  };
}
