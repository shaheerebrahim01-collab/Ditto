// Mirrors backend/prisma/schema.prisma's Address model. No GET /addresses
// endpoint exists yet, so ProfileScreen renders this against local mock data.
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.line1,
    this.line2,
    required this.city,
    required this.country,
  });

  final String id;
  final String label;
  final String line1;
  final String? line2;
  final String city;
  final String country;
}
