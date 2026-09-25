import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/consultant/companies/expenses/application/expense_monthly_report_provider.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class ExpenseMonthlyReportPage extends ConsumerWidget {
  final String companyId;
  final String periodId;

  const ExpenseMonthlyReportPage({
    super.key,
    required this.companyId,
    required this.periodId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(expenseMonthlyReportProvider(periodId));

    return CompanyScaffold(
      companyId: companyId,
      currentRoute:
          '/consultant/companies/$companyId/expenses/reports/$periodId',
      title: 'گزارش ماهانه هزینه',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            return _ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(expenseMonthlyReportProvider(periodId));
              },
            );
          },
          data: (report) {
            return _ReportContent(report: report);
          },
        ),
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  final ExpenseMonthlyReportData report;

  const _ReportContent({required this.report});

  double categoryPercent(double amount) {
    if (report.total <= 0) {
      return 0;
    }

    return (amount / report.total) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return SingleChildScrollView(
      padding: EdgeInsets.all(width < 700 ? 16 : 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeaderCard(),

              const SizedBox(height: 20),

              _KpiGrid(report: report),

              const SizedBox(height: 20),

              _DistributionCard(report: report),

              const SizedBox(height: 20),

              _CategoriesCard(report: report, categoryPercent: categoryPercent),

              const SizedBox(height: 20),

              _DetailsCard(report: report, categoryPercent: categoryPercent),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: theme.colorScheme.primary.withOpacity(.10),
              ),
              child: Icon(
                Icons.assessment_outlined,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'گزارش ماهانه هزینه',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'خلاصه هزینه‌های ثبت‌شده در دوره مالی',
                    style: theme.textTheme.bodyMedium,
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

class _KpiGrid extends StatelessWidget {
  final ExpenseMonthlyReportData report;

  const _KpiGrid({required this.report});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final crossAxisCount =
        width < 600
            ? 1
            : width < 1000
            ? 2
            : 4;

    final items = [
      _KpiItem(
        title: 'کل هزینه',
        value: _formatAmount(report.total),
        icon: Icons.account_balance_wallet_outlined,
      ),
      _KpiItem(
        title: 'هزینه عملیاتی',
        value: _formatAmount(report.operational),
        icon: Icons.trending_up,
      ),
      _KpiItem(
        title: 'هزینه غیرعملیاتی',
        value: _formatAmount(report.nonOperational),
        icon: Icons.swap_vert,
      ),
      _KpiItem(
        title: 'تعداد دسته‌ها',
        value: report.categoryCount.toString(),
        icon: Icons.category_outlined,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: width < 600 ? 3.2 : 2.3,
      ),
      itemBuilder: (context, index) {
        return items[index];
      },
    );
  }
}

class _KpiItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _KpiItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.primary.withOpacity(.10),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
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

class _DistributionCard extends StatelessWidget {
  final ExpenseMonthlyReportData report;

  const _DistributionCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'توزیع هزینه',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _DistributionRow(
              title: 'هزینه‌های عملیاتی',
              amount: report.operational,
              percent: report.operationalPercent,
            ),
            const SizedBox(height: 18),
            _DistributionRow(
              title: 'هزینه‌های غیرعملیاتی',
              amount: report.nonOperational,
              percent: report.nonOperationalPercent,
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final String title;
  final double amount;
  final double percent;

  const _DistributionRow({
    required this.title,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${percent.toStringAsFixed(1)}٪',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 9,
          ),
        ),
        const SizedBox(height: 6),
        Text(_formatAmount(amount), style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _CategoriesCard extends StatelessWidget {
  final ExpenseMonthlyReportData report;
  final double Function(double amount) categoryPercent;

  const _CategoriesCard({required this.report, required this.categoryPercent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (report.categories.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'برای این دوره هنوز هزینه‌ای ثبت نشده است.',
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'هزینه بر اساس دسته‌بندی',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            ...report.categories.map((category) {
              final percent = categoryPercent(category.amount);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _CategoryProgress(category: category, percent: percent),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CategoryProgress extends StatelessWidget {
  final ExpenseMonthlyReportCategory category;
  final double percent;

  const _CategoryProgress({required this.category, required this.percent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                category.categoryName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${percent.toStringAsFixed(1)}٪',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0.0, 1.0),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 5),
        Text(_formatAmount(category.amount), style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final ExpenseMonthlyReportData report;
  final double Function(double amount) categoryPercent;

  const _DetailsCard({required this.report, required this.categoryPercent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'جزئیات گزارش',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (report.categories.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('اطلاعاتی برای نمایش وجود ندارد.'),
                ),
              )
            else if (width < 800)
              Column(
                children:
                    report.categories.map((category) {
                      final percent = categoryPercent(category.amount);

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              category.categoryName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'نوع: ${category.expenseType == 'non_operational' ? 'غیرعملیاتی' : 'عملیاتی'}',
                            ),
                            const SizedBox(height: 5),
                            Text('مبلغ: ${_formatAmount(category.amount)}'),
                            const SizedBox(height: 5),
                            Text('سهم: ${percent.toStringAsFixed(1)}٪'),
                          ],
                        ),
                      );
                    }).toList(),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('دسته‌بندی')),
                    DataColumn(label: Text('نوع')),
                    DataColumn(label: Text('مبلغ')),
                    DataColumn(label: Text('سهم')),
                  ],
                  rows:
                      report.categories.map((category) {
                        final percent = categoryPercent(category.amount);

                        return DataRow(
                          cells: [
                            DataCell(Text(category.categoryName)),
                            DataCell(
                              Text(
                                category.expenseType == 'non_operational'
                                    ? 'غیرعملیاتی'
                                    : 'عملیاتی',
                              ),
                            ),
                            DataCell(Text(_formatAmount(category.amount))),
                            DataCell(Text('${percent.toStringAsFixed(1)}٪')),
                          ],
                        );
                      }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text(
              'خطا در دریافت گزارش هزینه',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatAmount(double value) {
  final rounded = value.round();
  final text = rounded.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(text[i]);
  }

  return '${buffer.toString()} ریال';
}
