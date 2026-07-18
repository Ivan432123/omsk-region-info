import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vacancy_model.dart';

class VacancyCard extends StatelessWidget {
  final VacancyModel vacancy;
  final VoidCallback onTap;

  const VacancyCard({super.key, required this.vacancy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vacancy.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              vacancy.company,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            if (vacancy.salary != null) ...[
              const SizedBox(height: 8),
              Text(
                vacancy.salary!,
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
