import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/district_provider.dart';
import '../../providers/feedback_provider.dart';
import '../../services/fcm_service.dart';
import '../../services/local_storage_service.dart';

/// Экран обращения в поддержку — вопросы по сотрудничеству, работе
/// приложения, пожелания. Подаётся без входа, как и другие заявки
/// (см. PostVacancyScreen), но в отличие от них ведёт не к оплате, а к
/// ответу супер-админа: после отправки устройство подписывается на
/// персональный push-topic (см. FcmService.subscribeToFeedbackReply), а
/// id обращения сохраняется локально, чтобы ответ можно было увидеть в
/// "Мои обращения" даже если push не дошёл (устройство сменилось, и т.п.).
class SendFeedbackScreen extends ConsumerStatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  ConsumerState<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends ConsumerState<SendFeedbackScreen> {
  final _messageController = TextEditingController();
  final _contactController = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _messageController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.accentRed),
    );
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    final contact = _contactController.text.trim();

    if (message.isEmpty) {
      _showError('Опишите вопрос или пожелание');
      return;
    }

    final district = ref.read(selectedDistrictProvider);
    final districtId = district.id ?? '';

    setState(() => _isSubmitting = true);
    try {
      final id = await ref.read(feedbackRepositoryProvider).submitFeedback(
            message: message,
            contact: contact.isEmpty ? null : contact,
            districtId: districtId,
            districtName: district.name ?? '',
          );

      await FcmService().subscribeToFeedbackReply(id);
      await LocalStorageService().saveMyFeedbackId(id);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Обратная связь'),
        actions: [
          TextButton(
            onPressed: () => context.push('/my-feedback'),
            child: const Text('Мои обращения'),
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
            'Вопросы по сотрудничеству, работе приложения, ошибки, пожелания — пишите сюда. '
            'Обращение видит только супер-админ, ответ придёт push-уведомлением в приложение.',
            style:
                TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 20),
          Text('Сообщение', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 6,
            decoration: const InputDecoration(
                hintText: 'Опишите вопрос или предложение подробно'),
          ),
          const SizedBox(height: 20),
          Text('Контакт для связи (необязательно)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _contactController,
            decoration: const InputDecoration(
                hintText: 'Телефон или email, если push не дойдёт'),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? 'Отправка...' : 'Отправить'),
            ),
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
            'Ответ придёт push-уведомлением. Посмотреть статус и ответ можно в разделе '
            '"Мои обращения".',
            style:
                TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
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
