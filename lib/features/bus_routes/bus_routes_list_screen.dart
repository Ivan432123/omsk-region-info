import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/bus_route_provider.dart';
import '../../providers/district_provider.dart';
import '../../widgets/bus_routes/bus_route_card.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';

class BusRoutesListScreen extends ConsumerWidget {
  const BusRoutesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final district = ref.watch(selectedDistrictProvider);
    final districtId = district.id ?? '';
    final routesAsync = ref.watch(busRoutesProvider(districtId));

    return Scaffold(
      appBar: AppBar(title: const Text('Автобусы')),
      body: routesAsync.when(
        loading: () => const LoadingListWidget(),
        error: (_, __) => EmptyStateWidget.error(
          onRetry: () => ref.invalidate(busRoutesProvider(districtId)),
        ),
        data: (routes) => routes.isEmpty
            ? const EmptyStateWidget.noBusRoutes()
            : RefreshIndicator(
                color: AppTheme.primaryBlue,
                onRefresh: () async =>
                    ref.invalidate(busRoutesProvider(districtId)),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: routes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    return BusRouteCard(
                      key: ValueKey(route.id),
                      route: route,
                      onTap: () => context.push('/bus-routes/${route.id}'),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
