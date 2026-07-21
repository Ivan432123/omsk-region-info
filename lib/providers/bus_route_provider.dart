import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bus_route_model.dart';
import '../repositories/bus_route_repository.dart';

final busRouteRepositoryProvider = Provider((ref) => BusRouteRepository());

/// Маршруты автобусов выбранного района.
/// autoDispose: раздел "Автобусы" — отдельный push-маршрут (не вкладка
/// нижней навигации), см. комментарий у vacancyListProvider — та же причина.
final busRoutesProvider = FutureProvider.autoDispose
    .family<List<BusRouteModel>, String>((ref, districtId) async {
  if (districtId.isEmpty) return [];
  final repo = ref.watch(busRouteRepositoryProvider);
  return repo.getRoutes(districtId);
});

/// autoDispose: см. комментарий у busRoutesProvider — та же причина.
final busRouteDetailsProvider = FutureProvider.autoDispose
    .family<BusRouteModel?, String>((ref, routeId) async {
  final repo = ref.watch(busRouteRepositoryProvider);
  return repo.getRouteById(routeId);
});
