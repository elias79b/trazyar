import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_repository.dart';
import '../domain/models/chart_point.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
      (ref) => DashboardRepository(),
);

final companiesProvider = FutureProvider<int>((ref) async {
  return ref.read(dashboardRepositoryProvider).companiesCount();
});

final usersProvider = FutureProvider<int>((ref) async {
  return ref.read(dashboardRepositoryProvider).usersCount();
});

final subscriptionsProvider = FutureProvider<int>((ref) async {
  return ref.read(dashboardRepositoryProvider).activeSubscriptions();
});

final revenueProvider = FutureProvider<double>((ref) async {
  return ref.read(dashboardRepositoryProvider).totalRevenue();
});

final recentActivityProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(dashboardRepositoryProvider).recentActivities();
});

final latestUsersProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(dashboardRepositoryProvider).latestUsers();
});

final companiesGrowthProvider =
FutureProvider<List<DashboardChartPoint>>((ref) async {
  return ref.read(dashboardRepositoryProvider).companiesGrowthByMonth();
});

final usersGrowthProvider =
FutureProvider<List<DashboardChartPoint>>((ref) async {
  return ref.read(dashboardRepositoryProvider).usersGrowthByMonth();
});

final subscriptionsStatusProvider =
FutureProvider<List<DashboardChartPoint>>((ref) async {
  return ref.read(dashboardRepositoryProvider).subscriptionsByStatus();
});