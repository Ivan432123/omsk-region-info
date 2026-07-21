import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/organization_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/organizations/organization_card.dart';

class BookmarkedOrganizationsScreen extends ConsumerWidget {
  const BookmarkedOrganizationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkedOrganizationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Мои закладки')),
      body: bookmarksAsync.when(
        loading: () => const LoadingListWidget(),
        error: (_, __) => EmptyStateWidget.error(
          onRetry: () => ref.invalidate(bookmarkedOrganizationsProvider),
        ),
        data: (organizations) => organizations.isEmpty
            ? const EmptyStateWidget.noBookmarks()
            : RefreshIndicator(
                color: AppTheme.primaryBlue,
                onRefresh: () async =>
                    ref.invalidate(bookmarkedOrganizationsProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: organizations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final org = organizations[index];
                    return OrganizationCard(
                      organization: org,
                      onTap: () => context.push('/organizations/${org.id}'),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
