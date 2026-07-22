import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/payment_info.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/input_sanitizer.dart';
import '../../providers/district_provider.dart';
import '../../providers/feature_flags_provider.dart';
import '../../providers/vacancy_request_provider.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/common/empty_state_widget.dart';

/// Экран заявки работодателя на публикацию вакансии, по образцу формы
/// заявки на баннер (см. PostBannerScreen) — подаётся без входа в
/// приложение, оплата вручную через СБП, администратор сверяет поступление
/// и публикует вакансию через веб-панель. В отличие от баннеров — цена
/// фиксированная, без выбора срока размещения.
class PostVacancyScreen extends ConsumerStatefulWidget {
  const PostVacancyScreen({super.key});

  @override
  ConsumerState<PostVacancyScreen> createState() => _PostVacancyScreenState();
}

class _PostVacancyScreenState extends ConsumerState<PostVacancyScreen> {
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _salaryController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;
  String? _submittedRequestId;

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.accentRed),
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final company = _companyController.text.trim();
    final description = _descriptionController.text.trim();
    final salary = _salaryController.text.trim();
    final phone = _phoneController.text.trim();

    if (title.isEmpty ||
        company.isEmpty ||
        description.isEmpty ||
        phone.isEmpty) {
      _showError('Заполните должность, компанию, описание и телефон');
      return;
    }
    if (!InputSanitizer.isValidPhone(phone)) {
      _showError(
          'Проверьте номер телефона — укажите его вместе с кодом города');
      return;
    }

    // Перечитываем флаг прямо перед отправкой, а не полагаемся на то, что
    // видели при открытии экрана — супер-админ мог выключить приём заявок,
    // пока работодатель заполнял форму.
    final vacancySubmissionEnabled =
        ref.read(featureFlagsProvider).valueOrNull?.vacancySubmissionEnabled ??
            false;
    if (!vacancySubmissionEnabled) {
      _showError('Приём заявок на вакансии сейчас недоступен');
      return;
    }

    final districtId = ref.read(selectedDistrictProvider).id;
    if (districtId == null || districtId.isEmpty) return;

    const price = VacancyRequestPricing.price;

    setState(() => _isSubmitting = true);
    try {
      final id = await ref.read(vacancyRequestRepositoryProvider).submitRequest(
            title: title,
            company: company,
            description: description,
            salary: salary.isEmpty ? null : salary,
            phone: phone,
            price: price,
            districtId: districtId,
          );

      await LocalStorageService().saveMyVacancyRequest({
        'id': id,
        'title': title,
        'amount': price,
        'paymentPhone': PaymentInfo.phoneNumber,
        'banks': PaymentInfo.banks,
        'createdAt': DateTime.now().toIso8601String(),
      });

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
    final vacancySubmissionEnabled =
        ref.watch(featureFlagsProvider).valueOrNull?.vacancySubmissionEnabled ??
            false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Разместить вакансию'),
        actions: [
          TextButton(
            onPressed: () => context.push('/my-vacancy-requests'),
            child: const Text('Мои заявки'),
          ),
        ],
      ),
      body: SafeArea(
        child: !vacancySubmissionEnabled
            ? const EmptyStateWidget.vacancySubmissionDisabled()
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
            'Вашу вакансию увидят жители района в разделе "Вакансии" после проверки и оплаты.',
            style:
                TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 20),
          Text('Должность', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
                hintText: 'Например: Продавец-консультант'),
          ),
          const SizedBox(height: 20),
          Text('Компания', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _companyController,
            decoration: const InputDecoration(hintText: 'Название организации'),
          ),
          const SizedBox(height: 20),
          Text('Описание', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            decoration: const InputDecoration(
                hintText: 'Обязанности, требования, условия работы'),
          ),
          const SizedBox(height: 20),
          Text('Зарплата (необязательно)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _salaryController,
            decoration: const InputDecoration(hintText: 'от 40 000 руб.'),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Публикация вакансии — ${VacancyRequestPricing.price} ₽, объявление будет видно 30 дней.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
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
            'Вакансия появится в приложении после проверки администратором и поступления оплаты.',
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
    const amount = VacancyRequestPricing.price;
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
                const Text(
                  'Публикация на 30 дней — $amount ₽. Для публикации вакансии:',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                    '1. Переведите $amount ₽ по номеру ${PaymentInfo.phoneNumber} (СБП)'),
                const SizedBox(height: 4),
                Text('Доступно через: ${PaymentInfo.banks.join(', ')}'),
                const SizedBox(height: 6),
                Text(
                    '2. В комментарии к переводу укажите номер заявки: $shortId'),
                const SizedBox(height: 6),
                const Text(
                    '3. Вакансию опубликуют в течение часа после поступления оплаты'),
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
