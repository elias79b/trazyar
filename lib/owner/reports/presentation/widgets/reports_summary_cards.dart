import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/reports/application/reports_provider.dart';

import '../../domain/models/report_summary_model.dart';

class ReportsSummaryCards extends ConsumerWidget {
  const ReportsSummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(reportSummaryProvider);

    return summary.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            error.toString(),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      data: (summary) => _Cards(summary: summary),
    );
  }
}

class _Cards extends StatelessWidget {
  final ReportSummaryModel summary;

  const _Cards({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count = 5;

        if (constraints.maxWidth < 650) {
          count = 1;
        } else if (constraints.maxWidth < 1000) {
          count = 2;
        } else if (constraints.maxWidth < 1400) {
          count = 3;
        } else if (constraints.maxWidth < 1700) {
          count = 4;
        }

        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 3.5,
          children: [
            _SummaryCard(
              title: "کل کاربران",
              value: summary.totalUsers.toString(),
              icon: Icons.people,
              color: Colors.blue,
            ),
            _SummaryCard(
              title: "کاربران فعال",
              value: summary.activeUsers.toString(),
              icon: Icons.person,
              color: Colors.green,
            ),
            _SummaryCard(
              title: "شرکت‌ها",
              value: summary.totalCompanies.toString(),
              icon: Icons.business,
              color: Colors.orange,
            ),
            _SummaryCard(
              title: "شرکت‌های فعال",
              value: summary.activeCompanies.toString(),
              icon: Icons.apartment,
              color: Colors.teal,
            ),
            _SummaryCard(
              title: "اشتراک فعال",
              value: summary.activeSubscriptions.toString(),
              icon: Icons.workspace_premium,
              color: Colors.deepPurple,
            ),
            _SummaryCard(
              title: "درآمد ماه",
              value: summary.monthlyRevenue.toStringAsFixed(0),
              icon: Icons.payments,
              color: Colors.green,
            ),
            _SummaryCard(
              title: "درآمد سال",
              value: summary.yearlyRevenue.toStringAsFixed(0),
              icon: Icons.trending_up,
              color: Colors.indigo,
            ),
            _SummaryCard(
              title: "ورود امروز",
              value: summary.todayLogins.toString(),
              icon: Icons.login,
              color: Colors.red,
            ),
            _SummaryCard(
              title: "کاربران آنلاین",
              value: summary.onlineUsers.toString(),
              icon: Icons.circle,
              color: Colors.lightGreen,
            ),
            _SummaryCard(
              title: "فعالیت امروز",
              value: summary.todayActivities.toString(),
              icon: Icons.history,
              color: Colors.brown,
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(.15),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}