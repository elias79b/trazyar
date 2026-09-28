import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/accountant_income_report_provider.dart';

class AccountantIncomeReportPage extends ConsumerStatefulWidget {
  final String companyId;

  const AccountantIncomeReportPage({super.key, required this.companyId});

  @override
  ConsumerState<AccountantIncomeReportPage> createState() =>
      _AccountantIncomeReportPageState();
}

class _AccountantIncomeReportPageState
    extends ConsumerState<AccountantIncomeReportPage> {
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(
      accountantIncomeReportProvider(widget.companyId),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stack) => _ErrorView(
                message: error.toString(),
                onRetry: () {
                  ref.invalidate(
                    accountantIncomeReportProvider(widget.companyId),
                  );
                },
              ),
          data: (data) {
            if (data.years.isEmpty) {
              return const _EmptyView();
            }

            final years = data.years;

            final selectedYear =
                years.any((year) => year.year == _selectedYear)
                    ? _selectedYear!
                    : years.first.year;

            final yearData = years.firstWhere(
              (year) => year.year == selectedYear,
            );

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                  accountantIncomeReportProvider(widget.companyId),
                );

                await ref.read(
                  accountantIncomeReportProvider(widget.companyId).future,
                );
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(context, data, years, selectedYear),
                  ),
                  SliverToBoxAdapter(
                    child: _buildSummaryCards(context, yearData),
                  ),
                  SliverToBoxAdapter(
                    child: _buildYearSummary(context, yearData),
                  ),
                  SliverToBoxAdapter(
                    child: _buildMonthlyReport(context, yearData),
                  ),
                  SliverToBoxAdapter(
                    child: _buildCategoryReport(context, yearData),
                  ),
                  SliverToBoxAdapter(
                    child: _buildReceivableReport(context, yearData),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AccountantIncomeReportData data,
    List<AccountantIncomeReportYear> years,
    int selectedYear,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EAF0))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 700;

          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'گزارش درآمد',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF171923),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'گزارش تحلیلی درآمدهای ثبت‌شده و مطالبات شرکت',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          );

          final yearSelector = Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE1E4EA)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedYear,
                borderRadius: BorderRadius.circular(12),
                items:
                    years
                        .map(
                          (year) => DropdownMenuItem<int>(
                            value: year.year,
                            child: Text(
                              'سال ${year.year}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _selectedYear = value;
                  });
                },
              ),
            ),
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 16), yearSelector],
            );
          }

          return Row(children: [Expanded(child: title), yearSelector]);
        },
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    AccountantIncomeReportYear year,
  ) {
    final cards = [
      _SummaryCardData(
        title: 'کل درآمد',
        value: _money(year.totalIncome),
        icon: Icons.trending_up_rounded,
      ),
      _SummaryCardData(
        title: 'درآمد عملیاتی',
        value: _money(year.operationalTotal),
        icon: Icons.business_center_rounded,
      ),
      _SummaryCardData(
        title: 'درآمد غیرعملیاتی',
        value: _money(year.nonOperationalTotal),
        icon: Icons.account_balance_rounded,
      ),
      _SummaryCardData(
        title: 'مطالبات',
        value: _money(year.receivablesTotal),
        icon: Icons.receipt_long_rounded,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns =
              constraints.maxWidth >= 1100
                  ? 4
                  : constraints.maxWidth >= 700
                  ? 2
                  : 1;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cards.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: columns == 1 ? 3.2 : 1.8,
            ),
            itemBuilder: (context, index) {
              return _SummaryCard(data: cards[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildYearSummary(
    BuildContext context,
    AccountantIncomeReportYear year,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _SectionCard(
        title: 'خلاصه سال مالی ${year.year}',
        icon: Icons.analytics_outlined,
        child: Column(
          children: [
            _InfoRow(
              title: 'درآمد عملیاتی',
              value: _money(year.operationalTotal),
            ),
            const Divider(height: 1),
            _InfoRow(
              title: 'درآمد غیرعملیاتی',
              value: _money(year.nonOperationalTotal),
            ),
            const Divider(height: 1),
            _InfoRow(
              title: 'کل درآمد',
              value: _money(year.totalIncome),
              emphasized: true,
            ),
            const Divider(height: 1),
            _InfoRow(title: 'کل مطالبات', value: _money(year.receivablesTotal)),
            const Divider(height: 1),
            _InfoRow(
              title: 'اسناد دریافت‌شده مطالبات',
              value: _money(year.totalReceivedDocuments),
            ),
            const Divider(height: 1),
            _InfoRow(
              title: 'مانده مطالبات',
              value: _money(year.totalReceivablesRemaining),
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyReport(
    BuildContext context,
    AccountantIncomeReportYear year,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: _SectionCard(
        title: 'گزارش ماهانه',
        icon: Icons.calendar_month_rounded,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 700) {
              return Column(
                children:
                    year.periods
                        .map((period) => _MobileMonthCard(period: period))
                        .toList(),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowHeight: 48,
                  dataRowMinHeight: 58,
                  dataRowMaxHeight: 72,
                  columns: const [
                    DataColumn(label: Text('ماه')),
                    DataColumn(label: Text('عملیاتی')),
                    DataColumn(label: Text('غیرعملیاتی')),
                    DataColumn(label: Text('کل درآمد')),
                    DataColumn(label: Text('مطالبات')),
                    DataColumn(label: Text('مانده مطالبات')),
                    DataColumn(label: Text('وضعیت')),
                  ],
                  rows:
                      year.periods.map((period) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                period.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataCell(Text(_money(period.operationalTotal))),
                            DataCell(Text(_money(period.nonOperationalTotal))),
                            DataCell(
                              Text(
                                _money(period.totalIncome),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DataCell(Text(_money(period.receivablesTotal))),
                            DataCell(Text(_money(period.receivablesRemaining))),
                            DataCell(_StatusChip(title: period.statusTitle)),
                          ],
                        );
                      }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryReport(
    BuildContext context,
    AccountantIncomeReportYear year,
  ) {
    final categories = year.categories;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: _SectionCard(
        title: 'گزارش بر اساس دسته درآمد',
        icon: Icons.category_outlined,
        child:
            categories.isEmpty
                ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('داده‌ای برای نمایش وجود ندارد.')),
                )
                : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 700) {
                      return Column(
                        children:
                            categories
                                .map(
                                  (category) =>
                                      _CategoryMobileCard(category: category),
                                )
                                .toList(),
                      );
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          headingRowHeight: 48,
                          dataRowMinHeight: 58,
                          dataRowMaxHeight: 72,
                          columns: const [
                            DataColumn(label: Text('دسته درآمد')),
                            DataColumn(label: Text('نوع')),
                            DataColumn(label: Text('مبلغ')),
                            DataColumn(label: Text('سهم از کل')),
                          ],
                          rows:
                              categories.map((category) {
                                final total = year.totalIncome;

                                final share =
                                    total <= 0
                                        ? 0
                                        : (category.amount / total) * 100;

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        category.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      _TypeChip(
                                        operational:
                                            category.categoryType ==
                                            'operational',
                                      ),
                                    ),
                                    DataCell(Text(_money(category.amount))),
                                    DataCell(
                                      Text('${share.toStringAsFixed(1)}٪'),
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _buildReceivableReport(
    BuildContext context,
    AccountantIncomeReportYear year,
  ) {
    final monthsWithReceivables =
        year.periods.where((period) => period.receivables.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: _SectionCard(
        title: 'جزئیات مطالبات',
        icon: Icons.receipt_long_outlined,
        child:
            monthsWithReceivables.isEmpty
                ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('مطالبه‌ای برای این سال ثبت نشده است.'),
                  ),
                )
                : Column(
                  children:
                      monthsWithReceivables.map((period) {
                        return ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            8,
                            0,
                            8,
                            12,
                          ),
                          title: Text(
                            period.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            'جمع مطالبات: '
                            '${_money(period.receivablesTotal)}',
                          ),
                          children:
                              period.receivables
                                  .map(
                                    (receivable) =>
                                        _ReceivableRow(receivable: receivable),
                                  )
                                  .toList(),
                        );
                      }).toList(),
                ),
      ),
    );
  }

  String _money(double value) {
    return '${_formatNumber(value)} ریال';
  }

  String _formatNumber(double value) {
    final text = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;

      buffer.write(text[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;

  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E9EF)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 5),
            color: Color(0x0A000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: const Color(0xFF30333D)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
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

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E9EF)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Row(
              children: [
                Icon(icon, size: 21, color: const Color(0xFF30333D)),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;
  final bool emphasized;

  const _InfoRow({
    required this.title,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
                color:
                    emphasized ? const Color(0xFF171923) : Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String title;

  const _StatusChip({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final bool operational;

  const _TypeChip({required this.operational});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        operational ? 'عملیاتی' : 'غیرعملیاتی',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MobileMonthCard extends StatelessWidget {
  final AccountantIncomeReportPeriod period;

  const _MobileMonthCard({required this.period});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9EF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  period.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _StatusChip(title: period.statusTitle),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            title: 'عملیاتی',
            value: _formatMoney(period.operationalTotal),
          ),
          _InfoRow(
            title: 'غیرعملیاتی',
            value: _formatMoney(period.nonOperationalTotal),
          ),
          _InfoRow(
            title: 'کل درآمد',
            value: _formatMoney(period.totalIncome),
            emphasized: true,
          ),
          _InfoRow(
            title: 'مطالبات',
            value: _formatMoney(period.receivablesTotal),
          ),
        ],
      ),
    );
  }

  static String _formatMoney(double value) {
    final text = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;

      buffer.write(text[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    return '${buffer.toString()} ریال';
  }
}

class _CategoryMobileCard extends StatelessWidget {
  final AccountantIncomeReportCategory category;

  const _CategoryMobileCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E9EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _TypeChip(operational: category.categoryType == 'operational'),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(title: 'مبلغ', value: _formatMoney(category.amount)),
          _InfoRow(
            title: 'سهم از کل',
            value: '${category.sharePercent.toStringAsFixed(1)}٪',
          ),
        ],
      ),
    );
  }

  static String _formatMoney(double value) {
    final text = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;

      buffer.write(text[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    return '${buffer.toString()} ریال';
  }
}

class _ReceivableRow extends StatelessWidget {
  final AccountantIncomeReportReceivable receivable;

  const _ReceivableRow({required this.receivable});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E9EF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receivable.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (receivable.description != null &&
                    receivable.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    receivable.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatMoney(receivable.amount),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (receivable.receivedDocumentsAmount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'اسناد: ${_formatMoney(receivable.receivedDocumentsAmount)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _formatMoney(double value) {
    final text = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;

      buffer.write(text[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    return '${buffer.toString()} ریال';
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
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            const Text(
              'دریافت گزارش با خطا مواجه شد.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('تلاش مجدد')),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 54, color: Colors.grey),
            SizedBox(height: 14),
            Text(
              'هنوز سال مالی درآمدی ثبت نشده است.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
