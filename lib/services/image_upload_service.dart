import 'dart:convert';
import 'package:http/http.dart' as http;

/// Загрузка изображений в Cloudinary — тот же облачный аккаунт и unsigned-
/// пресет ('my_preset', облако 'agidf3gy'), которым уже пользуется
/// админ-панель (docs/index.html) для фото организаций/новостей/баннеров.
/// Единое хранилище изображений для всего проекта: не важно, загружено
/// фото из приложения (например, рекламодателем при подаче заявки на
/// баннер) или из веб-панели — URL одного формата и в одном облаке.
class ImageUploadService {
  static const String _cloudName = 'agidf3gy';
  static const String _uploadPreset = 'my_preset';

  /// Загружает файл по [path] и возвращает публичный URL (secure_url).
  /// Бросает исключение при сетевой ошибке или неуспешном ответе — вызывающий
  /// код должен показать пользователю понятную ошибку и не терять состояние.
  Future<String> uploadImage(String path) async {
    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', path));

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Cloudinary вернул ошибку (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['secure_url'] as String?;
    if (url == null) {
      throw Exception('Cloudinary не вернул ссылку на загруженное фото');
    }
    return url;
  }
}
