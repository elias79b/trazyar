import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/accountant_expense_fiscal_periods_provider.dart';

class AccountantExpenseFiscalPeriodsPage extends ConsumerStatefulWidget {
  const AccountantExpenseFiscalPeriodsPage({
    super.key,
    required this.companyId,
  });

  final String companyId;

  @override
  ConsumerState<AccountantExpenseFiscalPeriodsPage> createState() =>
      _AccountantExpenseFiscalPeriodsPageState();
}

class _AccountantExpenseFiscalPeriodsPageState
    extends ConsumerState<AccountantExpenseFiscalPeriodsPage> {
  int? _selectedYear;

  static const List<String> _monthNames = [
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      accountantExpenseFiscalPeriodsProvider(widget.companyId),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f7fb),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xff172033),
          title: const Text(
            'دوره‌های هزینه',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilledButton.icon(
                onPressed: () => _showCreateYearDialog(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('سال مالی جدید'),
              ),
            ),
          ],
        ),
        body: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stackTrace) => _ErrorView(
                error: error,
                onRetry: () {
                  ref.invalidate(
                    accountantExpenseFiscalPeriodsProvider(widget.companyId),
                  );
                },
              ),
          data: (data) {
            if (data.years.isEmpty) {
              return _EmptyYearsView(
                onCreate: () => _showCreateYearDialog(context),
              );
            }

            final selectedYear = _resolveSelectedYear(data);

            return _buildContent(context, data, selectedYear);
          },
        ),
      ),
    );
  }

  AccountantExpenseFiscalYear _resolveSelectedYear(
    AccountantExpenseFiscalPeriodsData data,
  ) {
    if (_selectedYear != null) {
      final existing = data.years.where((year) => year.year == _selectedYear);

      if (existing.isNotEmpty) {
        return existing.first;
      }
    }

    return data.years.first;
  }

  Widget _buildContent(
    BuildContext context,
    AccountantExpenseFiscalPeriodsData data,
    AccountantExpenseFiscalYear selectedYear,
  ) {
    final periods = data.periodsForYear(selectedYear);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1250),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(context, data, selectedYear, isMobile),
                  const SizedBox(height: 20),
                  _buildYearSelector(context, data, selectedYear, isMobile),
                  const SizedBox(height: 20),
                  _buildPeriodsSection(context, periods, isMobile),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    AccountantExpenseFiscalPeriodsData data,
    AccountantExpenseFiscalYear selectedYear,
    bool isMobile,
  ) {
    final periods = data.periodsForYear(selectedYear);

    final openCount = periods.where((period) => period.status == 'open').length;

    final closedCount =
        periods.where((period) => period.status == 'closed').length;

    final approvedCount =
        periods.where((period) => period.status == 'approved').length;

    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffe6e9f0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child:
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _yearTitle(selectedYear),
                  const SizedBox(height: 20),
                  _summaryGrid(openCount, approvedCount, closedCount),
                ],
              )
              : Row(
                children: [
                  Expanded(child: _yearTitle(selectedYear)),
                  _summaryGrid(openCount, approvedCount, closedCount),
                ],
              ),
    );
  }

  Widget _yearTitle(AccountantExpenseFiscalYear year) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'سال مالی هزینه',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xff7b8497),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _faNumber(year.year.toString()),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xff172033),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          year.title,
          style: const TextStyle(
            color: Color(0xff687286),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _summaryGrid(int openCount, int approvedCount, int closedCount) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _SummaryItem(
          title: 'باز',
          value: openCount,
          icon: Icons.lock_open_rounded,
          iconColor: const Color(0xff2563eb),
        ),
        _SummaryItem(
          title: 'تأییدشده',
          value: approvedCount,
          icon: Icons.verified_rounded,
          iconColor: const Color(0xff059669),
        ),
        _SummaryItem(
          title: 'بسته',
          value: closedCount,
          icon: Icons.lock_rounded,
          iconColor: const Color(0xff64748b),
        ),
      ],
    );
  }

  Widget _buildYearSelector(
    BuildContext context,
    AccountantExpenseFiscalPeriodsData data,
    AccountantExpenseFiscalYear selectedYear,
    bool isMobile,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe6e9f0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedYear.id,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(14),
          items:
              data.years.map((year) {
                return DropdownMenuItem<String>(
                  value: year.id,
                  child: Text(
                    '${_faNumber(year.year.toString())} — ${year.title}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                );
              }).toList(),
          onChanged: (value) {
            if (value == null) return;

            final selected = data.years.firstWhere((year) => year.id == value);

            setState(() {
              _selectedYear = selected.year;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPeriodsSection(
    BuildContext context,
    List<AccountantExpenseFiscalPeriod> periods,
    bool isMobile,
  ) {
    final sortedPeriods = [...periods]
      ..sort((a, b) => a.month.compareTo(b.month));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'ماه‌های سال مالی',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: Color(0xff172033),
          ),
        ),
        const SizedBox(height: 12),
        if (sortedPeriods.isEmpty)
          _EmptyPeriodsView()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedPeriods.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount:
                  isMobile
                      ? 1
                      : MediaQuery.sizeOf(context).width < 1050
                      ? 2
                      : 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: isMobile ? 2.5 : 2.05,
            ),
            itemBuilder: (context, index) {
              final period = sortedPeriods[index];

              return _PeriodCard(
                period: period,
                monthName: _monthName(period.month),
                onTap: () {
                  context.push('/accountant/expenses/recognition/${period.id}');
                },
              );
            },
          ),
      ],
    );
  }

  Future<void> _showCreateYearDialog(BuildContext context) async {
    final yearController = TextEditingController();
    final titleController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool loading = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text(
                  'ایجاد سال مالی هزینه',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                content: SizedBox(
                  width: 430,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: yearController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'سال مالی',
                          hintText: 'مثلاً ۱۴۰۵',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'عنوان',
                          hintText: 'اختیاری',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        loading
                            ? null
                            : () => Navigator.pop(dialogContext, false),
                    child: const Text('انصراف'),
                  ),
                  FilledButton(
                    onPressed:
                        loading
                            ? null
                            : () async {
                              final rawYear = _normalizeDigits(
                                yearController.text.trim(),
                              );

                              final year = int.tryParse(rawYear);

                              if (year == null || year < 1300 || year > 1600) {
                                _showMessage(
                                  'سال مالی را بین ۱۳۰۰ تا ۱۶۰۰ وارد کنید.',
                                  isError: true,
                                );
                                return;
                              }

                              setDialogState(() {
                                loading = true;
                              });

                              try {
                                await ref
                                    .read(
                                      accountantExpenseFiscalPeriodsProvider(
                                        widget.companyId,
                                      ).future,
                                    )
                                    .then((_) async {
                                      final repository = AccountantExpenseFiscalPeriodsRepository(
                                        // ignore: invalid_use_of_visible_for_testing_member
                                        // This is the actual Supabase client.
                                        // The repository itself owns the client.
                                        // We intentionally use the same singleton.
                                        // ignore: unnecessary_cast
                                        // ignore: avoid_redundant_argument_values
                                        _supabaseClient(),
                                      );

                                      await repository.createFiscalYear(
                                        companyId: widget.companyId,
                                        year: year,
                                        title:
                                            titleController.text.trim().isEmpty
                                                ? null
                                                : titleController.text.trim(),
                                      );
                                    });

                                if (!dialogContext.mounted) return;

                                Navigator.pop(dialogContext, true);

                                ref.invalidate(
                                  accountantExpenseFiscalPeriodsProvider(
                                    widget.companyId,
                                  ),
                                );

                                _showMessage(
                                  'سال مالی و ۱۲ ماه آن با موفقیت ایجاد شد.',
                                );
                              } catch (error) {
                                setDialogState(() {
                                  loading = false;
                                });

                                _showMessage(_cleanError(error), isError: true);
                              }
                            },
                    child:
                        loading
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
          },
        );
      },
    );

    yearController.dispose();
    titleController.dispose();

    if (result == true) {
      ref.invalidate(accountantExpenseFiscalPeriodsProvider(widget.companyId));
    }
  }

  Future<void> _showPeriodActions(
    BuildContext context,
    AccountantExpenseFiscalPeriod period,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _monthName(period.month),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    period.statusTitle,
                    style: const TextStyle(color: Color(0xff687286)),
                  ),
                  const SizedBox(height: 20),
                  ..._periodActions(period).map(
                    (item) => ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.title),
                      onTap: () => Navigator.pop(sheetContext, item.action),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (action == null) return;

    await _processPeriod(context, period, action);
  }

  List<_PeriodAction> _periodActions(AccountantExpenseFiscalPeriod period) {
    if (period.status == 'open') {
      return const [
        _PeriodAction(
          action: 'submit_to_company_admin',
          title: 'ارسال برای مدیرعامل',
          icon: Icons.send_rounded,
        ),
      ];
    }

    if (period.status == 'submitted_to_company_admin') {
      return const [
        _PeriodAction(
          action: 'approve_and_send_to_consultant',
          title: 'تأیید و ارسال برای مشاور',
          icon: Icons.forward_to_inbox_rounded,
        ),
        _PeriodAction(
          action: 'return_to_accountant',
          title: 'برگشت به حسابدار',
          icon: Icons.undo_rounded,
        ),
      ];
    }

    if (period.status == 'submitted_to_consultant') {
      return const [
        _PeriodAction(
          action: 'approve_by_consultant',
          title: 'تأیید نهایی مشاور',
          icon: Icons.verified_rounded,
        ),
        _PeriodAction(
          action: 'return_by_consultant',
          title: 'برگشت به حسابدار',
          icon: Icons.undo_rounded,
        ),
      ];
    }

    if (period.status == 'approved') {
      return const [
        _PeriodAction(
          action: 'close',
          title: 'بستن دوره',
          icon: Icons.lock_rounded,
        ),
      ];
    }

    if (period.status == 'closed') {
      return const [
        _PeriodAction(
          action: 'reopen',
          title: 'بازگشایی دوره',
          icon: Icons.lock_open_rounded,
        ),
      ];
    }

    return const [];
  }

  Future<void> _processPeriod(
    BuildContext context,
    AccountantExpenseFiscalPeriod period,
    String action,
  ) async {
    final noteController = TextEditingController();

    final needsNote = action.contains('return');

    if (needsNote) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('برگشت دوره'),
              content: TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'دلیل برگشت',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('تأیید برگشت'),
                ),
              ],
            ),
          );
        },
      );

      if (confirmed != true) {
        noteController.dispose();
        return;
      }
    }

    try {
      final repository = AccountantExpenseFiscalPeriodsRepository(
        _supabaseClient(),
      );

      await repository.processPeriod(
        periodId: period.id,
        action: action,
        note:
            noteController.text.trim().isEmpty
                ? null
                : noteController.text.trim(),
      );

      ref.invalidate(accountantExpenseFiscalPeriodsProvider(widget.companyId));

      if (mounted) {
        _showMessage('وضعیت دوره با موفقیت تغییر کرد.');
      }
    } catch (error) {
      if (mounted) {
        _showMessage(_cleanError(error), isError: true);
      }
    } finally {
      noteController.dispose();
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? const Color(0xffdc2626) : const Color(0xff059669),
        ),
      );
  }

  String _monthName(int month) {
    if (month < 1 || month > 12) {
      return 'ماه $month';
    }

    return _monthNames[month - 1];
  }

  String _faNumber(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    return value.split('').map((char) {
      final index = english.indexOf(char);
      return index >= 0 ? persian[index] : char;
    }).join();
  }

  String _normalizeDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const english = '0123456789';

    var result = value;

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(persian[i], english[i]);
      result = result.replaceAll(arabic[i], english[i]);
    }

    return result;
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.contains('سال مالی نامعتبر است')) {
      return 'سال مالی نامعتبر است.';
    }

    if (text.contains('این سال مالی قبلاً ایجاد شده است')) {
      return 'این سال مالی قبلاً ایجاد شده است.';
    }

    if (text.contains('شما مجوز')) {
      return 'شما مجوز انجام این عملیات را ندارید.';
    }

    if (text.contains('duplicate key')) {
      return 'این مورد قبلاً ثبت شده است.';
    }

    return text
        .replaceFirst('Exception: ', '')
        .replaceFirst('PostgrestException(message: ', '')
        .trim();
  }

  dynamic _supabaseClient() {
    return Supabase.instance.client;
  }
}

