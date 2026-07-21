import 'package:go_router/go_router.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/district_selection/district_selection_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/news/news_list_screen.dart';
import '../../features/news/news_details_screen.dart';
import '../../features/organizations/organizations_list_screen.dart';
import '../../features/organizations/organization_details_screen.dart';
import '../../features/organizations/bookmarked_organizations_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/vacancies/vacancies_list_screen.dart';
import '../../features/vacancies/vacancy_details_screen.dart';
import '../../features/announcements/announcements_list_screen.dart';
import '../../features/announcements/announcement_details_screen.dart';
import '../../features/events/events_list_screen.dart';
import '../../features/events/event_details_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/post_announcement/post_announcement_screen.dart';
import '../../features/post_announcement/my_ad_requests_screen.dart';
import '../../features/bus_routes/bus_routes_list_screen.dart';
import '../../features/bus_routes/bus_route_details_screen.dart';
import 'scaffold_with_nav_bar.dart';

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
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/post-announcement',
        builder: (context, state) => const PostAnnouncementScreen(),
      ),
      GoRoute(
        path: '/my-ad-requests',
        builder: (context, state) => const MyAdRequestsScreen(),
      ),
      GoRoute(
        path: '/vacancies',
        builder: (context, state) => const VacanciesListScreen(),
      ),
      GoRoute(
        path: '/vacancies/:id',
        builder: (context, state) =>
            VacancyDetailsScreen(vacancyId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/announcements',
        builder: (context, state) => const AnnouncementsListScreen(),
      ),
      GoRoute(
        path: '/announcements/:id',
        builder: (context, state) => AnnouncementDetailsScreen(
            announcementId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const EventsListScreen(),
      ),
      GoRoute(
        path: '/events/:id',
        builder: (context, state) =>
            EventDetailsScreen(eventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/bus-routes',
        builder: (context, state) => const BusRoutesListScreen(),
      ),
      GoRoute(
        path: '/bookmarks',
        builder: (context, state) => const BookmarkedOrganizationsScreen(),
      ),
      GoRoute(
        path: '/bus-routes/:id',
        builder: (context, state) =>
            BusRouteDetailsScreen(routeId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/news',
                builder: (context, state) => const NewsListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        NewsDetailsScreen(newsId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/organizations',
                builder: (context, state) => const OrganizationsListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => OrganizationDetailsScreen(
                      organizationId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
