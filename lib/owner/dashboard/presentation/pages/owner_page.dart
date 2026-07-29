import 'package:flutter/material.dart';
import 'package:tarazyar/owner/dashboard/presentation/widgets/dashboard_cards.dart';
import 'package:tarazyar/owner/dashboard/presentation/widgets/dashboard_charts.dart';
import 'package:tarazyar/owner/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:tarazyar/owner/dashboard/presentation/widgets/latest_users_widget.dart';
import 'package:tarazyar/owner/dashboard/presentation/widgets/recent_activity_widget.dart';

import '../widgets/owner_scaffold.dart';

class OwnerPage extends StatelessWidget {
  const OwnerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OwnerScaffold(
      currentRoute: '/owner',
      title: 'پنل مدیریت ترازیار',
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(),
          SizedBox(height: 30),
          DashboardCards(),
          SizedBox(height: 30),
          DashboardCharts(),
          SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: RecentActivityWidget(),
              ),
              SizedBox(width: 20),
              Expanded(
                child: LatestUsersWidget(),
              ),
            ],
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}