import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tarazyar/company_admin/banking/application/company_admin_cash_fiscal_periods_provider.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

class CompanyAdminCashFiscalPeriodsPage extends ConsumerStatefulWidget {
  const CompanyAdminCashFiscalPeriodsPage({super.key});

  @override
  ConsumerState<CompanyAdminCashFiscalPeriodsPage> createState() =>
      _CompanyAdminCashFiscalPeriodsPageState();
}

class _CompanyAdminCashFiscalPeriodsPageState
    extends ConsumerState<CompanyAdminCashFiscalPeriodsPage> {
  String? _selectedFiscalYearId;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initialize);
  }

  Future<void> _initialize() async {
    try {
      await ref
          .read(companyAdminCashFiscalPeriodsProvider.notifier)
          .load();

      if (!mounted) return;

      final state = ref.read(companyAdminCashFiscalPeriodsProvider);

      if (state.fiscalYears.isNotEmpty) {
        setState(() {
          _selectedFiscalYearId = state.fiscalYears.first.id;
        });
      }
    } catch (_) {}
  }

  Future<void> _refresh() async {
    await ref
        .read(companyAdminCashFiscalPeriodsProvider.notifier)
        .load();
  }

  String _statusTitle(String status) {
    return ref
        .read(companyAdminCashFiscalPeriodsProvider.notifier)
        .statusTitle(status);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.green;

      case 'submitted_to_company_admin':
        return Colors.orange;

      case 'submitted_to_consultant':
        return Colors.deepPurple;

      case 'approved':
        return Colors.blue;

      case 'closed':
        return Colors.blueGrey;

      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.edit_calendar_outlined;

      case 'submitted_to_company_admin':
        return Icons.pending_actions;

      case 'submitted_to_consultant':
        return Icons.person_search_outlined;

      case 'approved':
        return Icons.verified_outlined;

      case 'closed':
        return Icons.lock_outline;

      default:
        return Icons.help_outline;
    }
  }

  Future<void> _createYear() async {
    final yearController = TextEditingController();
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('ایجاد سال مالی جدید'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'سال مالی',
                        hintText: 'مثلاً 1407',
                        prefixIcon: Icon(
                          Icons.calendar_month_outlined,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final year = int.tryParse(
                          value?.trim() ?? '',
                        );

                        if (year == null) {
                          return 'سال مالی را وارد کنید';
                        }

                        if (year < 1300 || year > 1600) {
                          return 'سال مالی نامعتبر است';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان سال مالی',
                        hintText: 'مثلاً سال مالی 1407',
                        prefixIcon: Icon(
                          Icons.title_outlined,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'عنوان را وارد کنید';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('انصراف'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }

                  try {
                    final id = await ref
                        .read(
                      companyAdminCashFiscalPeriodsProvider.notifier,
                    )
                        .createFiscalYear(
                      year: int.parse(
                        yearController.text.trim(),
                      ),
                      title: titleController.text.trim(),
                    );

                    if (!dialogContext.mounted) return;

                    Navigator.of(dialogContext).pop(id);
                  } catch (e) {
                    if (!dialogContext.mounted) return;

                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          'خطا در ایجاد سال مالی: $e',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('ایجاد سال'),
              ),
            ],
          );
        },
      );

      if (result != null && mounted) {
        setState(() {
          _selectedFiscalYearId = result;
        });

        await _refresh();
      }
    } finally {
      yearController.dispose();
      titleController.dispose();
    }
  }

  Future<void> _completeMissingMonths() async {
    if (_selectedFiscalYearId == null) {
      return;
    }

    try {
      await ref
          .read(companyAdminCashFiscalPeriodsProvider.notifier)
          .createMissingPeriods(
        _selectedFiscalYearId!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ماه‌های ناقص ایجاد شدند.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: $e'),
        ),
      );
    }
  }

  void _openPeriod(
      CompanyAdminCashFiscalPeriod period,
      ) {
    context.push(
      '/company-admin/banking/fiscal-periods/${period.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      companyAdminCashFiscalPeriodsProvider,
    );

    final selectedYear = state.fiscalYears
        .where(
          (year) => year.id == _selectedFiscalYearId,
    )
        .firstOrNull;

    // مهم:
    // periodsForYear متعلق به Notifier است، نه State.
    final periods = selectedYear == null
        ? <CompanyAdminCashFiscalPeriod>[]
        : ref
        .read(
      companyAdminCashFiscalPeriodsProvider.notifier,
    )
        .periodsForYear(
      selectedYear.id,
    );

    return CompanyAdminScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'دوره‌های مالی نقد و بانک',
          ),
          actions: [
            IconButton(
              tooltip: 'بروزرسانی',
              onPressed: state.isLoading ? null : _refresh,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: state.isLoading && state.fiscalYears.isEmpty
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildYearSelector(
                context,
                state,
              ),
              const SizedBox(height: 20),
              if (selectedYear == null)
                _buildEmptyState()
              else
                _buildYearContent(
                  context,
                  selectedYear,
                  periods,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearSelector(
      BuildContext context,
      CompanyAdminCashFiscalPeriodsState state,
      ) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_month_outlined,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedFiscalYearId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'سال مالی',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: state.fiscalYears
                    .map(
                      (year) => DropdownMenuItem<String>(
                    value: year.id,
                    child: Text(
                      '${year.title} (${year.year})',
                    ),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFiscalYearId = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _createYear,
              icon: const Icon(Icons.add),
              label: const Text('سال جدید'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearContent(
      BuildContext context,
      CompanyAdminCashFiscalYear year,
      List<CompanyAdminCashFiscalPeriod> periods,
      ) {
    final periodMap = <int, CompanyAdminCashFiscalPeriod>{
      for (final period in periods) period.month: period,
    };

    final openCount = periods
        .where(
          (item) => item.status == 'open',
    )
        .length;

    final pendingCount = periods
        .where(
          (item) =>
      item.status == 'submitted_to_company_admin',
    )
        .length;

    final consultantCount = periods
        .where(
          (item) =>
      item.status == 'submitted_to_consultant',
    )
        .length;

    final approvedCount = periods
        .where(
          (item) => item.status == 'approved',
    )
        .length;

    final missingCount = 12 - periods.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildYearHero(
          context,
          year,
          missingCount,
        ),
        const SizedBox(height: 16),
        _buildSummaryCards(
          openCount: openCount,
          pendingCount: pendingCount,
          consultantCount: consultantCount,
          approvedCount: approvedCount,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'ماه‌های سال مالی',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (missingCount > 0)
              OutlinedButton.icon(
                onPressed: _completeMissingMonths,
                icon: const Icon(Icons.playlist_add),
                label: Text(
                  'تکمیل $missingCount ماه',
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            int columns;

            if (width >= 1200) {
              columns = 4;
            } else if (width >= 800) {
              columns = 3;
            } else if (width >= 520) {
              columns = 2;
            } else {
              columns = 1;
            }

            final cardWidth =
                (width - ((columns - 1) * 12)) / columns;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(
                12,
                    (index) {
                  final month = index + 1;
                  final period = periodMap[month];

                  return SizedBox(
                    width: cardWidth,
                    child: _MonthCard(
                      month: month,
                      monthTitle: ref
                          .read(
                        companyAdminCashFiscalPeriodsProvider
                            .notifier,
                      )
                          .monthName(month),
                      period: period,
                      statusTitle: period == null
                          ? null
                          : _statusTitle(period.status),
                      statusColor: period == null
                          ? null
                          : _statusColor(period.status),
                      statusIcon: period == null
                          ? Icons.add_circle_outline
                          : _statusIcon(period.status),
                      onTap: period == null
                          ? null
                          : () => _openPeriod(period),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildYearHero(
      BuildContext context,
      CompanyAdminCashFiscalYear year,
      int missingCount,
      ) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                year.year.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    year.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'سال مالی ${year.year}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (missingCount == 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: Colors.green,
                    ),
                    SizedBox(width: 7),
                    Text(
                      '۱۲ ماه کامل',
                      style: TextStyle(
                        color: Colors.green,
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

  Widget _buildSummaryCards({
    required int openCount,
    required int pendingCount,
    required int consultantCount,
    required int approvedCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;

        if (width >= 1100) {
          columns = 4;
        } else if (width >= 700) {
          columns = 2;
        } else {
          columns = 1;
        }

        final cardWidth =
            (width - ((columns - 1) * 12)) / columns;

        final items = [
          _SummaryData(
            title: 'دوره‌های باز',
            value: openCount,
            icon: Icons.edit_calendar_outlined,
            color: Colors.green,
          ),
          _SummaryData(
            title: 'در انتظار مدیرعامل',
            value: pendingCount,
            icon: Icons.pending_actions,
            color: Colors.orange,
          ),
          _SummaryData(
            title: 'در انتظار مشاور',
            value: consultantCount,
            icon: Icons.person_search_outlined,
            color: Colors.deepPurple,
          ),
          _SummaryData(
            title: 'تأیید نهایی',
            value: approvedCount,
            icon: Icons.verified_outlined,
            color: Colors.blue,
          ),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map(
                (item) => SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                data: item,
              ),
            ),
          )
              .toList(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 64,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 18),
            const Text(
              'هنوز سال مالی ثبت نشده است.',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'برای شروع یک سال مالی ایجاد کنید.',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _createYear,
              icon: const Icon(Icons.add),
              label: const Text('ایجاد سال مالی'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryData data;

  const _SummaryCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: data.color.withOpacity(.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                data.icon,
                color: data.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${data.value}',
                    style: const TextStyle(
                      fontSize: 23,
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

class _MonthCard extends StatelessWidget {
  final int month;
  final String monthTitle;
  final CompanyAdminCashFiscalPeriod? period;
  final String? statusTitle;
  final Color? statusColor;
  final IconData statusIcon;
  final VoidCallback? onTap;

  const _MonthCard({
    required this.month,
    required this.monthTitle,
    required this.period,
    required this.statusTitle,
    required this.statusColor,
    required this.statusIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final exists = period != null;

    final isPending =
        period?.status == 'submitted_to_company_admin';

    final effectiveColor = statusColor ?? Colors.grey;

    return Card(
      elevation: isPending ? 2 : 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: isPending
                ? Border.all(
              color: Colors.orange.withOpacity(.35),
              width: 1.2,
            )
                : null,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isPending
                          ? Colors.orange.withOpacity(.12)
                          : Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      borderRadius:
                      BorderRadius.circular(13),
                    ),
                    child: Text(
                      '$month',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exists
                              ? period!.title
                              : 'ایجاد نشده',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (exists)
                    Icon(
                      Icons.chevron_left,
                      color: Colors.grey.shade500,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (exists)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: effectiveColor.withOpacity(.08),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        statusIcon,
                        size: 18,
                        color: effectiveColor,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          statusTitle!,
                          style: TextStyle(
                            color: effectiveColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(.08),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: Colors.grey,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'این ماه ایجاد نشده',
                        style: TextStyle(
                          color: Colors.grey,
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
}

// =====================================================================
// DETAIL PAGE
// =====================================================================

class CompanyAdminCashFiscalPeriodDetailsPage
    extends ConsumerStatefulWidget {
  final String periodId;

  const CompanyAdminCashFiscalPeriodDetailsPage({
    super.key,
    required this.periodId,
  });

  @override
  ConsumerState<CompanyAdminCashFiscalPeriodDetailsPage>
  createState() =>
      _CompanyAdminCashFiscalPeriodDetailsPageState();
}

class _CompanyAdminCashFiscalPeriodDetailsPageState
    extends ConsumerState<CompanyAdminCashFiscalPeriodDetailsPage> {
  CompanyAdminCashFiscalPeriodReviewData? _data;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await ref
          .read(
        companyAdminCashFiscalPeriodsProvider.notifier,
      )
          .loadPeriodReview(
        widget.periodId,
      );

      if (!mounted) return;

      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _statusTitle(String status) {
    return ref
        .read(
      companyAdminCashFiscalPeriodsProvider.notifier,
    )
        .statusTitle(status);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.green;

      case 'submitted_to_company_admin':
        return Colors.orange;

      case 'submitted_to_consultant':
        return Colors.deepPurple;

      case 'approved':
        return Colors.blue;

      case 'closed':
        return Colors.blueGrey;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // FIXED: _statusIcon WAS MISSING HERE
  // ============================================================

  IconData _statusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.edit_calendar_outlined;

      case 'submitted_to_company_admin':
        return Icons.pending_actions;

      case 'submitted_to_consultant':
        return Icons.person_search_outlined;

      case 'approved':
        return Icons.verified_outlined;

      case 'closed':
        return Icons.lock_outline;

      default:
        return Icons.help_outline;
    }
  }

  Future<String?> _askNote({
    required String title,
    required String actionTitle,
    required String hint,
  }) async {
    final controller = TextEditingController();

    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 480,
              child: TextField(
                controller: controller,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'توضیحات',
                  hintText: hint,
                  border: const OutlineInputBorder(),
                ),
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
                onPressed: () {
                  Navigator.of(dialogContext).pop(
                    controller.text.trim(),
                  );
                },
                child: Text(actionTitle),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _rejectPeriod() async {
    if (_data == null) return;

    if (_data!.period.status !=
        'submitted_to_company_admin') {
      return;
    }

    final note = await _askNote(
      title: 'برگشت دوره به حسابدار',
      actionTitle: 'برگشت برای اصلاح',
      hint:
      'علت برگشت یا مواردی که حسابدار باید اصلاح کند...',
    );

    if (!mounted || note == null) return;

    try {
      await ref
          .read(
        companyAdminCashFiscalPeriodsProvider.notifier,
      )
          .rejectPeriodByCompanyAdmin(
        id: widget.periodId,
        note: note,
      );

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'دوره برای اصلاح به حسابدار برگشت داده شد.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در برگشت دوره: $e',
          ),
        ),
      );
    }
  }

  Future<void> _approvePeriod() async {
    if (_data == null) return;

    if (_data!.period.status !=
        'submitted_to_company_admin') {
      return;
    }

    final note = await _askNote(
      title: 'تأیید و ارسال برای مشاور',
      actionTitle: 'تأیید و ارسال',
      hint:
      'در صورت نیاز توضیح یا نکته‌ای برای مشاور وارد کنید...',
    );

    if (!mounted || note == null) return;

    try {
      await ref
          .read(
        companyAdminCashFiscalPeriodsProvider.notifier,
      )
          .approveAndSendToConsultant(
        id: widget.periodId,
        note: note,
      );

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'دوره تأیید و برای مشاور ارسال شد.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در تأیید دوره: $e',
          ),
        ),
      );
    }
  }

  String _money(dynamic value) {
    if (value == null) {
      return 'ثبت نشده';
    }

    final number = num.tryParse(
      value.toString(),
    );

    if (number == null) {
      return value.toString();
    }

    return number.toStringAsFixed(0);
  }

  Widget _moneyRow(
      String title,
      dynamic value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title),
          ),
          Text(
            _money(value),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
      String title,
      String subtitle,
      IconData icon,
      ) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context)
                .colorScheme
                .primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionPanel() {
    final period = _data!.period;

    if (period.status !=
        'submitted_to_company_admin') {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 1,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withOpacity(.30),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(.10),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pending_actions,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نیاز به بررسی مدیرعامل',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'این دوره توسط حسابدار برای بررسی ارسال شده است.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _rejectPeriod,
                    icon: const Icon(
                      Icons.undo_outlined,
                    ),
                    label: const Text(
                      'رد و برگشت به حسابدار',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize:
                      const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _approvePeriod,
                    icon: const Icon(
                      Icons.send_outlined,
                    ),
                    label: const Text(
                      'تأیید و ارسال برای مشاور',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize:
                      const Size.fromHeight(48),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bankSection() {
    final banks = _data!.bankAccounts;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'حساب‌های بانکی',
              '${banks.length} حساب',
              Icons.account_balance_outlined,
            ),
            const SizedBox(height: 18),
            if (banks.isEmpty)
              _emptySection(
                'هیچ حساب بانکی برای شرکت ثبت نشده است.',
              )
            else
              ...banks.map(
                    (bank) {
                  final data =
                  bank['period_data']
                  as Map<String, dynamic>?;

                  return _FinancialItemCard(
                    title:
                    '${bank['bank_name'] ?? 'بانک'} - ${bank['account_number'] ?? ''}',
                    icon:
                    Icons.account_balance_outlined,
                    child: data == null
                        ? _notRegistered()
                        : Column(
                      children: [
                        _moneyRow(
                          'مانده ابتدای دوره',
                          data['opening_balance'],
                        ),
                        _moneyRow(
                          'گردش بدهکار',
                          data['debit_turnover'],
                        ),
                        _moneyRow(
                          'گردش بستانکار',
                          data['credit_turnover'],
                        ),
                        _moneyRow(
                          'مانده پایان دوره',
                          data['closing_balance'],
                        ),
                        _moneyRow(
                          'مانده دفتر',
                          data['ledger_balance'],
                        ),
                        _moneyRow(
                          'مغایرت',
                          data['discrepancy'],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _cashBoxSection() {
    final boxes = _data!.cashBoxes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'صندوق‌ها',
              '${boxes.length} صندوق',
              Icons.point_of_sale_outlined,
            ),
            const SizedBox(height: 18),
            if (boxes.isEmpty)
              _emptySection(
                'هیچ صندوقی برای شرکت ثبت نشده است.',
              )
            else
              ...boxes.map(
                    (box) {
                  final data =
                  box['period_data']
                  as Map<String, dynamic>?;

                  return _FinancialItemCard(
                    title:
                    box['box_name']?.toString() ??
                        'صندوق',
                    icon:
                    Icons.point_of_sale_outlined,
                    child: data == null
                        ? _notRegistered()
                        : Column(
                      children: [
                        _moneyRow(
                          'مانده ابتدای دوره',
                          data['opening_balance'],
                        ),
                        _moneyRow(
                          'دریافت‌ها',
                          data['total_receipts'],
                        ),
                        _moneyRow(
                          'پرداخت‌ها',
                          data['total_payments'],
                        ),
                        _moneyRow(
                          'مانده پایان دوره',
                          data['closing_balance'],
                        ),
                        _moneyRow(
                          'مانده دفتر',
                          data['ledger_balance'],
                        ),
                        _moneyRow(
                          'مغایرت',
                          data['discrepancy'],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _pettyCashSection() {
    final accounts = _data!.pettyCashAccounts;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'تنخواه‌ها',
              '${accounts.length} تنخواه',
              Icons.wallet_outlined,
            ),
            const SizedBox(height: 18),
            if (accounts.isEmpty)
              _emptySection(
                'هیچ تنخواهی برای شرکت ثبت نشده است.',
              )
            else
              ...accounts.map(
                    (account) {
                  final data =
                  account['period_data']
                  as Map<String, dynamic>?;

                  return _FinancialItemCard(
                    title:
                    account['name']?.toString() ??
                        'تنخواه',
                    icon: Icons.wallet_outlined,
                    child: data == null
                        ? _notRegistered()
                        : Column(
                      children: [
                        _moneyRow(
                          'مانده ابتدای دوره',
                          data['opening_balance'],
                        ),
                        _moneyRow(
                          'دریافت‌ها',
                          data['total_receipts'],
                        ),
                        _moneyRow(
                          'پرداخت‌ها',
                          data['total_payments'],
                        ),
                        _moneyRow(
                          'مانده پایان دوره',
                          data['closing_balance'],
                        ),
                        _moneyRow(
                          'مانده دفتر',
                          data['ledger_balance'],
                        ),
                        _moneyRow(
                          'مغایرت',
                          data['discrepancy'],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptySection(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _notRegistered() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
          ),
          SizedBox(width: 8),
          Text(
            'اطلاعات این مورد برای این دوره ثبت نشده است.',
          ),
        ],
      ),
    );
  }

  Widget _workflowSection() {
    final workflows = _data!.workflows;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'گردش کار دوره',
              'تاریخچه تغییر وضعیت',
              Icons.route_outlined,
            ),
            const SizedBox(height: 18),
            if (workflows.isEmpty)
              _emptySection(
                'هنوز سابقه‌ای برای این دوره ثبت نشده است.',
              )
            else
              ...workflows.map(
                    (workflow) => _WorkflowItem(
                  workflow: workflow,
                  statusTitle: _statusTitle,
                  statusColor: _statusColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompanyAdminScaffold(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _data == null
                ? 'جزئیات دوره مالی'
                : _data!.period.title,
          ),
          leading: IconButton(
            onPressed: () {
              context.pop();
            },
            icon: const Icon(
              Icons.arrow_back,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'بروزرسانی',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: _loading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : _error != null
            ? _buildError()
            : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: Colors.red,
            ),
            const SizedBox(height: 14),
            Text(
              _error!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final period = _data!.period;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildPeriodHeader(period),
          const SizedBox(height: 16),
          _actionPanel(),
          if (period.status ==
              'submitted_to_company_admin')
            const SizedBox(height: 16),
          _bankSection(),
          const SizedBox(height: 16),
          _cashBoxSection(),
          const SizedBox(height: 16),
          _pettyCashSection(),
          const SizedBox(height: 16),
          _workflowSection(),
        ],
      ),
    );
  }

  Widget _buildPeriodHeader(
      CompanyAdminCashFiscalPeriod period,
      ) {
    final color = _statusColor(period.status);

    final isPending =
        period.status == 'submitted_to_company_admin';

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isPending
                    ? Colors.orange.withOpacity(.10)
                    : Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${period.month}',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    period.title,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'سال مالی ${period.year} • ماه ${period.month}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _statusIcon(period.status),
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _statusTitle(period.status),
                    style: TextStyle(
                      color: color,
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

class _FinancialItemCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FinancialItemCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.withOpacity(.18),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _WorkflowItem extends StatelessWidget {
  final CompanyAdminCashFiscalPeriodWorkflow workflow;
  final String Function(String) statusTitle;
  final Color Function(String) statusColor;

  const _WorkflowItem({
    required this.workflow,
    required this.statusTitle,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor(
      workflow.toStatus,
    );

    final createdAt = workflow.createdAt;
    final from = workflow.fromStatus;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.withOpacity(.18),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  from == null
                      ? 'ایجاد دوره → ${statusTitle(workflow.toStatus)}'
                      : '${statusTitle(from)} → ${statusTitle(workflow.toStatus)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (workflow.note != null &&
                    workflow.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(workflow.note!),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    _formatDate(createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
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

  String _formatDate(DateTime date) {
    final local = date.toLocal();

    String two(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${local.year}/${two(local.month)}/${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}