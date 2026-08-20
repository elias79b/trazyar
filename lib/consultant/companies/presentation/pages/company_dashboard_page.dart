import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_financial_chart.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_kpi_card.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/company_provider.dart';
import '../widgets/company_modules_card.dart';
import '../widgets/company_alert_card.dart';
import '../widgets/company_workflow_card.dart';

class CompanyDashboardPage extends ConsumerWidget {
  const CompanyDashboardPage({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyProvider(companyId));

    return CompanyScaffold(
      companyId: companyId,

      currentRoute: '/consultant/companies/$companyId',

      title: 'داشبورد شرکت',

      body: companyAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },

        error: (error, stackTrace) {
          return Center(
            child: Text(error.toString(), textAlign: TextAlign.center),
          );
        },

        data: (company) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                _CompanyHeader(companyName: company.name, city: company.city),

                const SizedBox(height: 24),

                const _KpiSection(),

                const SizedBox(height: 24),

                const CompanyFinancialChart(),

                const SizedBox(height: 24),

                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 1000) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Expanded(child: CompanyAlertCard()),

                          const SizedBox(width: 20),

                          Expanded(child: CompanyWorkflowCard()),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        CompanyAlertCard(),

                        const SizedBox(height: 20),

                        CompanyWorkflowCard(),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),
                const SizedBox(height:24),

                CompanyModulesCard(
                  companyId: companyId,
                ),

                _CompanyInfoSection(
                  companyName: company.name,

                  city: company.city,

                  isActive: company.isActive,
                ),

                const SizedBox(height: 24),

                const _ReportSection(),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({required this.companyName, this.city});

  final String companyName;

  final String? city;

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

      child: Row(
        children: [
          Container(
            width: 64,

            height: 64,

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(18),
            ),

            child: const Icon(
              Icons.business_rounded,

              size: 34,

              color: Color(0xFF1B4332),
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  companyName,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 22,

                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  city == null
                      ? 'نمای کلی وضعیت شرکت'
                      : '$city - نمای کلی وضعیت شرکت',

                  style: const TextStyle(color: Colors.white70, fontSize: 12),
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
  const _KpiSection();

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
          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),

          crossAxisCount: count,

          crossAxisSpacing: 16,

          mainAxisSpacing: 16,

          childAspectRatio: 2.3,

          children: [
            CompanyKpiCard(
              title: 'فروش کل',

              value: '---',

              icon: Icons.trending_up_rounded,
            ),

            CompanyKpiCard(
              title: 'هزینه',

              value: '---',

              icon: Icons.money_off_rounded,
            ),

            CompanyKpiCard(
              title: 'سود خالص',

              value: '---',

              icon: Icons.account_balance_wallet_rounded,
            ),

            CompanyKpiCard(
              title: 'نقدینگی',

              value: '---',

              icon: Icons.account_balance_rounded,
            ),
          ],
        );
      },
    );
  }
}

class _CompanyInfoSection extends StatelessWidget {
  const _CompanyInfoSection({
    required this.companyName,

    required this.city,

    required this.isActive,
  });

  final String companyName;

  final String? city;

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'وضعیت شرکت',

            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 16),

          _RowItem(title: 'نام شرکت', value: companyName),

          _RowItem(title: 'شهر', value: city ?? '---'),

          _RowItem(title: 'وضعیت', value: isActive ? 'فعال' : 'غیرفعال'),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'گزارش‌های اخیر',

            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 15),

          const ListTile(
            leading: Icon(Icons.description_outlined),

            title: Text('گزارش عملکرد ماهانه'),

            trailing: Icon(Icons.chevron_left),
          ),

          const ListTile(
            leading: Icon(Icons.analytics_outlined),

            title: Text('تحلیل مالی شرکت'),

            trailing: Icon(Icons.chevron_left),
          ),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({required this.title, required this.value});

  final String title;

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),

      child: Row(
        children: [
          Expanded(child: Text(title)),

          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
