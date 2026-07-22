import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weather_model.dart';
import '../repositories/geocoding_repository.dart';
import '../repositories/weather_repository.dart';
import '../services/local_storage_service.dart';

final weatherRepositoryProvider = Provider((ref) => WeatherRepository());
final geocodingRepositoryProvider = Provider((ref) => GeocodingRepository());

typedef WeatherQuery = ({String districtId, String districtName});

/// null, если координаты района определить не удалось (геокодирование не
/// нашло совпадение) или сам запрос погоды не удался (нет сети и т.п.) — в
/// обоих случаях виджет погоды на Главной просто не рисуется, без ошибки:
/// это необязательный вспомогательный блок, а не ключевой контент.
///
/// Координаты района определяются геокодированием его названия (Open-Meteo
/// Geocoding — тот же бесплатный сервис без ключа, что и сама погода) при
/// первом обращении и кэшируются на устройстве навсегда (см.
/// LocalStorageService.cacheDistrictCoordinates) — поэтому виджет погоды
/// сразу работает и для новых районов, добавленных через админку, без
/// правок кода и релиза приложения.
final weatherProvider =
    FutureProvider.family<WeatherModel?, WeatherQuery>((ref, query) async {
  final storage = LocalStorageService();
  var coords = await storage.getCachedDistrictCoordinates(query.districtId);

  if (coords == null) {
    final geocoder = ref.watch(geocodingRepositoryProvider);
    try {
      coords = await geocoder.geocode(query.districtName);
    } catch (_) {
      coords = null;
    }
    if (coords == null) return null;
    await storage.cacheDistrictCoordinates(
        query.districtId, coords.$1, coords.$2);
  }

  final repo = ref.watch(weatherRepositoryProvider);
  try {
    return await repo.getCurrentWeather(coords.$1, coords.$2);
  } catch (_) {
    return null;
  }
});
