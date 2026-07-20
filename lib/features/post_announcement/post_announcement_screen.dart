import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ad_request_provider.dart';
import '../../providers/district_provider.dart';
import '../../services/local_storage_service.dart';

/// Стоимость платного продвижения (push всем подписчикам района), номер
/// для перевода и банки, к которым он привязан через СБП.
const String _pushPromotionPrice = '350';
const String _paymentPhoneNumber = '+79236885501';
const List<String> _paymentBanks = ['Т-Банк', 'Озон Банк', 'Сбербанк'];

class PostAnnouncementScreen extends ConsumerStatefulWidget {
  const PostAnnouncementScreen({super.key});

  @override
  ConsumerState<PostAnnouncementScreen> createState() => _PostAnnouncementScreenState();
}

class _PostAnnouncementScreenState extends ConsumerState<PostAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _wantsPush = false;
  bool _isSubmitting = false;
  String? _submittedRequestId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
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

    final districtId = ref.read(selectedDistrictProvider).id;
    if (districtId == null || districtId.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final id = await ref.read(adRequestRepositoryProvider).submitRequest(
            title: title,
            description: description,
            phone: phone,
            wantsPush: _wantsPush,
            districtId: districtId,
          );

      await LocalStorageService().saveMyAdRequest({
        'id': id,
        'title': title,
        'wantsPush': _wantsPush,
        'amount': _pushPromotionPrice,
        'paymentPhone': _paymentPhoneNumber,
        'banks': _paymentBanks,
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
      const SnackBar(content: Text('Номер заявки скопирован'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Разместить объявление'),
        actions: [
          TextButton(
            onPressed: () => context.push('/my-ad-requests'),
            child: const Text('Мои заявки'),
          ),
        ],
      ),
      body: SafeArea(
        child: _submittedRequestId != null ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Заголовок', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(hintText: 'Например: Продам детский велосипед'),
          ),
          const SizedBox(height: 20),
          Text('Текст объявления', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: const InputDecoration(hintText: 'Подробности, цена, состояние...'),
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _wantsPush,
                  onChanged: (v) => setState(() => _wantsPush = v ?? false),
                  activeColor: AppTheme.primaryBlue,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _wantsPush = !_wantsPush),
                    child: Text(
                      'Хочу, чтобы объявление увидели все в районе, у кого установлено приложение ($_pushPromotionPrice ₽)',
                      style: const TextStyle(fontSize: 14, color: AppTheme.primaryBlueDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? 'Отправка...' : 'Отправить на проверку'),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Объявление появится в приложении после проверки администратором района.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final shortId = _submittedRequestId!.substring(0, _submittedRequestId!.length.clamp(0, 8));
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 64),
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
              Text('№$shortId', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
                color: AppTheme.surfaceGrey,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Для рассылки объявления всем в районе:',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text('1. Переведите $_pushPromotionPrice ₽ по номеру $_paymentPhoneNumber (СБП)'),
                  const SizedBox(height: 4),
                  Text('Доступно через: ${_paymentBanks.join(', ')}'),
                  const SizedBox(height: 6),
                  Text('2. В комментарии к переводу укажите номер заявки: $shortId'),
                  const SizedBox(height: 6),
                  const Text('3. Объявление опубликуют в течение часа после поступления оплаты'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Реквизиты можно посмотреть снова в разделе "Мои заявки".',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ] else
            const Text(
              'Объявление опубликуют после проверки администратором, обычно в течение дня.',
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
