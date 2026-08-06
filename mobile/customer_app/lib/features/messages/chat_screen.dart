import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../models/chat_message.dart';

// A single thread — GET/POST /conversations/:id/messages, plus a mark-read
// call on open (server computes unread counts off Message.readAt, not a
// client-side guess).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversationId, required this.otherUserName});

  final String conversationId;
  final String otherUserName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiClient();
  final _inputController = TextEditingController();
  List<ChatMessage>? _messages;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    try {
      final messages = await _api.listMessages(accessToken, widget.conversationId);
      await _api.markConversationRead(accessToken, widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load messages');
    }
  }

  Future<void> _send() async {
    final accessToken = context.read<AuthRepository>().accessToken;
    final body = _inputController.text.trim();
    if (accessToken == null || body.isEmpty) return;
    setState(() => _sending = true);
    try {
      final sent = await _api.sendMessage(accessToken, widget.conversationId, body);
      if (!mounted) return;
      setState(() {
        _messages = [sent, ...?_messages];
        _inputController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send message')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthRepository>().currentUser?.id;
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUserName)),
      body: Column(
        children: [
          Expanded(child: _buildBody(currentUserId)),
          _Composer(controller: _inputController, sending: _sending, onSend: _send),
        ],
      ),
    );
  }

  Widget _buildBody(String? currentUserId) {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: DittoColors.mutedInk)));
    }
    if (_messages == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messages!.isEmpty) {
      return const Center(
        child: Text('No messages yet — say hello', style: TextStyle(color: DittoColors.mutedInk)),
      );
    }
    // listMessages returns newest-first; reverse: true keeps that as the
    // natural scroll order (newest at the bottom) without re-sorting.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: _messages!.length,
      itemBuilder: (context, index) {
        final message = _messages![index];
        final isMine = message.senderId == currentUserId;
        return _MessageBubble(message: message, isMine: isMine);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine ? DittoColors.brown : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isMine ? null : Border.all(color: DittoColors.brown.withValues(alpha: 0.12)),
        ),
        child: Text(
          message.body ?? '',
          style: TextStyle(color: isMine ? DittoColors.cream : DittoColors.ink),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.sending, required this.onSend});

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Message...'),
                onSubmitted: (_) => sending ? null : onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: DittoColors.brown),
              onPressed: sending ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}
