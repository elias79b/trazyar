import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tarazyar/accountant/banking/application/accountant_fiscal_periods_provider.dart';
import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';

class AccountantFiscalPeriodsPage extends ConsumerStatefulWidget {
  final String companyId;

  const AccountantFiscalPeriodsPage({super.key, required this.companyId});

  @override
  ConsumerState<AccountantFiscalPeriodsPage> createState() =>
      _AccountantFiscalPeriodsPageState();
}

class _AccountantFiscalPeriodsPageState
    extends ConsumerState<AccountantFiscalPeriodsPage> {
  String? _selectedYearId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountantFiscalPeriodsProvider(widget.companyId));

    return AccountantScaffold(
      currentRoute: '/accountant/banking/fiscal-periods',
      title: 'دوره‌های مالی',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: state.when(
          loading: () {
            return const Center(child: CircularProgressIndicator());
          },
          error: (error, stackTrace) {
            return _ErrorView(
              error: error.toString(),
              onRetry: () {
                ref.invalidate(
                  accountantFiscalPeriodsProvider(widget.companyId),
                );
              },
            );
          },
          data: (data) {
            if (data.years.isEmpty) {
              return _EmptyYears(
                onCreate: () {
                  _showCreateYearDialog(context);
                },
              );
            }

            final selectedYear = _resolveSelectedYear(data.years);

            final periods = data.periodsForYear(selectedYear.id);

            return _Content(
              companyId: widget.companyId,
              data: data,
              selectedYear: selectedYear,
              periods: periods,
              onYearChanged: (yearId) {
                setState(() {
                  _selectedYearId = yearId;
                });
              },
              onCreateYear: () {
                _showCreateYearDialog(context);
              },
              onCreateMissingPeriods: () async {
                await _createMissingPeriods(selectedYear);
              },
            );
          },
        ),
      ),
    );
  }

  AccountantFiscalYear _resolveSelectedYear(List<AccountantFiscalYear> years) {
    if (_selectedYearId != null) {
      for (final year in years) {
        if (year.id == _selectedYearId) {
          return year;
        }
      }
    }

    _selectedYearId = years.first.id;

    return years.first;
  }

  Future<void> _showCreateYearDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _CreateYearDialog(companyId: widget.companyId);
      },
    );

    if (result != true || !mounted) {
      return;
    }

    ref.invalidate(accountantFiscalPeriodsProvider(widget.companyId));
  }

  Future<void> _createMissingPeriods(AccountantFiscalYear year) async {
    try {
      await AccountantFiscalPeriodsRepository.createMissingPeriods(
        companyId: widget.companyId,
        fiscalYear: year,
      );

      ref.invalidate(accountantFiscalPeriodsProvider(widget.companyId));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'دوره‌های ناقص با موفقیت ایجاد شدند.',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در ایجاد دوره‌ها:\n$e',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
  }
}

// ============================================================
// CONTENT
// ============================================================

class _Content extends ConsumerWidget {
  final String companyId;
  final AccountantFiscalPeriodsData data;
  final AccountantFiscalYear selectedYear;
  final List<AccountantFiscalPeriod> periods;
  final ValueChanged<String> onYearChanged;
  final VoidCallback onCreateYear;
  final VoidCallback onCreateMissingPeriods;

