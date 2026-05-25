import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_session.dart';
import '../services/notification_poller.dart';
import 'payments/payments_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.getNotifications(AuthSession.instance.token);
      if (res['status'] == 200 && mounted) {
        final data = res['body']['data'] as List<dynamic>? ?? [];
        setState(() {
          _notifications = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final extra = data['extra'] as Map<String, dynamic>? ?? {};
    final action = extra['action']?.toString() ?? '';
    switch (action) {
      case 'pay_now':
      case 'refund_approved':
      case 'refund_rejected':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaymentsScreen()),
        );
        break;
      default:
        break;
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete All', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await ApiService.deleteAllNotifications(AuthSession.instance.token);
    setState(() => _notifications.clear());
    NotificationPoller.instance.refresh();
  }

  Future<void> _markRead(int id, int index) async {
    await ApiService.markNotificationRead(AuthSession.instance.token, id);
    setState(() {
      _notifications[index]['status'] = 'read';
    });
    NotificationPoller.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left, color: AppTheme.primaryBlue),
          label: const Text('Back', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 16)),
        ),
        leadingWidth: 100,
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          if (AuthSession.instance.role != 'admin' && _notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
              tooltip: 'Clear All',
              onPressed: _clearAll,
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 60, color: AppTheme.lightGrey),
                      SizedBox(height: 16),
                      Text('No notifications yet',
                          style: TextStyle(color: AppTheme.textGrey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, i) => _buildNotificationCard(i),
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(int index) {
    final n = _notifications[index];
    final id = n['id'] as int? ?? 0;
    final data = n['data'] as Map<String, dynamic>? ?? {};
    final title = data['title']?.toString() ?? 'Notification';
    final body = data['body']?.toString() ?? '';
    final status = n['status']?.toString() ?? 'sent';
    final createdAt = n['created_at']?.toString().substring(0, 16) ?? '';
    final isRead = status == 'read';

    return GestureDetector(
      onTap: () {
        if (!isRead) _markRead(id, index);
        _handleNotificationTap(data);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppTheme.primaryBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? AppTheme.cardBorder : AppTheme.primaryBlue.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isRead
                    ? AppTheme.lightGrey.withValues(alpha: 0.3)
                    : AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIcon(data),
                color: isRead ? AppTheme.textGrey : AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textGrey, height: 1.3),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    createdAt.replaceAll('T', ' '),
                    style: const TextStyle(fontSize: 11, color: AppTheme.lightGrey),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(Map<String, dynamic> data) {
    final extra = data['extra'] as Map<String, dynamic>? ?? {};
    final action = extra['action']?.toString() ?? '';
    switch (action) {
      case 'contract_submitted':
        return Icons.description_outlined;
      case 'contract_accepted':
        return Icons.check_circle_outline;
      case 'contract_refused':
        return Icons.cancel_outlined;
      case 'refund_approved':
        return Icons.money_off;
      case 'refund_rejected':
        return Icons.money_off_csred_outlined;
      case 'payment_due':
        return Icons.payment;
      default:
        return Icons.notifications_outlined;
    }
  }
}
