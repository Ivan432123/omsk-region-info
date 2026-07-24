import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/organization_icon_helper.dart';
import '../../models/organization_model.dart';

class OrganizationCard extends StatelessWidget {
  final OrganizationModel organization;
  final VoidCallback onTap;

  const OrganizationCard(
      {super.key, required this.organization, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final icon = OrganizationIconHelper.iconFor(organization.category);
    final color = OrganizationIconHelper.colorFor(context, organization.category);
    final background =
        OrganizationIconHelper.backgroundFor(context, organization.category);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider(context)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Hero(
              tag: 'org_${organization.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: organization.logoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: organization.logoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              color: AppTheme.surfaceVariant(context)),
                          errorWidget: (_, __, ___) => Container(
                            color: background,
                            child: Icon(icon, color: color),
                          ),
                        )
                      : Container(
                          color: background,
                          child: Icon(icon, color: color),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    organization.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    organization.category,
                    style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.call_outlined,
                          size: 14, color: AppTheme.textSecondary(context)),
                      const SizedBox(width: 4),
                      Text(
                        PhoneFormatter.format(organization.phone),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
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