  const _Content({
    required this.companyId,
    required this.data,
    required this.selectedYear,
    required this.periods,
    required this.onYearChanged,
    required this.onCreateYear,
    required this.onCreateMissingPeriods,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openCount = periods.where((e) => e.isOpen).length;

    final submittedCount =
        periods
            .where(
              (e) =>
                  e.status == 'submitted_to_company_admin' ||
                  e.status == 'submitted_to_consultant',
            )
            .length;

    final approvedCount =
        periods
            .where((e) => e.status == 'approved' || e.status == 'closed')
            .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return ListView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'دوره‌های مالی',
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onCreateYear,
                  icon: const Icon(Icons.add),
                  label: const Text('سال مالی جدید'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'حسابدار ابتدا اطلاعات دوره را ثبت می‌کند و پس از ثبت اولیه آن را برای مدیرعامل ارسال می‌کند.',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: .65),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: selectedYear.id,
                  decoration: const InputDecoration(
                    labelText: 'سال مالی',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items:
                      data.years
                          .map(
                            (year) => DropdownMenuItem<String>(
                              value: year.id,
                              child: Text(
                                year.title?.trim().isNotEmpty == true
                                    ? '${_digits(year.year.toString())} - ${year.title}'
                                    : 'سال ${_digits(year.year.toString())}',
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onYearChanged(value);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: isMobile ? 1 : 4,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: isMobile ? 4.2 : 2.4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SummaryCard(
                  title: 'کل دوره‌ها',
                  value: _digits(periods.length.toString()),
                  icon: Icons.calendar_month_outlined,
                ),
                _SummaryCard(
                  title: 'در حال ثبت',
                  value: _digits(openCount.toString()),
                  icon: Icons.edit_calendar_outlined,
                ),
                _SummaryCard(
                  title: 'در گردش بررسی',
                  value: _digits(submittedCount.toString()),
                  icon: Icons.pending_actions_outlined,
                ),
                _SummaryCard(
                  title: 'تأیید شده',
                  value: _digits(approvedCount.toString()),
                  icon: Icons.verified_outlined,
                ),
              ],
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'ماه‌های سال ${_digits(selectedYear.year.toString())}',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed:
                      periods.length < 12 ? onCreateMissingPeriods : null,
                  icon: const Icon(Icons.sync),
                  label: const Text('تکمیل دوره‌ها'),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (periods.isEmpty)
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.event_busy_outlined, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'برای این سال دوره‌ای ثبت نشده است.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: onCreateMissingPeriods,
                        child: const Text('ایجاد ۱۲ دوره'),
                      ),
                    ],
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: periods.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : 3,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isMobile ? 1.9 : 1.55,
                ),
                itemBuilder: (context, index) {
                  final period = periods[index];

                  return _PeriodCard(
                    period: period,
                    onOpen: () {
                      context.push(
                        '/accountant/banking/fiscal-periods/${period.id}',
                      );
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }

  static String _digits(String value) {
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
}

// ============================================================
// PERIOD CARD
// ============================================================

class _PeriodCard extends StatelessWidget {
  final AccountantFiscalPeriod period;
  final VoidCallback onOpen;

  const _PeriodCard({required this.period, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final status = period.status;

    final bool editable = status == 'open';

    final bool inCompanyAdminReview = status == 'submitted_to_company_admin';

    final bool inConsultantReview = status == 'submitted_to_consultant';

    final bool approved = status == 'approved' || status == 'closed';

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  child: Text(
                    _digits(period.month.toString()),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        period.title?.trim().isNotEmpty == true
                            ? period.title!
                            : period.monthTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'ماه ${_digits(period.month.toString())} سال ${_digits(period.year.toString())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: .60),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _WorkflowStatus(status: status),

            const Spacer(),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpen,
                icon: Icon(
                  editable ? Icons.edit_rounded : Icons.visibility_outlined,
                  size: 18,
                ),
                label: Text(editable ? 'ورود به دوره و ثبت' : 'مشاهده دوره'),
              ),
            ),

            const SizedBox(height: 8),

            if (editable)
              const Text(
                'حسابدار می‌تواند ثبت اولیه انجام دهد.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              )
            else if (inCompanyAdminReview)
              const Text(
                'در انتظار بررسی مدیرعامل',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              )
            else if (inConsultantReview)
              const Text(
                'در انتظار بررسی مشاور',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              )
            else if (approved)
              const Text(
                'دوره تأیید شده است.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  static String _digits(String value) {
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
}

// ============================================================
// WORKFLOW STATUS
// ============================================================

class _WorkflowStatus extends StatelessWidget {
  final String status;

  const _WorkflowStatus({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;

    switch (status) {
      case 'open':
        label = 'در حال ثبت توسط حسابدار';
        icon = Icons.edit_outlined;
        break;

      case 'submitted_to_company_admin':
        label = 'در انتظار مدیرعامل';
        icon = Icons.business_center_outlined;
        break;

      case 'submitted_to_consultant':
        label = 'در انتظار مشاور';
        icon = Icons.rate_review_outlined;
        break;

      case 'approved':
        label = 'تأیید نهایی شده';
        icon = Icons.verified_outlined;
        break;

      case 'closed':
        label = 'بسته و نهایی شده';
        icon = Icons.lock_outline;
        break;

      default:
        label = 'وضعیت نامشخص';
        icon = Icons.help_outline;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================

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
            CircleAvatar(radius: 22, child: Icon(icon)),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY YEARS
// ============================================================

class _EmptyYears extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyYears({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 64,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 18),
                const Text(
                  'هنوز سال مالی ثبت نشده است.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'برای شروع اولین سال مالی شرکت را ایجاد کنید.',
                  style: TextStyle(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('ایجاد سال مالی'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CREATE YEAR DIALOG
// ============================================================

class _CreateYearDialog extends StatefulWidget {
  final String companyId;

  const _CreateYearDialog({required this.companyId});

  @override
  State<_CreateYearDialog> createState() => _CreateYearDialogState();
}

class _CreateYearDialogState extends State<_CreateYearDialog> {
  final _formKey = GlobalKey<FormState>();

  final _yearController = TextEditingController();

  final _titleController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _yearController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('ایجاد سال مالی'),
        content: SizedBox(
          width: 460,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'سال مالی',
                    hintText: 'مثلاً ۱۴۰۵',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final normalized = _normalizeDigits(value ?? '');

                    final year = int.tryParse(normalized);

                    if (year == null) {
                      return 'سال معتبر وارد کنید.';
                    }

                    if (year < 1300 || year > 1600) {
                      return 'سال باید بین ۱۳۰۰ و ۱۶۰۰ باشد.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان سال مالی',
                    hintText: 'مثلاً سال مالی ۱۴۰۵',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child:
                _saving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('ایجاد'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final year = int.parse(_normalizeDigits(_yearController.text));

      await AccountantFiscalPeriodsRepository.createYear(
        companyId: widget.companyId,
        year: year,
        title: _titleController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در ایجاد سال مالی:\n$e',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
  }

  static String _normalizeDigits(String value) {
    return value
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9')
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .trim();
  }
}

// ============================================================
// ERROR VIEW
// ============================================================

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
                  'خطا در دریافت دوره‌های مالی',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
                  icon: const Icon(Icons.refresh_rounded),
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
