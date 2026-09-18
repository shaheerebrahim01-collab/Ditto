// Mirrors backend/prisma/schema.prisma's Review model as returned by
// GET /reviews (reviewInclude in reviews.service.ts: author.fullName only).
class Review {
  const Review({
    required this.id,
    required this.rating,
    required this.authorName,
    required this.createdAt,
    this.comment,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>;
    return Review(
      id: json['id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      authorName: author['fullName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final int rating;
  final String? comment;
  final String authorName;
  final DateTime createdAt;
}
