import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../models/conversation_summary.dart';
import 'chat_screen.dart';

// GET /conversations — every thread the signed-in user is a participant
// in, newest-active first (server sorts by Conversation.updatedAt).
class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  final _api = ApiClient();
  List<ConversationSummary>? _conversations;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    try {
      final conversations = await _api.listConversations(accessToken);
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load conversations');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        children: [Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(_error!)))],
      );
    }
    if (_conversations == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_conversations!.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text('No conversations yet', style: TextStyle(color: DittoColors.mutedInk)),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      itemCount: _conversations!.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final conversation = _conversations![index];
        return _ConversationRow(
          conversation: conversation,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: conversation.id,
                  otherUserName: conversation.otherUser.fullName,
                ),
              ),
            );
            _load();
          },
        );
      },
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation, required this.onTap});

  final ConversationSummary conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount > 0;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: DittoColors.brown.withValues(alpha: 0.12),
        backgroundImage: conversation.otherUser.avatarUrl != null
            ? NetworkImage(conversation.otherUser.avatarUrl!)
            : null,
        child: conversation.otherUser.avatarUrl == null
            ? Text(
                conversation.otherUser.fullName.isNotEmpty
                    ? conversation.otherUser.fullName.substring(0, 1)
                    : '?',
                style: const TextStyle(color: DittoColors.brown),
              )
            : null,
      ),
      title: Text(
        conversation.otherUser.fullName,
        style: TextStyle(fontWeight: unread ? FontWeight.w700 : FontWeight.w500),
      ),
      subtitle: Text(
        conversation.lastMessage?.body ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: unread ? DittoColors.ink : DittoColors.mutedInk),
      ),
      trailing: unread
          ? CircleAvatar(
              radius: 10,
              backgroundColor: DittoColors.gold,
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(fontSize: 11, color: DittoColors.ink),
              ),
            )
          : null,
    );
  }
}
