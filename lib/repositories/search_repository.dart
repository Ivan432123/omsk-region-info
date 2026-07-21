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

/// Весь контент района, забранный для поиска — до фильтрации по запросу.
class SearchableDistrictContent {
  final List<NewsModel> news;
  final List<OrganizationModel> organizations;
  final List<VacancyModel> vacancies;
  final List<AnnouncementModel> announcements;
  final List<EventModel> events;

  const SearchableDistrictContent({
    this.news = const [],
    this.organizations = const [],
    this.vacancies = const [],
    this.announcements = const [],
    this.events = const [],
  });
}

/// Простой поиск по всем разделам района без отдельного поискового индекса:
/// забираем все документы района из каждой коллекции (их объём в масштабе
/// одного района небольшой) и фильтруем на клиенте по вхождению текста —
/// без учёта регистра. Такой подход не требует внешнего сервиса поиска и
/// работает мгновенно после первой загрузки списков.
///
/// Загрузка контента (fetchDistrictContent) и фильтрация по запросу (filter)
/// разделены намеренно: контент района не зависит от текста запроса, поэтому
/// провайдер (см. search_provider.dart) кэширует его по districtId и
/// перезапрашивает Firestore только при смене района — набор из 5 полных
/// .get() не повторяется на каждый введённый символ.
class SearchRepository {
  final FirestoreService _firestoreService;

  SearchRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  static String normalize(String value) => value.toLowerCase().trim();

  Future<SearchableDistrictContent> fetchDistrictContent(
      String districtId) async {
    if (districtId.isEmpty) return const SearchableDistrictContent();

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

    return SearchableDistrictContent(
      news: results[0].docs.map(NewsModel.fromFirestore).toList(),
      organizations:
          results[1].docs.map(OrganizationModel.fromFirestore).toList(),
      vacancies: results[2].docs.map(VacancyModel.fromFirestore).toList(),
      announcements:
          results[3].docs.map(AnnouncementModel.fromFirestore).toList(),
      events: results[4].docs.map(EventModel.fromFirestore).toList(),
    );
  }

  SearchResults filter(SearchableDistrictContent content, String query) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return const SearchResults();

    return SearchResults(
      news: content.news
          .where((n) =>
              normalize(n.title).contains(normalizedQuery) ||
              normalize(n.description).contains(normalizedQuery))
          .toList(),
      organizations: content.organizations
          .where((o) =>
              normalize(o.name).contains(normalizedQuery) ||
              normalize(o.category).contains(normalizedQuery))
          .toList(),
      vacancies: content.vacancies
          .where((v) =>
              normalize(v.title).contains(normalizedQuery) ||
              normalize(v.company).contains(normalizedQuery))
          .toList(),
      announcements: content.announcements
          .where((a) =>
              normalize(a.title).contains(normalizedQuery) ||
              normalize(a.description).contains(normalizedQuery))
          .toList(),
      events: content.events
          .where((e) => normalize(e.title).contains(normalizedQuery))
          .toList(),
    );
  }
}
