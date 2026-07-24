import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/district_provider.dart';
import '../../providers/feature_flags_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/announcements/announcement_card.dart';
import '../../widgets/events/event_card.dart';
import '../../widgets/news/news_card.dart';
import '../../widgets/organizations/organization_card.dart';
import '../../widgets/vacancies/vacancy_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final districtId = ref.watch(selectedDistrictProvider).id ?? '';
    final announcementsEnabled = ref
            .watch(featureFlagsProvider)
            .valueOrNull
            ?.announcementsEnabled ??
        false;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          decoration: const InputDecoration(
            hintText: 'Поиск по новостям, организациям...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: _query.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Начните печатать, чтобы найти новости, организации, вакансии, объявления или события в вашем районе',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary(context)),
                ),
              ),
            )
          : Consumer(
              builder: (context, ref, _) {
                final resultsAsync = ref.watch(
                  searchResultsProvider(
                      (districtId: districtId, query: _query)),
                );
                return resultsAsync.when(
                  loading: () => Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryBlueText(context))),
                  error: (_, __) => Center(
                    child: Text('Не удалось выполнить поиск',
                        style:
                            TextStyle(color: AppTheme.textSecondary(context))),
                  ),
                  data: (results) {
                    final hasVisibleResults = results.news.isNotEmpty ||
                        results.organizations.isNotEmpty ||
                        results.vacancies.isNotEmpty ||
                        (announcementsEnabled &&
                            results.announcements.isNotEmpty) ||
                        results.events.isNotEmpty;
                    if (!hasVisibleResults) {
                      return Center(
                        child: Text(
                          'Ничего не найдено',
                          style:
                              TextStyle(color: AppTheme.textSecondary(context)),
                        ),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (results.news.isNotEmpty)
                          ..._section(
                            context,
                            'Новости',
                            results.news
                                .map((n) => NewsCard(
                                      news: n,
                                      heroTag: 'news_${n.id}',
                                      onTap: () =>
                                          context.push('/news/${n.id}'),
                                    ))
                                .toList(),
                          ),
                        if (results.organizations.isNotEmpty)
                          ..._section(
                            context,
                            'Организации',
                            results.organizations
                                .map((o) => OrganizationCard(
                                      organization: o,
                                      onTap: () => context
                                          .push('/organizations/${o.id}'),
                                    ))
                                .toList(),
                          ),
                        if (results.vacancies.isNotEmpty)
                          ..._section(
                            context,
                            'Вакансии',
                            results.vacancies
                                .map((v) => VacancyCard(
                                      vacancy: v,
                                      onTap: () =>
                                          context.push('/vacancies/${v.id}'),
                                    ))
                                .toList(),
                          ),
                        if (announcementsEnabled &&
                            results.announcements.isNotEmpty)
                          ..._section(
                            context,
                            'Объявления',
                            results.announcements
                                .map((a) => AnnouncementCard(
                                      announcement: a,
                                      onTap: () => context
                                          .push('/announcements/${a.id}'),
                                    ))
                                .toList(),
                          ),
                        if (results.events.isNotEmpty)
                          ..._section(
                            context,
                            'Афиша',
                            results.events
                                .map((e) => EventCard(
                                      event: e,
                                      onTap: () =>
                                          context.push('/events/${e.id}'),
                                    ))
                                .toList(),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  List<Widget> _section(
      BuildContext context, String title, List<Widget> cards) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 6),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      ...cards.map(
          (c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)),
      const SizedBox(height: 12),
    ];
  }
}
