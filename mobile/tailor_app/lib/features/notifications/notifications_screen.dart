import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../models/app_notification.dart';

// GET /notifications, POST /notifications/:id/read, POST /notifications/read-all.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiClient();
  List<AppNotification>? _notifications;
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
      final notifications = await _api.listNotifications(accessToken);
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load notifications');
    }
  }

  Future<void> _markAllRead() async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    await _api.markAllNotificationsRead(accessToken);
    _load();
  }

  Future<void> _tapNotification(AppNotification notification) async {
    if (notification.read) return;
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    await _api.markNotificationRead(accessToken, notification.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications?.any((n) => !n.read) ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(onPressed: _markAllRead, child: const Text('Mark all read')),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ListView(
        children: [Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(_error!)))],
      );
    }
    if (_notifications == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_notifications!.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Text('No notifications yet', style: TextStyle(color: DittoColors.mutedInk)),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      itemCount: _notifications!.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notification = _notifications![index];
        return ListTile(
          onTap: () => _tapNotification(notification),
          leading: Icon(
            notification.read ? Icons.notifications_none : Icons.notifications,
            color: notification.read ? DittoColors.mutedInk : DittoColors.brown,
          ),
          title: Text(
            notification.title,
            style: TextStyle(fontWeight: notification.read ? FontWeight.w500 : FontWeight.w700),
          ),
          subtitle: Text(notification.body, style: const TextStyle(color: DittoColors.mutedInk)),
        );
      },
    );
  }
}
