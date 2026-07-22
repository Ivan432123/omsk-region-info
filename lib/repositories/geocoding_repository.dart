import 'dart:convert';
import 'package:http/http.dart' as http;

/// Геокодирование через Open-Meteo Geocoding API (тот же бесплатный сервис
/// без ключа, что и погода, см. weather_repository.dart) — превращает
/// название района в координаты, чтобы виджет погоды на Главной работал
/// для новых районов сам, без ручного ввода координат при добавлении
/// района в админке.
class GeocodingRepository {
  Future<(double lat, double lon)?> geocode(String query) async {
    final uri = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search'
      '?name=${Uri.encodeQueryComponent(query)}'
      '&count=5&language=ru&format=json',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final results = json['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    // Название района может теоретически совпасть с местом за пределами
    // России (гео-база всемирная) — из нескольких совпадений предпочитаем
    // результат с country_code RU, а не просто первый по релевантности.
    final list = results.cast<Map<String, dynamic>>();
    final best = list.firstWhere(
      (r) => r['country_code'] == 'RU',
      orElse: () => list.first,
    );

    return (
      (best['latitude'] as num).toDouble(),
      (best['longitude'] as num).toDouble(),
    );
  }
}
