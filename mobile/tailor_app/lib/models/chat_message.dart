// Mirrors backend/prisma/schema.prisma's Message model.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.createdAt,
    this.body,
    this.attachmentUrl,
    this.attachmentType,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    conversationId: json['conversationId'] as String,
    senderId: json['senderId'] as String,
    body: json['body'] as String?,
    attachmentUrl: json['attachmentUrl'] as String?,
    attachmentType: json['attachmentType'] as String?,
    readAt: json['readAt'] == null ? null : DateTime.parse(json['readAt'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final String id;
  final String conversationId;
  final String senderId;
  final String? body;
  final String? attachmentUrl;
  final String? attachmentType;
  final DateTime? readAt;
  final DateTime createdAt;
}
