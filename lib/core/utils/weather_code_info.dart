import 'package:flutter/material.dart';

/// Перевод кода погоды WMO (его отдаёт Open-Meteo в поле weather_code) в
/// человекочитаемое описание на русском и иконку. Полная таблица кодов
/// избыточна для компактного виджета на главном экране — коды сгруппированы
/// в укрупнённые категории (морось/дождь/ливень — просто "Дождь" и т.п.).
/// https://open-meteo.com/en/docs — раздел WMO Weather interpretation codes.
class WeatherCodeInfo {
  final String label;
  final IconData icon;

  const WeatherCodeInfo(this.label, this.icon);
}

WeatherCodeInfo weatherCodeInfo(int code) {
  if (code == 0) return const WeatherCodeInfo('Ясно', Icons.wb_sunny_rounded);
  if (code == 1 || code == 2) {
    return const WeatherCodeInfo('Малооблачно', Icons.wb_cloudy_rounded);
  }
  if (code == 3) return const WeatherCodeInfo('Облачно', Icons.cloud_rounded);
  if (code == 45 || code == 48) {
    return const WeatherCodeInfo('Туман', Icons.foggy);
  }
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
    return const WeatherCodeInfo('Дождь', Icons.water_drop_rounded);
  }
  if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
    return const WeatherCodeInfo('Снег', Icons.ac_unit_rounded);
  }
  if (code >= 95) {
    return const WeatherCodeInfo('Гроза', Icons.thunderstorm_rounded);
  }
  return const WeatherCodeInfo(
      'Переменная облачность', Icons.cloud_queue_rounded);
}
