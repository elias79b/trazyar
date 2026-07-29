import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/dashboard_provider.dart';
import 'dashboard_grid.dart';
import 'dashboard_stat_card.dart';

class DashboardCards extends ConsumerWidget {
  const DashboardCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companies = ref.watch(companiesProvider);
    final users = ref.watch(usersProvider);
    final subs = ref.watch(subscriptionsProvider);
    final revenue = ref.watch(revenueProvider);

    return DashboardGrid(
      children: [
        DashboardStatCard(
          title: 'شرکت ها',
          value: companies.when(
            data: (e) => '$e',
            loading: () => '...',
            error: (_, __) => '0',
          ),
          icon: Icons.business,
          color: Colors.blue,
        ),
        DashboardStatCard(
          title: 'کاربران',
          value: users.when(
            data: (e) => '$e',
            loading: () => '...',
            error: (_, __) => '0',
          ),
          icon: Icons.people,
          color: Colors.green,
        ),
        DashboardStatCard(
          title: 'اشتراک فعال',
          value: subs.when(
            data: (e) => '$e',
            loading: () => '...',
            error: (_, __) => '0',
          ),
          icon: Icons.workspace_premium,
          color: Colors.orange,
        ),
        DashboardStatCard(
          title: 'درآمد',
          value: revenue.when(
            data: (e) => e.toStringAsFixed(0),
            loading: () => '...',
            error: (_, __) => '0',
          ),
          icon: Icons.payments,
          color: Colors.deepPurple,
        ),
      ],
    );
  }
}