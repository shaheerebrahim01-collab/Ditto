import 'dart:typed_data';

// Mirrors backend/prisma/schema.prisma's PortfolioItem (category + image).
// imageBytes holds a freshly picked image for this session only — there's
// no upload endpoint yet (AWS_S3_BUCKET/CLOUDINARY_URL are Phase 11), so
// nothing here persists past a reload.
class PortfolioItem {
  const PortfolioItem({required this.id, required this.category, this.imageBytes});

  final String id;
  final String category;
  final Uint8List? imageBytes;
}
