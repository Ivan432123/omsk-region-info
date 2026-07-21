import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/bus_route_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';

class BusRouteDetailsScreen extends ConsumerWidget {
  final String routeId;

  const BusRouteDetailsScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(busRouteDetailsProvider(routeId));

    return Scaffold(
      appBar: AppBar(),
      body: routeAsync.when(
        loading: () => const LoadingIndicatorWidget(),
        error: (_, __) => EmptyStateWidget.error(
          onRetry: () => ref.invalidate(busRouteDetailsProvider(routeId)),
        ),
        data: (route) {
          if (route == null) {
            return const EmptyStateWidget(
              icon: Icons.directions_bus_outlined,
              title: 'Маршрут не найден',
              subtitle: 'Возможно, он был удалён',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        route.routeNumber,
                        style: TextStyle(
                          color: AppTheme.onPrimaryContainer(context),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(route.routeName,
                          style: Theme.of(context).textTheme.headlineMedium),
                    ),
                  ],
                ),
                if (route.stops.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Остановки',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...route.stops.map(
                    (stop) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 18, color: AppTheme.textSecondary(context)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(stop)),
                        ],
                      ),
                    ),
                  ),
                ],
                if (route.departureTimes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Расписание',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: route.departureTimes
                        .map((time) => Chip(label: Text(time)))
                        .toList(),
                  ),
                ],
                if (route.notes != null && route.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Примечание',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(route.notes!,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
