import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/announcement_provider.dart';
import '../../providers/district_provider.dart';
import '../../providers/notification_provider.dart';

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

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        // С 5 вкладками и длинными русскими подписями ("Организации",
        // "Уведомления") подписи под всеми иконками одновременно (поведение
        // по умолчанию) переносились на второй ряд на обычных экранах — та
        // же причина "кривизны", что раньше была у кнопок на главном.
        // Показ подписи только у выбранной вкладки — стандартный приём
        // Material для панели с 5+ пунктами, а не костыль.
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Главная',
          ),
          const NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article_rounded),
            label: 'Новости',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadAnnouncements > 0,
              label: Text('$unreadAnnouncements'),
              child: const Icon(Icons.campaign_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadAnnouncements > 0,
              label: Text('$unreadAnnouncements'),
              child: const Icon(Icons.campaign_rounded),
            ),
            label: 'Объявления',
          ),
          const NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment_rounded),
            label: 'Организации',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadNotifications > 0,
              label: Text('$unreadNotifications'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadNotifications > 0,
              label: Text('$unreadNotifications'),
              child: const Icon(Icons.notifications_rounded),
            ),
            label: 'Уведомления',
          ),
        ],
      ),
    );
  }
}
