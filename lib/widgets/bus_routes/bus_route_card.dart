import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bus_route_model.dart';

class BusRouteCard extends StatelessWidget {
  final BusRouteModel route;
  final VoidCallback onTap;

  const BusRouteCard({super.key, required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider(context)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer(context),
                shape: BoxShape.circle,
              ),
              child: Text(
                route.routeNumber,
                style: TextStyle(
                  color: AppTheme.onPrimaryContainer(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route.routeName,
                      style: Theme.of(context).textTheme.titleMedium),
                  if (route.departureTimes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Ближайшее отправление: ${route.departureTimes.first}',
                      style: TextStyle(
                          color: AppTheme.textSecondary(context), fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondary(context)),
          ],
        ),
      ),
    );
  }
}
