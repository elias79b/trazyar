import 'package:flutter/material.dart';
import 'package:tarazyar/owner/dashboard/presentation/widgets/latest_users_widget.dart';
import 'package:tarazyar/owner/dashboard/presentation/widgets/owner_scaffold.dart';

import '../widgets/reports_filters.dart';
import '../widgets/reports_summary_cards.dart';
import '../widgets/revenue_chart.dart';
import '../widgets/users_chart.dart';
import '../widgets/subscriptions_chart.dart';
import '../widgets/recent_activity_widget.dart';
import '../widgets/latest_companies_widget.dart';
import '../widgets/users_report_table.dart';
import '../widgets/companies_report_table.dart';
import '../widgets/subscriptions_report_table.dart';
import '../widgets/export_excel_button.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OwnerScaffold(
      currentRoute: '/owner/reports',
      title: 'گزارشات',
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "گزارشات سیستم",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "نمای کلی از وضعیت کاربران، شرکت‌ها، اشتراک‌ها و فعالیت‌های سیستم",
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 30),

              const ReportsFilters(),

              const SizedBox(height: 25),

              const ReportsSummaryCards(),

              const SizedBox(height: 30),

              LayoutBuilder(
                builder: (context, constraints) {

                  if (constraints.maxWidth > 1200) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [

                        Expanded(
                          child: RevenueChart(),
                        ),

                        SizedBox(width: 20),

                        Expanded(
                          child: UsersChart(),
                        ),

                      ],
                    );
                  }

                  return const Column(
                    children: [

                      RevenueChart(),

                      SizedBox(height: 20),

                      UsersChart(),

                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              const SubscriptionsChart(),

              const SizedBox(height: 30),

              LayoutBuilder(
                builder: (context, constraints) {

                  if (constraints.maxWidth > 1200) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [

                        Expanded(
                          child: LatestUsersWidget(),
                        ),

                        SizedBox(width: 20),

                        Expanded(
                          child: LatestCompaniesWidget(),
                        ),

                      ],
                    );
                  }

                  return const Column(
                    children: [

                      LatestUsersWidget(),

                      SizedBox(height: 20),

                      LatestCompaniesWidget(),

                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              const RecentActivityWidget(),

              const SizedBox(height: 30),

              const Text(
                "گزارش کاربران",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              const UsersReportTable(),

              const SizedBox(height: 30),

              const Text(
                "گزارش شرکت‌ها",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              const CompaniesReportTable(),

              const SizedBox(height: 30),

              const Text(
                "گزارش اشتراک‌ها",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              const SubscriptionsReportTable(),

              const SizedBox(height: 35),

              Align(
                alignment: Alignment.centerLeft,
                child: ExportExcelButton(
                  onExcel: () {},
                  onPdf: () {},
                ),
              ),

              const SizedBox(height: 50),

            ],
          ),
        ),
      ),
    );
  }
}