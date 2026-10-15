import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class BankingReportsPage extends StatefulWidget {
  final String companyId;

  const BankingReportsPage({super.key, required this.companyId});

  @override
  State<BankingReportsPage> createState() => _BankingReportsPageState();
}

class _BankingReportsPageState extends State<BankingReportsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _periods = [];
  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> _cashBoxes = [];
  List<Map<String, dynamic>> _pettyCash = [];

  String? _selectedPeriodId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _supabase
            .from('cash_fiscal_periods')
            .select('id, year, month, title, status')
            .eq('company_id', widget.companyId)
            .order('year', ascending: false)
            .order('month', ascending: false),
        _supabase
            .from('bank_account_periods')
            .select(
          'id, period_id, bank_account_id, '
              'opening_balance, debit_turnover, '
              'credit_turnover, closing_balance, '
              'ledger_balance, discrepancy, '
              'bank_accounts(bank_name, account_number)',
        )
            .eq('company_id', widget.companyId),
        _supabase
            .from('cash_box_periods')
            .select(
          'id, period_id, cash_box_id, '
              'opening_balance, total_receipts, '
              'total_payments, closing_balance, '
              'ledger_balance, discrepancy, '
              'cash_boxes(box_name)',
        )
            .eq('company_id', widget.companyId),
        _supabase
            .from('petty_cash_periods')
            .select(
          'id, period_id, petty_cash_id, '
              'opening_balance, total_receipts, '
              'total_payments, closing_balance, '
              'ledger_balance, discrepancy, '
              'petty_cash_accounts(name)',
        )
            .eq('company_id', widget.companyId),
      ]);

      final periods = List<Map<String, dynamic>>.from(results[0] as List);

      final banks = List<Map<String, dynamic>>.from(results[1] as List);

      final cashBoxes = List<Map<String, dynamic>>.from(results[2] as List);

      final pettyCash = List<Map<String, dynamic>>.from(results[3] as List);

      if (!mounted) return;

      setState(() {
        _periods = periods;
        _banks = banks;
        _cashBoxes = cashBoxes;
        _pettyCash = pettyCash;

        if (_selectedPeriodId == null && periods.isNotEmpty) {
          _selectedPeriodId = periods.first['id'].toString();
        }

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

  double _num(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0.0;
  }

  String _money(dynamic value) {
    final number = _num(value).round();

    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
    );
  }

  String _monthName(int month) {
    const names = [
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

    if (month < 1 || month > 12) {
      return '-';
    }

    return names[month - 1];
  }

  String _periodTitle(Map<String, dynamic> period) {
    final year = int.tryParse(period['year']?.toString() ?? '') ?? 0;

    final month = int.tryParse(period['month']?.toString() ?? '') ?? 0;

    return '${_monthName(month)} $year';
  }

  List<Map<String, dynamic>> _selectedBanks() {
    return _banks
        .where((row) => row['period_id']?.toString() == _selectedPeriodId)
        .toList();
  }

  List<Map<String, dynamic>> _selectedCashBoxes() {
    return _cashBoxes
        .where((row) => row['period_id']?.toString() == _selectedPeriodId)
        .toList();
  }

  List<Map<String, dynamic>> _selectedPettyCash() {
    return _pettyCash
        .where((row) => row['period_id']?.toString() == _selectedPeriodId)
        .toList();
  }

  double _bankTotal() {
    return _selectedBanks().fold(
      0.0,
          (sum, row) => sum + _num(row['closing_balance']),
    );
  }

  double _cashTotal() {
    return _selectedCashBoxes().fold(
      0.0,
          (sum, row) => sum + _num(row['closing_balance']),
    );
  }

  double _pettyTotal() {
    return _selectedPettyCash().fold(
      0.0,
          (sum, row) => sum + _num(row['closing_balance']),
    );
  }

  double _liquidityTotal() {
    return _bankTotal() + _cashTotal() + _pettyTotal();
  }

  double _bankLedgerTotal() {
    return _selectedBanks().fold(
      0.0,
          (sum, row) => sum + _num(row['ledger_balance']),
    );
  }

  double _cashLedgerTotal() {
    return _selectedCashBoxes().fold(
      0.0,
          (sum, row) => sum + _num(row['ledger_balance']),
    );
  }

  double _pettyLedgerTotal() {
    return _selectedPettyCash().fold(
      0.0,
          (sum, row) => sum + _num(row['ledger_balance']),
    );
  }

  double _bankDiscrepancy() {
    return _selectedBanks().fold(
      0.0,
          (sum, row) => sum + _num(row['discrepancy']),
    );
  }

  double _cashDiscrepancy() {
    return _selectedCashBoxes().fold(
      0.0,
          (sum, row) => sum + _num(row['discrepancy']),
    );
  }

  double _pettyDiscrepancy() {
    return _selectedPettyCash().fold(
      0.0,
          (sum, row) => sum + _num(row['discrepancy']),
    );
  }

  double _totalDiscrepancy() {
    return _bankDiscrepancy().abs() +
        _cashDiscrepancy().abs() +
        _pettyDiscrepancy().abs();
  }

  Map<String, dynamic>? _selectedPeriod() {
    for (final period in _periods) {
      if (period['id']?.toString() == _selectedPeriodId) {
        return period;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute: '/consultant/companies/${widget.companyId}/banking/reports',
      title: 'گزارش‌های بانک و نقدینگی',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 50),
              const SizedBox(height: 12),
              const Text(
                'خطا در دریافت گزارش‌ها',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
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

    if (_periods.isEmpty) {
      return const Center(child: Text('هنوز هیچ دوره مالی ثبت نشده است.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 950;

        return ListView(
          primary: true,
          padding: EdgeInsets.all(constraints.maxWidth < 600 ? 14 : 24),
          children: [
            _header(),
            const SizedBox(height: 18),
            _periodSelector(),
            const SizedBox(height: 18),
            _liquidityCards(compact),
            const SizedBox(height: 18),
            _liquidityReport(),
            const SizedBox(height: 18),
            _bankComparisonReport(),
            const SizedBox(height: 18),
            _bankLedgerReport(),
            const SizedBox(height: 18),
            _cashLedgerReport(),
            const SizedBox(height: 18),
            _pettyLedgerReport(),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

  Widget _header() {
    final period = _selectedPeriod();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'گزارش‌های مالی',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                period == null
                    ? 'گزارش بانک، صندوق و تنخواه'
                    : 'دوره انتخابی: ${_periodTitle(period)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'به‌روزرسانی',
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _periodSelector() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined),
            const SizedBox(width: 12),
            const Text(
              'دوره مالی',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: DropdownButtonFormField<String>(
                value:
                _periods.any(
                      (p) => p['id']?.toString() == _selectedPeriodId,
                )
                    ? _selectedPeriodId
                    : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items:
                _periods.map((period) {
                  final id = period['id'].toString();

                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(_periodTitle(period)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPeriodId = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liquidityCards(bool compact) {
    final cards = [
      _card(
        'کل نقدینگی',
        _money(_liquidityTotal()),
        Icons.account_balance_wallet_outlined,
      ),
      _card('بانک', _money(_bankTotal()), Icons.account_balance_outlined),
      _card('صندوق', _money(_cashTotal()), Icons.point_of_sale_outlined),
      _card('تنخواه', _money(_pettyTotal()), Icons.payments_outlined),
      _card(
        'مغایرت',
        _money(_totalDiscrepancy()),
        Icons.compare_arrows_outlined,
      ),
    ];

    if (compact) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 620 ? 2 : 1;
          return GridView.count(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 2 ? 2.7 : 3.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cards,
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          crossAxisCount: 5,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.35,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      },
    );
  }

  Widget _card(String title, String value, IconData icon) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: Theme.of(context).colorScheme.primary.withOpacity(.10),
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
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

  Widget _liquidityReport() {
    return _reportCard(
      title: 'گزارش نقدینگی',
      icon: Icons.account_balance_wallet_outlined,
      child: _reportTable(
        headers: const ['منبع نقدینگی', 'مانده', 'درصد از کل'],
        rows: [
          ['حساب‌های بانکی', _money(_bankTotal()), _percent(_bankTotal())],
          ['صندوق‌ها', _money(_cashTotal()), _percent(_cashTotal())],
          ['تنخواه‌ها', _money(_pettyTotal()), _percent(_pettyTotal())],
          ['کل نقدینگی', _money(_liquidityTotal()), '100%'],
        ],
      ),
    );
  }

  String _percent(double value) {
    final total = _liquidityTotal();

    if (total == 0) {
      return '0%';
    }

    return '${(value / total * 100).toStringAsFixed(1)}%';
  }

  Widget _bankComparisonReport() {
    final rows = _selectedBanks();

    return _reportCard(
      title: 'گزارش مقایسه بانک‌ها',
      icon: Icons.account_balance_outlined,
      child:
      rows.isEmpty
          ? _emptyReport()
          : _reportTable(
        headers: const [
          'بانک',
          'شماره حساب',
          'مانده',
          'بدهکار',
          'بستانکار',
          'مغایرت',
        ],
        rows:
        rows.map((row) {
          final relation = row['bank_accounts'];

          final bank =
          relation is Map ? relation : <String, dynamic>{};

          return [
            bank['bank_name']?.toString() ?? '-',
            bank['account_number']?.toString() ?? '-',
            _money(row['closing_balance']),
            _money(row['debit_turnover']),
            _money(row['credit_turnover']),
            _money(row['discrepancy']),
          ];
        }).toList(),
      ),
    );
  }

  Widget _bankLedgerReport() {
    final rows = _selectedBanks();

    return _reportCard(
      title: 'بانک در مقابل دفاتر',
      icon: Icons.compare_outlined,
      child: _reportTable(
        headers: const ['شاخص', 'مبلغ'],
        rows: [
          ['مانده بانک', _money(_bankTotal())],
          ['مانده دفاتر', _money(_bankLedgerTotal())],
          ['مغایرت', _money(_bankDiscrepancy())],
          ['تعداد حساب‌ها', rows.length.toString()],
        ],
      ),
    );
  }

  Widget _cashLedgerReport() {
    final rows = _selectedCashBoxes();

    return _reportCard(
      title: 'صندوق در مقابل دفاتر',
      icon: Icons.account_balance_wallet_outlined,
      child: _reportTable(
        headers: const ['شاخص', 'مبلغ'],
        rows: [
          ['مانده صندوق', _money(_cashTotal())],
          ['مانده دفاتر', _money(_cashLedgerTotal())],
          ['مغایرت', _money(_cashDiscrepancy())],
          ['تعداد صندوق‌ها', rows.length.toString()],
        ],
      ),
    );
  }

  Widget _pettyLedgerReport() {
    final rows = _selectedPettyCash();

    return _reportCard(
      title: 'تنخواه در مقابل دفاتر',
      icon: Icons.payments_outlined,
      child: _reportTable(
        headers: const ['شاخص', 'مبلغ'],
        rows: [
          ['مانده تنخواه', _money(_pettyTotal())],
          ['مانده دفاتر', _money(_pettyLedgerTotal())],
          ['مغایرت', _money(_pettyDiscrepancy())],
          ['تعداد تنخواه‌ها', rows.length.toString()],
        ],
      ),
    );
  }

  Widget _reportCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }

  Widget _reportTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    if (rows.isEmpty) return _emptyReport();

    final columnCount = headers.length;
    final normalizedRows = rows.map((row) {
      if (row.length == columnCount) return row;
      return List<String>.generate(
        columnCount,
            (index) => index < row.length ? row[index] : '-',
      );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final minTableWidth = columnCount * 150.0;
        final tableWidth = constraints.maxWidth.isFinite
            ? (constraints.maxWidth > minTableWidth
            ? constraints.maxWidth
            : minTableWidth)
            : minTableWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          primary: false,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(.55),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: headers.map((header) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            header,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                ...List.generate(normalizedRows.length, (rowIndex) {
                  final row = normalizedRows[rowIndex];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: rowIndex.isEven
                          ? Theme.of(context).colorScheme.surface
                          : Theme.of(context)
                          .colorScheme
                          .surfaceContainerLowest,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withOpacity(.45),
                        ),
                      ),
                    ),
                    child: Row(
                      children: row.map((value) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              value,
                              textAlign: TextAlign.right,
                              softWrap: true,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _emptyReport() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(
        child: Text(
          'برای این دوره اطلاعاتی ثبت نشده است.',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ),
    );
  }
}