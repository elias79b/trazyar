import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';
import 'package:tarazyar/consultant/companies/expenses/application/expense_fiscal_provider.dart';

const Color _projectColor = Color(0xFF163A2B);
const Color _projectColorLight = Color(0xFF245B45);
const Color _projectColorSoft = Color(0xFFEAF2EE);

const List<String> _jalaliMonths = [
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

class ExpenseFiscalPeriodsPage extends ConsumerStatefulWidget {
  final String companyId;

  const ExpenseFiscalPeriodsPage({super.key, required this.companyId});

  @override
  ConsumerState<ExpenseFiscalPeriodsPage> createState() =>
      _ExpenseFiscalPeriodsPageState();
}

class _ExpenseFiscalPeriodsPageState
    extends ConsumerState<ExpenseFiscalPeriodsPage> {
  String? _selectedYearId;

  @override
  Widget build(BuildContext context) {
    final yearsAsync = ref.watch(expenseFiscalYearsProvider(widget.companyId));

    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute:
          '/consultant/companies/${widget.companyId}/expenses/periods',
      title: 'دوره‌های مالی هزینه',
      body: yearsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => _ErrorView(
              message: _errorMessage(error),
              onRetry: () {
                ref.invalidate(expenseFiscalYearsProvider(widget.companyId));
              },
            ),
        data: (years) {
          if (years.isEmpty) {
            return _EmptyYearView(onCreate: _showCreateYearDialog);
          }

          final selectedYear = _resolveSelectedYear(years);

          if (selectedYear == null) {
            return _EmptyYearView(onCreate: _showCreateYearDialog);
          }

          return _PageContent(
            companyId: widget.companyId,
            years: years,
            selectedYear: selectedYear,
            onYearChanged: (yearId) {
              setState(() {
                _selectedYearId = yearId;
              });
            },
            onCreateYear: _showCreateYearDialog,
            onCloseYear: () => _changeYearStatus(selectedYear, close: true),
            onReopenYear: () => _changeYearStatus(selectedYear, close: false),
            onRefresh: () {
              ref.invalidate(expenseFiscalYearsProvider(widget.companyId));
              ref.invalidate(
                expenseFiscalPeriodsProvider(selectedYear['id'].toString()),
              );
            },
          );
        },
      ),
    );
  }

  Map<String, dynamic>? _resolveSelectedYear(List<Map<String, dynamic>> years) {
    if (_selectedYearId != null) {
      for (final year in years) {
        if (year['id'].toString() == _selectedYearId) {
          return year;
        }
      }
    }

    return years.first;
  }

  Future<void> _showCreateYearDialog() async {
    final yearController = TextEditingController();
    final titleController = TextEditingController();

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('ایجاد سال مالی هزینه'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'سال مالی',
                        hintText: 'مثلاً ۱۴۰۵',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'عنوان سال مالی',
                        hintText: 'مثلاً سال مالی ۱۴۰۵',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _projectColor),
                  onPressed: () {
                    final yearText =
                        _normalizeDigits(yearController.text).trim();

                    final year = int.tryParse(yearText);

                    if (year == null || year < 1300 || year > 1600) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('سال مالی باید بین ۱۳۰۰ تا ۱۶۰۰ باشد.'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop({'year': year, 'title': titleController.text.trim()});
                  },
                  child: const Text('ایجاد سال مالی'),
                ),
              ],
            ),
          );
        },
      );

      if (result == null) return;
      if (!mounted) return;

      await _runBusyAction(() async {
        final yearId = await ExpenseFiscalService.createFiscalYear(
          companyId: widget.companyId,
          year: result['year'] as int,
          title:
              (result['title'] as String).isEmpty
                  ? null
                  : result['title'] as String,
        );

        if (!mounted) return;

        setState(() {
          _selectedYearId = yearId;
        });

        ref.invalidate(expenseFiscalYearsProvider(widget.companyId));
      });
    } finally {
      yearController.dispose();
      titleController.dispose();
    }
  }

  Future<void> _changeYearStatus(
    Map<String, dynamic> year, {
    required bool close,
  }) async {
    final yearId = year['id'].toString();
    final status = year['status']?.toString() ?? 'open';

    if (close && status == 'closed') return;
    if (!close && status == 'open') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(close ? 'بستن سال مالی' : 'باز کردن سال مالی'),
            content: Text(
              close
                  ? 'آیا از بستن سال مالی ${year['year']} مطمئن هستید؟'
                  : 'آیا از باز کردن سال مالی ${year['year']} مطمئن هستید؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _projectColor),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(close ? 'بستن سال مالی' : 'باز کردن'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    await _runBusyAction(() async {
      if (close) {
        await ExpenseFiscalService.closeFiscalYear(yearId);
      } else {
        await ExpenseFiscalService.reopenFiscalYear(yearId);
      }

      ref.invalidate(expenseFiscalYearsProvider(widget.companyId));

      ref.invalidate(expenseFiscalPeriodsProvider(yearId));
    });
  }

  Future<void> _runBusyAction(Future<void> Function() action) async {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                SizedBox(width: 16),
                Text('در حال پردازش...'),
              ],
            ),
          ),
        );
      },
    );

    try {
      await action();
    } catch (error) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      }

      return;
    }

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('عملیات با موفقیت انجام شد.')),
      );
    }
  }

  String _errorMessage(Object error) {
    if (error is PostgrestException) {
      return error.message;
    }

    return error.toString().replaceFirst('Exception: ', '');
  }

  String _normalizeDigits(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';
    const en = '0123456789';

    var result = value;

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(fa[i], en[i]);
      result = result.replaceAll(ar[i], en[i]);
    }

    return result;
  }
}

