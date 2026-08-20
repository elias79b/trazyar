import 'package:flutter/material.dart';

import '../widgets/consultant_scaffold.dart';
import '../widgets/consultant_kpi_card.dart';
import '../widgets/company_compare_card.dart';
import '../widgets/consultant_chart_card.dart';
import '../widgets/consultant_alert_card.dart';
import '../widgets/consultant_action_card.dart';
import '../widgets/consultant_workflow_card.dart';

class ConsultantPage extends StatelessWidget {
  const ConsultantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ConsultantScaffold(
      currentRoute: '/consultant',

      title: 'داشبورد مشاور',

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            _HeaderSection(),

            const SizedBox(height: 24),

            _KpiSection(),

            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1100) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Expanded(flex: 2, child: const CompanyCompareCard()),

                      const SizedBox(width: 18),

                      Expanded(
                        flex: 2,

                        child: const ConsultantChartCard(
                          title: 'روند درآمد و هزینه',

                          subtitle: 'بررسی تغییرات مالی شرکت‌ها',
                        ),
                      ),
                    ],
                  );
                }

                return const Column(
                  children: [
                    CompanyCompareCard(),

                    SizedBox(height: 18),

                    ConsultantChartCard(
                      title: 'روند درآمد و هزینه',

                      subtitle: 'بررسی تغییرات مالی شرکت‌ها',
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1100) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Expanded(child: ConsultantAlertCard()),

                      const SizedBox(width: 18),

                      Expanded(child: ConsultantActionCard()),
                    ],
                  );
                }

                return const Column(
                  children: [
                    ConsultantAlertCard(),

                    SizedBox(height: 18),

                    ConsultantActionCard(),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            ConsultantWorkflowCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
        ),

        borderRadius: BorderRadius.circular(24),
      ),

      child: Row(
        children: [
          Container(
            width: 62,

            height: 62,

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(18),
            ),

            child: const Icon(
              Icons.support_agent_rounded,

              size: 32,

              color: Color(0xFF1B4332),
            ),
          ),

          const SizedBox(width: 18),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'سلام، مشاور عزیز',

                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),

                SizedBox(height: 6),

                Text(
                  'نمای کلی وضعیت شرکت‌های تحت مدیریت شما',

                  style: TextStyle(
                    color: Colors.white,

                    fontSize: 20,

                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count;

        if (constraints.maxWidth >= 1200) {
          count = 4;
        } else if (constraints.maxWidth >= 700) {
          count = 2;
        } else {
          count = 1;
        }

        return GridView.count(
          crossAxisCount: count,

          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),

          crossAxisSpacing: 16,

          mainAxisSpacing: 16,

          childAspectRatio: 2.4,

          children: const [
            ConsultantKpiCard(
              title: 'شرکت‌های تحت پوشش',

              value: '۱۲',

              icon: Icons.business_rounded,
            ),

            ConsultantKpiCard(
              title: 'درآمد کل',

              value: '۲۵ میلیارد',

              icon: Icons.trending_up_rounded,
            ),

            ConsultantKpiCard(
              title: 'هزینه کل',

              value: '۸ میلیارد',

              icon: Icons.money_off_rounded,
            ),

            ConsultantKpiCard(
              title: 'اقدامات باز',

              value: '۷',

              icon: Icons.task_alt_rounded,
            ),
          ],
        );
      },
    );
  }
}
