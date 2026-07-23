import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/input_sanitizer.dart';
import '../../providers/district_provider.dart';
import '../../providers/feedback_request_provider.dart';
import '../../services/fcm_service.dart';
import '../../services/local_storage_service.dart';

/// Экран отправки обращения к супер-администратору (вопросы по
/// сотрудничеству, работе приложения, пожелания) — по образцу формы заявки
/// на вакансию (см. PostVacancyScreen), но без оплаты: сразу после
/// отправки устройство подписывается на персональную push-тему (см.
/// FcmService.subscribeToFeedbackTopic), чтобы получить ответ супер-админа.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _messageController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _messageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.accentRed),
    );
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    final phone = _phoneController.text.trim();

    if (message.isEmpty) {
      _showError('Опишите ваш вопрос или пожелание');
      return;
    }
    if (phone.isNotEmpty && !InputSanitizer.isValidPhone(phone)) {
      _showError(
          'Проверьте номер телефона — укажите его вместе с кодом города');
      return;
    }

    final districtId = ref.read(selectedDistrictProvider).id;
    if (districtId == null || districtId.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final storage = LocalStorageService();
      final deviceId = await storage.getOrCreateDeviceId();

      final id =
          await ref.read(feedbackRequestRepositoryProvider).submitRequest(
                message: message,
                phone: phone.isEmpty ? null : phone,
                districtId: districtId,
                deviceId: deviceId,
              );

      await FcmService().subscribeToFeedbackTopic(deviceId);
      await storage.saveMyFeedbackRequest({
        'id': id,
        'message': message,
        'createdAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      _showError('Не удалось отправить обращение, попробуйте ещё раз');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadFeedback = ref.watch(unreadFeedbackRepliesCountProvider).value ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Обратная связь'),
        actions: [
          TextButton(
            onPressed: () async {
              await context.push('/my-feedback-requests');
              ref.invalidate(unreadFeedbackRepliesCountProvider);
            },
            child: Badge(
              isLabelVisible: unreadFeedback > 0,
              label: Text('$unreadFeedback'),
              backgroundColor: AppTheme.accentRed,
              child: const Text('Мои обращения'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _submitted ? _buildSuccess() : _buildForm(),
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
            'Вопросы по сотрудничеству, работе приложения или пожелания — '
            'напишите прямо здесь, обращение попадёт супер-администратору.',
            style:
                TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 20),
          Text('Ваше обращение',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 6,
            decoration:
                const InputDecoration(hintText: 'Опишите вопрос или пожелание'),
          ),
          const SizedBox(height: 20),
          Text('Телефон для связи (необязательно)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '79135551234'),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? 'Отправка...' : 'Отправить'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ответ супер-администратора придёт push-уведомлением и будет виден '
            'в разделе "Мои обращения".',
            style:
                TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppTheme.success, size: 64),
          const SizedBox(height: 16),
          Text(
            'Обращение отправлено',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Ответ придёт push-уведомлением и будет доступен в разделе '
            '"Мои обращения".',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
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
