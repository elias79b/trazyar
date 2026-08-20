import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_repository.dart';
import '../data/models/activity_log_model.dart';

final activityRepositoryProvider = Provider<ActivityRepository>(
  (ref) => ActivityRepository(),
);

final companyActivitiesProvider = FutureProvider<List<ActivityLogModel>>((
  ref,
) async {
  return ref.read(activityRepositoryProvider).fetchActivities();
});
