import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/consultant/companies/income/application/income_monthly_report_provider.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class IncomeMonthlyReportPage extends ConsumerStatefulWidget {
  final String companyId;

  const IncomeMonthlyReportPage({super.key, required this.companyId});

  @override
  ConsumerState<IncomeMonthlyReportPage> createState() =>
      _IncomeMonthlyReportPageState();
}

class _IncomeMonthlyReportPageState
    extends ConsumerState<IncomeMonthlyReportPage> {
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(
      incomeMonthlyReportProvider(widget.companyId),
    );

    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute: '/consultant/companies/${widget.companyId}/income/reports',
      title: 'گزارش ماهانه درآمد',
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => _ErrorView(
              message: _friendlyError(error),
              onRetry: () {
                ref.invalidate(incomeMonthlyReportProvider(widget.companyId));
              },
            ),
        data: (data) => _buildContent(context, data),
      ),
    );
  }

  Widget _buildContent(BuildContext context, IncomeMonthlyReportData data) {
    if (data.rows.isEmpty) {
      return _EmptyView(
        onRefresh: () {
          ref.invalidate(incomeMonthlyReportProvider(widget.companyId));
        },
      );
    }

    final years =
        data.years
            .map((item) => _toInt(item['year']))
            .where((year) => year > 0)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    final selectedYear =
        _selectedYear != null && years.contains(_selectedYear)
            ? _selectedYear!
            : years.first;

    final filteredRows =
        data.rows.where((row) => row.year == selectedYear).toList()
          ..sort((a, b) => a.month.compareTo(b.month));

    final yearOperational = filteredRows.fold(
      0.0,
      (sum, row) => sum + row.operational,
    );

    final yearNonOperational = filteredRows.fold(
      0.0,
      (sum, row) => sum + row.nonOperational,
    );

    final yearTotal = filteredRows.fold(0.0, (sum, row) => sum + row.total);

    final yearReceivables = filteredRows.fold(
      0.0,
      (sum, row) => sum + row.receivableTotal,
    );

    final yearReceived = filteredRows.fold(
      0.0,
      (sum, row) => sum + row.receivedDocuments,
    );

    final yearRemaining = filteredRows.fold(
      0.0,
      (sum, row) => sum + row.remainingReceivable,
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(incomeMonthlyReportProvider(widget.companyId));
        await ref.read(incomeMonthlyReportProvider(widget.companyId).future);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1100;
          final isTablet = constraints.maxWidth >= 700;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isDesktop ? 28 : 16),
            children: [
              _buildHeader(context, selectedYear, years),
              const SizedBox(height: 20),

              _buildKpiGrid(
                context,
                isDesktop: isDesktop,
                isTablet: isTablet,
                total: yearTotal,
                operational: yearOperational,
                nonOperational: yearNonOperational,
                receivables: yearReceivables,
                received: yearReceived,
                remaining: yearRemaining,
              ),

              const SizedBox(height: 24),

              _buildMonthlyTable(context, filteredRows, isDesktop: isDesktop),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int selectedYear, List<int> years) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'گزارش ماهانه درآمد',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'نمایش عملکرد درآمد، دریافتنی‌ها و مبالغ دریافت‌شده',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (years.length > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedYear,
                  items:
                      years
                          .map(
                            (year) => DropdownMenuItem<int>(
                              value: year,
                              child: Text('سال ${_formatNumber(year)}'),
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
            ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(
    BuildContext context, {
    required bool isDesktop,
    required bool isTablet,
    required double total,
    required double operational,
    required double nonOperational,
    required double receivables,
    required double received,
    required double remaining,
  }) {
    final cards = [
      _KpiData(
        title: 'کل درآمد',
        value: total,
        icon: Icons.account_balance_wallet_outlined,
      ),
      _KpiData(
        title: 'درآمد عملیاتی',
        value: operational,
        icon: Icons.trending_up_rounded,
      ),
      _KpiData(
        title: 'درآمد غیرعملیاتی',
        value: nonOperational,
        icon: Icons.category_outlined,
      ),
      _KpiData(
        title: 'کل دریافتنی',
        value: receivables,
        icon: Icons.receipt_long_outlined,
      ),
      _KpiData(
        title: 'دریافت‌شده',
        value: received,
        icon: Icons.check_circle_outline,
      ),
      _KpiData(
        title: 'مانده دریافتنی',
        value: remaining,
        icon: Icons.pending_actions_outlined,
      ),
    ];

    final columns =
        isDesktop
            ? 3
            : isTablet
            ? 2
            : 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio:
              isDesktop
                  ? 2.35
                  : isTablet
                  ? 2.8
                  : 3.2,
        ),
        itemBuilder: (context, index) {
          final item = cards[index];

          return _KpiCard(data: item);
        },
      ),
    );
  }

  Widget _buildMonthlyTable(
    BuildContext context,
    List<IncomeMonthlyReportRow> rows, {
    required bool isDesktop,
  }) {
    final theme = Theme.of(context);

    if (!isDesktop) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'جزئیات ماهانه',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ...rows.map(
              (row) => _MonthlyMobileCard(
                row: row,
                onOpen: () => _openPeriod(row.periodId),
              ),
            ),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'جزئیات ماهانه',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 28,
                  headingRowHeight: 48,
                  dataRowMinHeight: 58,
                  dataRowMaxHeight: 70,
                  columns: const [
                    DataColumn(label: Text('ماه')),
                    DataColumn(label: Text('عملیاتی')),
                    DataColumn(label: Text('غیرعملیاتی')),
                    DataColumn(label: Text('کل درآمد')),
                    DataColumn(label: Text('دریافتنی')),
                    DataColumn(label: Text('دریافت‌شده')),
                    DataColumn(label: Text('مانده')),
                    DataColumn(label: Text('وضعیت')),
                    DataColumn(label: Text('')),
                  ],
                  rows:
                      rows
                          .map(
                            (row) => DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    row.title.isEmpty
                                        ? 'ماه ${_formatNumber(row.month)}'
                                        : row.title,
                                  ),
                                ),
                                DataCell(Text(_money(row.operational))),
                                DataCell(Text(_money(row.nonOperational))),
                                DataCell(
                                  Text(
                                    _money(row.total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                DataCell(Text(_money(row.receivableTotal))),
                                DataCell(Text(_money(row.receivedDocuments))),
                                DataCell(Text(_money(row.remainingReceivable))),
                                DataCell(_StatusChip(isClosed: row.isClosed)),
                                DataCell(
                                  IconButton(
                                    tooltip: 'مشاهده دوره',
                                    onPressed: () => _openPeriod(row.periodId),
                                    icon: const Icon(Icons.arrow_back_rounded),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPeriod(String periodId) {
    Navigator.of(context).pushNamed(
      '/consultant/companies/${widget.companyId}/income/recognition/$periodId',
    );
  }

  String _money(double value) {
    return '${_formatNumber(value.round())} ریال';
  }

  String _formatNumber(num value) {
    final text = value.toString();
    final parts = text.split('.');
    final integer = parts.first;

    final buffer = StringBuffer();

    for (var i = 0; i < integer.length; i++) {
      if (i > 0 && (integer.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(integer[i]);
    }

    return parts.length > 1 && parts[1] != '0'
        ? '${buffer.toString()}.${parts[1]}'
        : buffer.toString();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _friendlyError(Object error) {
    final text = error.toString();

    if (text.contains('permission denied')) {
      return 'دسترسی لازم برای مشاهده گزارش درآمد وجود ندارد.';
    }

    if (text.contains('JWT')) {
      return 'نشست کاربری معتبر نیست. دوباره وارد شوید.';
    }

    return 'خطا در دریافت گزارش درآمد: $text';
  }
}

class _KpiData {
  final String title;
  final double value;
  final IconData icon;

  const _KpiData({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;

  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  data.icon,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_format(data.value.round())} ریال',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _format(num value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }
}

class _MonthlyMobileCard extends StatelessWidget {
  final IncomeMonthlyReportRow row;
  final VoidCallback onOpen;

  const _MonthlyMobileCard({required this.row, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row.title.isEmpty
                          ? 'ماه ${_format(row.month)}'
                          : row.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusChip(isClosed: row.isClosed),
                ],
              ),
              const SizedBox(height: 14),
              _InfoLine(title: 'درآمد عملیاتی', value: row.operational),
              _InfoLine(title: 'درآمد غیرعملیاتی', value: row.nonOperational),
              const Divider(height: 22),
              _InfoLine(title: 'کل درآمد', value: row.total, bold: true),
              _InfoLine(title: 'کل دریافتنی', value: row.receivableTotal),
              _InfoLine(title: 'دریافت‌شده', value: row.receivedDocuments),
              _InfoLine(
                title: 'مانده دریافتنی',
                value: row.remainingReceivable,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('مشاهده دوره'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _format(num value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }
}

class _InfoLine extends StatelessWidget {
  final String title;
  final double value;
  final bool bold;

  const _InfoLine({
    required this.title,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(
            '${_format(value.round())} ریال',
            style: style?.copyWith(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _format(num value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }
}

class _StatusChip extends StatelessWidget {
  final bool isClosed;

  const _StatusChip({required this.isClosed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color:
            isClosed
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isClosed ? 'بسته' : 'باز',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              const Text(
                'هنوز داده‌ای برای گزارش درآمد ثبت نشده است.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ),
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
        padding: const EdgeInsets.all(32),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 14),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
