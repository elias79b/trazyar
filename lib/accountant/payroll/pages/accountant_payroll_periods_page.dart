import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tarazyar/accountant/payroll/application/accountant_payroll_periods_provider.dart';
import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';

class AccountantPayrollPeriodsPage extends ConsumerStatefulWidget {
  final String companyId;

  const AccountantPayrollPeriodsPage({super.key, required this.companyId});

  @override
  ConsumerState<AccountantPayrollPeriodsPage> createState() =>
      _AccountantPayrollPeriodsPageState();
}

class _AccountantPayrollPeriodsPageState
    extends ConsumerState<AccountantPayrollPeriodsPage> {
  int? selectedYear;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountantPayrollPeriodsProvider(widget.companyId));

    return AccountantScaffold(
      currentRoute: '/accountant/payroll/periods',
      title: 'دوره‌های حقوق',
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stackTrace) => _ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(
                  accountantPayrollPeriodsProvider(widget.companyId),
                );
              },
            ),
        data: (data) {
          if (data.years.isEmpty) {
            return _EmptyYearsView(onCreateYear: _createFiscalYear);
          }

          final availableYears = data.years.map((item) => item.year).toList();

          final effectiveYear =
              selectedYear != null && availableYears.contains(selectedYear)
                  ? selectedYear!
                  : availableYears.first;

          final selectedFiscalYear = data.year(effectiveYear);

          if (selectedFiscalYear == null) {
            return _EmptyYearsView(onCreateYear: _createFiscalYear);
          }

          final monthMap = <int, AccountantPayrollPeriod>{
            for (final period in selectedFiscalYear.periods)
              period.month: period,
          };

          return Directionality(
            textDirection: TextDirection.rtl,
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                  accountantPayrollPeriodsProvider(widget.companyId),
                );

                await ref.read(
                  accountantPayrollPeriodsProvider(widget.companyId).future,
                );
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _PageHeader(
                    selectedYear: effectiveYear,
                    years: availableYears,
                    fiscalYear: selectedFiscalYear,
                    onYearChanged: (year) {
                      setState(() {
                        selectedYear = year;
                      });
                    },
                    onCreateYear: _createFiscalYear,
                    onCompleteYear: () => _completeExistingYear(effectiveYear),
                  ),
                  const SizedBox(height: 20),
                  _YearSummary(fiscalYear: selectedFiscalYear),
                  const SizedBox(height: 20),
                  _MonthsGrid(
                    monthMap: monthMap,
                    onOpen: _openPeriod,
                    onSubmit: _submitToCeo,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createFiscalYear() async {
    final result = await showDialog<_CreateYearResult>(
      context: context,
      builder: (_) => const _CreateYearDialog(),
    );

    if (result == null) {
      return;
    }

    await _createOrCompleteYear(result.year, result.notes);
  }

  Future<void> _completeExistingYear(int year) async {
    await _createOrCompleteYear(year, null, showMessageOnComplete: true);
  }

  Future<void> _createOrCompleteYear(
    int year,
    String? notes, {
    bool showMessageOnComplete = false,
  }) async {
    try {
      await AccountantPayrollPeriodsRepository.createFiscalYear(
        companyId: widget.companyId,
        year: year,
        notes: notes,
      );

      ref.invalidate(accountantPayrollPeriodsProvider(widget.companyId));

      if (mounted) {
        setState(() {
          selectedYear = year;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'سال مالی $year تکمیل شد؛ ماه‌های ناقص ایجاد شدند.',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      final message = e.toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message, textDirection: TextDirection.rtl)),
      );
    }
  }

  Future<void> _deleteFiscalYear(int year) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف سال مالی'),
            content: Text('آیا سال مالی $year و دوره‌های آن حذف شود؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await AccountantPayrollPeriodsRepository.deleteFiscalYear(
        companyId: widget.companyId,
        year: year,
      );

      ref.invalidate(accountantPayrollPeriodsProvider(widget.companyId));

      if (mounted) {
        setState(() {
          selectedYear = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('سال مالی حذف شد.', textDirection: TextDirection.rtl),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString(), textDirection: TextDirection.rtl)),
      );
    }
  }

  Future<void> _submitToCeo(AccountantPayrollPeriod period) async {
    try {
      await AccountantPayrollPeriodsRepository.submitToCeo(period.id);

      ref.invalidate(accountantPayrollPeriodsProvider(widget.companyId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'دوره برای مدیرعامل ارسال شد.',
              textDirection: TextDirection.rtl,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString(), textDirection: TextDirection.rtl)),
      );
    }
  }

  void _openPeriod(AccountantPayrollPeriod period) {
    context.push('/accountant/payroll/records/${period.id}');
  }
}

