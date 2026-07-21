import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/notification_model.dart';
import '../../providers/district_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/category_chip.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // Снимок "последний раз просмотрено" на МОМЕНТ ОТКРЫТИЯ экрана — используется
  // для подсветки непрочитанных в этом посещении. Обновляется на новое
  // значение уже после того, как снимок прочитан, поэтому при следующем
  // заходе все текущие уведомления окажутся прочитанными, а не раньше.
  DateTime? _lastSeenAtOpen;
  bool _lastSeenLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureAndMarkSeen());
  }

  Future<void> _captureAndMarkSeen() async {
    final districtId = ref.read(selectedDistrictProvider).id ?? '';
    if (districtId.isEmpty) return;
    final storage = LocalStorageService();
    final lastSeen = await storage.getLastSeenNotificationsTime(districtId);
    if (!mounted) return;
    setState(() {
      _lastSeenAtOpen = lastSeen;
      _lastSeenLoaded = true;
    });
    await storage.markNotificationsSeen(districtId);
    if (mounted) ref.invalidate(lastSeenNotificationsProvider(districtId));
  }

  @override
  Widget build(BuildContext context) {
    final districtId = ref.watch(selectedDistrictProvider).id ?? '';
    final notificationsAsync =
        ref.watch(notificationsStreamProvider(districtId));

    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: notificationsAsync.when(
        loading: () => const LoadingListWidget(),
        error: (_, __) => EmptyStateWidget.error(
          onRetry: () =>
              ref.invalidate(notificationsStreamProvider(districtId)),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget.noNotifications();
          }

          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: () async =>
                ref.invalidate(notificationsStreamProvider(districtId)),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = _lastSeenLoaded &&
                    _lastSeenAtOpen != null &&
                    notification.createdAt.isBefore(_lastSeenAtOpen!);
                return _NotificationTile(
                  key: ValueKey(notification.id),
                  notification: notification,
                  isRead: isRead,
                  onTap: () {
                    if (notification.relatedNewsId != null) {
                      context.push('/news/${notification.relatedNewsId}');
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationTile({
    super.key,
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead
              ? AppTheme.surface(context)
              : AppTheme.primaryContainer(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRead
                ? AppTheme.divider(context)
                : AppTheme.primaryBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(top: 6, right: 10),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.accentRed,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CategoryChip(category: notification.category),
                      const Spacer(),
                      Text(
                        DateFormatter.formatRelative(notification.createdAt),
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
