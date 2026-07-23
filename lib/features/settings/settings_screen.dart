import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/district_provider.dart';
import '../../providers/feedback_request_provider.dart';

/// Версия приложения — читается из платформенного манифеста (тот же номер,
/// что в pubspec.yaml), а не хранится второй копией здесь вручную, чтобы
/// экран "Настройки" не показывал устаревшую версию после каждого релиза.
final _packageInfoProvider =
    FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());

/// Экран настроек.
/// MVP-скоуп: смена района, обратная связь с супер-администратором и
/// справочная информация о приложении.
/// Будущий скоуп (не реализовано намеренно): управление push-категориями,
/// тёмная тема.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final district = ref.watch(selectedDistrictProvider);
    final packageInfo = ref.watch(_packageInfoProvider);
    final unreadFeedback =
        ref.watch(unreadFeedbackRepliesCountProvider).value ?? 0;
    final appVersion = packageInfo.maybeWhen(
      data: (info) => info.version,
      orElse: () => '…',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Ваш район', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.location_on_outlined,
            title: district.name ?? 'Район не выбран',
            subtitle:
                'Новости и организации показываются только для этого района',
            trailingLabel: 'Изменить',
            onTap: () => _openChangeDistrict(context, ref),
          ),
          const SizedBox(height: 28),
          Text('О приложении', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Версия приложения',
            subtitle: appVersion,
          ),
          const _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Push-уведомления',
            subtitle:
                'Включены автоматически для вашего района: вода, газ, электричество, '
                'экстренные оповещения',
          ),
          const SizedBox(height: 28),
          Text('Обратная связь',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.mail_outline_rounded,
            title: 'Написать администрации',
            subtitle: 'Вопросы по сотрудничеству, работе приложения, пожелания',
            trailingLabel: 'Открыть',
            onTap: () => context.push('/feedback'),
          ),
          _SettingsTile(
            icon: Icons.history_rounded,
            title: 'Мои обращения',
            subtitle: 'История отправленных обращений и ответов',
            trailingLabel: 'Открыть',
            badgeCount: unreadFeedback,
            onTap: () async {
              await context.push('/my-feedback-requests');
              ref.invalidate(unreadFeedbackRepliesCountProvider);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openChangeDistrict(BuildContext context, WidgetRef ref) async {
    final result = await context.push<DistrictPickResult>(
      '/district-selection',
      extra: true, // isChangeMode = true
    );

    if (result != null && context.mounted) {
      await ref
          .read(selectedDistrictProvider.notifier)
          .changeDistrict(result.id, result.name);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Район изменён на «${result.name}»')),
        );
      }
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final VoidCallback? onTap;
  final int badgeCount;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingLabel,
    this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.divider(context)),
            ),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: badgeCount > 0,
                  label: Text('$badgeCount'),
                  backgroundColor: AppTheme.accentRed,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryContainer(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon,
                        color: AppTheme.onPrimaryContainer(context), size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                if (trailingLabel != null && onTap != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    trailingLabel!,
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.primaryBlue),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
