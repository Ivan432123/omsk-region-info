import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/vacancy_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';

class VacancyDetailsScreen extends ConsumerWidget {
  final String vacancyId;

  const VacancyDetailsScreen({super.key, required this.vacancyId});

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: PhoneFormatter.toDialFormat(phone));
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось совершить звонок'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vacancyAsync = ref.watch(vacancyDetailsProvider(vacancyId));

    return Scaffold(
      appBar: AppBar(),
      body: vacancyAsync.when(
        loading: () => const LoadingIndicatorWidget(),
        error: (_, __) => EmptyStateWidget.error(
          onRetry: () => ref.invalidate(vacancyDetailsProvider(vacancyId)),
        ),
        data: (vacancy) {
          if (vacancy == null) {
            return const EmptyStateWidget(
              icon: Icons.work_outline_rounded,
              title: 'Вакансия не найдена',
              subtitle: 'Возможно, она была удалена',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vacancy.title,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  vacancy.company,
                  style: TextStyle(
                      color: AppTheme.textSecondary(context), fontSize: 15),
                ),
                if (vacancy.salary != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    vacancy.salary!,
                    style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(vacancy.description,
                    style: Theme.of(context).textTheme.bodyLarge),
                if (vacancy.contactPhone != null) ...[
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: () => _call(context, vacancy.contactPhone!),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer(context),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Контактный телефон',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary(context)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  PhoneFormatter.format(vacancy.contactPhone!),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.onPrimaryContainer(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: AppTheme.onPrimaryContainer(context)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
