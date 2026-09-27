import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/accountant/banking/application/accountant_fiscal_period_entry_provider.dart';
import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';

class AccountantFiscalPeriodEntryPage extends ConsumerStatefulWidget {
  final String periodId;

  const AccountantFiscalPeriodEntryPage({super.key, required this.periodId});

  @override
  ConsumerState<AccountantFiscalPeriodEntryPage> createState() =>
      _AccountantFiscalPeriodEntryPageState();
}

class _AccountantFiscalPeriodEntryPageState
    extends ConsumerState<AccountantFiscalPeriodEntryPage> {
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;
  bool _sending = false;

  final Map<String, Map<String, TextEditingController>> _bankControllers = {};
  final Map<String, Map<String, TextEditingController>> _cashControllers = {};
  final Map<String, Map<String, TextEditingController>> _pettyControllers = {};

  @override
  void dispose() {
    _disposeControllers(_bankControllers);
    _disposeControllers(_cashControllers);
    _disposeControllers(_pettyControllers);
    super.dispose();
  }

  void _disposeControllers(
    Map<String, Map<String, TextEditingController>> groups,
  ) {
    for (final fields in groups.values) {
      for (final controller in fields.values) {
        controller.dispose();
      }
    }
  }

  TextEditingController _controller(
    Map<String, Map<String, TextEditingController>> groups,
    String rowId,
    String field,
    double value,
  ) {
    final row = groups.putIfAbsent(rowId, () => {});

    return row.putIfAbsent(
      field,
      () => TextEditingController(text: _formatNumber(value)),
    );
  }

  String _formatNumber(double value) {
    if (value == 0) return '';

    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  double _parse(String value) {
    return double.tryParse(
          value.replaceAll(',', '').replaceAll('٬', '').trim(),
        ) ??
        0;
  }

  String _money(double value) {
    final rounded = value.round();
    final text = rounded.toString();

    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }

    return buffer.toString();
  }

  void _recalculateBank(BankAccountPeriodEntry entry) {
    final fields = _bankControllers[entry.bankAccountId];
    if (fields == null) return;

    final opening = _parse(fields['opening']!.text);
    final debit = _parse(fields['debit']!.text);
    final credit = _parse(fields['credit']!.text);
    final ledger = _parse(fields['ledger']!.text);

    final closing = opening + debit - credit;
    final discrepancy = closing - ledger;

    fields['closing']!.text = _formatNumber(closing);
    fields['discrepancy']!.text = _formatNumber(discrepancy);
  }

  void _recalculateCash(CashBoxPeriodEntry entry) {
    final fields = _cashControllers[entry.cashBoxId];
    if (fields == null) return;

    final opening = _parse(fields['opening']!.text);
    final receipts = _parse(fields['receipts']!.text);
    final payments = _parse(fields['payments']!.text);
    final ledger = _parse(fields['ledger']!.text);

    final closing = opening + receipts - payments;
    final discrepancy = closing - ledger;

    fields['closing']!.text = _formatNumber(closing);
    fields['discrepancy']!.text = _formatNumber(discrepancy);
  }

  void _recalculatePetty(PettyCashPeriodEntry entry) {
    final fields = _pettyControllers[entry.pettyCashId];
    if (fields == null) return;

    final opening = _parse(fields['opening']!.text);
    final receipts = _parse(fields['receipts']!.text);
    final payments = _parse(fields['payments']!.text);
    final ledger = _parse(fields['ledger']!.text);

    final closing = opening + receipts - payments;
    final discrepancy = closing - ledger;

    fields['closing']!.text = _formatNumber(closing);
    fields['discrepancy']!.text = _formatNumber(discrepancy);
  }

  Future<void> _save(AccountantFiscalPeriodEntryData data) async {
    if (!data.period.canEdit) {
      _showError('این دوره در حال حاضر قابل ویرایش نیست.');
      return;
    }

    setState(() => _saving = true);

    try {
      for (final item in data.bankAccounts) {
        final fields = _bankControllers[item.bankAccountId]!;

        final opening = _parse(fields['opening']!.text);
        final debit = _parse(fields['debit']!.text);
        final credit = _parse(fields['credit']!.text);
        final closing = opening + debit - credit;
        final ledger = _parse(fields['ledger']!.text);
        final discrepancy = closing - ledger;

        await AccountantFiscalPeriodEntryRepository.saveBankAccount(
          periodId: data.period.id,
          companyId: data.period.companyId,
          entry: item.copyWith(
            openingBalance: opening,
            debitTurnover: debit,
            creditTurnover: credit,
            closingBalance: closing,
            ledgerBalance: ledger,
            discrepancy: discrepancy,
          ),
        );
      }

      for (final item in data.cashBoxes) {
        final fields = _cashControllers[item.cashBoxId]!;

        final opening = _parse(fields['opening']!.text);
        final receipts = _parse(fields['receipts']!.text);
        final payments = _parse(fields['payments']!.text);
        final closing = opening + receipts - payments;
        final ledger = _parse(fields['ledger']!.text);
        final discrepancy = closing - ledger;

        await AccountantFiscalPeriodEntryRepository.saveCashBox(
          periodId: data.period.id,
          companyId: data.period.companyId,
          entry: item.copyWith(
            openingBalance: opening,
            totalReceipts: receipts,
            totalPayments: payments,
            closingBalance: closing,
            ledgerBalance: ledger,
            discrepancy: discrepancy,
          ),
        );
      }

      for (final item in data.pettyCashAccounts) {
        final fields = _pettyControllers[item.pettyCashId]!;

        final opening = _parse(fields['opening']!.text);
        final receipts = _parse(fields['receipts']!.text);
        final payments = _parse(fields['payments']!.text);
        final closing = opening + receipts - payments;
        final ledger = _parse(fields['ledger']!.text);
        final discrepancy = closing - ledger;

        await AccountantFiscalPeriodEntryRepository.savePettyCash(
          periodId: data.period.id,
          companyId: data.period.companyId,
          entry: item.copyWith(
            openingBalance: opening,
            totalReceipts: receipts,
            totalPayments: payments,
            closingBalance: closing,
            ledgerBalance: ledger,
            discrepancy: discrepancy,
          ),
        );
      }

      ref.invalidate(accountantFiscalPeriodEntryProvider(widget.periodId));

      if (mounted) {
        _showSuccess('اطلاعات دوره با موفقیت ذخیره شد.');
      }
    } catch (e) {
      if (mounted) {
        _showError('خطا در ذخیره اطلاعات:\n$e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _sendToCompanyAdmin(AccountantFiscalPeriodEntryData data) async {
    if (!data.period.canEdit) {
      _showError('این دوره در وضعیت قابل ارسال نیست.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('ارسال دوره برای مدیرعامل'),
            content: const Text(
              'پس از ارسال، حسابدار دیگر امکان ویرایش اطلاعات این دوره را ندارد.\n\n'
              'آیا از ثبت اولیه و ارسال برای مدیرعامل اطمینان دارید؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('ارسال برای مدیرعامل'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _sending = true);

    try {
      await _save(data);

      await AccountantFiscalPeriodEntryRepository.submitToCompanyAdmin(
        periodId: data.period.id,
        note: 'ثبت اولیه توسط حسابدار و ارسال برای بررسی مدیرعامل',
      );

      ref.invalidate(accountantFiscalPeriodEntryProvider(widget.periodId));

      if (mounted) {
        _showSuccess('دوره برای مدیرعامل ارسال شد.');
      }
    } catch (e) {
      if (mounted) {
        _showError('خطا در ارسال دوره:\n$e');
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textDirection: TextDirection.rtl)),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textDirection: TextDirection.rtl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      accountantFiscalPeriodEntryProvider(widget.periodId),
    );

    return state.when(
      loading:
          () => const AccountantScaffold(
            currentRoute: '/accountant/banking/fiscal-periods',
            title: 'ثبت اطلاعات دوره',
            body: Center(child: CircularProgressIndicator()),
          ),
      error:
          (error, stackTrace) => AccountantScaffold(
            currentRoute: '/accountant/banking/fiscal-periods',
            title: 'ثبت اطلاعات دوره',
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'خطا در دریافت اطلاعات دوره\n\n$error',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      data: (data) {
        return AccountantScaffold(
          currentRoute: '/accountant/banking/fiscal-periods',
          title: 'ثبت اطلاعات دوره',
          body: _buildBody(data),
        );
      },
    );
  }

  Widget _buildBody(AccountantFiscalPeriodEntryData data) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 800;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(compact ? 16 : 24),
          children: [
            _buildHeader(data, compact),
            const SizedBox(height: 20),
            _buildWorkflowCard(data),
            const SizedBox(height: 20),
            _buildBankSection(data, compact),
            const SizedBox(height: 20),
            _buildCashSection(data, compact),
            const SizedBox(height: 20),
            _buildPettySection(data, compact),
            const SizedBox(height: 24),
            _buildBottomActions(data, compact, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AccountantFiscalPeriodEntryData data, bool compact) {
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .10),
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.period.title.isEmpty
                      ? 'دوره ${data.period.month} سال ${data.period.year}'
                      : data.period.title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'ثبت اطلاعات مالی دوره',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: .65),
                  ),
                ),
              ],
            ),
          ),
          _statusChip(data.period.status),
        ],
      ),
    );
  }

  Widget _buildWorkflowCard(AccountantFiscalPeriodEntryData data) {
    final status = data.period.status;

    final steps = [
      ('ثبت حسابدار', 'open'),
      ('بررسی مدیرعامل', 'submitted_to_company_admin'),
      ('بررسی مشاور', 'submitted_to_consultant'),
      ('تأیید نهایی', 'approved'),
    ];

    int activeIndex = 0;

    if (status == 'submitted_to_company_admin') {
      activeIndex = 1;
    } else if (status == 'submitted_to_consultant') {
      activeIndex = 2;
    } else if (status == 'approved' || status == 'closed') {
      activeIndex = 3;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'گردش بررسی دوره',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: List.generate(steps.length, (index) {
              final active = index <= activeIndex;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          active
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                    ),
                    child: Center(
                      child:
                          active
                              ? Icon(
                                index < activeIndex
                                    ? Icons.check_rounded
                                    : Icons.circle,
                                size: 16,
                                color: Colors.white,
                              )
                              : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    steps[index].$1,
                    style: TextStyle(
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (index < steps.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.chevron_left_rounded, size: 18),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBankSection(AccountantFiscalPeriodEntryData data, bool compact) {
    return _section(
      title: 'حساب‌های بانکی',
      icon: Icons.account_balance_rounded,
      count: data.bankAccounts.length,
      child:
          data.bankAccounts.isEmpty
              ? _empty('حساب بانکی برای این شرکت ثبت نشده است.')
              : Column(
                children:
                    data.bankAccounts.map((item) {
                      final fields = _bankControllers.putIfAbsent(
                        item.bankAccountId,
                        () => {
                          'opening': TextEditingController(
                            text: _formatNumber(item.openingBalance),
                          ),
                          'debit': TextEditingController(
                            text: _formatNumber(item.debitTurnover),
                          ),
                          'credit': TextEditingController(
                            text: _formatNumber(item.creditTurnover),
                          ),
                          'closing': TextEditingController(
                            text: _formatNumber(item.closingBalance),
                          ),
                          'ledger': TextEditingController(
                            text: _formatNumber(item.ledgerBalance),
                          ),
                          'discrepancy': TextEditingController(
                            text: _formatNumber(item.discrepancy),
                          ),
                        },
                      );

                      return _bankCard(
                        item,
                        fields,
                        enabled: data.period.canEdit,
                        compact: compact,
                      );
                    }).toList(),
              ),
    );
  }

  Widget _buildCashSection(AccountantFiscalPeriodEntryData data, bool compact) {
    return _section(
      title: 'صندوق‌ها',
      icon: Icons.point_of_sale_rounded,
      count: data.cashBoxes.length,
      child:
          data.cashBoxes.isEmpty
              ? _empty('صندوقی برای این شرکت ثبت نشده است.')
              : Column(
                children:
                    data.cashBoxes.map((item) {
                      final fields = _cashControllers.putIfAbsent(
                        item.cashBoxId,
                        () => {
                          'opening': TextEditingController(
                            text: _formatNumber(item.openingBalance),
                          ),
                          'receipts': TextEditingController(
                            text: _formatNumber(item.totalReceipts),
                          ),
                          'payments': TextEditingController(
                            text: _formatNumber(item.totalPayments),
                          ),
                          'closing': TextEditingController(
                            text: _formatNumber(item.closingBalance),
                          ),
                          'ledger': TextEditingController(
                            text: _formatNumber(item.ledgerBalance),
                          ),
                          'discrepancy': TextEditingController(
                            text: _formatNumber(item.discrepancy),
                          ),
                        },
                      );

                      return _cashCard(
                        item,
                        fields,
                        enabled: data.period.canEdit,
                        compact: compact,
                      );
                    }).toList(),
              ),
    );
  }

  Widget _buildPettySection(
    AccountantFiscalPeriodEntryData data,
    bool compact,
  ) {
    return _section(
      title: 'تنخواه‌ها',
      icon: Icons.wallet_rounded,
      count: data.pettyCashAccounts.length,
      child:
          data.pettyCashAccounts.isEmpty
              ? _empty('تنخواهی برای این شرکت ثبت نشده است.')
              : Column(
                children:
                    data.pettyCashAccounts.map((item) {
                      final fields = _pettyControllers.putIfAbsent(
                        item.pettyCashId,
                        () => {
                          'opening': TextEditingController(
                            text: _formatNumber(item.openingBalance),
                          ),
                          'receipts': TextEditingController(
                            text: _formatNumber(item.totalReceipts),
                          ),
                          'payments': TextEditingController(
                            text: _formatNumber(item.totalPayments),
                          ),
                          'closing': TextEditingController(
                            text: _formatNumber(item.closingBalance),
                          ),
                          'ledger': TextEditingController(
                            text: _formatNumber(item.ledgerBalance),
                          ),
                          'discrepancy': TextEditingController(
                            text: _formatNumber(item.discrepancy),
                          ),
                        },
                      );

                      return _pettyCard(
                        item,
                        fields,
                        enabled: data.period.canEdit,
                        compact: compact,
                      );
                    }).toList(),
              ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required int count,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .10),
                ),
                child: Text('$count مورد'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _bankCard(
    BankAccountPeriodEntry item,
    Map<String, TextEditingController> fields, {
    required bool enabled,
    required bool compact,
  }) {
    return _entryCard(
      title: item.bankName,
      subtitle:
          item.accountNumber.isEmpty
              ? 'شماره حساب ثبت نشده'
              : 'شماره حساب: ${item.accountNumber}',
      icon: Icons.account_balance_rounded,
      enabled: enabled,
      children: [
        _field(
          fields['opening']!,
          'مانده افتتاحیه',
          enabled,
          onChanged: (_) => _recalculateBank(item),
        ),
        _field(
          fields['debit']!,
          'گردش بدهکار',
          enabled,
          onChanged: (_) => _recalculateBank(item),
        ),
        _field(
          fields['credit']!,
          'گردش بستانکار',
          enabled,
          onChanged: (_) => _recalculateBank(item),
        ),
        _field(fields['closing']!, 'مانده پایان', false),
        _field(
          fields['ledger']!,
          'مانده دفتر',
          enabled,
          onChanged: (_) => _recalculateBank(item),
        ),
        _field(fields['discrepancy']!, 'مغایرت', false),
      ],
    );
  }

  Widget _cashCard(
    CashBoxPeriodEntry item,
    Map<String, TextEditingController> fields, {
    required bool enabled,
    required bool compact,
  }) {
    return _entryCard(
      title: item.boxName,
      subtitle: 'صندوق',
      icon: Icons.point_of_sale_rounded,
      enabled: enabled,
      children: [
        _field(
          fields['opening']!,
          'مانده افتتاحیه',
          enabled,
          onChanged: (_) => _recalculateCash(item),
        ),
        _field(
          fields['receipts']!,
          'جمع دریافت‌ها',
          enabled,
          onChanged: (_) => _recalculateCash(item),
        ),
        _field(
          fields['payments']!,
          'جمع پرداخت‌ها',
          enabled,
          onChanged: (_) => _recalculateCash(item),
        ),
        _field(fields['closing']!, 'مانده پایان', false),
        _field(
          fields['ledger']!,
          'مانده دفتر',
          enabled,
          onChanged: (_) => _recalculateCash(item),
        ),
        _field(fields['discrepancy']!, 'مغایرت', false),
      ],
    );
  }

  Widget _pettyCard(
    PettyCashPeriodEntry item,
    Map<String, TextEditingController> fields, {
    required bool enabled,
    required bool compact,
  }) {
    return _entryCard(
      title: item.name,
      subtitle: 'تنخواه',
      icon: Icons.wallet_rounded,
      enabled: enabled,
      children: [
        _field(
          fields['opening']!,
          'مانده افتتاحیه',
          enabled,
          onChanged: (_) => _recalculatePetty(item),
        ),
        _field(
          fields['receipts']!,
          'جمع دریافت‌ها',
          enabled,
          onChanged: (_) => _recalculatePetty(item),
        ),
        _field(
          fields['payments']!,
          'جمع پرداخت‌ها',
          enabled,
          onChanged: (_) => _recalculatePetty(item),
        ),
        _field(fields['closing']!, 'مانده پایان', false),
        _field(
          fields['ledger']!,
          'مانده دفتر',
          enabled,
          onChanged: (_) => _recalculatePetty(item),
        ),
        _field(fields['discrepancy']!, 'مغایرت', false),
      ],
    );
  }

  Widget _entryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
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
                ),
              ),
              if (!enabled)
                const Chip(
                  avatar: Icon(Icons.lock_outline_rounded, size: 16),
                  label: Text('فقط مشاهده'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns =
                  constraints.maxWidth >= 1050
                      ? 3
                      : constraints.maxWidth >= 650
                      ? 2
                      : 1;

              final spacing = 12.0;
              final itemWidth =
                  columns == 1
                      ? constraints.maxWidth
                      : (constraints.maxWidth - spacing * (columns - 1)) /
                          columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children:
                    children
                        .map(
                          (child) => SizedBox(width: itemWidth, child: child),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    bool enabled, {
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textDirection: TextDirection.ltr,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'ریال',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _empty(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .60),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    String label;

    switch (status) {
      case 'open':
        label = 'در حال ثبت';
        break;
      case 'submitted_to_company_admin':
        label = 'در انتظار مدیرعامل';
        break;
      case 'submitted_to_consultant':
        label = 'در انتظار مشاور';
        break;
      case 'approved':
        label = 'تأیید شده';
        break;
      case 'closed':
        label = 'بسته شده';
        break;
      default:
        label = status;
    }

    return Chip(
      avatar: Icon(
        status == 'open' ? Icons.edit_outlined : Icons.lock_outline_rounded,
        size: 17,
      ),
      label: Text(label),
    );
  }

  Widget _buildBottomActions(
    AccountantFiscalPeriodEntryData data,
    bool compact,
    ThemeData theme,
  ) {
    if (!data.period.canEdit) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surfaceContainerLowest,
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'این دوره برای حسابدار قابل ویرایش نیست. '
                'پس از بررسی مدیرعامل یا مشاور، وضعیت دوره از همین مسیر ادامه پیدا می‌کند.',
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: _saving || _sending ? null : () => _save(data),
          icon:
              _saving
                  ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.save_outlined),
          label: const Text('ذخیره ثبت اولیه'),
        ),
        FilledButton.icon(
          onPressed:
              _saving || _sending ? null : () => _sendToCompanyAdmin(data),
          icon:
              _sending
                  ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.send_rounded),
          label: const Text('ارسال برای مدیرعامل'),
        ),
      ],
    );
  }
}