class _PeriodAction {
  const _PeriodAction({
    required this.action,
    required this.title,
    required this.icon,
  });

  final String action;
  final String title;
  final String titleUnused = '';
  final IconData icon;
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xfff8fafc),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 8),
          Text(
            _faNumber(value.toString()),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xff172033),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xff687286)),
          ),
        ],
      ),
    );
  }

  String _faNumber(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    return value.split('').map((char) {
      final index = english.indexOf(char);
      return index >= 0 ? persian[index] : char;
    }).join();
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.period,
    required this.monthName,
    required this.onTap,
  });

  final AccountantExpenseFiscalPeriod period;
  final String monthName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(period.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffe6e9f0)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  _faNumber(period.month.toString()),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xff172033),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        period.statusTitle,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: Color(0xff8b93a3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return const Color(0xff2563eb);
      case 'submitted_to_company_admin':
        return const Color(0xffd97706);
      case 'submitted_to_consultant':
        return const Color(0xff7c3aed);
      case 'approved':
        return const Color(0xff059669);
      case 'closed':
        return const Color(0xff64748b);
      default:
        return const Color(0xff64748b);
    }
  }

  String _faNumber(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    return value.split('').map((char) {
      final index = english.indexOf(char);
      return index >= 0 ? persian[index] : char;
    }).join();
  }
}

class _EmptyYearsView extends StatelessWidget {
  const _EmptyYearsView({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 72,
              color: Color(0xff94a3b8),
            ),
            const SizedBox(height: 18),
            const Text(
              'هنوز سال مالی هزینه‌ای ایجاد نشده است.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'برای شروع، اولین سال مالی هزینه را ایجاد کنید.',
              style: TextStyle(color: Color(0xff64748b)),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('ایجاد سال مالی'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPeriodsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe6e9f0)),
      ),
      child: const Center(
        child: Text(
          'برای این سال مالی ماهی ثبت نشده است.',
          style: TextStyle(
            color: Color(0xff64748b),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Color(0xffdc2626),
            ),
            const SizedBox(height: 14),
            const Text(
              'خطا در دریافت دوره‌های هزینه',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xff64748b)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}
