// Mirrors backend/prisma/schema.prisma's Notification model. `type` is a
// free-form string set by whichever service created it (messaging,
// measurement-visits, rentals, admin) — see NotificationsService.create's
// callers for the full vocabulary in use today.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    read: json['read'] as bool,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final String id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
}
