import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/payment_info.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/input_sanitizer.dart';
import '../../providers/banner_request_provider.dart';
import '../../providers/district_provider.dart';
import '../../providers/feature_flags_provider.dart';
import '../../services/image_upload_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/common/duration_price_option.dart';
import '../../widgets/common/empty_state_widget.dart';

/// Экран заявки рекламодателя на размещение баннера в партнёрской ленте.
/// Подаётся без входа в приложение, по образцу формы объявлений жителей
/// (см. PostAnnouncementScreen) — оплата вручную через СБП, администратор
/// сверяет поступление и публикует баннер через веб-панель.
class PostBannerScreen extends ConsumerStatefulWidget {
  const PostBannerScreen({super.key});

  @override
  ConsumerState<PostBannerScreen> createState() => _PostBannerScreenState();
}

class _PostBannerScreenState extends ConsumerState<PostBannerScreen> {
  final _titleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _targetUrlController = TextEditingController();
  final _phoneController = TextEditingController();
  int _selectedDuration = 7;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  String? _submittedRequestId;

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _targetUrlController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.accentRed),
    );
  }

  /// Выбирает фото из галереи и загружает его в Cloudinary (тот же
  /// облачный аккаунт, что и у веб-панели), подставляя результат в поле
  /// ссылки на изображение — рекламодателю не нужно самому где-то
  /// размещать картинку и искать её URL.
  Future<void> _pickAndUploadImage() async {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final url = await ImageUploadService().uploadImage(file.path);
      if (mounted) setState(() => _imageUrlController.text = url);
    } catch (e) {
      if (mounted) {
        _showError(
            'Не удалось загрузить фото — проверьте подключение к интернету');
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    final targetUrl = _targetUrlController.text.trim();
    final phone = _phoneController.text.trim();

    if (title.isEmpty ||
        imageUrl.isEmpty ||
        targetUrl.isEmpty ||
        phone.isEmpty) {
      _showError(
          'Заполните название, ссылку на изображение, ссылку перехода и телефон');
      return;
    }
    if (!InputSanitizer.isValidUrl(imageUrl)) {
      _showError(
          'Ссылка на изображение должна начинаться с http:// или https://');
      return;
    }
    if (!InputSanitizer.isValidUrl(targetUrl)) {
      _showError('Ссылка перехода должна начинаться с http:// или https://');
      return;
    }
    if (!InputSanitizer.isValidPhone(phone)) {
      _showError(
          'Проверьте номер телефона — укажите его вместе с кодом города');
      return;
    }

    final districtId = ref.read(selectedDistrictProvider).id;
    if (districtId == null || districtId.isEmpty) return;

    final price = BannerPricing.priceFor(_selectedDuration);

    setState(() => _isSubmitting = true);
    try {
      final id = await ref.read(bannerRequestRepositoryProvider).submitRequest(
            title: title,
            imageUrl: imageUrl,
            targetUrl: targetUrl,
            phone: phone,
            durationDays: _selectedDuration,
            price: price,
            districtId: districtId,
          );

      await LocalStorageService().saveMyBannerRequest({
        'id': id,
        'title': title,
        'durationDays': _selectedDuration,
        'amount': price,
        'paymentPhone': PaymentInfo.phoneNumber,
        'banks': PaymentInfo.banks,
        'createdAt': DateTime.now().toIso8601String(),
      });

      unawaited(ref.read(analyticsServiceProvider).logBannerRequestSubmitted());

      if (!mounted) return;
      setState(() => _submittedRequestId = id);
    } catch (e) {
      if (!mounted) return;
      _showError('Не удалось отправить заявку, попробуйте ещё раз');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Номер заявки скопирован'),
          duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bannerSubmissionEnabled =
        ref.watch(featureFlagsProvider).valueOrNull?.bannerSubmissionEnabled ??
            false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Разместить баннер'),
        actions: [
          TextButton(
            onPressed: () => context.push('/my-banner-requests'),
            child: const Text('Мои заявки'),
          ),
        ],
      ),
      body: SafeArea(
        child: !bannerSubmissionEnabled
            ? const EmptyStateWidget.bannerSubmissionDisabled()
            : (_submittedRequestId != null ? _buildSuccess() : _buildForm()),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ваш баннер увидят все жители района на главном экране приложения — в той же ленте, что и другие партнёрские баннеры.',
            style:
                TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 20),
          Text('Название (виден на баннере)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration:
                const InputDecoration(hintText: 'Например: Скидки на шины 20%'),
          ),
          const SizedBox(height: 20),
          Text('Изображение баннера',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          // ValueListenableBuilder, а не onChanged+setState на весь _buildForm:
          // только превью картинки и подпись кнопки зависят от текста ссылки,
          // остальная форма (другие поля, варианты срока размещения) не
          // должна перестраиваться на каждое нажатие клавиши.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _imageUrlController,
            builder: (context, value, _) {
              final imageUrl = value.text;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                                color: AppTheme.surfaceVariant(context)),
                            errorWidget: (_, __, ___) => Container(
                              color: AppTheme.surfaceVariant(context),
                              child: Icon(Icons.image_not_supported_outlined,
                                  color: AppTheme.textSecondary(context)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                      icon: _isUploadingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(_isUploadingImage
                          ? 'Загрузка...'
                          : (imageUrl.isEmpty
                              ? 'Загрузить фото с телефона'
                              : 'Заменить фото')),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _imageUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'или вставьте ссылку на готовое изображение',
            ),
          ),
          const SizedBox(height: 20),
          Text('Ссылка перехода (куда ведёт баннер)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _targetUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(hintText: 'https://...'),
          ),
          const SizedBox(height: 20),
          Text('Ваш телефон', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '79135551234'),
          ),
          const SizedBox(height: 20),
          Text('Срок размещения',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: BannerPricing.priceByDurationDays.keys
                .map(
                  (days) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: DurationPriceOption(
                        days: days,
                        price: BannerPricing.priceByDurationDays[days]!,
                        isSelected: _selectedDuration == days,
                        onTap: () => setState(() => _selectedDuration = days),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child:
                  Text(_isSubmitting ? 'Отправка...' : 'Отправить на проверку'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Баннер появится в приложении после проверки администратором и поступления оплаты.',
            style:
                TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final shortId = _submittedRequestId!
        .substring(0, _submittedRequestId!.length.clamp(0, 8));
    final amount = BannerPricing.priceFor(_selectedDuration);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.success, size: 64),
          const SizedBox(height: 16),
          Text(
            'Заявка отправлена',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('№$shortId',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () => _copyToClipboard(shortId),
                tooltip: 'Скопировать номер заявки',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Размещение на $_selectedDuration дней — $amount ₽. Для публикации баннера:',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                    '1. Переведите $amount ₽ по номеру ${PaymentInfo.phoneNumber} (СБП)'),
                const SizedBox(height: 4),
                Text('Доступно через: ${PaymentInfo.banks.join(', ')}'),
                const SizedBox(height: 6),
                Text(
                    '2. В комментарии к переводу укажите номер заявки: $shortId'),
                const SizedBox(height: 6),
                const Text(
                    '3. Баннер опубликуют в течение часа после поступления оплаты'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Реквизиты можно посмотреть снова в разделе "Мои заявки".',
            style:
                TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Готово'),
            ),
          ),
        ],
      ),
    );
  }
}