class _PageContent extends ConsumerWidget {
  final String companyId;
  final List<Map<String, dynamic>> years;
  final Map<String, dynamic> selectedYear;
  final ValueChanged<String> onYearChanged;
  final VoidCallback onCreateYear;
  final VoidCallback onCloseYear;
  final VoidCallback onReopenYear;
  final VoidCallback onRefresh;

  const _PageContent({
    required this.companyId,
    required this.years,
    required this.selectedYear,
    required this.onYearChanged,
    required this.onCreateYear,
    required this.onCloseYear,
    required this.onReopenYear,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearId = selectedYear['id'].toString();

    final periodsAsync = ref.watch(expenseFiscalPeriodsProvider(yearId));

    final status = selectedYear['status']?.toString() ?? 'open';

    final isClosed = status == 'closed';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(expenseFiscalYearsProvider(companyId));
              ref.invalidate(expenseFiscalPeriodsProvider(yearId));

              await ref.read(expenseFiscalYearsProvider(companyId).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 14 : 24),
              children: [
                _Header(
                  years: years,
                  selectedYear: selectedYear,
                  isClosed: isClosed,
                  onYearChanged: onYearChanged,
                  onCreateYear: onCreateYear,
                  onCloseYear: onCloseYear,
                  onReopenYear: onReopenYear,
                  onRefresh: onRefresh,
                ),
                const SizedBox(height: 20),
                _YearSummary(
                  year: selectedYear,
                  periods: periodsAsync.valueOrNull ?? const [],
                ),
                const SizedBox(height: 20),
                periodsAsync.when(
                  loading:
                      () => const SizedBox(
                        height: 360,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  error:
                      (error, stack) => _ErrorView(
                        message:
                            error is PostgrestException
                                ? error.message
                                : error.toString(),
                        onRetry: () {
                          ref.invalidate(expenseFiscalPeriodsProvider(yearId));
                        },
                      ),
                  data: (periods) {
                    if (periods.isEmpty) {
                      return const _EmptyPeriods();
                    }

                    return _PeriodsGrid(
                      companyId: companyId,
                      periods: periods,
                      fiscalYearStatus: status,
                      isMobile: isMobile,
                      onRefresh: () {
                        ref.invalidate(expenseFiscalPeriodsProvider(yearId));
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final List<Map<String, dynamic>> years;
  final Map<String, dynamic> selectedYear;
  final bool isClosed;
  final ValueChanged<String> onYearChanged;
  final VoidCallback onCreateYear;
  final VoidCallback onCloseYear;
  final VoidCallback onReopenYear;
  final VoidCallback onRefresh;

  const _Header({
    required this.years,
    required this.selectedYear,
    required this.isClosed,
    required this.onYearChanged,
    required this.onCreateYear,
    required this.onCloseYear,
    required this.onReopenYear,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child:
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TitleBlock(selectedYear: selectedYear, isClosed: isClosed),
                  const SizedBox(height: 16),
                  _YearDropdown(
                    years: years,
                    selectedYear: selectedYear,
                    onChanged: onYearChanged,
                  ),
                  const SizedBox(height: 12),
                  _ActionButtons(
                    isClosed: isClosed,
                    onCreateYear: onCreateYear,
                    onCloseYear: onCloseYear,
                    onReopenYear: onReopenYear,
                    onRefresh: onRefresh,
                  ),
                ],
              )
              : Row(
                children: [
                  Expanded(
                    child: _TitleBlock(
                      selectedYear: selectedYear,
                      isClosed: isClosed,
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: 230,
                    child: _YearDropdown(
                      years: years,
                      selectedYear: selectedYear,
                      onChanged: onYearChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _ActionButtons(
                    isClosed: isClosed,
                    onCreateYear: onCreateYear,
                    onCloseYear: onCloseYear,
                    onReopenYear: onReopenYear,
                    onRefresh: onRefresh,
                  ),
                ],
              ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final Map<String, dynamic> selectedYear;
  final bool isClosed;

  const _TitleBlock({required this.selectedYear, required this.isClosed});

  @override
  Widget build(BuildContext context) {
    final year = selectedYear['year']?.toString() ?? '-';

    final title = selectedYear['title']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'دوره‌های مالی هزینه',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _projectColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title?.isNotEmpty == true ? title! : 'سال مالی $year',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isClosed ? Colors.grey.shade100 : _projectColorSoft,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            isClosed ? 'سال مالی بسته است' : 'سال مالی باز است',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isClosed ? Colors.grey.shade700 : _projectColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _YearDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> years;
  final Map<String, dynamic> selectedYear;
  final ValueChanged<String> onChanged;

  const _YearDropdown({
    required this.years,
    required this.selectedYear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedYear['id'].toString(),
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'سال مالی',
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items:
          years.map((year) {
            final id = year['id'].toString();
            final value = year['year']?.toString() ?? '-';

            return DropdownMenuItem<String>(
              value: id,
              child: Text('سال مالی $value', overflow: TextOverflow.ellipsis),
            );
          }).toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool isClosed;
  final VoidCallback onCreateYear;
  final VoidCallback onCloseYear;
  final VoidCallback onReopenYear;
  final VoidCallback onRefresh;

  const _ActionButtons({
    required this.isClosed,
    required this.onCreateYear,
    required this.onCloseYear,
    required this.onReopenYear,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: onCreateYear,
          icon: const Icon(Icons.add),
          label: const Text('سال مالی جدید'),
        ),
        IconButton(
          tooltip: 'بازخوانی',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
        if (isClosed)
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _projectColor),
            onPressed: onReopenYear,
            icon: const Icon(Icons.lock_open),
            label: const Text('باز کردن سال'),
          )
        else
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _projectColor),
            onPressed: onCloseYear,
            icon: const Icon(Icons.lock_outline),
            label: const Text('بستن سال'),
          ),
      ],
    );
  }
}

class _YearSummary extends StatelessWidget {
  final Map<String, dynamic> year;
  final List<Map<String, dynamic>> periods;

  const _YearSummary({required this.year, required this.periods});

  @override
  Widget build(BuildContext context) {
    final openCount = periods.where((item) => item['status'] == 'open').length;

    final closedCount =
        periods.where((item) => item['status'] == 'closed').length;

    final yearValue = year['year']?.toString() ?? '-';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        final cards = [
          _SummaryCard(
            title: 'سال مالی',
            value: yearValue,
            icon: Icons.calendar_month_outlined,
          ),
          _SummaryCard(
            title: 'دوره‌های باز',
            value: openCount.toString(),
            icon: Icons.lock_open_outlined,
          ),
          _SummaryCard(
            title: 'دوره‌های بسته',
            value: closedCount.toString(),
            icon: Icons.lock_outline,
          ),
          _SummaryCard(
            title: 'تعداد ماه‌ها',
            value: periods.length.toString(),
            icon: Icons.calendar_view_month_outlined,
          ),
        ];

        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _projectColorSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _projectColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _projectColor,
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

class _PeriodsGrid extends StatelessWidget {
  final String companyId;
  final List<Map<String, dynamic>> periods;
  final String fiscalYearStatus;
  final bool isMobile;
  final VoidCallback onRefresh;

  const _PeriodsGrid({
    required this.companyId,
    required this.periods,
    required this.fiscalYearStatus,
    required this.isMobile,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...periods]..sort(
      (a, b) => ((a['month'] as num?)?.toInt() ?? 0).compareTo(
        (b['month'] as num?)?.toInt() ?? 0,
      ),
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            isMobile
                ? 1
                : MediaQuery.sizeOf(context).width < 1100
                ? 2
                : 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: isMobile ? 1.8 : 1.55,
      ),
      itemBuilder: (context, index) {
        return _PeriodCard(
          companyId: companyId,
          period: sorted[index],
          fiscalYearStatus: fiscalYearStatus,
          onRefresh: onRefresh,
        );
      },
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final String companyId;
  final Map<String, dynamic> period;
  final String fiscalYearStatus;
  final VoidCallback onRefresh;

  const _PeriodCard({
    required this.companyId,
    required this.period,
    required this.fiscalYearStatus,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final month = (period['month'] as num?)?.toInt() ?? 0;

    final year = period['year']?.toString() ?? '-';

    final status = period['status']?.toString() ?? 'open';

    final isClosed = status == 'closed' || fiscalYearStatus == 'closed';

    final monthTitle =
        month >= 1 && month <= 12
            ? _jalaliMonths[month - 1]
            : period['title']?.toString() ?? 'ماه';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isClosed ? Colors.grey.shade300 : _projectColorSoft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isClosed ? Colors.grey.shade100 : _projectColorSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  color: isClosed ? Colors.grey.shade600 : _projectColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _projectColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$year • ماه $month',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(isClosed: isClosed),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      isClosed
                          ? null
                          : () {
                            context.push(
                              '/consultant/companies/$companyId/expenses/recognition/${period['id']}',
                            );
                          },
                  icon: const Icon(Icons.edit_note_outlined, size: 18),
                  label: const Text('ثبت هزینه'),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'عملیات دوره',
                onSelected: (value) async {
                  if (value == 'recognition') {
                    context.push(
                      '/consultant/companies/$companyId/expenses/recognition/${period['id']}',
                    );
                  }

                  if (value == 'status') {
                    await _changePeriodStatus(context, period, isClosed);
                    onRefresh();
                  }
                },
                itemBuilder:
                    (_) => [
                      PopupMenuItem(
                        value: 'recognition',
                        enabled: !isClosed,
                        child: const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_note_outlined),
                          title: Text('ثبت هزینه ماهانه'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'status',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isClosed ? Icons.lock_open : Icons.lock_outline,
                          ),
                          title: Text(isClosed ? 'باز کردن دوره' : 'بستن دوره'),
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _changePeriodStatus(
    BuildContext context,
    Map<String, dynamic> period,
    bool isClosed,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(isClosed ? 'باز کردن دوره' : 'بستن دوره'),
            content: Text(
              isClosed
                  ? 'آیا می‌خواهید دوره ${period['title']} دوباره باز شود؟'
                  : 'آیا می‌خواهید دوره ${period['title']} بسته شود؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _projectColor),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(isClosed ? 'باز کردن' : 'بستن دوره'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      if (isClosed) {
        await ExpenseFiscalService.reopenFiscalPeriod(period['id'].toString());
      } else {
        await ExpenseFiscalService.closeFiscalPeriod(period['id'].toString());
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('وضعیت دوره با موفقیت تغییر کرد.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        final message =
            error is PostgrestException
                ? error.message
                : error.toString().replaceFirst('Exception: ', '');

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}

class _StatusChip extends StatelessWidget {
  final bool isClosed;

  const _StatusChip({required this.isClosed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isClosed ? Colors.grey.shade100 : _projectColorSoft,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        isClosed ? 'بسته' : 'باز',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isClosed ? Colors.grey.shade700 : _projectColor,
        ),
      ),
    );
  }
}

class _EmptyYearView extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyYearView({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 64,
                color: _projectColorLight,
              ),
              const SizedBox(height: 16),
              const Text(
                'هنوز سال مالی هزینه‌ای ایجاد نشده است.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'یک سال مالی ایجاد کنید تا ۱۲ ماه آن به‌صورت خودکار ساخته شود.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _projectColor),
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('ایجاد سال مالی'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPeriods extends StatelessWidget {
  const _EmptyPeriods();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: Text('برای این سال مالی هنوز دوره‌ای ثبت نشده است.'),
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
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _projectColor),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
