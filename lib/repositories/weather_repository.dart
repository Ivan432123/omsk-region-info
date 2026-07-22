import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

/// Open-Meteo — бесплатный погодный API без ключа и лимитов на некоммерческое
/// использование. https://open-meteo.com
class WeatherRepository {
  Future<WeatherModel?> getCurrentWeather(double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,weather_code'
      '&timezone=auto',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return WeatherModel.fromOpenMeteo(json);
  }
}
