import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/district_geocoding_names.dart';
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
/// Координаты определяются геокодированием названия РАЙЦЕНТРА (см.
/// district_geocoding_names.dart) — по официальному названию района вида
/// "Шербакульский район" Open-Meteo не находит вообще ничего (проверено).
/// Для района без записи в этом списке (новый район вне известных 32-х)
/// используется best-effort фолбэк — название района с обрезанным
/// суффиксом " район"; он реже находится (см. комментарий в
/// district_geocoding_names.dart), но безопаснее ничего не показать, чем
/// не пытаться вовсе.
///
/// Результат кэшируется на устройстве навсегда (см.
/// LocalStorageService.cacheDistrictCoordinates), чтобы не дёргать
/// geocoding API при каждом обновлении Главной.
final weatherProvider =
    FutureProvider.family<WeatherModel?, WeatherQuery>((ref, query) async {
  final storage = LocalStorageService();
  var coords = await storage.getCachedDistrictCoordinates(query.districtId);

  if (coords == null) {
    final geocodeQuery = districtGeocodingNames[query.districtId] ??
        query.districtName.replaceAll(RegExp(r'\s*район\s*$'), '').trim();
    if (geocodeQuery.isEmpty) return null;

    final geocoder = ref.watch(geocodingRepositoryProvider);
    try {
      coords = await geocoder.geocode(geocodeQuery, requireRegion: 'Омск');
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
