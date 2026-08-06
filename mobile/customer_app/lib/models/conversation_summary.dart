import 'chat_message.dart';

// The other participant in a conversation — mirrors the subset of User
// MessagingService's otherUserSelect returns (never the full User shape).
class ConversationParticipant {
  const ConversationParticipant({
    required this.id,
    required this.fullName,
    required this.role,
    this.avatarUrl,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) => ConversationParticipant(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    role: json['role'] as String,
    avatarUrl: json['avatarUrl'] as String?,
  );

  final String id;
  final String fullName;
  final String role;
  final String? avatarUrl;
}

// GET /conversations list-row shape — includes lastMessage/unreadCount
// alongside the Conversation row, computed server-side.
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.otherUser,
    required this.unreadCount,
    required this.updatedAt,
    this.lastMessage,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) => ConversationSummary(
    id: json['id'] as String,
    otherUser: ConversationParticipant.fromJson(json['otherUser'] as Map<String, dynamic>),
    lastMessage: json['lastMessage'] == null
        ? null
        : ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>),
    unreadCount: json['unreadCount'] as int,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  final String id;
  final ConversationParticipant otherUser;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;
}
