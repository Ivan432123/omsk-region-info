import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/district_provider.dart';
import '../../providers/notification_provider.dart';
import '../theme/app_theme.dart';

/// Оболочка с нижней навигацией (5 вкладок). Каждая вкладка хранит свой
/// собственный стек экранов (StatefulShellRoute.indexedStack), поэтому
/// при переключении вкладок состояние списков (скролл, загруженные
/// страницы) не сбрасывается.
///
/// "Объявления" — единственный раздел, до которого раньше можно было
/// добраться только с главного экрана (кнопка в _QuickNavRow), а из любого
/// другого места — только вернувшись на Главную. Он самый частый повод
/// открыть приложение повторно (у него один есть счётчик новых на
/// главном), поэтому вынесен в постоянную навигацию вместо этого.
///
/// Панель нарисована вручную, а не через встроенный NavigationBar: у
/// последнего подпись жёстко ограничена шириной 1/N бара (N — число
/// вкладок), и длинные русские слова ("Объявления", "Организации",
/// "Уведомления") переносились на вторую строку независимо от
/// labelBehavior — тот вариант чинил только неактивные вкладки, а не саму
/// выбранную. NavigationDestination.label — это String, обернуть его в
/// FittedBox через публичный API нельзя. Здесь используется тот же приём,
/// что уже проверен на кнопках главного экрана (_QuickNavButton) —
/// однострочный текст, уменьшающийся по ширине вместо переноса.
class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final district = ref.watch(selectedDistrictProvider);
    final districtId = district.id ?? '';
    final unreadNotifications =
        ref.watch(unreadNotificationsCountProvider(districtId));
    final unreadAnnouncements =
        ref.watch(unreadAnnouncementsCountProvider(districtId)).value ?? 0;
    final currentIndex = navigationShell.currentIndex;

    void onTap(int index) => navigationShell.goBranch(
          index,
          initialLocation: index == currentIndex,
        );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.scaffoldBackground(context),
          border: Border(top: BorderSide(color: AppTheme.divider(context))),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Главная',
                    isSelected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.article_outlined,
                    selectedIcon: Icons.article_rounded,
                    label: 'Новости',
                    isSelected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.campaign_outlined,
                    selectedIcon: Icons.campaign_rounded,
                    label: 'Объявления',
                    badgeCount: unreadAnnouncements,
                    isSelected: currentIndex == 2,
                    onTap: () => onTap(2),
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.apartment_outlined,
                    selectedIcon: Icons.apartment_rounded,
                    label: 'Организации',
                    isSelected: currentIndex == 3,
                    onTap: () => onTap(3),
                  ),
                ),
                Expanded(
                  child: _NavBarItem(
                    icon: Icons.notifications_outlined,
                    selectedIcon: Icons.notifications_rounded,
                    label: 'Уведомления',
                    badgeCount: unreadNotifications,
                    isSelected: currentIndex == 4,
                    onTap: () => onTap(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badgeCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Badge(
      isLabelVisible: badgeCount > 0,
      label: Text('$badgeCount'),
      backgroundColor: AppTheme.accentRed,
      child: Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected
            ? AppTheme.onPrimaryContainer(context)
            : AppTheme.textSecondary(context),
        size: 24,
      ),
    );

    return InkWell(
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          // Верхняя граница только для широких экранов (планшеты) — на
          // обычном телефоне реальную ширину всё равно диктует Expanded
          // (1/5 панели), это лишь не даёт таблетке растянуть пилюлю
          // на всю выделенную колонку.
          constraints: const BoxConstraints(maxWidth: 160),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryContainer(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              // Подпись показывается только у выбранной вкладки (как и
              // раньше) — так у соседних остаётся простор, а сама подпись
              // на всякий случай защищена от переноса FittedBox'ом, а не
              // только достаточной шириной.
              if (isSelected) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.onPrimaryContainer(context),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
