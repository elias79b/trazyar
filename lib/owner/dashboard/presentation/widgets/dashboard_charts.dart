import 'package:flutter/material.dart';
import 'package:tarazyar/core/responsive/responsive.dart';
import 'revenue_chart.dart';
import 'subscriptions_chart.dart';
import 'users_chart.dart';

class DashboardCharts extends StatelessWidget {
  const DashboardCharts({super.key});

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                SizedBox(height: 350, child: RevenueChart()),
                SizedBox(height: 20),
                SizedBox(height: 350, child: UsersChart()),
              ],
            ),
          ),
          SizedBox(width: 20),
          Expanded(
            child: SizedBox(
              height: 720,
              child: SubscriptionsChart(),
            ),
          ),
        ],
      );
    }

    return const Column(
      children: [
        SizedBox(height: 350, child: RevenueChart()),
        SizedBox(height: 20),
        SizedBox(height: 350, child: UsersChart()),
        SizedBox(height: 20),
        SizedBox(height: 350, child: SubscriptionsChart()),
      ],
    );
  }
}