import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/vacancy_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';

class VacancyDetailsScreen extends ConsumerWidget {
  final String vacancyId;

  const VacancyDetailsScreen({super.key, required this.vacancyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vacancyAsync = ref.watch(vacancyDetailsProvider(vacancyId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
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
                Text(vacancy.title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  vacancy.company,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
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
                Text(vacancy.description, style: Theme.of(context).textTheme.bodyLarge),
                if (vacancy.contactPhone != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Контакт: ${vacancy.contactPhone}',
                    style: Theme.of(context).textTheme.titleMedium,
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
