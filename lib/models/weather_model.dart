import 'package:equatable/equatable.dart';

/// Текущая погода по координатам района (Open-Meteo, current weather).
/// weatherCode — код по таблице WMO (см. weather_code_info.dart для
/// перевода в текст/иконку на русском).
class WeatherModel extends Equatable {
  final double temperature;
  final int weatherCode;

  const WeatherModel({
    required this.temperature,
    required this.weatherCode,
  });

  factory WeatherModel.fromOpenMeteo(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    return WeatherModel(
      temperature: (current['temperature_2m'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
    );
  }

  @override
  List<Object?> get props => [temperature, weatherCode];
}
