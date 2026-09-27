import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/accountant/banking/application/accountant_banking_reports_provider.dart';
import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';

class AccountantBankingReportsPage extends ConsumerWidget {
  final String companyId;

  const AccountantBankingReportsPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountantBankingReportsProvider(companyId));

    return AccountantScaffold(
      currentRoute: '/accountant/banking/reports',
      title: 'گزارش‌های بانکی',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            return _ErrorView(
              error: error.toString(),
              onRetry: () {
                ref.invalidate(accountantBankingReportsProvider(companyId));
              },
            );
          },
          data: (data) {
            return _ReportsContent(data: data);
          },
        ),
      ),
    );
  }
}

class _ReportsContent extends StatefulWidget {
  final AccountantBankingReportsData data;

  const _ReportsContent({required this.data});

  @override
  State<_ReportsContent> createState() => _ReportsContentState();
}

class _ReportsContentState extends State<_ReportsContent> {
  String _search = '';
  String _selectedPeriod = 'همه دوره‌ها';
  String _selectedBank = 'همه بانک‌ها';
  bool _onlyDiscrepancies = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    final periods =
        <String>{
          'همه دوره‌ها',
          ...data.rows.map((row) => row.periodTitle),
        }.toList();

    final banks =
        <String>{
          'همه بانک‌ها',
          ...data.rows.map((row) => row.bankName),
        }.toList();

    final filteredRows =
        data.rows.where((row) {
          final search = _search.trim().toLowerCase();

          final matchesSearch =
              search.isEmpty ||
              row.bankName.toLowerCase().contains(search) ||
              row.accountNumber.toLowerCase().contains(search) ||
              row.periodTitle.toLowerCase().contains(search);

          final matchesPeriod =
              _selectedPeriod == 'همه دوره‌ها' ||
              row.periodTitle == _selectedPeriod;

          final matchesBank =
              _selectedBank == 'همه بانک‌ها' || row.bankName == _selectedBank;

          final matchesDiscrepancy = !_onlyDiscrepancies || row.hasDiscrepancy;

          return matchesSearch &&
              matchesPeriod &&
              matchesBank &&
              matchesDiscrepancy;
        }).toList();

    final filteredOpening = filteredRows.fold<double>(
      0,
      (sum, row) => sum + row.openingBalance,
    );

    final filteredDebit = filteredRows.fold<double>(
      0,
      (sum, row) => sum + row.debitTurnover,
    );

    final filteredCredit = filteredRows.fold<double>(
      0,
      (sum, row) => sum + row.creditTurnover,
    );

    final filteredClosing = filteredRows.fold<double>(
      0,
      (sum, row) => sum + row.closingBalance,
    );

    final filteredLedger = filteredRows.fold<double>(
      0,
      (sum, row) => sum + row.ledgerBalance,
    );

