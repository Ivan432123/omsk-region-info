import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/feedback_repository.dart';

final feedbackRepositoryProvider = Provider((ref) => FeedbackRepository());
