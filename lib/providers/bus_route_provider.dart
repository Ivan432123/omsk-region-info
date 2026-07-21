import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bus_route_model.dart';
import '../repositories/bus_route_repository.dart';

final busRouteRepositoryProvider = Provider((ref) => BusRouteRepository());

/// Маршруты автобусов выбранного района.
final busRoutesProvider =
    FutureProvider.family<List<BusRouteModel>, String>((ref, districtId) async {
  if (districtId.isEmpty) return [];
  final repo = ref.watch(busRouteRepositoryProvider);
  return repo.getRoutes(districtId);
});

final busRouteDetailsProvider =
    FutureProvider.family<BusRouteModel?, String>((ref, routeId) async {
  final repo = ref.watch(busRouteRepositoryProvider);
  return repo.getRouteById(routeId);
});
