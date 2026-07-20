import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/ad_request_repository.dart';

final adRequestRepositoryProvider = Provider((ref) => AdRequestRepository());
