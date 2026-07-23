import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/feedback_request_repository.dart';

final feedbackRequestRepositoryProvider =
    Provider((ref) => FeedbackRequestRepository());
