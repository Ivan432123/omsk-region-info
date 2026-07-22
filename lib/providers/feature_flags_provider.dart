import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feature_flags_model.dart';
import '../repositories/feature_flags_repository.dart';

final featureFlagsRepositoryProvider =
    Provider((ref) => FeatureFlagsRepository());

final featureFlagsProvider = StreamProvider<FeatureFlagsModel>((ref) {
  return ref.watch(featureFlagsRepositoryProvider).watchFeatureFlags();
});
