import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/reports/data/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository();
});

/// Summary

final reportSummaryProvider = FutureProvider((ref) async {
  return ref.read(reportsRepositoryProvider).getSummary();
});

/// Charts

final usersChartProvider = FutureProvider((ref) async {
  return ref.read(reportsRepositoryProvider).getUsersChart();
});

final companiesChartProvider = FutureProvider((ref) async {
  return ref.read(reportsRepositoryProvider).getCompaniesReport();
});

final subscriptionsChartProvider = FutureProvider((ref) async {
  return ref.read(reportsRepositoryProvider).getSubscriptionsChart();
});

final revenueChartProvider = FutureProvider((ref) async {
  return ref.read(reportsRepositoryProvider).getRevenueChart();
});

/// Latest

final latestUsersProvider = FutureProvider((ref) async {
  return ref.read(reportsRepositoryProvider).getLatestUsers();
});

final latestCompaniesProvider = FutureProvider((ref) async {
  return ref.read(reportsRepositoryProvider).getLatestCompanies();
});

final recentActivitiesProvider = FutureProvider((ref) async {
  return ref.read(reportsRepositoryProvider).getRecentActivities();
});

/// Tables

final usersReportProvider = FutureProvider((ref) async {
  return ref.read(reportsRepositoryProvider).getUsersReport();
});

final companiesReportProvider = FutureProvider((ref) async {
  return ref.read(reportsRepositoryProvider).getCompaniesReport();
});

final subscriptionsReportProvider = FutureProvider((ref) async {
  return ref.read(reportsRepositoryProvider).getSubscriptionsReport();
});