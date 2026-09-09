
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/payroll_period_provider.dart';
import '../../data/payroll_period_model.dart';
import '../widgets/payroll_period_form_dialog.dart';
import 'payroll_records_page.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class PayrollPeriodsPage extends ConsumerWidget {
  const PayrollPeriodsPage({
    super.key,
    required this.companyId,
  });

  final String companyId;

  String get _currentRoute =>
      '/consultant/companies/$companyId/payroll/periods';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodsAsync =
    ref.watch(payrollPeriodsProvider(companyId));

    return CompanyScaffold(
      companyId: companyId,
      currentRoute: _currentRoute,
      title: 'حقوق و دستمزد',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: periodsAsync.when(
          loading: () {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
          error: (error, stackTrace) {
            return _ErrorView(
              error: _friendlyError(error),
              onRetry: () {
                ref.invalidate(
                  payrollPeriodsProvider(companyId),
                );
              },
            );
          },
          data: (periods) {
            return _PeriodsContent(
              companyId: companyId,
              periods: periods,
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// PERIODS CONTENT
// ============================================================

class _PeriodsContent extends ConsumerStatefulWidget {
  const _PeriodsContent({
    required this.companyId,
    required this.periods,
  });

  final String companyId;
  final List<PayrollPeriodModel> periods;

  @override
  ConsumerState<_PeriodsContent> createState() =>
      _PeriodsContentState();
}

class _PeriodsContentState
    extends ConsumerState<_PeriodsContent> {
  int _selectedYear = 1405;
  String _statusFilter = 'all';
  String _search = '';

  @override
  void initState() {
    super.initState();

    if (widget.periods.isNotEmpty) {
      _selectedYear = widget.periods
          .map((e) => e.periodYear)
          .reduce(
            (a, b) => a > b ? a : b,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allPeriods = widget.periods;

    final availableYears =
    <int>{
      1405,
      ...allPeriods.map(
            (e) => e.periodYear,
      ),
    }.toList()
      ..sort(
            (a, b) => b.compareTo(a),
      );

    if (!availableYears.contains(_selectedYear)) {
      _selectedYear = availableYears.first;
    }

    final yearPeriods = allPeriods
        .where(
          (period) =>
      period.periodYear == _selectedYear,
    )
        .toList();

    final filteredRows = _buildMonthlyRows(yearPeriods)
        .where(_matchesFilter)
        .toList();

    final total = yearPeriods.length;

    final draftCount = yearPeriods
        .where(
          (e) => e.status == 'draft',
    )
        .length;

    final calculatedCount = yearPeriods
        .where(
          (e) => e.status == 'calculated',
    )
        .length;

    final approvedCount = yearPeriods
        .where(
          (e) => e.status == 'approved',
    )
        .length;

    final paidCount = yearPeriods
        .where(
          (e) => e.status == 'paid',
    )
        .length;

    final cancelledCount = yearPeriods
        .where(
          (e) => e.status == 'cancelled',
    )
        .length;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        // ========================================================
        // HEADER
        // ========================================================

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'دوره‌های حقوق',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'مدیریت دوره‌های حقوق بر اساس سال مالی و ماه',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // ==================================================
            // YEAR DROPDOWN
            // ==================================================

            Container(
              width: 170,
              height: 46,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedYear,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                  ),
                  items: availableYears
                      .map(
                        (year) =>
                        DropdownMenuItem<int>(
                          value: year,
                          child: Row(
                            mainAxisSize:
                            MainAxisSize.max,
                            children: [
                              const Icon(
                                Icons
                                    .calendar_today_rounded,
                                size: 18,
                              ),
                              const SizedBox(
                                width: 6,
                              ),
                              Expanded(
                                child: Text(
                                  'سال مالی ${_toPersianDigits(year.toString())}',
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow
                                      .ellipsis,
                                  softWrap: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                  )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _selectedYear = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(width: 12),

            FilledButton.icon(
              onPressed: () async {
                await _openCreateDialog(
                  context,
                  initialYear: _selectedYear,
                );
              },
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'دوره جدید',
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ========================================================
        // SUMMARY
        // ========================================================

        SizedBox(
          height: 112,
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'کل دوره‌ها',
                  value: _toPersianDigits(
                    total.toString(),
                  ),
                  subtitle: 'از ۱۲ ماه سال',
                  icon:
                  Icons.calendar_month_rounded,
                  iconColor:
                  const Color(0xFF1B4332),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _SummaryCard(
                  title: 'پیش‌نویس',
                  value: _toPersianDigits(
                    draftCount.toString(),
                  ),
                  subtitle: 'نیازمند تکمیل',
                  icon:
                  Icons.edit_note_rounded,
                  iconColor:
                  Colors.orange.shade700,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _SummaryCard(
                  title: 'محاسبه شده',
                  value: _toPersianDigits(
                    calculatedCount.toString(),
                  ),
                  subtitle: 'آماده بررسی',
                  icon:
                  Icons.calculate_rounded,
                  iconColor:
                  Colors.blue.shade700,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _SummaryCard(
                  title: 'تأیید شده',
                  value: _toPersianDigits(
                    approvedCount.toString(),
                  ),
                  subtitle: 'قفل شده',
                  icon:
                  Icons.verified_rounded,
                  iconColor:
                  Colors.indigo.shade700,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _SummaryCard(
                  title: 'پرداخت شده',
                  value: _toPersianDigits(
                    paidCount.toString(),
                  ),
                  subtitle: 'تکمیل نهایی',
                  icon:
                  Icons.payments_rounded,
                  iconColor:
                  Colors.green.shade700,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _SummaryCard(
                  title: 'لغو شده',
                  value: _toPersianDigits(
                    cancelledCount.toString(),
                  ),
                  subtitle: 'دوره‌های لغو شده',
                  icon:
                  Icons.cancel_rounded,
                  iconColor:
                  Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ========================================================
        // MAIN AREA
        // ========================================================

        Expanded(
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _FiltersBar(
                      search: _search,
                      statusFilter:
                      _statusFilter,
                      onSearchChanged: (value) {
                        setState(() {
                          _search = value;
                        });
                      },
                      onStatusChanged: (value) {
                        setState(() {
                          _statusFilter = value;
                        });
                      },
                      onClear: () {
                        setState(() {
                          _search = '';
                          _statusFilter = 'all';
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    Expanded(
                      child:
                      filteredRows.isEmpty
                          ? const _EmptyFilteredView()
                          : _PeriodsTable(
                        rows: filteredRows,
                        companyId:
                        widget.companyId,
                        onRefresh: () {
                          ref.invalidate(
                            payrollPeriodsProvider(
                              widget.companyId,
                            ),
                          );
                        },
                        onCreate: (month) {
                          return _openCreateDialog(
                            context,
                            initialYear:
                            _selectedYear,
                            initialMonth:
                            month,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // ==================================================
              // SIDE INFO
              // ==================================================

              SizedBox(
                width: 280,
                child: _YearInfoCard(
                  year: _selectedYear,
                  existingCount:
                  yearPeriods.length,
                  onCreateNext: () {
                    final nextMonth =
                    _findNextMissingMonth(
                      yearPeriods,
                    );

                    _openCreateDialog(
                      context,
                      initialYear:
                      _selectedYear,
                      initialMonth:
                      nextMonth,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MONTHLY ROWS
  // ============================================================

  List<_MonthlyRow> _buildMonthlyRows(
      List<PayrollPeriodModel> periods,
      ) {
    final map =
    <int, PayrollPeriodModel>{};

    for (final period in periods) {
      if (period.periodMonth >= 1 &&
          period.periodMonth <= 12) {
        map[period.periodMonth] = period;
      }
    }

    return List.generate(
      12,
          (index) {
        final month = index + 1;

        return _MonthlyRow(
          month: month,
          period: map[month],
        );
      },
    );
  }

  bool _matchesFilter(
      _MonthlyRow row,
      ) {
    final period = row.period;

    if (_statusFilter != 'all') {
      if (_statusFilter == 'missing') {
        if (period != null) {
          return false;
        }
      } else {
        if (period == null ||
            period.status !=
                _statusFilter) {
          return false;
        }
      }
    }

    if (_search.trim().isNotEmpty) {
      final query =
      _search.trim().toLowerCase();

      final monthName =
      _monthName(row.month)
          .toLowerCase();

      final title =
      '${monthName} $_selectedYear'
          .toLowerCase();

      if (!monthName.contains(query) &&
          !title.contains(query)) {
        return false;
      }
    }

    return true;
  }

  int _findNextMissingMonth(
      List<PayrollPeriodModel> periods,
      ) {
    final existing =
    periods
        .map((e) => e.periodMonth)
        .toSet();

    for (var month = 1;
    month <= 12;
    month++) {
      if (!existing.contains(month)) {
        return month;
      }
    }

    return 1;
  }

  // ============================================================
  // CREATE DIALOG
  // ============================================================

  Future<void> _openCreateDialog(
      BuildContext context, {
        required int initialYear,
        int? initialMonth,
      }) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return PayrollPeriodFormDialog(
          companyId: widget.companyId,
        );
      },
    );

    if (!mounted) {
      return;
    }

    ref.invalidate(
      payrollPeriodsProvider(
        widget.companyId,
      ),
    );
  }

  // ============================================================
  // MONTH
  // ============================================================

  String _monthName(int month) {
    const months = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];

    if (month < 1 ||
        month > 12) {
      return 'نامشخص';
    }

    return months[month - 1];
  }

  // ============================================================
  // PERSIAN DIGITS
  // ============================================================

  String _toPersianDigits(
      String value,
      ) {
    const english =
        '0123456789';

    const persian =
        '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (var i = 0;
    i < 10;
    i++) {
      result = result.replaceAll(
        english[i],
        persian[i],
      );
    }

    return result;
  }
}

// ============================================================
// MONTHLY ROW MODEL
// ============================================================

class _MonthlyRow {
  const _MonthlyRow({
    required this.month,
    required this.period,
  });

  final int month;
  final PayrollPeriodModel? period;
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _SummaryCard
    extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color:
              iconColor.withOpacity(.10),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  style:
                  const TextStyle(
                    fontSize: 22,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                    Colors.grey.shade500,
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

// ============================================================
// FILTERS
// ============================================================

class _FiltersBar
    extends StatelessWidget {
  const _FiltersBar({
    required this.search,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onClear,
  });

  final String search;
  final String statusFilter;
  final ValueChanged<String>
  onSearchChanged;
  final ValueChanged<String>
  onStatusChanged;
  final VoidCallback onClear;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller:
              TextEditingController(
                text: search,
              )..selection =
              TextSelection.collapsed(
                offset: search.length,
              ),
              onChanged:
              onSearchChanged,
              decoration:
              InputDecoration(
                hintText:
                'جستجو در ماه یا سال...',
                prefixIcon:
                const Icon(
                  Icons.search_rounded,
                ),
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                  borderSide:
                  BorderSide.none,
                ),
                filled: true,
                fillColor:
                Colors.grey.shade50,
              ),
            ),
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 190,
            child:
            DropdownButtonFormField<
                String>(
              value: statusFilter,
              isExpanded: true,
              decoration:
              InputDecoration(
                labelText: 'وضعیت',
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child:
                  Text('همه وضعیت‌ها'),
                ),
                DropdownMenuItem(
                  value: 'draft',
                  child:
                  Text('پیش‌نویس'),
                ),
                DropdownMenuItem(
                  value: 'calculated',
                  child:
                  Text('محاسبه شده'),
                ),
                DropdownMenuItem(
                  value: 'approved',
                  child:
                  Text('تأیید شده'),
                ),
                DropdownMenuItem(
                  value: 'paid',
                  child:
                  Text('پرداخت شده'),
                ),
                DropdownMenuItem(
                  value: 'cancelled',
                  child:
                  Text('لغو شده'),
                ),
                DropdownMenuItem(
                  value: 'missing',
                  child:
                  Text('ایجاد نشده'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onStatusChanged(
                    value,
                  );
                }
              },
            ),
          ),

          const SizedBox(width: 10),

          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(
              Icons.filter_alt_off_rounded,
            ),
            label:
            const Text('پاک کردن'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TABLE
// ============================================================

class _PeriodsTable
    extends ConsumerWidget {
  const _PeriodsTable({
    required this.rows,
    required this.companyId,
    required this.onRefresh,
    required this.onCreate,
  });

  final List<_MonthlyRow> rows;
  final String companyId;
  final VoidCallback onRefresh;
  final Future<void> Function(
      int month,
      ) onCreate;

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 54,
            padding:
            const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            decoration:
            BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
              const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 55,
                  child: Text(
                    '#',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Text(
                    'ماه',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ),

                Expanded(
                  flex: 3,
                  child: Text(
                    'بازه دوره',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Text(
                    'وضعیت',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ),

                SizedBox(
                  width: 150,
                  child: Text(
                    'عملیات',
                    style:
                    TextStyle(
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child:
            ListView.separated(
              itemCount:
              rows.length,
              separatorBuilder:
                  (_, __) {
                return Divider(
                  height: 1,
                  color:
                  Colors.grey.shade200,
                );
              },
              itemBuilder:
                  (context, index) {
                final row =
                rows[index];

                return _MonthlyTableRow(
                  row: row,
                  companyId:
                  companyId,
                  onRefresh:
                  onRefresh,
                  onCreate:
                  onCreate,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TABLE ROW
// ============================================================

class _MonthlyTableRow extends StatelessWidget {
  const _MonthlyTableRow({
    required this.row,
    required this.companyId,
    required this.onRefresh,
    required this.onCreate,
  });

  final _MonthlyRow row;
  final String companyId;
  final VoidCallback onRefresh;
  final Future<void> Function(int month) onCreate;

  @override
  Widget build(BuildContext context) {
    final period = row.period;
    final isMissing = period == null;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: Row(
        children: [
          // ==================================================
          // NUMBER
          // ==================================================

          SizedBox(
            width: 55,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isMissing
                    ? Colors.grey.shade100
                    : const Color(
                  0xFF1B4332,
                ).withOpacity(.08),
                borderRadius:
                BorderRadius.circular(9),
              ),
              child: Text(
                _toPersianDigitsStatic(
                  row.month.toString(),
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isMissing
                      ? Colors.grey.shade600
                      : const Color(0xFF1B4332),
                ),
              ),
            ),
          ),

          // ==================================================
          // MONTH
          // ==================================================

          Expanded(
            flex: 2,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _monthNameStatic(row.month),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                if (isMissing) ...[
                  const SizedBox(width: 6),

                  Flexible(
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius:
                        BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ثبت نشده',
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ==================================================
          // PERIOD RANGE
          // ==================================================

          Expanded(
            flex: 3,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              child: Text(
                period == null
                    ? '—'
                    : _periodRange(period),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isMissing
                      ? Colors.grey.shade400
                      : Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // ==================================================
          // STATUS
          // ==================================================

          Expanded(
            flex: 2,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              child: _StatusBadge(
                status: period?.status,
              ),
            ),
          ),

          // ==================================================
          // OPERATIONS
          // ==================================================

          SizedBox(
            width: 170,
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.start,
              children: [
                if (period != null) ...[
                  // ------------------------------------------
                  // VIEW BUTTON
                  // ------------------------------------------

                  Flexible(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PayrollRecordsPage(
                                  companyId: companyId,
                                  period: period,
                                ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                        const Size(0, 38),
                        maximumSize:
                        const Size(
                          double.infinity,
                          38,
                        ),
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 9,
                        ),
                        visualDensity:
                        VisualDensity.compact,
                        tapTargetSize:
                        MaterialTapTargetSize
                            .shrinkWrap,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.visibility_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'مشاهده',
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // فاصله کم و کنترل‌شده
                  const SizedBox(width: 2),

                  // ------------------------------------------
                  // MORE MENU
                  // ------------------------------------------

                  SizedBox(
                    width: 36,
                    height: 38,
                    child: PopupMenuButton<String>(
                      tooltip: 'بیشتر',
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await showDialog<void>(
                            context: context,
                            builder: (_) =>
                                PayrollPeriodFormDialog(
                                  companyId: companyId,
                                  period: period,
                                ),
                          );

                          onRefresh();
                        }

                        if (value == 'delete') {
                          await _deletePeriod(
                            context,
                            period,
                          );

                          onRefresh();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            mainAxisSize:
                            MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 19,
                              ),
                              SizedBox(width: 8),
                              Text('ویرایش'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            mainAxisSize:
                            MainAxisSize.min,
                            children: [
                              Icon(
                                Icons
                                    .delete_outline_rounded,
                                color: Colors.red,
                                size: 19,
                              ),
                              SizedBox(width: 8),
                              Text('حذف'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // ------------------------------------------
                  // CREATE BUTTON
                  // ------------------------------------------

                  Flexible(
                    child:
                    FilledButton.tonalIcon(
                      onPressed: () {
                        onCreate(row.month);
                      },
                      style:
                      FilledButton.styleFrom(
                        minimumSize:
                        const Size(0, 38),
                        maximumSize:
                        const Size(
                          double.infinity,
                          38,
                        ),
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 12,
                        ),
                        visualDensity:
                        VisualDensity.compact,
                        tapTargetSize:
                        MaterialTapTargetSize
                            .shrinkWrap,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 17,
                      ),
                      label: const Text(
                        'ایجاد',
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deletePeriod(
      BuildContext context,
      PayrollPeriodModel period,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'حذف دوره حقوق',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'آیا از حذف دوره ${period.title} مطمئن هستید؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child: const Text(
                'انصراف',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                Colors.red.shade700,
              ),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'حذف',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final repository =
      ProviderScope.containerOf(
        context,
        listen: false,
      ).read(
        payrollPeriodRepositoryProvider,
      );

      await repository.deletePeriod(
        period.id,
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'دوره حقوق حذف شد.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          backgroundColor:
          Colors.red.shade700,
          content: Text(
            _friendlyError(error),
          ),
        ),
      );
    }
  }
}
// ============================================================
// STATUS BADGE
// ============================================================

class _StatusBadge
    extends StatelessWidget {
  const _StatusBadge({
    required this.status,
  });

  final String? status;

  @override
  Widget build(
      BuildContext context,
      ) {
    if (status == null) {
      return _badge(
        text: 'ایجاد نشده',
        icon:
        Icons.radio_button_unchecked_rounded,
        foreground:
        Colors.grey.shade600,
        background:
        Colors.grey.shade100,
      );
    }

    switch (status) {
      case 'draft':
        return _badge(
          text: 'پیش‌نویس',
          icon:
          Icons.edit_note_rounded,
          foreground:
          Colors.orange.shade800,
          background:
          Colors.orange.shade50,
        );

      case 'calculated':
        return _badge(
          text: 'محاسبه شده',
          icon:
          Icons.calculate_rounded,
          foreground:
          Colors.blue.shade800,
          background:
          Colors.blue.shade50,
        );

      case 'approved':
        return _badge(
          text: 'تأیید شده',
          icon:
          Icons.verified_rounded,
          foreground:
          Colors.indigo.shade800,
          background:
          Colors.indigo.shade50,
        );

      case 'paid':
        return _badge(
          text: 'پرداخت شده',
          icon:
          Icons.payments_rounded,
          foreground:
          Colors.green.shade800,
          background:
          Colors.green.shade50,
        );

      case 'cancelled':
        return _badge(
          text: 'لغو شده',
          icon:
          Icons.cancel_rounded,
          foreground:
          Colors.red.shade800,
          background:
          Colors.red.shade50,
        );

      default:
        return _badge(
          text: status!,
          icon:
          Icons.help_outline_rounded,
          foreground:
          Colors.grey.shade700,
          background:
          Colors.grey.shade100,
        );
    }
  }

  Widget _badge({
    required String text,
    required IconData icon,
    required Color foreground,
    required Color background,
  }) {
    return Align(
      alignment:
      Alignment.centerRight,
      child: Container(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration:
        BoxDecoration(
          color: background,
          borderRadius:
          BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: foreground,
            ),
            const SizedBox(
              width: 5,
            ),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontSize: 11,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// YEAR INFO
// ============================================================

class _YearInfoCard
    extends StatelessWidget {
  const _YearInfoCard({
    required this.year,
    required this.existingCount,
    required this.onCreateNext,
  });

  final int year;
  final int existingCount;
  final VoidCallback onCreateNext;

  @override
  Widget build(
      BuildContext context,
      ) {
    final missing =
        12 - existingCount;

    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFF1B4332,
                  ).withOpacity(.08),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: const Icon(
                  Icons
                      .calendar_month_rounded,
                  color:
                  Color(0xFF1B4332),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    const Text(
                      'سال مالی',
                      style:
                      TextStyle(
                        fontSize: 11,
                        color:
                        Colors.grey,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      _toPersianDigitsStatic(
                        year.toString(),
                      ),
                      style:
                      const TextStyle(
                        fontSize: 19,
                        fontWeight:
                        FontWeight
                            .w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          _InfoLine(
            label:
            'دوره‌های ایجاد شده',
            value:
            '${_toPersianDigitsStatic(existingCount.toString())} از ۱۲',
          ),

          const SizedBox(
            height: 10,
          ),

          _InfoLine(
            label:
            'ماه‌های باقی‌مانده',
            value:
            _toPersianDigitsStatic(
              missing.toString(),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          ClipRRect(
            borderRadius:
            BorderRadius.circular(
              10,
            ),
            child:
            LinearProgressIndicator(
              minHeight: 8,
              value:
              (existingCount / 12)
                  .clamp(
                0.0,
                1.0,
              ),
              backgroundColor:
              Colors.grey.shade200,
              color:
              const Color(
                0xFF1B4332,
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          Text(
            'نکته',
            style: TextStyle(
              fontWeight:
              FontWeight.w900,
              color:
              Colors.grey.shade800,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'برای هر ماه سال مالی یک دوره حقوق داشته باشید. ماه‌هایی که هنوز ایجاد نشده‌اند با وضعیت «ایجاد نشده» نمایش داده می‌شوند.',
            style: TextStyle(
              fontSize: 11,
              height: 1.6,
              color:
              Colors.grey.shade600,
            ),
          ),

          const Spacer(),

          SizedBox(
            width:
            double.infinity,
            child:
            FilledButton.tonalIcon(
              onPressed:
              missing == 0
                  ? null
                  : onCreateNext,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label:
              const Text(
                'ایجاد ماه بعدی',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INFO LINE
// ============================================================

class _InfoLine
    extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color:
              Colors.grey.shade600,
            ),
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        Text(
          value,
          maxLines: 1,
          overflow:
          TextOverflow.ellipsis,
          style:
          const TextStyle(
            fontSize: 12,
            fontWeight:
            FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EMPTY
// ============================================================

class _EmptyFilteredView
    extends StatelessWidget {
  const _EmptyFilteredView();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 54,
            color:
            Colors.grey.shade400,
          ),

          const SizedBox(
            height: 12,
          ),

          const Text(
            'دوره‌ای با این فیلتر پیدا نشد.',
            style:
            TextStyle(
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'فیلترها را تغییر دهید یا پاک کنید.',
            style: TextStyle(
              color:
              Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _ErrorView
    extends StatelessWidget {
  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            Icons
                .error_outline_rounded,
            size: 50,
            color:
            Colors.red.shade700,
          ),

          const SizedBox(
            height: 12,
          ),

          Padding(
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 30,
            ),
            child: Text(
              error,
              textAlign:
              TextAlign.center,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label:
            const Text(
              'تلاش مجدد',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

String _monthNameStatic(
    int month,
    ) {
  const months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  if (month < 1 ||
      month > 12) {
    return 'نامشخص';
  }

  return months[month - 1];
}

String _periodRange(
    PayrollPeriodModel period,
    ) {
  final year =
  _toPersianDigitsStatic(
    period.periodYear.toString(),
  );

  final month =
  _toPersianDigitsStatic(
    period.periodMonth
        .toString()
        .padLeft(
      2,
      '0',
    ),
  );

  return '$year/$month/۰۱  تا  $year/$month/۳۱';
}

String _toPersianDigitsStatic(
    String value,
    ) {
  const english =
      '0123456789';

  const persian =
      '۰۱۲۳۴۵۶۷۸۹';

  var result = value;

  for (var i = 0;
  i < 10;
  i++) {
    result = result.replaceAll(
      english[i],
      persian[i],
    );
  }

  return result;
}

String _friendlyError(
    Object error,
    ) {
  final message =
  error.toString();

  if (message.contains('23505') ||
      message
          .toLowerCase()
          .contains('duplicate')) {
    return 'این دوره حقوق قبلاً برای این ماه ثبت شده است.';
  }

  if (message.contains('42501') ||
      message
          .toLowerCase()
          .contains(
        'permission denied',
      )) {
    return 'دسترسی لازم برای انجام این عملیات وجود ندارد.';
  }

  if (message.contains('23503')) {
    return 'اطلاعات مرتبط با این دوره معتبر نیست.';
  }

  if (message.startsWith(
    'Exception: ',
  )) {
    return message.substring(
      'Exception: '.length,
    );
  }

  return message;
}