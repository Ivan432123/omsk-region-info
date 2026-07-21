import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/banner_request_repository.dart';

final bannerRequestRepositoryProvider =
    Provider((ref) => BannerRequestRepository());
