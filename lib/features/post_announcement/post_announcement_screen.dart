import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/payment_info.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/input_sanitizer.dart';
import '../../providers/ad_request_provider.dart';
import '../../providers/district_provider.dart';
import '../../providers/feature_flags_provider.dart';
import '../../repositories/announcement_repository.dart';
import '../../services/image_upload_service.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/common/duration_price_option.dart';
import '../../widgets/common/empty_state_widget.dart';

/// Не больше 5 фото на объявление — достаточно, чтобы показать товар/услугу
/// с разных сторон, и не даёт форме превратиться в фотогалерею.
const int _maxImages = 5;

class PostAnnouncementScreen extends ConsumerStatefulWidget {
  const PostAnnouncementScreen({super.key});

  @override
  ConsumerState<PostAnnouncementScreen> createState() =>
      _PostAnnouncementScreenState();
}

class _PostAnnouncementScreenState
    extends ConsumerState<PostAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _wantsPush = false;
  int _selectedDuration = 7;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  final List<String> _images = [];
  String? _submittedRequestId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Выбирает фото из галереи и загружает его в Cloudinary (тот же
  /// облачный аккаунт, что и у веб-панели) — по образцу PostBannerScreen.
  Future<void> _pickAndUploadImage() async {
    if (_images.length >= _maxImages) return;
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final url = await ImageUploadService().uploadImage(file.path);
      if (mounted) setState(() => _images.add(url));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Не удалось загрузить фото — проверьте подключение к интернету'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _removeImage(String url) {
    setState(() => _images.remove(url));
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final phone = _phoneController.text.trim();

    if (title.isEmpty || description.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните заголовок, текст объявления и телефон'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    if (!InputSanitizer.isValidPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Проверьте номер телефона — укажите его вместе с кодом города'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    final districtId = ref.read(selectedDistrictProvider).id;
    if (districtId == null || districtId.isEmpty) return;

    // Опция могла быть выключена супер-админом уже после того, как
    // пользователь отметил чекбокс в этой сессии, — перепроверяем флаг
    // прямо перед отправкой, а не доверяем состоянию виджета.
    final paidPushEnabled =
        ref.read(featureFlagsProvider).valueOrNull?.paidPushEnabled ?? false;
    if (!paidPushEnabled) _wantsPush = false;

    final price = _wantsPush
        ? AnnouncementPromotionPricing.priceFor(_selectedDuration)
        : null;

    setState(() => _isSubmitting = true);
    try {
      final id = await ref.read(adRequestRepositoryProvider).submitRequest(
            title: title,
            description: description,
            phone: phone,
            wantsPush: _wantsPush,
            districtId: districtId,
            images: _images,
            durationDays: _wantsPush ? _selectedDuration : null,
            price: price,
          );

      await LocalStorageService().saveMyAdRequest({
        'id': id,
        'title': title,
        'wantsPush': _wantsPush,
        'durationDays': _selectedDuration,
        'amount': price,
        'paymentPhone': PaymentInfo.phoneNumber,
        'banks': PaymentInfo.banks,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      setState(() => _submittedRequestId = id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось отправить заявку, попробуйте ещё раз'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
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
    final announcementsEnabled = ref
            .watch(featureFlagsProvider)
            .valueOrNull
            ?.announcementsEnabled ??
        false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Разместить объявление'),
        actions: [
          if (announcementsEnabled)
            TextButton(
              onPressed: () => context.push('/my-ad-requests'),
              child: const Text('Мои заявки'),
            ),
        ],
      ),
      body: SafeArea(
        child: !announcementsEnabled
            ? const EmptyStateWidget.announcementsSectionDisabled()
            : (_submittedRequestId != null ? _buildSuccess() : _buildForm()),
      ),
    );
  }

  Widget _buildForm() {
    final paidPushEnabled =
        ref.watch(featureFlagsProvider).valueOrNull?.paidPushEnabled ?? false;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FreeAnnouncementNotice(paidPushEnabled: paidPushEnabled),
          const SizedBox(height: 20),
          Text('Заголовок', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
                hintText: 'Например: Продам детский велосипед'),
          ),
          const SizedBox(height: 20),
          Text('Текст объявления',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: const InputDecoration(
                hintText: 'Подробности, цена, состояние...'),
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
          Text('Фото (необязательно)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildPhotosPicker(),
          if (paidPushEnabled) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _wantsPush,
                        onChanged: (v) =>
                            setState(() => _wantsPush = v ?? false),
                        activeColor: AppTheme.primaryBlue,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _wantsPush = !_wantsPush),
                          child: Text(
                            'Хочу, чтобы объявление увидели все в районе, у кого установлено приложение (от ${AnnouncementPromotionPricing.priceByDurationDays.values.first} ₽)',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.onPrimaryContainer(context)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_wantsPush) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: AnnouncementPromotionPricing
                          .priceByDurationDays.keys
                          .map(
                            (days) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: DurationPriceOption(
                                  days: days,
                                  price: AnnouncementPromotionPricing
                                      .priceByDurationDays[days]!,
                                  isSelected: _selectedDuration == days,
                                  onTap: () =>
                                      setState(() => _selectedDuration = days),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
            'Объявление появится в приложении после проверки администратором района '
            'и будет показано ${AnnouncementRepository.maxAge.inDays} дней с момента публикации.',
            style:
                TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_images.isNotEmpty)
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final url = _images[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            width: 90,
                            height: 90,
                            color: AppTheme.surfaceVariant(context)),
                        errorWidget: (_, __, ___) => Container(
                          width: 90,
                          height: 90,
                          color: AppTheme.surfaceVariant(context),
                          child: Icon(Icons.image_not_supported_outlined,
                              color: AppTheme.textSecondary(context)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => _removeImage(url),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        if (_images.isNotEmpty) const SizedBox(height: 8),
        if (_images.length < _maxImages)
          OutlinedButton.icon(
            onPressed: _isUploadingImage ? null : _pickAndUploadImage,
            icon: _isUploadingImage
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_a_photo_outlined, size: 18),
            label: Text(_isUploadingImage
                ? 'Загрузка...'
                : (_images.isEmpty ? 'Добавить фото' : 'Добавить ещё фото')),
          ),
      ],
    );
  }

  Widget _buildSuccess() {
    final shortId = _submittedRequestId!
        .substring(0, _submittedRequestId!.length.clamp(0, 8));
    final amount = _wantsPush
        ? AnnouncementPromotionPricing.priceFor(_selectedDuration)
        : 0;
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
          if (_wantsPush) ...[
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
                    'Рассылка на $_selectedDuration дней всем в районе:',
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
                      '3. Объявление опубликуют в течение часа после поступления оплаты'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Реквизиты можно посмотреть снова в разделе "Мои заявки".',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary(context)),
              textAlign: TextAlign.center,
            ),
          ] else
            Text(
              'Объявление опубликуют после проверки администратором, обычно в течение дня, '
              'и оно будет показано ${AnnouncementRepository.maxAge.inDays} дней с момента публикации.',
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

/// Предупреждение о назначении раздела — показано НАД формой, до того как
/// житель начнёт её заполнять, чтобы коммерческие объявления не подавались
/// как обычные бесплатные. Текст зависит от paidPushEnabled: если платное
/// продвижение сейчас включено — указываем на него как на способ разместить
/// рекламу; если выключено — только общее уточнение, без ссылки на функцию,
/// которой сейчас всё равно нельзя воспользоваться.
class _FreeAnnouncementNotice extends StatelessWidget {
  final bool paidPushEnabled;

  const _FreeAnnouncementNotice({required this.paidPushEnabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppTheme.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              paidPushEnabled
                  ? 'Раздел — для личных бесплатных объявлений жителей (продать, отдать, куплю). '
                      'Коммерческую и рекламную информацию размещать здесь нельзя — для неё есть '
                      'платное продвижение с рассылкой по району (доступно ниже, за отдельную плату).'
                  : 'Раздел — для личных бесплатных объявлений жителей (продать, отдать, куплю). '
                      'Коммерческую и рекламную информацию размещать здесь нельзя.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
