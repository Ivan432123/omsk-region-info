import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../illustrations/steppe_texture.dart';

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

  const EmptyStateWidget.bannerSubmissionDisabled({super.key})
      : icon = Icons.campaign_outlined,
        title = 'Приём баннеров временно недоступен',
        subtitle =
            'Администратор сейчас не принимает новые заявки на размещение баннеров — загляните позже',
        actionLabel = null,
        onAction = null;

  const EmptyStateWidget.vacancySubmissionDisabled({super.key})
      : icon = Icons.work_outline_rounded,
        title = 'Приём вакансий временно недоступен',
        subtitle =
            'Администратор сейчас не принимает новые заявки на публикацию вакансий — загляните позже',
        actionLabel = null,
        onAction = null;

  const EmptyStateWidget.announcementsSectionDisabled({super.key})
      : icon = Icons.campaign_outlined,
        title = 'Раздел временно недоступен',
        subtitle = 'Администратор сейчас отключил раздел "Объявления" — загляните позже',
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
            _EmptyStateIllustration(icon: icon),
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

/// Декоративная композиция вместо одинокой иконки в кружке — большой мягкий
/// круг фонового цвета (с едва заметной степной текстурой у основания —
/// региональный акцент, см. SteppeTexture) плюс два маленьких цветных
/// "блика" вразлёт и сама иконка в приподнятом (с тенью) круге поверх.
/// Простой приём, знакомый по пустым состояниям многих приложений, но
/// заметно живее плоской заглушки — и не требует внешних SVG/PNG-файлов,
/// иллюстрации рисуются штатными виджетами/CustomPainter Flutter.
class _EmptyStateIllustration extends StatelessWidget {
  final IconData icon;

  const _EmptyStateIllustration({required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer(context),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: SteppeTexture(color: AppTheme.regionGreenText(context)),
            ),
          ),
          Positioned(
            top: 6,
            right: 10,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Icon(icon, size: 36, color: AppTheme.primaryBlueText(context)),
          ),
        ],
      ),
    );
  }
}
