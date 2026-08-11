import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/chart_point.dart';
import '../domain/models/report_summary_model.dart';

class ReportsRepository {
  final _client = Supabase.instance.client;

  Future<ReportSummaryModel> getSummary() async {
    final users = await _client.from('users').select();
    final companies = await _client.from('companies').select();
    final subscriptions = await _client.from('subscriptions').select();
    final logs = await _client.from('activity_logs').select();

    return ReportSummaryModel(
      totalUsers: users.length,
      activeUsers:
      users.where((e) => e['is_active'] == true).length,
      totalCompanies: companies.length,
      activeCompanies:
      companies.where((e) => e['is_active'] == true).length,
      activeSubscriptions: subscriptions
          .where((e) => e['status'] == 'active')
          .length,
      monthlyRevenue: 0,
      yearlyRevenue: 0,
      todayLogins: logs
          .where((e) => e['action'] == 'login')
          .length,
      onlineUsers:
      users.where((e) => e['is_online'] == true).length,
      todayActivities: logs.length,
    );
  }

  Future<List<ChartPoint>> getUsersChart() async {
    final data = await _client
        .from('users')
        .select('created_at')
        .order('created_at');

    final Map<String, double> chart = {};

    for (final row in data) {
      final month = row['created_at'].toString().substring(0, 7);
      chart[month] = (chart[month] ?? 0) + 1;
    }

    return chart.entries
        .map((e) => ChartPoint(x: e.key, y: e.value))
        .toList();
  }

  Future<List<ChartPoint>> getCompaniesChart() async {
    final data = await _client
        .from('companies')
        .select('created_at')
        .order('created_at');

    final Map<String, double> chart = {};

    for (final row in data) {
      final month = row['created_at'].toString().substring(0, 7);
      chart[month] = (chart[month] ?? 0) + 1;
    }

    return chart.entries
        .map((e) => ChartPoint(x: e.key, y: e.value))
        .toList();
  }

  Future<List<ChartPoint>> getSubscriptionsChart() async {
    final data = await _client
        .from('subscriptions')
        .select('created_at')
        .order('created_at');

    final Map<String, double> chart = {};

    for (final row in data) {
      final month = row['created_at'].toString().substring(0, 7);
      chart[month] = (chart[month] ?? 0) + 1;
    }

    return chart.entries
        .map((e) => ChartPoint(x: e.key, y: e.value))
        .toList();
  }

  Future<List<ChartPoint>> getRevenueChart() async {
    return [];
  }

  Future<List<Map<String, dynamic>>> getLatestUsers() async {
    return await _client
        .from('users')
        .select()
        .order('created_at', ascending: false)
        .limit(10);
  }

  Future<List<Map<String, dynamic>>> getLatestCompanies() async {
    return await _client
        .from('companies')
        .select()
        .order('created_at', ascending: false)
        .limit(10);
  }

  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    return await _client
        .from('activity_logs')
        .select()
        .order('created_at', ascending: false)
        .limit(20);
  }

  Future<List<Map<String, dynamic>>> getUsersReport() async {
    return await _client
        .from('users')
        .select()
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getCompaniesReport() async {
    return await _client
        .from('companies')
        .select()
        .order('created_at', ascending: false);
  }

  Future<List<Map<String, dynamic>>> getSubscriptionsReport() async {
    return await _client
        .from('subscriptions')
        .select('*,plans(name),companies(name)')
        .order('created_at', ascending: false);
  }
}