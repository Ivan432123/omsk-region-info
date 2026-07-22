import 'dart:convert';
import 'package:http/http.dart' as http;

/// Геокодирование через Open-Meteo Geocoding API (тот же бесплатный сервис
/// без ключа, что и погода, см. weather_repository.dart) — превращает
/// название населённого пункта в координаты.
class GeocodingRepository {
  /// [requireRegion] — подстрока, которую обязан содержать admin1
  /// найденного результата (регистронезависимо), например "Омск" для
  /// "Омская Область". Без этой проверки одноимённые населённые пункты в
  /// других регионах матчились бы вместо нужного — проверено вручную:
  /// "Одесское" находится и в Омской, и в Калининградской области,
  /// "Таврическое" — сразу в трёх регионах кроме Омской. Если ни один
  /// результат не подходит по региону — считаем, что совпадения нет
  /// (возвращаем null), а не берём первый попавшийся из другого региона.
  Future<(double lat, double lon)?> geocode(
    String query, {
    required String requireRegion,
  }) async {
    final uri = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search'
      '?name=${Uri.encodeQueryComponent(query)}'
      '&count=10&language=ru&format=json',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final results = json['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final needle = requireRegion.toLowerCase();
    final list = results.cast<Map<String, dynamic>>();
    final match = list.cast<Map<String, dynamic>?>().firstWhere(
          (r) =>
              ((r?['admin1'] as String?) ?? '').toLowerCase().contains(needle),
          orElse: () => null,
        );
    if (match == null) return null;

    return (
      (match['latitude'] as num).toDouble(),
      (match['longitude'] as num).toDouble(),
    );
  }
}
