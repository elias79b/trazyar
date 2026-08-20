import 'package:flutter/material.dart';

import '../widgets/company_scaffold.dart';

import '../widgets/company_financial_summary_card.dart';
import '../widgets/company_income_expense_chart.dart';
import '../widgets/company_profit_chart.dart';
import '../widgets/company_financial_indicator.dart';

class CompanyAnalyticsPage extends StatelessWidget {
  const CompanyAnalyticsPage({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      companyId: companyId,

      currentRoute: '/consultant/companies/$companyId/analytics',

      title: 'تحلیل مالی شرکت',

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            _Header(),

            const SizedBox(height: 24),

            _SummarySection(),

            const SizedBox(height: 24),

            const CompanyIncomeExpenseChart(),

            const SizedBox(height: 24),

            const CompanyProfitChart(),

            const SizedBox(height: 24),

            const CompanyFinancialIndicator(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF40916C)],
        ),

        borderRadius: BorderRadius.circular(24),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'تحلیل مالی شرکت',

            style: TextStyle(
              color: Colors.white,

              fontSize: 22,

              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'بررسی روند درآمد، هزینه، سود و شاخص‌های کلیدی',

            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count;

        if (constraints.maxWidth >= 1100) {
          count = 4;
        } else if (constraints.maxWidth >= 700) {
          count = 2;
        } else {
          count = 1;
        }

        return GridView(
          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),

          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,

            crossAxisSpacing: 16,

            mainAxisSpacing: 16,

            childAspectRatio: 1.8,
          ),

          children: const [
            CompanyFinancialSummaryCard(
              title: 'درآمد کل',

              value: '۱۲ میلیارد',

              icon: Icons.trending_up_rounded,
            ),

            CompanyFinancialSummaryCard(
              title: 'هزینه کل',

              value: '۴ میلیارد',

              icon: Icons.money_off_rounded,
            ),

            CompanyFinancialSummaryCard(
              title: 'سود خالص',

              value: '۸ میلیارد',

              icon: Icons.account_balance_wallet_rounded,
            ),

            CompanyFinancialSummaryCard(
              title: 'حاشیه سود',

              value: '۳۲٪',

              icon: Icons.percent_rounded,
            ),
          ],
        );
      },
    );
  }
}
