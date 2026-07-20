import '../models/announcement_model.dart';
import '../models/event_model.dart';
import '../models/news_model.dart';
import '../models/organization_model.dart';
import '../models/vacancy_model.dart';
import '../services/firestore_service.dart';

/// Результаты поиска, сгруппированные по типу контента.
class SearchResults {
  final List<NewsModel> news;
  final List<OrganizationModel> organizations;
  final List<VacancyModel> vacancies;
  final List<AnnouncementModel> announcements;
  final List<EventModel> events;

  const SearchResults({
    this.news = const [],
    this.organizations = const [],
    this.vacancies = const [],
    this.announcements = const [],
    this.events = const [],
  });

  bool get isEmpty =>
      news.isEmpty &&
      organizations.isEmpty &&
      vacancies.isEmpty &&
      announcements.isEmpty &&
      events.isEmpty;
}

/// Простой поиск по всем разделам района без отдельного поискового индекса:
/// забираем все документы района из каждой коллекции (их объём в масштабе
/// одного района небольшой) и фильтруем на клиенте по вхождению текста —
/// без учёта регистра. Такой подход не требует внешнего сервиса поиска и
/// работает мгновенно после первой загрузки списков.
class SearchRepository {
  final FirestoreService _firestoreService;

  SearchRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  String _normalize(String value) => value.toLowerCase().trim();

  Future<SearchResults> search(String districtId, String query) async {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty || districtId.isEmpty) {
      return const SearchResults();
    }

    final results = await Future.wait([
      _firestoreService
          .collection('news')
          .where('district', isEqualTo: districtId)
          .get(),
      _firestoreService
          .collection('organizations')
          .where('district', isEqualTo: districtId)
          .get(),
      _firestoreService
          .collection('vacancies')
          .where('district', isEqualTo: districtId)
          .get(),
      _firestoreService
          .collection('announcements')
          .where('district', isEqualTo: districtId)
          .get(),
      _firestoreService
          .collection('events')
          .where('district', isEqualTo: districtId)
          .get(),
    ]);

    final news = results[0]
        .docs
        .map(NewsModel.fromFirestore)
        .where((n) =>
            _normalize(n.title).contains(normalizedQuery) ||
            _normalize(n.description).contains(normalizedQuery))
        .toList();

    final organizations = results[1]
        .docs
        .map(OrganizationModel.fromFirestore)
        .where((o) =>
            _normalize(o.name).contains(normalizedQuery) ||
            _normalize(o.category).contains(normalizedQuery))
        .toList();

    final vacancies = results[2]
        .docs
        .map(VacancyModel.fromFirestore)
        .where((v) =>
            _normalize(v.title).contains(normalizedQuery) ||
            _normalize(v.company).contains(normalizedQuery))
        .toList();

    final announcements = results[3]
        .docs
        .map(AnnouncementModel.fromFirestore)
        .where((a) =>
            _normalize(a.title).contains(normalizedQuery) ||
            _normalize(a.description).contains(normalizedQuery))
        .toList();

    final events = results[4]
        .docs
        .map(EventModel.fromFirestore)
        .where((e) => _normalize(e.title).contains(normalizedQuery))
        .toList();

    return SearchResults(
      news: news,
      organizations: organizations,
      vacancies: vacancies,
      announcements: announcements,
      events: events,
    );
  }
}
