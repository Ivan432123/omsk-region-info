import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/district_selection/district_selection_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/news/news_list_screen.dart';
import '../../features/news/news_details_screen.dart';
import '../../features/organizations/organizations_list_screen.dart';
import '../../features/organizations/organization_details_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/settings/settings_screen.dart';

/// Единая точка навигации приложения.
/// Плоская схема маршрутов сознательно выбрана для MVP; при расширении на
/// весь регион/страну сюда добавляются новые вложенные маршруты без
/// изменения существующих экранов (они принимают только districtId через
/// провайдер, а не через путь URL).
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/district-selection',
        builder: (context, state) => DistrictSelectionScreen(
          isChangeMode: state.extra as bool? ?? false,
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/news',
        builder: (context, state) => const NewsListScreen(),
      ),
      GoRoute(
        path: '/news/:id',
        builder: (context, state) =>
            NewsDetailsScreen(newsId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/organizations',
        builder: (context, state) => const OrganizationsListScreen(),
      ),
      GoRoute(
        path: '/organizations/:id',
        builder: (context, state) =>
            OrganizationDetailsScreen(organizationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