class _PageHeader extends StatelessWidget {
  final int selectedYear;
  final List<int> years;
  final AccountantPayrollYear fiscalYear;
  final ValueChanged<int> onYearChanged;
  final VoidCallback onCreateYear;
  final VoidCallback onCompleteYear;

  const _PageHeader({
    required this.selectedYear,
    required this.years,
    required this.fiscalYear,
    required this.onYearChanged,
    required this.onCreateYear,
    required this.onCompleteYear,
  });

  @override
  Widget build(BuildContext context) {
    final incomplete = fiscalYear.periods.length < 12;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 750;

            final title = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'دوره‌های حقوق و دستمزد',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'سال مالی $selectedYear شامل ۱۲ ماه است؛ حسابدار هر ماه را تکمیل و برای مدیرعامل ارسال می‌کند.',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            );

            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'سال مالی',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        years.map((year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onYearChanged(value);
                      }
                    },
                  ),
                ),
                if (incomplete)
                  FilledButton.icon(
                    onPressed: onCompleteYear,
                    icon: const Icon(Icons.build_circle_outlined),
                    label: const Text('تکمیل ۱۲ ماه'),
                  ),
                OutlinedButton.icon(
                  onPressed: onCreateYear,
                  icon: const Icon(Icons.add),
                  label: const Text('ایجاد سال مالی'),
                ),
              ],
            );

            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [title, const SizedBox(height: 16), actions],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: title),
                const SizedBox(width: 20),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _YearSummary extends StatelessWidget {
  final AccountantPayrollYear fiscalYear;

  const _YearSummary({required this.fiscalYear});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 850;

        final cards = [
          _SummaryCard(
            title: 'کل ماه‌ها',
            value: '۱۲',
            icon: Icons.calendar_month_outlined,
          ),
          _SummaryCard(
            title: 'پیش‌نویس',
            value: fiscalYear.draftMonths.toString(),
            icon: Icons.edit_note_outlined,
          ),
          _SummaryCard(
            title: 'ارسال شده',
            value: fiscalYear.pendingCeoMonths.toString(),
            icon: Icons.send_outlined,
          ),
          _SummaryCard(
            title: 'تأیید نهایی',
            value: fiscalYear.approvedMonths.toString(),
            icon: Icons.verified_outlined,
          ),
          _SummaryCard(
            title: 'پرداخت شده',
            value: fiscalYear.paidMonths.toString(),
            icon: Icons.payments_outlined,
          ),
        ];

        if (narrow) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                cards.map((card) {
                  return SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: card,
                  );
                }).toList(),
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 12),
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
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
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

class _MonthsGrid extends StatelessWidget {
  final Map<int, AccountantPayrollPeriod> monthMap;
  final ValueChanged<AccountantPayrollPeriod> onOpen;
  final ValueChanged<AccountantPayrollPeriod> onSubmit;

  const _MonthsGrid({
    required this.monthMap,
    required this.onOpen,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 1300) {
          columns = 4;
        } else if (constraints.maxWidth >= 900) {
          columns = 3;
        } else if (constraints.maxWidth >= 600) {
          columns = 2;
        } else {
          columns = 1;
        }

        final width = (constraints.maxWidth - ((columns - 1) * 14)) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: List.generate(12, (index) {
            final month = index + 1;
            final period = monthMap[month];

            return SizedBox(
              width: width,
              child: _MonthCard(
                month: month,
                period: period,
                onOpen: period == null ? null : () => onOpen(period),
                onSubmit: period == null ? null : () => onSubmit(period),
              ),
            );
          }),
        );
      },
    );
  }
}

class _MonthCard extends StatelessWidget {
  final int month;
  final AccountantPayrollPeriod? period;
  final VoidCallback? onOpen;
  final VoidCallback? onSubmit;

