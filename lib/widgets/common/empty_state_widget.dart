import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Универсальный виджет пустого состояния.
/// Используется для "Нет новостей", "Нет организаций", "Нет уведомлений"
/// и для ошибок загрузки — с единым, узнаваемым визуальным языком.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  const EmptyStateWidget.noNews({super.key})
      : icon = Icons.article_outlined,
        title = 'Нет новостей',
        subtitle =
            'Как только появятся новости вашего района — они будут здесь',
        actionLabel = null,
        onAction = null;

  const EmptyStateWidget.noOrganizations({super.key})
      : icon = Icons.apartment_outlined,
        title = 'Нет организаций',
        subtitle = 'Список организаций вашего района скоро появится',
        actionLabel = null,
        onAction = null;

  const EmptyStateWidget.noNotifications({super.key})
      : icon = Icons.notifications_none_rounded,
        title = 'Нет уведомлений',
        subtitle = 'Важные события вашего района будут приходить сюда',
        actionLabel = null,
        onAction = null;

  const EmptyStateWidget.noBusRoutes({super.key})
      : icon = Icons.directions_bus_outlined,
        title = 'Пока нет маршрутов',
        subtitle = 'Расписание автобусов вашего района скоро появится',
        actionLabel = null,
        onAction = null;

  const EmptyStateWidget.noBookmarks({super.key})
      : icon = Icons.bookmark_border_rounded,
        title = 'Пока нет закладок',
        subtitle =
            'Нажмите на значок закладки на странице организации, чтобы быстро находить её здесь',
        actionLabel = null,
        onAction = null;

  factory EmptyStateWidget.error({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.wifi_off_rounded,
      title: 'Ошибка загрузки',
      subtitle: 'Проверьте подключение к интернету и попробуйте снова',
      actionLabel: onRetry != null ? 'Повторить' : null,
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlueLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
