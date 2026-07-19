import 'package:intl/intl.dart';

/// Форматирование даты/времени в русском формате: dd.MM.yyyy, 24-часовой формат.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'ru_RU');
  static final DateFormat _dateTimeFormat = DateFormat('dd.MM.yyyy, HH:mm', 'ru_RU');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'ru_RU');

  static String formatDate(DateTime date) => _dateFormat.format(date);

  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Относительное время для уведомлений: "Только что", "5 мин назад", "Вчера" и т.д.
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Только что';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин назад';
    if (diff.inHours < 24) return '${diff.inHours} ч назад';
    if (diff.inDays == 1) return 'Вчера';
    if (diff.inDays < 7) return '${diff.inDays} дн назад';
    return formatDate(date);
  }
}

/// Форматирование телефона в формат +7 (XXX) XXX-XX-XX
class PhoneFormatter {
  PhoneFormatter._();

  static String format(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 11) return rawPhone;

    final normalized = digits.startsWith('8')
        ? '7${digits.substring(1)}'
        : digits;

    if (normalized.length != 11) return rawPhone;

    final code = normalized.substring(1, 4);
    final part1 = normalized.substring(4, 7);
    final part2 = normalized.substring(7, 9);
    final part3 = normalized.substring(9, 11);

    return '+7 ($code) $part1-$part2-$part3';
  }

  /// Приводит к чистому виду для звонка через url_launcher (tel:).
  /// Короткие местные номера (например, диспетчер такси на 5-6 цифр, без
  /// кода города) набираются как есть — код страны +7 добавляется только
  /// к полноценным российским номерам из 10-11 цифр, иначе он их портит.
  static String toDialFormat(String rawPhone) {
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10) {
      return digits;
    }
    if (digits.startsWith('8') && digits.length == 11) {
      return '+7${digits.substring(1)}';
    }
    if (digits.startsWith('7') && digits.length == 11) {
      return '+$digits';
    }
    return '+7$digits';
  }
}
