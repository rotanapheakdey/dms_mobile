import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../l10n/app_localizations.dart';
import '../widget/common/empty_state.dart';
import '../widget/common/loading_indicator.dart';
import '../../models/notification.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final notifications = notifProvider.notifications;
    final isLoading = notifProvider.isLoading;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.notifications),
        actions: [
          if (notifications.isNotEmpty && notifProvider.unreadCount > 0)
            TextButton(
              onPressed: () async {
                await notifProvider.markAllRead();
              },
              child: Text(context.l10n.markAllRead),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifProvider.loadNotifications(),
          ),
        ],
      ),
      body: isLoading
          ? LoadingIndicator(message: context.l10n.loadingNotifications)
          : notifications.isEmpty
              ? EmptyState(
                  title: context.l10n.noNotifications,
                  subtitle: context.l10n.noNotificationsSubtitle,
                  icon: Icons.notifications_off_outlined,
                )
              : RefreshIndicator(
                  onRefresh: () => notifProvider.loadNotifications(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationItem(
                        context,
                        notification,
                        colorScheme,
                        onTap: () => notifProvider.markAsRead(notification.id),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    ColorScheme colorScheme, {
    VoidCallback? onTap,
  }) {
    return Card(
      color: notification.isRead
          ? colorScheme.surface
          : colorScheme.primaryContainer.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: notification.isRead
              ? colorScheme.outlineVariant.withValues(alpha: 0.4)
              : colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getIconColor(notification, colorScheme).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIcon(notification),
                  color: _getIconColor(notification, colorScheme),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: notification.isRead
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: notification.isRead
                            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                            : colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(NotificationModel notification) {
    final title = notification.title.toLowerCase();
    if (title.contains('assign')) return Icons.assignment_rounded;
    if (title.contains('dispatch')) return Icons.send_rounded;
    if (title.contains('sign')) return Icons.draw_rounded;
    if (title.contains('upload')) return Icons.upload_file_rounded;
    if (title.contains('archive')) return Icons.archive_rounded;
    if (title.contains('approve')) return Icons.check_circle_rounded;
    if (title.contains('reject')) return Icons.cancel_rounded;
    return Icons.notifications_rounded;
  }

  Color _getIconColor(NotificationModel notification, ColorScheme colorScheme) {
    final title = notification.title.toLowerCase();
    if (title.contains('assign')) return Colors.blue;
    if (title.contains('dispatch')) return Colors.orange;
    if (title.contains('sign')) return Colors.purple;
    if (title.contains('upload')) return Colors.green;
    if (title.contains('archive')) return Colors.grey;
    if (title.contains('approve')) return Colors.green;
    if (title.contains('reject')) return Colors.red;
    return colorScheme.primary;
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
