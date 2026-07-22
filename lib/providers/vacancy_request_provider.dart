import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/vacancy_request_repository.dart';

final vacancyRequestRepositoryProvider =
    Provider((ref) => VacancyRequestRepository());
