// Mirrors GET /tailors / GET /tailors/:id's real response shape (backend/
// src/modules/tailors). Separate from TailorSummary, which is still mock
// data pending Home/Explore's own real-endpoint wiring (see
// tailor_summary.dart's comment) — this is the real thing, used by
// CreateScreen's tailor picker.
class Tailor {
  const Tailor({
    required this.id,
    required this.businessName,
    required this.specialties,
    required this.ratingAvg,
    required this.ratingCount,
    this.bio,
  });

  factory Tailor.fromJson(Map<String, dynamic> json) => Tailor(
    id: json['id'] as String,
    businessName: json['businessName'] as String,
    specialties: (json['specialties'] as List<dynamic>).map((e) => e as String).toList(),
    ratingAvg: (json['ratingAvg'] as num).toDouble(),
    ratingCount: json['ratingCount'] as int,
    bio: json['bio'] as String?,
  );

  final String id;
  final String businessName;
  final List<String> specialties;
  final double ratingAvg;
  final int ratingCount;
  final String? bio;
}
