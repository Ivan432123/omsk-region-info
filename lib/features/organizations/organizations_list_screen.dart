import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/district_provider.dart';
import '../../providers/organization_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/organizations/organization_card.dart';

class OrganizationsListScreen extends ConsumerStatefulWidget {
  const OrganizationsListScreen({super.key});

  @override
  ConsumerState<OrganizationsListScreen> createState() =>
      _OrganizationsListScreenState();
}

class _OrganizationsListScreenState
    extends ConsumerState<OrganizationsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final districtId = ref.read(selectedDistrictProvider).id ?? '';
      ref.read(organizationListProvider(districtId).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final districtId = ref.watch(selectedDistrictProvider).id ?? '';
    final state = ref.watch(organizationListProvider(districtId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Организации'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_rounded),
            tooltip: 'Мои закладки',
            onPressed: () => context.push('/bookmarks'),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) return const LoadingListWidget();
          if (state.error != null) {
            return EmptyStateWidget.error(
              onRetry: () => ref
                  .read(organizationListProvider(districtId).notifier)
                  .refresh(),
            );
          }
          if (state.items.isEmpty) {
            return const EmptyStateWidget.noOrganizations();
          }

          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: () => ref
                .read(organizationListProvider(districtId).notifier)
                .refresh(),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  );
                }
                final org = state.items[index];
                return OrganizationCard(
                  key: ValueKey(org.id),
                  organization: org,
                  onTap: () => context.push('/organizations/${org.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
