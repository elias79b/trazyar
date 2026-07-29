import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/chart_point.dart';

class DashboardRepository {
  DashboardRepository() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  Future<int> companiesCount() async {
    final data = await _client.from('companies').select('id');
    return (data as List).length;
  }

  Future<int> usersCount() async {
    final data = await _client.from('users').select('id');
    return (data as List).length;
  }

  Future<int> activeSubscriptions() async {
    final data = await _client
        .from('subscriptions')
        .select('id')
        .eq('status', 'active');

    return (data as List).length;
  }

  Future<double> totalRevenue() async {
    return 0;
  }

  Future<List<Map<String, dynamic>>> recentActivities() async {
    try {
      final data = await _client
          .from('activity_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(10);

      return (data as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> latestUsers() async {
    try {
      final data = await _client
          .from('users')
          .select()
          .order('created_at', ascending: false)
          .limit(10);

      return (data as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<List<DashboardChartPoint>> companiesGrowthByMonth() async {
    try {
      final data = await _client.from('companies').select('created_at');

      return _groupByMonth(
        data: (data as List).cast<Map<String, dynamic>>(),
        dateKey: 'created_at',
      );
    } catch (_) {
      return _emptyMonthData();
    }
  }

  Future<List<DashboardChartPoint>> usersGrowthByMonth() async {
    try {
      final data = await _client.from('users').select('created_at');

      return _groupByMonth(
        data: (data as List).cast<Map<String, dynamic>>(),
        dateKey: 'created_at',
      );
    } catch (_) {
      return _emptyMonthData();
    }
  }

  Future<List<DashboardChartPoint>> subscriptionsByStatus() async {
    try {
      final data = await _client.from('subscriptions').select('status');

      final rows = (data as List).cast<Map<String, dynamic>>();
      final active = rows.where((e) => (e['status'] ?? '') == 'active').length;
      final trial = rows.where((e) => (e['status'] ?? '') == 'trial').length;
      final expired = rows.where((e) => (e['status'] ?? '') == 'expired').length;
      final cancelled =
          rows.where((e) => (e['status'] ?? '') == 'cancelled').length;

      return [
        DashboardChartPoint('فعال', active.toDouble()),
        DashboardChartPoint('آزمایشی', trial.toDouble()),
        DashboardChartPoint('منقضی', expired.toDouble()),
        DashboardChartPoint('لغوشده', cancelled.toDouble()),
      ];
    } catch (_) {
      return [
        const DashboardChartPoint('فعال', 0),
        const DashboardChartPoint('آزمایشی', 0),
        const DashboardChartPoint('منقضی', 0),
        const DashboardChartPoint('لغوشده', 0),
      ];
    }
  }

  List<DashboardChartPoint> _groupByMonth({
    required List<Map<String, dynamic>> data,
    required String dateKey,
  }) {
    const months = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];

    final counts = List<double>.filled(12, 0);
    final now = DateTime.now();

    for (final row in data) {
      final raw = row[dateKey];
      if (raw == null) continue;

      final dt = DateTime.tryParse(raw.toString());
      if (dt == null) continue;

      if (dt.year == now.year) {
        counts[dt.month - 1] += 1;
      }
    }

    return List.generate(
      12,
          (index) => DashboardChartPoint(months[index], counts[index]),
    );
  }

  List<DashboardChartPoint> _emptyMonthData() {
    const months = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];

    return List.generate(
      12,
          (index) => DashboardChartPoint(months[index], 0),
    );
  }
}