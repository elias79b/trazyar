import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/activity_log_model.dart';

class ActivityRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<ActivityLogModel>> fetchActivities() async {
    final data = await _client
        .from('activity_logs')
        .select()
        .order('created_at', ascending: false)
        .limit(5);

    return data
        .map<ActivityLogModel>((item) => ActivityLogModel.fromMap(item))
        .toList();
  }
}