    final filteredDiscrepancy = filteredRows.fold<double>(
      0,
      (sum, row) => sum + row.discrepancy,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final isTablet = constraints.maxWidth < 1100;

        return RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            children: [
              _Header(rowCount: filteredRows.length),

              const SizedBox(height: 20),

              _FilterPanel(
                search: _search,
                selectedPeriod: _selectedPeriod,
                selectedBank: _selectedBank,
                onlyDiscrepancies: _onlyDiscrepancies,
                periods: periods,
                banks: banks,
                onSearchChanged: (value) {
                  setState(() {
                    _search = value;
                  });
                },
                onPeriodChanged: (value) {
                  setState(() {
                    _selectedPeriod = value ?? 'همه دوره‌ها';
                  });
                },
                onBankChanged: (value) {
                  setState(() {
                    _selectedBank = value ?? 'همه بانک‌ها';
                  });
                },
                onDiscrepancyChanged: (value) {
                  setState(() {
                    _onlyDiscrepancies = value;
                  });
                },
                onClear: () {
                  setState(() {
                    _search = '';
                    _selectedPeriod = 'همه دوره‌ها';
                    _selectedBank = 'همه بانک‌ها';
                    _onlyDiscrepancies = false;
                  });
                },
              ),

              const SizedBox(height: 20),

              GridView.count(
                crossAxisCount:
                    isMobile
                        ? 1
                        : isTablet
                        ? 2
                        : 4,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: isMobile ? 4.1 : 2.35,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _KpiCard(
                    title: 'مانده ابتدای دوره',
                    value: _money(filteredOpening),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  _KpiCard(
                    title: 'جمع بدهکار',
                    value: _money(filteredDebit),
                    icon: Icons.arrow_downward_rounded,
                  ),
                  _KpiCard(
                    title: 'جمع بستانکار',
                    value: _money(filteredCredit),
                    icon: Icons.arrow_upward_rounded,
                  ),
                  _KpiCard(
                    title: 'مانده پایان دوره',
                    value: _money(filteredClosing),
                    icon: Icons.account_balance_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount:
                    isMobile
                        ? 1
                        : isTablet
                        ? 2
                        : 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: isMobile ? 4.1 : 2.35,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _KpiCard(
                    title: 'مانده دفتر',
                    value: _money(filteredLedger),
                    icon: Icons.menu_book_outlined,
                  ),
                  _KpiCard(
                    title: 'مغایرت',
                    value: _money(filteredDiscrepancy),
                    icon: Icons.compare_arrows_rounded,
                  ),
                  _KpiCard(
                    title: 'تعداد موارد مغایرت',
                    value: _digits(
                      filteredRows
                          .where((row) => row.hasDiscrepancy)
                          .length
                          .toString(),
                    ),
                    icon: Icons.warning_amber_rounded,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _SectionTitle(
                title: 'گزارش حساب‌های بانکی',
                subtitle:
                    'مانده، گردش و مغایرت حساب‌های بانکی در دوره‌های مالی',
              ),

              const SizedBox(height: 12),

              if (filteredRows.isEmpty)
                const _EmptyReport()
              else
                _ReportsTable(rows: filteredRows),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final int rowCount;

  const _Header({required this.rowCount});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 650;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'گزارش‌های بانکی',
                    style: TextStyle(
                      fontSize: mobile ? 21 : 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'بررسی گردش، مانده دفتر و مغایرت حساب‌های بانکی',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: .62),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                '${_digits(rowCount.toString())} رکورد',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final String search;
  final String selectedPeriod;
  final String selectedBank;
  final bool onlyDiscrepancies;

  final List<String> periods;
  final List<String> banks;

  final ValueChanged<String> onSearchChanged;

  final ValueChanged<String?> onPeriodChanged;

  final ValueChanged<String?> onBankChanged;

  final ValueChanged<bool> onDiscrepancyChanged;

  final VoidCallback onClear;

  const _FilterPanel({
    required this.search,
    required this.selectedPeriod,
    required this.selectedBank,
    required this.onlyDiscrepancies,
    required this.periods,
    required this.banks,
    required this.onSearchChanged,
    required this.onPeriodChanged,
    required this.onBankChanged,
    required this.onDiscrepancyChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mobile = constraints.maxWidth < 700;

            final children = [
              SizedBox(
                width: mobile ? double.infinity : 280,
                child: TextField(
                  controller: TextEditingController(
                    text: search,
                  )..selection = TextSelection.collapsed(offset: search.length),
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    labelText: 'جستجو',
                    hintText: 'بانک، شماره حساب یا دوره',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                width: mobile ? double.infinity : 220,
                child: DropdownButtonFormField<String>(
                  value: selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'دوره مالی',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      periods
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: onPeriodChanged,
                ),
              ),
              SizedBox(
                width: mobile ? double.infinity : 220,
                child: DropdownButtonFormField<String>(
                  value: selectedBank,
                  decoration: const InputDecoration(
                    labelText: 'بانک',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      banks
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: onBankChanged,
                ),
              ),
              SizedBox(
                width: mobile ? double.infinity : 220,
                child: SwitchListTile(
                  value: onlyDiscrepancies,
                  onChanged: onDiscrepancyChanged,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: const Text('فقط دارای مغایرت'),
                  subtitle: const Text('نمایش موارد اختلاف'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_all),
                label: const Text('پاک کردن فیلتر'),
              ),
            ];

            if (mobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < children.length; i++) ...[
                    children[i],
                    if (i < children.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            }

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: children,
            );
          },
        ),
      ),
    );
  }
}

class _ReportsTable extends StatelessWidget {
  final List<AccountantBankingReportRow> rows;

  const _ReportsTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 54,
          dataRowMinHeight: 62,
          dataRowMaxHeight: 72,
          columnSpacing: 28,
          columns: const [
            DataColumn(label: Text('دوره')),
            DataColumn(label: Text('بانک')),
            DataColumn(label: Text('شماره حساب')),
            DataColumn(label: Text('ابتدای دوره')),
            DataColumn(label: Text('بدهکار')),
            DataColumn(label: Text('بستانکار')),
            DataColumn(label: Text('پایان دوره')),
            DataColumn(label: Text('مانده دفتر')),
            DataColumn(label: Text('مغایرت')),
          ],
          rows:
              rows.map((row) {
                final discrepancy = row.hasDiscrepancy;

                return DataRow(
                  color: WidgetStateProperty.resolveWith((states) {
                    if (discrepancy) {
                      return Theme.of(
                        context,
                      ).colorScheme.errorContainer.withValues(alpha: .25);
                    }
                    return null;
                  }),
                  cells: [
                    DataCell(
                      Text(
                        row.periodTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DataCell(Text(row.bankName)),
                    DataCell(
                      Text(row.accountNumber.isEmpty ? '—' : row.accountNumber),
                    ),
                    DataCell(Text(_money(row.openingBalance))),
                    DataCell(Text(_money(row.debitTurnover))),
                    DataCell(Text(_money(row.creditTurnover))),
                    DataCell(Text(_money(row.closingBalance))),
                    DataCell(Text(_money(row.ledgerBalance))),
                    DataCell(
                      discrepancy
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _money(row.discrepancy),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          )
                          : Text(_money(row.discrepancy)),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 23, child: Icon(icon)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: .62),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$value ریال',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: .60),
          ),
        ),
      ],
    );
  }
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(45),
        child: Column(
          children: [
            Icon(
              Icons.assessment_outlined,
              size: 58,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 14),
            const Text(
              'اطلاعاتی برای گزارش وجود ندارد.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            Text(
              'پس از ثبت اطلاعات حساب‌های بانکی در دوره‌های مالی، گزارش در این بخش نمایش داده می‌شود.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 58,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'خطا در دریافت گزارش بانکی',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تلاش مجدد'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _money(double value) {
  final rounded = value.round();

  final negative = rounded < 0;
  final digits = rounded.abs().toString();

  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(digits[i]);
  }

  final result = buffer.toString();

  return '${negative ? '-' : ''}${_digits(result)}';
}

String _digits(String value) {
  return value
      .replaceAll('0', '۰')
      .replaceAll('1', '۱')
      .replaceAll('2', '۲')
      .replaceAll('3', '۳')
      .replaceAll('4', '۴')
      .replaceAll('5', '۵')
      .replaceAll('6', '۶')
      .replaceAll('7', '۷')
      .replaceAll('8', '۸')
      .replaceAll('9', '۹');
}
