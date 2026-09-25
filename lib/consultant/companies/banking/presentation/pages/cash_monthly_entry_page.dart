import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class CashMonthlyEntryPage extends StatefulWidget {
  final String companyId;
  final String periodId;

  const CashMonthlyEntryPage({
    super.key,
    required this.companyId,
    required this.periodId,
  });

  @override
  State<CashMonthlyEntryPage> createState() =>
      _CashMonthlyEntryPageState();
}

class _CashMonthlyEntryPageState extends State<CashMonthlyEntryPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool loading = true;
  bool saving = false;
  String? error;

  Map<String, dynamic>? period;

  List<Map<String, dynamic>> banks = [];
  List<Map<String, dynamic>> cashBoxes = [];
  List<Map<String, dynamic>> pettyCash = [];

  final Map<String, EntryData> bankData = {};
  final Map<String, EntryData> cashData = {};
  final Map<String, EntryData> pettyData = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    for (final item in bankData.values) {
      item.dispose();
    }
    for (final item in cashData.values) {
      item.dispose();
    }
    for (final item in pettyData.values) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final periodResult = await supabase
          .from('cash_fiscal_periods')
          .select(
        'id, company_id, fiscal_year_id, year, month, title, status',
      )
          .eq('id', widget.periodId)
          .eq('company_id', widget.companyId)
          .maybeSingle();

      if (periodResult == null) {
        throw Exception('دوره مالی پیدا نشد.');
      }

      final bankResult = await supabase
          .from('bank_accounts')
          .select(
        'id, company_id, bank_name, account_number, created_by, created_at',
      )
          .eq('company_id', widget.companyId)
          .order('bank_name');

      final cashResult = await supabase
          .from('cash_boxes')
          .select('*')
          .eq('company_id', widget.companyId)
          .order('created_at');

      final pettyResult = await supabase
          .from('petty_cash_accounts')
          .select('*')
          .eq('company_id', widget.companyId)
          .order('created_at');

      period = Map<String, dynamic>.from(periodResult);
      banks = _list(bankResult);
      cashBoxes = _list(cashResult);
      pettyCash = _list(pettyResult);

      await loadExisting();

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = cleanError(e);
      });
    }
  }

  List<Map<String, dynamic>> _list(dynamic value) {
    return (value as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> loadExisting() async {
    final bankResult = await supabase
        .from('bank_account_periods')
        .select(
      'id, bank_account_id, opening_balance, '
          'debit_turnover, credit_turnover, '
          'closing_balance, ledger_balance, discrepancy',
    )
        .eq('company_id', widget.companyId)
        .eq('period_id', widget.periodId);

    final cashResult = await supabase
        .from('cash_box_periods')
        .select(
      'id, cash_box_id, opening_balance, '
          'total_receipts, total_payments, '
          'closing_balance, ledger_balance, discrepancy',
    )
        .eq('company_id', widget.companyId)
        .eq('period_id', widget.periodId);

    final pettyResult = await supabase
        .from('petty_cash_periods')
        .select(
      'id, petty_cash_id, opening_balance, '
          'total_receipts, total_payments, '
          'closing_balance, ledger_balance, discrepancy',
    )
        .eq('company_id', widget.companyId)
        .eq('period_id', widget.periodId);

    for (final item in bankResult) {
      final row = Map<String, dynamic>.from(item);
      final id = row['bank_account_id']?.toString();

      if (id != null) {
        bankData[id] = EntryData.fromBank(row);
      }
    }

    for (final item in cashResult) {
      final row = Map<String, dynamic>.from(item);
      final id = row['cash_box_id']?.toString();

      if (id != null) {
        cashData[id] = EntryData.fromCash(row);
      }
    }

    for (final item in pettyResult) {
      final row = Map<String, dynamic>.from(item);
      final id = row['petty_cash_id']?.toString();

      if (id != null) {
        pettyData[id] = EntryData.fromCash(row);
      }
    }

    for (final item in banks) {
      final id = item['id'].toString();
      bankData.putIfAbsent(id, EntryData.new);
    }

    for (final item in cashBoxes) {
      final id = item['id'].toString();
      cashData.putIfAbsent(id, EntryData.new);
    }

    for (final item in pettyCash) {
      final id = item['id'].toString();
      pettyData.putIfAbsent(id, EntryData.new);
    }
  }

  Future<void> save() async {
    if (saving) return;

    FocusScope.of(context).unfocus();

    setState(() {
      saving = true;
    });

    try {
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('کاربر وارد سیستم نشده است.');
      }

      for (final bank in banks) {
        final id = bank['id'].toString();
        final data = bankData[id]!;

        final opening = data.openingValue;
        final debit = data.debitValue;
        final credit = data.creditValue;
        final closing = opening + debit - credit;
        final ledger = data.ledgerValue;
        final discrepancy = closing - ledger;

        await supabase.from('bank_account_periods').upsert(
          {
            'company_id': widget.companyId,
            'period_id': widget.periodId,
            'bank_account_id': id,
            'opening_balance': opening,
            'debit_turnover': debit,
            'credit_turnover': credit,
            'closing_balance': closing,
            'ledger_balance': ledger,
            'discrepancy': discrepancy,
            'created_by': userId,
          },
          onConflict: 'period_id,bank_account_id',
        );
      }

      for (final box in cashBoxes) {
        final id = box['id'].toString();
        final data = cashData[id]!;

        final opening = data.openingValue;
        final receipts = data.receiptsValue;
        final payments = data.paymentsValue;
        final closing = opening + receipts - payments;
        final ledger = data.ledgerValue;
        final discrepancy = closing - ledger;

        await supabase.from('cash_box_periods').upsert(
          {
            'company_id': widget.companyId,
            'period_id': widget.periodId,
            'cash_box_id': id,
            'opening_balance': opening,
            'total_receipts': receipts,
            'total_payments': payments,
            'closing_balance': closing,
            'ledger_balance': ledger,
            'discrepancy': discrepancy,
            'created_by': userId,
          },
          onConflict: 'period_id,cash_box_id',
        );
      }

      for (final petty in pettyCash) {
        final id = petty['id'].toString();
        final data = pettyData[id]!;

        final opening = data.openingValue;
        final receipts = data.receiptsValue;
        final payments = data.paymentsValue;
        final closing = opening + receipts - payments;
        final ledger = data.ledgerValue;
        final discrepancy = closing - ledger;

        await supabase.from('petty_cash_periods').upsert(
          {
            'company_id': widget.companyId,
            'period_id': widget.periodId,
            'petty_cash_id': id,
            'opening_balance': opening,
            'total_receipts': receipts,
            'total_payments': payments,
            'closing_balance': closing,
            'ledger_balance': ledger,
            'discrepancy': discrepancy,
            'created_by': userId,
          },
          onConflict: 'period_id,petty_cash_id',
        );
      }

      if (!mounted) return;

      showSuccess('اطلاعات دوره با موفقیت ذخیره شد.');
    } catch (e) {
      if (!mounted) return;
      showError(cleanError(e));
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute:
      '/consultant/companies/${widget.companyId}/banking/fiscal-periods',
      title: 'ثبت اطلاعات دوره',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (error != null) {
      return _errorView();
    }

    return Container(
      color: const Color(0xfff5f7f6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1000;

          return SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 28 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(),
                    const SizedBox(height: 18),
                    _kpis(),
                    const SizedBox(height: 22),
                    _section(
                      title: 'حساب‌های بانکی',
                      icon: Icons.account_balance_rounded,
                      count: banks.length,
                      child: banks.isEmpty
                          ? _empty('حساب بانکی ثبت نشده است.')
                          : _responsiveBankTable(wide),
                    ),
                    const SizedBox(height: 20),
                    _section(
                      title: 'صندوق‌ها',
                      icon: Icons.point_of_sale_rounded,
                      count: cashBoxes.length,
                      child: cashBoxes.isEmpty
                          ? _empty('صندوقی ثبت نشده است.')
                          : _responsiveCashTable(
                        wide,
                        cashBoxes,
                        cashData,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _section(
                      title: 'تنخواه‌ها',
                      icon: Icons.wallet_rounded,
                      count: pettyCash.length,
                      child: pettyCash.isEmpty
                          ? _empty('تنخواهی ثبت نشده است.')
                          : _responsiveCashTable(
                        wide,
                        pettyCash,
                        pettyData,
                        petty: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _actions(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _header() {
    final title = period?['title']?.toString() ?? 'دوره مالی';
    final year = toPersianDigits(period?['year']?.toString() ?? '');
    final month = period?['month']?.toString() ?? '';
    final status = period?['status']?.toString() ?? 'open';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Color(0xffeaf5ef),
            Color(0xfff8fbf9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffdce9e2)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 16,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xffd8eee3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xff176044),
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title $year',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'ماه $month  •  اطلاعات مالی بانک، صندوق و تنخواه',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _statusChip(status),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final open = status == 'open';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: open
            ? const Color(0xffe1f4e9)
            : const Color(0xffeeeeee),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            open ? Icons.edit_rounded : Icons.lock_rounded,
            size: 16,
            color: open
                ? const Color(0xff16834f)
                : Colors.grey.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            open ? 'دوره باز' : 'دوره بسته',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: open
                  ? const Color(0xff16834f)
                  : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpis() {
    double bankClosing = 0;
    double cashClosing = 0;
    double pettyClosing = 0;
    double discrepancy = 0;

    for (final item in banks) {
      final data = bankData[item['id'].toString()]!;
      bankClosing += data.bankClosing;
      discrepancy += data.bankDiscrepancy.abs();
    }

    for (final item in cashBoxes) {
      final data = cashData[item['id'].toString()]!;
      cashClosing += data.cashClosing;
      discrepancy += data.cashDiscrepancy.abs();
    }

    for (final item in pettyCash) {
      final data = pettyData[item['id'].toString()]!;
      pettyClosing += data.cashClosing;
      discrepancy += data.cashDiscrepancy.abs();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;

        final cards = [
          _kpi(
            'مانده بانک‌ها',
            bankClosing,
            Icons.account_balance_rounded,
          ),
          _kpi(
            'مانده صندوق‌ها',
            cashClosing,
            Icons.point_of_sale_rounded,
          ),
          _kpi(
            'مانده تنخواه',
            pettyClosing,
            Icons.wallet_rounded,
          ),
          _kpi(
            'مغایرت',
            discrepancy,
            Icons.compare_arrows_rounded,
            danger: discrepancy != 0,
          ),
        ];

        if (!wide) {
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
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }

  Widget _kpi(
      String title,
      double value,
      IconData icon, {
        bool danger = false,
      }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: danger
              ? const Color(0xffffdddd)
              : const Color(0xffe3eae6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: danger
                  ? const Color(0xffffeeee)
                  : const Color(0xffe8f4ee),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 21,
              color: danger
                  ? Colors.red.shade700
                  : const Color(0xff176044),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  money(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: danger
                        ? Colors.red.shade700
                        : const Color(0xff17372b),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xffe2e9e5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xffe6f3ec),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xff176044),
                ),
              ),
              const SizedBox(width: 11),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 9),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xfff0f4f2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count مورد',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _responsiveBankTable(bool wide) {
    if (!wide) {
      return Column(
        children: [
          for (final bank in banks) _bankMobileCard(bank),
        ],
      );
    }

    return Column(
      children: [
        _bankHeader(),
        for (final bank in banks) _bankDesktopRow(bank),
        _bankTotalRow(),
      ],
    );
  }

  Widget _bankHeader() {
    return _tableRow(
      background: const Color(0xfff4f7f5),
      cells: [
        _textCell('حساب', bold: true),
        _textCell('شماره حساب', bold: true),
        _textCell('مانده اول دوره', bold: true),
        _textCell('گردش بدهکار', bold: true),
        _textCell('گردش بستانکار', bold: true),
        _textCell('مانده پایان دوره', bold: true),
        _textCell('مانده طبق دفتر', bold: true),
        _textCell('مغایرت', bold: true),
      ],
      header: true,
    );
  }

  Widget _bankDesktopRow(Map<String, dynamic> bank) {
    final data = bankData[bank['id'].toString()]!;

    return _tableRow(
      cells: [
        _textCell(
          bank['bank_name']?.toString() ?? 'حساب بانکی',
          bold: true,
        ),
        _textCell(
          bank['account_number']?.toString() ?? '-',
        ),
        _editorCell(data.opening),
        _editorCell(data.debit),
        _editorCell(data.credit),
        _moneyCell(data.bankClosing),
        _editorCell(data.ledger),
        _moneyCell(
          data.bankDiscrepancy,
          danger: data.bankDiscrepancy != 0,
        ),
      ],
    );
  }

  Widget _bankMobileCard(Map<String, dynamic> bank) {
    final data = bankData[bank['id'].toString()]!;

    return _mobileCard(
      title: bank['bank_name']?.toString() ?? 'حساب بانکی',
      subtitle: bank['account_number']?.toString() ?? '',
      children: [
        _field('مانده اول دوره', data.opening),
        _field('گردش بدهکار', data.debit),
        _field('گردش بستانکار', data.credit),
        _calculatedField('مانده پایان دوره', data.bankClosing),
        _field('مانده طبق دفتر', data.ledger),
        _calculatedField(
          'مغایرت',
          data.bankDiscrepancy,
          danger: data.bankDiscrepancy != 0,
        ),
      ],
    );
  }

  Widget _responsiveCashTable(
      bool wide,
      List<Map<String, dynamic>> items,
      Map<String, EntryData> source, {
        bool petty = false,
      }) {
    if (!wide) {
      return Column(
        children: [
          for (final item in items)
            _cashMobileCard(item, source, petty: petty),
        ],
      );
    }

    return Column(
      children: [
        _cashHeader(),
        for (final item in items)
          _cashDesktopRow(
            item,
            source,
            petty: petty,
          ),
        _cashTotalRow(items, source),
      ],
    );
  }

  Widget _cashHeader() {
    return _tableRow(
      background: const Color(0xfff4f7f5),
      cells: [
        _textCell('عنوان', bold: true),
        _textCell('مسئول', bold: true),
        _textCell('مانده اول دوره', bold: true),
        _textCell('دریافت‌ها', bold: true),
        _textCell('پرداخت‌ها', bold: true),
        _textCell('مانده پایان دوره', bold: true),
        _textCell('مانده طبق دفتر', bold: true),
        _textCell('مغایرت', bold: true),
      ],
      header: true,
    );
  }

  Widget _cashDesktopRow(
      Map<String, dynamic> item,
      Map<String, EntryData> source, {
        bool petty = false,
      }) {
    final data = source[item['id'].toString()]!;

    return _tableRow(
      cells: [
        _textCell(
          _itemName(item, petty: petty),
          bold: true,
        ),
        _textCell(_responsible(item)),
        _editorCell(data.opening),
        _editorCell(data.receipts),
        _editorCell(data.payments),
        _moneyCell(data.cashClosing),
        _editorCell(data.ledger),
        _moneyCell(
          data.cashDiscrepancy,
          danger: data.cashDiscrepancy != 0,
        ),
      ],
    );
  }

  Widget _cashMobileCard(
      Map<String, dynamic> item,
      Map<String, EntryData> source, {
        bool petty = false,
      }) {
    final data = source[item['id'].toString()]!;

    return _mobileCard(
      title: _itemName(item, petty: petty),
      subtitle: _responsible(item),
      children: [
        _field('مانده اول دوره', data.opening),
        _field('دریافت‌ها', data.receipts),
        _field('پرداخت‌ها', data.payments),
        _calculatedField('مانده پایان دوره', data.cashClosing),
        _field('مانده طبق دفتر', data.ledger),
        _calculatedField(
          'مغایرت',
          data.cashDiscrepancy,
          danger: data.cashDiscrepancy != 0,
        ),
      ],
    );
  }

  Widget _tableRow({
    required List<Widget> cells,
    Color? background,
    bool header = false,
  }) {
    const flexes = [
      2,
      2,
      1,
      1,
      1,
      1,
      1,
      1,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: background ?? Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xffe7ece9),
          ),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < cells.length; i++)
            Expanded(
              flex: flexes[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: cells[i],
              ),
            ),
        ],
      ),
    );
  }

  Widget _textCell(
      String text, {
        bool bold = false,
      }) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
        color: const Color(0xff26352f),
      ),
    );
  }

  Widget _editorCell(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(r'[0-9۰-۹,.-]'),
        ),
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      onChanged: (_) {
        if (mounted) setState(() {});
      },
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 11,
        ),
        filled: true,
        fillColor: const Color(0xfffbfcfb),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xffe0e7e3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xffe0e7e3),
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(
            color: Color(0xff4a9272),
            width: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _moneyCell(
      double value, {
        bool danger = false,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: danger
            ? const Color(0xfffff0f0)
            : const Color(0xffedf7f1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        money(value),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: danger
              ? Colors.red.shade700
              : const Color(0xff176044),
        ),
      ),
    );
  }

  Widget _bankTotalRow() {
    double opening = 0;
    double debit = 0;
    double credit = 0;
    double closing = 0;
    double ledger = 0;
    double discrepancy = 0;

    for (final item in banks) {
      final data = bankData[item['id'].toString()]!;
      opening += data.openingValue;
      debit += data.debitValue;
      credit += data.creditValue;
      closing += data.bankClosing;
      ledger += data.ledgerValue;
      discrepancy += data.bankDiscrepancy;
    }

    return _totalRow([
      _textCell('جمع کل', bold: true),
      const SizedBox(),
      _textCell(money(opening), bold: true),
      _textCell(money(debit), bold: true),
      _textCell(money(credit), bold: true),
      _textCell(money(closing), bold: true),
      _textCell(money(ledger), bold: true),
      _textCell(money(discrepancy), bold: true),
    ]);
  }

  Widget _cashTotalRow(
      List<Map<String, dynamic>> items,
      Map<String, EntryData> source,
      ) {
    double opening = 0;
    double receipts = 0;
    double payments = 0;
    double closing = 0;
    double ledger = 0;
    double discrepancy = 0;

    for (final item in items) {
      final data = source[item['id'].toString()]!;
      opening += data.openingValue;
      receipts += data.receiptsValue;
      payments += data.paymentsValue;
      closing += data.cashClosing;
      ledger += data.ledgerValue;
      discrepancy += data.cashDiscrepancy;
    }

    return _totalRow([
      _textCell('جمع کل', bold: true),
      const SizedBox(),
      _textCell(money(opening), bold: true),
      _textCell(money(receipts), bold: true),
      _textCell(money(payments), bold: true),
      _textCell(money(closing), bold: true),
      _textCell(money(ledger), bold: true),
      _textCell(money(discrepancy), bold: true),
    ]);
  }

  Widget _totalRow(List<Widget> cells) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      decoration: const BoxDecoration(
        color: Color(0xffedf6f1),
      ),
      child: Row(
        children: [
          for (int i = 0; i < cells.length; i++)
            Expanded(
              flex: i < 2 ? 2 : 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: cells[i],
              ),
            ),
        ],
      ),
    );
  }

  Widget _mobileCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfffafcfb),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xffe1e9e5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
      String title,
      TextEditingController controller,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 125,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: _editorCell(controller),
          ),
        ],
      ),
    );
  }

  Widget _calculatedField(
      String title,
      double value, {
        bool danger = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 125,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: _moneyCell(
              value,
              danger: danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffe2e9e5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 650;

          final saveButton = ElevatedButton.icon(
            onPressed: saving ? null : save,
            icon: saving
                ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.save_rounded),
            label: Text(
              saving ? 'در حال ذخیره...' : 'ذخیره اطلاعات',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff176044),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          );

          final backButton = OutlinedButton.icon(
            onPressed: saving
                ? null
                : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('بازگشت'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          );

          if (wide) {
            return Row(
              children: [
                backButton,
                const Spacer(),
                saveButton,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              saveButton,
              const SizedBox(height: 10),
              backButton,
            ],
          );
        },
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.red.shade100,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.red.shade600,
            ),
            const SizedBox(height: 15),
            const Text(
              'خطا در بارگذاری دوره',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error ?? '',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xfffafcfb),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: Colors.grey.shade400,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _itemName(
      Map<String, dynamic> item, {
        bool petty = false,
      }) {
    return item['name']?.toString() ??
        item['title']?.toString() ??
        item['cash_box_name']?.toString() ??
        item['petty_cash_name']?.toString() ??
        (petty ? 'تنخواه' : 'صندوق');
  }

  String _responsible(Map<String, dynamic> item) {
    return item['responsible_name']?.toString() ??
        item['manager_name']?.toString() ??
        item['custodian_name']?.toString() ??
        item['description']?.toString() ??
        '-';
  }

  double parse(String value) {
    return double.tryParse(
      value
          .replaceAll(',', '')
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
          .trim(),
    ) ??
        0;
  }

  String money(double value) {
    final negative = value < 0;
    final text = value.abs().round().toString();

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }

    return '${negative ? '-' : ''}${toPersianDigits(buffer.toString())}';
  }

  String toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(
        english[i],
        persian[i],
      );
    }

    return result;
  }

  String cleanError(Object e) {
    final text = e.toString();

    if (text.contains('row-level security')) {
      return 'دسترسی ثبت اطلاعات دوره برای این کاربر فعال نیست.';
    }

    if (text.contains('permission denied')) {
      return 'دسترسی لازم برای مشاهده اطلاعات وجود ندارد.';
    }

    if (text.contains('duplicate key')) {
      return 'این اطلاعات قبلاً برای این دوره ثبت شده است.';
    }

    if (text.contains('does not exist')) {
      return 'یکی از ستون‌های مورد استفاده در دیتابیس وجود ندارد.\n$text';
    }

    return text.replaceFirst('Exception: ', '');
  }

  void showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showSuccess(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xff176044),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class EntryData {
  final TextEditingController opening;
  final TextEditingController debit;
  final TextEditingController credit;
  final TextEditingController receipts;
  final TextEditingController payments;
  final TextEditingController ledger;

  EntryData({
    String opening = '0',
    String debit = '0',
    String credit = '0',
    String receipts = '0',
    String payments = '0',
    String ledger = '0',
  })  : opening = TextEditingController(text: opening),
        debit = TextEditingController(text: debit),
        credit = TextEditingController(text: credit),
        receipts = TextEditingController(text: receipts),
        payments = TextEditingController(text: payments),
        ledger = TextEditingController(text: ledger);

  factory EntryData.fromBank(Map<String, dynamic> row) {
    return EntryData(
      opening: value(row['opening_balance']),
      debit: value(row['debit_turnover']),
      credit: value(row['credit_turnover']),
      ledger: value(row['ledger_balance']),
    );
  }

  factory EntryData.fromCash(Map<String, dynamic> row) {
    return EntryData(
      opening: value(row['opening_balance']),
      receipts: value(row['total_receipts']),
      payments: value(row['total_payments']),
      ledger: value(row['ledger_balance']),
    );
  }

  double get openingValue => number(opening.text);
  double get debitValue => number(debit.text);
  double get creditValue => number(credit.text);
  double get receiptsValue => number(receipts.text);
  double get paymentsValue => number(payments.text);
  double get ledgerValue => number(ledger.text);

  double get bankClosing =>
      openingValue + debitValue - creditValue;

  double get bankDiscrepancy =>
      bankClosing - ledgerValue;

  double get cashClosing =>
      openingValue + receiptsValue - paymentsValue;

  double get cashDiscrepancy =>
      cashClosing - ledgerValue;

  void dispose() {
    opening.dispose();
    debit.dispose();
    credit.dispose();
    receipts.dispose();
    payments.dispose();
    ledger.dispose();
  }

  static double number(String value) {
    return double.tryParse(
      value
          .replaceAll(',', '')
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
          .trim(),
    ) ??
        0;
  }

  static String value(dynamic value) {
    if (value == null) return '0';
    return value.toString();
  }
}