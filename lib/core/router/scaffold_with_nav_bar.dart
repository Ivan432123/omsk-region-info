import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/district_provider.dart';
import '../../providers/news_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/organization_provider.dart';
import '../../providers/sponsored_content_provider.dart';
import '../../providers/weather_provider.dart';
import '../theme/app_theme.dart';

/// Оболочка с нижней навигацией (5 вкладок). Каждая вкладка хранит свой
/// собственный стек экранов (StatefulShellRoute.indexedStack), поэтому
/// при переключении вкладок состояние списков (скролл, загруженные
/// страницы) не сбрасывается.
///
/// Обратная сторона того же: провайдеры вкладок (Главная/Новости/
/// Объявления/Организации) не autoDispose и живут в контейнере вечно —
/// однажды загруженный список так и остаётся закэширован, даже если
/// администратор в это время опубликовал что-то новое. IndexedStack не
/// пересоздаёт скрытые вкладки при переключении, поэтому "просто зайти на
/// вкладку заново" не помогает само по себе. Здесь это решено вручную: при
/// переходе НА вкладку (а не при повторном тапе по уже активной)
/// соответствующие провайдеры инвалидируются в onTap ниже, и вкладка
/// подгружает свежие данные при каждом заходе — тем же способом, что и
/// pull-to-refresh, только без необходимости тянуть список руками.
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
/// "Уведомления") переносились на вторую строку — ни labelBehavior, ни
/// сокрытие подписей у неактивных вкладок это не решали до конца.
/// NavigationDestination.label — это String, обернуть его в FittedBox
/// через публичный API нельзя. Подписи здесь показаны всегда (у всех
/// вкладок, не только у активной — так понятнее, куда ведёт кнопка, без
/// необходимости сначала на неё нажать), но однострочны и уменьшаются по
/// ширине вместо переноса — тот же приём, что уже проверен на кнопках
/// главного экрана (_QuickNavButton).
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

    void onTap(int index) {
      if (index != currentIndex) {
        switch (index) {
          case 0:
            ref.invalidate(newsListProvider);
            ref.invalidate(importantAnnouncementsProvider);
            ref.invalidate(promotedAnnouncementsProvider);
            ref.invalidate(unreadAnnouncementsCountProvider);
            ref.invalidate(sponsoredContentProvider);
            ref.invalidate(weatherProvider);
          case 1:
            ref.invalidate(newsListByCategoryProvider);
          case 2:
            ref.invalidate(announcementListProvider);
            ref.invalidate(unreadAnnouncementsCountProvider);
          case 3:
            ref.invalidate(organizationListProvider);
        }
      }
      navigationShell.goBranch(index, initialLocation: index == currentIndex);
    }

    return PopScope(
      // На вкладках "Новости"/"Объявления"/"Организации"/"Уведомления"
      // (индекс != 0) их собственный Navigator пуст (в стеке только
      // список), поэтому системный жест "назад" (и он же — свайп от края
      // экрана) не находит, что поднимать, и уходит в корневой Navigator,
      // у которого тоже только один элемент — сама StatefulShellRoute.
      // Итог: приложение не возвращается на Главную, а закрывается
      // целиком. canPop:false на всех вкладках, кроме Главной, отдаёт
      // системе "мне есть что показать взамен" — вместо pop переключаем
      // на вкладку 0; закрытие приложения остаётся доступно только с неё,
      // как и ожидает пользователь.
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onTap(0);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.scaffoldBackground(context),
            border: Border(top: BorderSide(color: AppTheme.divider(context))),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 68,
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
    final color = isSelected
        ? AppTheme.onPrimaryContainer(context)
        : AppTheme.textSecondary(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryContainer(context)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Badge(
                isLabelVisible: badgeCount > 0,
                label: Text('$badgeCount'),
                backgroundColor: AppTheme.accentRed,
                child: Icon(isSelected ? selectedIcon : icon,
                    color: color, size: 22),
              ),
            ),
            const SizedBox(height: 2),
            // Подпись видна у ВСЕХ вкладок постоянно (не только у
            // выбранной) — так пользователь всегда видит названия разделов,
            // не нажимая на них. FittedBox + maxLines:1 гарантируют, что
            // длинные слова ("Объявления", "Организации", "Уведомления")
            // уменьшаются по ширине вместо переноса на вторую строку —
            // тот же приём, что уже проверен на кнопках главного экрана.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
