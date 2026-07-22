import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Кнопка выбора срока платного размещения с ценой — общий вид для заявки
/// на баннер и на платное продвижение объявления (push всем в районе).
class DurationPriceOption extends StatelessWidget {
  final int days;
  final int price;
  final bool isSelected;
  final VoidCallback onTap;

  const DurationPriceOption({
    super.key,
    required this.days,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryContainer(context)
              : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? AppTheme.primaryBlue : AppTheme.divider(context),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$days дн.',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isSelected
                    ? AppTheme.onPrimaryContainer(context)
                    : AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$price ₽',
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? AppTheme.onPrimaryContainer(context)
                    : AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
