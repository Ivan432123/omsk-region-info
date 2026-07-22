import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/district_coordinates.dart';
import '../models/weather_model.dart';
import '../repositories/weather_repository.dart';

final weatherRepositoryProvider = Provider((ref) => WeatherRepository());

/// null, если для района нет координат (см. district_coordinates.dart) или
/// запрос не удался (нет сети и т.п.) — в обоих случаях виджет погоды на
/// Главной просто не рисуется, без сообщения об ошибке: это необязательный
/// вспомогательный блок, а не ключевой контент.
final weatherProvider =
    FutureProvider.family<WeatherModel?, String>((ref, districtId) async {
  final coords = districtCoordinates[districtId];
  if (coords == null) return null;

  final repo = ref.watch(weatherRepositoryProvider);
  try {
    return await repo.getCurrentWeather(coords.$1, coords.$2);
  } catch (_) {
    return null;
  }
});
