/// Утилиты валидации и очистки пользовательского ввода.
/// Используются в поле поиска и в любых будущих формах (бизнес-кабинет,
/// админ-панель), чтобы исключить некорректные или потенциально опасные
/// данные ещё на клиенте (серверная валидация в Firestore Rules обязательна).
class InputSanitizer {
  InputSanitizer._();

  /// Убирает управляющие символы, HTML-теги и лишние пробелы, ограничивает
  /// длину.
  static String sanitizeSearchQuery(String input, {int maxLength = 100}) {
    final trimmed = input.trim();
    final withoutControlChars =
        trimmed.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    final withoutHtmlTags =
        withoutControlChars.replaceAll(RegExp(r'<[^>]*>'), '');
    if (withoutHtmlTags.length > maxLength) {
      return withoutHtmlTags.substring(0, maxLength);
    }
    return withoutHtmlTags;
  }

  /// Нормализация строки для поиска без учёта регистра (кириллица).
  static String normalizeForSearch(String input) => input.trim().toLowerCase();

  static bool isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == 11;
  }

  static bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.isScheme('HTTP') || uri.isScheme('HTTPS'));
  }
}