  const _MonthCard({
    required this.month,
    required this.period,
    required this.onOpen,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final hasPeriod = period != null;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade100,
                    ),
                    child: Text(
                      month.toString(),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      payrollMonthName(month),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (hasPeriod)
                    _StatusChip(
                      status: period!.normalizedStatus,
                      title: period!.statusTitle,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (!hasPeriod)
                const Text(
                  'دوره این ماه هنوز ایجاد نشده است.',
                  style: TextStyle(color: Colors.red),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _MonthMetric(
                        title: 'پرسنل',
                        value: _number(period!.employeeCount),
                      ),
                    ),
                    Expanded(
                      child: _MonthMetric(
                        title: 'ناخالص',
                        value: _money(period!.totalGrossSalary),
                      ),
                    ),
                    Expanded(
                      child: _MonthMetric(
                        title: 'خالص',
                        value: _money(period!.totalNetSalary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onOpen,
                        icon: Icon(
                          period!.canEnterRecords
                              ? Icons.edit_note_outlined
                              : Icons.visibility_outlined,
                        ),
                        label: Text(
                          period!.canEnterRecords ? 'ورود به دوره' : 'مشاهده',
                        ),
                      ),
                    ),
                    if (period!.canSubmitToCeo) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'ارسال برای مدیرعامل',
                        onPressed: onSubmit,
                        icon: const Icon(Icons.send_outlined),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthMetric extends StatelessWidget {
  final String title;
  final String value;

  const _MonthMetric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final String title;

  const _StatusChip({required this.status, required this.title});

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;

    switch (status) {
      case 'paid':
        background = Colors.green.shade50;
        foreground = Colors.green.shade700;
        break;

      case 'consultant_approved':
      case 'ceo_approved':
        background = Colors.blue.shade50;
        foreground = Colors.blue.shade700;
        break;

      case 'pending_ceo':
      case 'pending_consultant':
        background = Colors.orange.shade50;
        foreground = Colors.orange.shade800;
        break;

      case 'rejected':
      case 'cancelled':
        background = Colors.red.shade50;
        foreground = Colors.red.shade700;
        break;

      default:
        background = Colors.grey.shade100;
        foreground = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CreateYearDialog extends StatefulWidget {
  const _CreateYearDialog();

  @override
  State<_CreateYearDialog> createState() => _CreateYearDialogState();
}

class _CreateYearDialogState extends State<_CreateYearDialog> {
  late final TextEditingController yearController;
  late final TextEditingController notesController;

  @override
  void initState() {
    super.initState();

    yearController = TextEditingController(text: '1405');

    notesController = TextEditingController();
  }

  @override
  void dispose() {
    yearController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('ایجاد / تکمیل سال مالی حقوق'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'سال مالی',
                  hintText: 'مثلاً ۱۴۰۵',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'توضیحات',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'اگر سال وجود داشته باشد، فقط ماه‌های ناقص آن ساخته می‌شوند و ماه‌های قبلی تغییر نمی‌کنند.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              final year = int.tryParse(yearController.text.trim());

              if (year == null || year < 1300 || year > 1600) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'سال مالی نامعتبر است.',
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                );
                return;
              }

              Navigator.pop(
                context,
                _CreateYearResult(
                  year: year,
                  notes:
                      notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                ),
              );
            },
            child: const Text('ایجاد / تکمیل'),
          ),
        ],
      ),
    );
  }
}

class _CreateYearResult {
  final int year;
  final String? notes;

  const _CreateYearResult({required this.year, required this.notes});
}

class _EmptyYearsView extends StatelessWidget {
  final VoidCallback onCreateYear;

  const _EmptyYearsView({required this.onCreateYear});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'هنوز سال مالی حقوقی ایجاد نشده است.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'با ایجاد سال مالی، ۱۲ ماه آن به‌صورت خودکار ساخته می‌شود.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreateYear,
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 12),
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
      ),
    );
  }
}

String _money(double value) {
  final text = value.round().toString();
  final buffer = StringBuffer();

  for (int i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(text[i]);
  }

  return buffer.toString();
}

String _number(int value) {
  final text = value.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(text[i]);
  }

  return buffer.toString();
}
