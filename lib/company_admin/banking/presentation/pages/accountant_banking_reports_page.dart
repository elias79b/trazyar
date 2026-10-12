import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';

final accountantBankingReportsProvider =
FutureProvider.autoDispose<AccountantBankingReportsData>((ref) async {
  final client = Supabase.instance.client;

  final authUser = client.auth.currentUser;

  if (authUser == null) {
    throw Exception('کاربر وارد نشده است.');
  }

  // ============================================================
  // COMPANY MEMBERSHIP
  // ============================================================

  final membership = await client
      .from('company_users')
      .select('company_id, user_id, role, is_active')
      .eq('user_id', authUser.id)
      .eq('role', 'accountant')
      .eq('is_active', true)
      .maybeSingle();

  if (membership == null) {
    throw Exception(
      'هیچ شرکتی برای این حسابدار تخصیص داده نشده است.',
    );
  }

  final companyId = membership['company_id']?.toString();

  if (companyId == null || companyId.isEmpty) {
    throw Exception('شناسه شرکت حسابدار پیدا نشد.');
  }

  return AccountantBankingReportsRepository(
    client,
  ).load(companyId);
});

class AccountantBankingReportsRepository {
  final SupabaseClient _supabase;

  AccountantBankingReportsRepository(this._supabase);

  Future<AccountantBankingReportsData> load(
      String companyId,
      ) async {
    // ============================================================
    // FISCAL PERIODS
    // ============================================================

    final periodsResponse = await _supabase
        .from('cash_fiscal_periods')
        .select(
      'id, year, month, title, status',
    )
        .eq('company_id', companyId)
        .inFilter(
      'status',
      ['approved', 'closed'],
    )
        .order(
      'year',
      ascending: false,
    )
        .order(
      'month',
      ascending: true,
    );

    final periods = (periodsResponse as List)
        .map(
          (row) => FiscalReportPeriod.fromMap(
        Map<String, dynamic>.from(row),
      ),
    )
        .toList();

    final periodIds = periods
        .map((e) => e.id)
        .toList();

    List<Map<String, dynamic>> bankRows = [];
    List<Map<String, dynamic>> cashRows = [];
    List<Map<String, dynamic>> pettyRows = [];

    if (periodIds.isNotEmpty) {
      // ==========================================================
      // BANK
      // ==========================================================

      final bankResponse = await _supabase
          .from('bank_account_periods')
          .select(
        '''
            id,
            period_id,
            bank_account_id,
            opening_balance,
            debit_turnover,
            credit_turnover,
            closing_balance,
            ledger_balance,
            discrepancy,
            bank_accounts(
              bank_name,
              account_number
            )
            ''',
      )
          .eq(
        'company_id',
        companyId,
      )
          .inFilter(
        'period_id',
        periodIds,
      );

      // ==========================================================
      // CASH BOX
      // ==========================================================

      final cashResponse = await _supabase
          .from('cash_box_periods')
          .select(
        '''
            id,
            period_id,
            cash_box_id,
            opening_balance,
            total_receipts,
            total_payments,
            closing_balance,
            ledger_balance,
            discrepancy,
            cash_boxes(
              box_name
            )
            ''',
      )
          .eq(
        'company_id',
        companyId,
      )
          .inFilter(
        'period_id',
        periodIds,
      );

      // ==========================================================
      // PETTY CASH
      // ==========================================================

      final pettyResponse = await _supabase
          .from('petty_cash_periods')
          .select(
        '''
            id,
            period_id,
            petty_cash_id,
            opening_balance,
            total_receipts,
            total_payments,
            closing_balance,
            ledger_balance,
            discrepancy,
            petty_cash_accounts(
              name
            )
            ''',
      )
          .eq(
        'company_id',
        companyId,
      )
          .inFilter(
        'period_id',
        periodIds,
      );

      bankRows = (bankResponse as List)
          .map(
            (e) => Map<String, dynamic>.from(e),
      )
          .toList();

      cashRows = (cashResponse as List)
          .map(
            (e) => Map<String, dynamic>.from(e),
      )
          .toList();

      pettyRows = (pettyResponse as List)
          .map(
            (e) => Map<String, dynamic>.from(e),
      )
          .toList();
    }

    // ============================================================
    // BANK LOANS
    // ============================================================

    final loansResponse = await _supabase
        .from('bank_loans')
        .select(
      '''
          id,
          bank_name,
          loan_type,
          principal_amount,
          remaining_amount,
          interest_rate,
          start_date,
          end_date,
          monthly_installment
          ''',
    )
        .eq(
      'company_id',
      companyId,
    )
        .order(
      'bank_name',
      ascending: true,
    );

    // ============================================================
    // RECEIVED CHECKS
    // ============================================================

    final receivedResponse = await _supabase
        .from('received_checks')
        .select(
      '''
          id,
          check_number,
          bank_name,
          amount,
          due_date,
          status
          ''',
    )
        .eq(
      'company_id',
      companyId,
    )
        .order(
      'due_date',
      ascending: true,
    );

    // ============================================================
    // PAID CHECKS
    // ============================================================

    final paidResponse = await _supabase
        .from('paid_checks')
        .select(
      '''
          id,
          check_number,
          bank_name,
          amount,
          due_date,
          status
          ''',
    )
        .eq(
      'company_id',
      companyId,
    )
        .order(
      'due_date',
      ascending: true,
    );

    return AccountantBankingReportsData(
      periods: periods,
      bankRows: bankRows,
      cashRows: cashRows,
      pettyRows: pettyRows,
      loans: (loansResponse as List)
          .map(
            (e) => BankLoanReportRow.fromMap(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList(),
      receivedChecks: (receivedResponse as List)
          .map(
            (e) => CheckReportRow.fromMap(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList(),
      paidChecks: (paidResponse as List)
          .map(
            (e) => CheckReportRow.fromMap(
          Map<String, dynamic>.from(e),
        ),
      )
          .toList(),
    );
  }
}

// ================================================================
// PERIOD
// ================================================================

class FiscalReportPeriod {
  final String id;
  final int year;
  final int month;
  final String title;
  final String status;

  const FiscalReportPeriod({
    required this.id,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
  });

  factory FiscalReportPeriod.fromMap(
      Map<String, dynamic> map,
      ) {
    return FiscalReportPeriod(
      id: map['id']?.toString() ?? '',
      year: _toInt(map['year']),
      month: _toInt(map['month']),
      title: map['title']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
    );
  }
}

// ================================================================
// BANK LOAN
// ================================================================

class BankLoanReportRow {
  final String bankName;
  final String loanType;
  final double principal;
  final double remaining;
  final double interestRate;
  final double monthlyInstallment;

  const BankLoanReportRow({
    required this.bankName,
    required this.loanType,
    required this.principal,
    required this.remaining,
    required this.interestRate,
    required this.monthlyInstallment,
  });

  factory BankLoanReportRow.fromMap(
      Map<String, dynamic> map,
      ) {
    return BankLoanReportRow(
      bankName: map['bank_name']?.toString() ?? '-',
      loanType: map['loan_type']?.toString() ?? '-',
      principal: _toDouble(
        map['principal_amount'],
      ),
      remaining: _toDouble(
        map['remaining_amount'],
      ),
      interestRate: _toDouble(
        map['interest_rate'],
      ),
      monthlyInstallment: _toDouble(
        map['monthly_installment'],
      ),
    );
  }
}

// ================================================================
// CHECK
// ================================================================

class CheckReportRow {
  final String checkNumber;
  final String bankName;
  final double amount;
  final String? dueDate;
  final String status;

  const CheckReportRow({
    required this.checkNumber,
    required this.bankName,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  factory CheckReportRow.fromMap(
      Map<String, dynamic> map,
      ) {
    return CheckReportRow(
      checkNumber:
      map['check_number']?.toString() ?? '-',
      bankName:
      map['bank_name']?.toString() ?? '-',
      amount:
      _toDouble(map['amount']),
      dueDate:
      map['due_date']?.toString(),
      status:
      map['status']?.toString() ?? 'pending',
    );
  }
}

// ================================================================
// REPORT DATA
// ================================================================

class AccountantBankingReportsData {
  final List<FiscalReportPeriod> periods;
  final List<Map<String, dynamic>> bankRows;
  final List<Map<String, dynamic>> cashRows;
  final List<Map<String, dynamic>> pettyRows;
  final List<BankLoanReportRow> loans;
  final List<CheckReportRow> receivedChecks;
  final List<CheckReportRow> paidChecks;

  const AccountantBankingReportsData({
    required this.periods,
    required this.bankRows,
    required this.cashRows,
    required this.pettyRows,
    required this.loans,
    required this.receivedChecks,
    required this.paidChecks,
  });

  List<FiscalReportPeriod> periodsForYear(
      int? year,
      ) {
    if (year == null) {
      return periods;
    }

    return periods
        .where(
          (e) => e.year == year,
    )
        .toList();
  }

  List<String> get years {
    final values = periods
        .map(
          (e) => e.year.toString(),
    )
        .toSet()
        .toList();

    values.sort(
          (a, b) =>
          int.parse(b).compareTo(
            int.parse(a),
          ),
    );

    return values;
  }

  Set<String> periodIdsForYear(
      int? year,
      ) {
    return periodsForYear(year)
        .map((e) => e.id)
        .toSet();
  }

  List<Map<String, dynamic>> banksForYear(
      int? year,
      ) {
    final ids = periodIdsForYear(year);

    return bankRows
        .where(
          (e) => ids.contains(
        e['period_id']?.toString(),
      ),
    )
        .toList();
  }

  List<Map<String, dynamic>> cashForYear(
      int? year,
      ) {
    final ids = periodIdsForYear(year);

    return cashRows
        .where(
          (e) => ids.contains(
        e['period_id']?.toString(),
      ),
    )
        .toList();
  }

  List<Map<String, dynamic>> pettyForYear(
      int? year,
      ) {
    final ids = periodIdsForYear(year);

    return pettyRows
        .where(
          (e) => ids.contains(
        e['period_id']?.toString(),
      ),
    )
        .toList();
  }
}

// ================================================================
// PAGE
// ================================================================

class AccountantBankingReportsPage
    extends ConsumerStatefulWidget {
  const AccountantBankingReportsPage({
    super.key,
  });

  @override
  ConsumerState<AccountantBankingReportsPage>
  createState() =>
      _AccountantBankingReportsPageState();
}

class _AccountantBankingReportsPageState
    extends ConsumerState<
        AccountantBankingReportsPage> {
  int? _selectedYear;

  @override
  Widget build(
      BuildContext context,
      ) {
    final asyncData = ref.watch(
      accountantBankingReportsProvider,
    );

    return asyncData.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) =>
          _buildError(
            context,
            error,
          ),
      data: (data) =>
          _buildReport(
            context,
            data,
          ),
    );
  }

  Widget _buildReport(
      BuildContext context,
      AccountantBankingReportsData data,
      ) {
    final years = data.years;

    if (_selectedYear != null &&
        !years.contains(
          _selectedYear.toString(),
        )) {
      _selectedYear = null;
    }

    final periods =
    data.periodsForYear(
      _selectedYear,
    );

    final banks =
    data.banksForYear(
      _selectedYear,
    );

    final cash =
    data.cashForYear(
      _selectedYear,
    );

    final petty =
    data.pettyForYear(
      _selectedYear,
    );

    final bankClosing =
    _sum(
      banks,
      'closing_balance',
    );

    final cashClosing =
    _sum(
      cash,
      'closing_balance',
    );

    final pettyClosing =
    _sum(
      petty,
      'closing_balance',
    );

    final bankDebit =
    _sum(
      banks,
      'debit_turnover',
    );

    final bankCredit =
    _sum(
      banks,
      'credit_turnover',
    );

    final receipts =
        _sum(
          cash,
          'total_receipts',
        ) +
            _sum(
              petty,
              'total_receipts',
            );

    final payments =
        _sum(
          cash,
          'total_payments',
        ) +
            _sum(
              petty,
              'total_payments',
            );

    final discrepancy =
        _sum(
          banks,
          'discrepancy',
        ) +
            _sum(
              cash,
              'discrepancy',
            ) +
            _sum(
              petty,
              'discrepancy',
            );

    return AccountantScaffold(
      currentRoute:
      '/accountant/banking/reports',
      title: 'گزارش‌های نقد و بانک',
      body: Directionality(
        textDirection:
        TextDirection.rtl,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(
              accountantBankingReportsProvider,
            );

            await ref.read(
              accountantBankingReportsProvider.future,
            );
          },
          child: ListView(
            padding:
            const EdgeInsets.all(24),
            children: [
              _buildHeader(
                context,
                periods.length,
              ),

              const SizedBox(height: 18),

              _buildYearFilter(
                years,
              ),

              const SizedBox(height: 18),

              _buildSummaryGrid([
                _SummaryItem(
                  title: 'مانده بانک',
                  value: bankClosing,
                  icon:
                  Icons.account_balance_outlined,
                ),
                _SummaryItem(
                  title: 'مانده صندوق',
                  value: cashClosing,
                  icon:
                  Icons.point_of_sale_outlined,
                ),
                _SummaryItem(
                  title: 'مانده تنخواه',
                  value: pettyClosing,
                  icon:
                  Icons.wallet_outlined,
                ),
                _SummaryItem(
                  title: 'اختلاف',
                  value: discrepancy,
                  icon:
                  Icons.compare_arrows_outlined,
                  danger:
                  discrepancy.abs() > 0.01,
                ),
              ]),

              const SizedBox(height: 18),

              _buildTurnoverCard(
                debit: bankDebit,
                credit: bankCredit,
                receipts: receipts,
                payments: payments,
              ),

              const SizedBox(height: 18),

              _buildPeriodsCard(
                periods,
              ),

              const SizedBox(height: 18),

              _buildBankDetails(
                banks,
              ),

              const SizedBox(height: 18),

              _buildCashDetails(
                cash,
              ),

              const SizedBox(height: 18),

              _buildPettyDetails(
                petty,
              ),

              const SizedBox(height: 18),

              _buildLoans(
                data.loans,
              ),

              const SizedBox(height: 18),

              _buildChecks(
                title: 'چک‌های دریافتی',
                rows:
                data.receivedChecks,
                icon:
                Icons.call_received_outlined,
              ),

              const SizedBox(height: 18),

              _buildChecks(
                title: 'چک‌های پرداختی',
                rows:
                data.paidChecks,
                icon:
                Icons.call_made_outlined,
              ),

              const SizedBox(height: 24),

              _buildFooterNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      int periodCount,
      ) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'گزارش‌های نقد و بانک',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'گزارش فقط بر اساس دوره‌های تأییدشده و بسته‌شده تهیه می‌شود.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        _InfoChip(
          text:
          '$periodCount دوره',
        ),
      ],
    );
  }

  Widget _buildYearFilter(
      List<String> years,
      ) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.filter_alt_outlined,
            ),
            const SizedBox(width: 10),
            const Text(
              'سال مالی',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child:
              DropdownButtonFormField<int?>(
                value: _selectedYear,
                decoration:
                const InputDecoration(
                  border:
                  OutlineInputBorder(),
                  hintText:
                  'همه سال‌های تأییدشده',
                ),
                items: [
                  const DropdownMenuItem<
                      int?>(
                    value: null,
                    child: Text(
                      'همه سال‌های تأییدشده',
                    ),
                  ),
                  ...years.map(
                        (year) =>
                        DropdownMenuItem<
                            int?>(
                          value:
                          int.parse(year),
                          child: Text(
                            'سال مالی $year',
                          ),
                        ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedYear =
                        value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(
      List<_SummaryItem> items,
      ) {
    return LayoutBuilder(
      builder:
          (context, constraints) {
        final count =
        constraints.maxWidth >=
            1200
            ? 4
            : constraints.maxWidth >=
            700
            ? 2
            : 1;

        final width =
            (constraints.maxWidth -
                ((count - 1) *
                    12)) /
                count;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
          items.map(
                (item) {
              return SizedBox(
                width: width,
                child:
                _SummaryCard(
                  item: item,
                ),
              );
            },
          ).toList(),
        );
      },
    );
  }

  Widget _buildTurnoverCard({
    required double debit,
    required double credit,
    required double receipts,
    required double payments,
  }) {
    return _SectionCard(
      title: 'گردش مالی',
      icon:
      Icons.swap_vert_circle_outlined,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _MetricLine(
            title:
            'گردش بدهکار بانک',
            value: debit,
          ),
          _MetricLine(
            title:
            'گردش بستانکار بانک',
            value: credit,
          ),
          _MetricLine(
            title:
            'دریافت صندوق و تنخواه',
            value: receipts,
          ),
          _MetricLine(
            title:
            'پرداخت صندوق و تنخواه',
            value: payments,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodsCard(
      List<FiscalReportPeriod>
      periods,
      ) {
    return _SectionCard(
      title:
      'دوره‌های واردشده در گزارش',
      icon:
      Icons.calendar_month_outlined,
      child: periods.isEmpty
          ? _empty(
        'دوره تأییدشده‌ای برای گزارش وجود ندارد.',
      )
          : Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
        periods.map(
              (period) {
            return Chip(
              avatar:
              const Icon(
                Icons
                    .check_circle_outline,
                size: 17,
              ),
              label: Text(
                '${period.title} • ${_statusTitle(period.status)}',
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildBankDetails(
      List<Map<String, dynamic>>
      rows,
      ) {
    final grouped =
    <String, _BankAggregate>{};

    for (final row in rows) {
      final id =
          row['bank_account_id']
              ?.toString() ??
              '';

      final nested =
      row['bank_accounts'];

      final bank =
      nested is Map
          ? nested['bank_name']
          ?.toString() ??
          '-'
          : '-';

      final number =
      nested is Map
          ? nested[
      'account_number']
          ?.toString() ??
          '-'
          : '-';

      final current =
          grouped[id] ??
              _BankAggregate(
                bankName: bank,
                accountNumber:
                number,
              );

      current.opening +=
          _toDouble(
            row['opening_balance'],
          );

      current.debit +=
          _toDouble(
            row['debit_turnover'],
          );

      current.credit +=
          _toDouble(
            row['credit_turnover'],
          );

      current.closing +=
          _toDouble(
            row['closing_balance'],
          );

      current.ledger +=
          _toDouble(
            row['ledger_balance'],
          );

      current.discrepancy +=
          _toDouble(
            row['discrepancy'],
          );

      grouped[id] =
          current;
    }

    final values =
    grouped.values.toList();

    return _SectionCard(
      title:
      'وضعیت حساب‌های بانکی',
      icon:
      Icons.account_balance_outlined,
      child: values.isEmpty
          ? _empty(
        'برای دوره‌های تأییدشده اطلاعات بانکی ثبت نشده است.',
      )
          : _ReportTable(
        columns: const [
          'بانک',
          'شماره حساب',
          'افتتاحیه',
          'بدهکار',
          'بستانکار',
          'پایانی',
          'دفتر',
          'اختلاف',
        ],
        rows:
        values.map(
              (e) => [
            e.bankName,
            e.accountNumber,
            _money(
                e.opening),
            _money(
                e.debit),
            _money(
                e.credit),
            _money(
                e.closing),
            _money(
                e.ledger),
            _money(
                e.discrepancy),
          ],
        ).toList(),
      ),
    );
  }

  Widget _buildCashDetails(
      List<Map<String, dynamic>>
      rows,
      ) {
    return _buildCashSection(
      title: 'وضعیت صندوق‌ها',
      empty:
      'برای دوره‌های تأییدشده اطلاعات صندوق ثبت نشده است.',
      rows: rows,
      idField: 'cash_box_id',
      relation:
      'cash_boxes',
      nameField:
      'box_name',
    );
  }

  Widget _buildPettyDetails(
      List<Map<String, dynamic>>
      rows,
      ) {
    return _buildCashSection(
      title: 'وضعیت تنخواه‌ها',
      empty:
      'برای دوره‌های تأییدشده اطلاعات تنخواه ثبت نشده است.',
      rows: rows,
      idField:
      'petty_cash_id',
      relation:
      'petty_cash_accounts',
      nameField: 'name',
    );
  }

  Widget _buildCashSection({
    required String title,
    required String empty,
    required List<Map<String, dynamic>>
    rows,
    required String idField,
    required String relation,
    required String nameField,
  }) {
    final grouped =
    <String, _CashAggregate>{};

    for (final row in rows) {
      final id =
          row[idField]?.toString() ??
              '';

      final nested =
      row[relation];

      final name =
      nested is Map
          ? nested[nameField]
          ?.toString() ??
          '-'
          : '-';

      final current =
          grouped[id] ??
              _CashAggregate(
                name: name,
              );

      current.opening +=
          _toDouble(
            row['opening_balance'],
          );

      current.receipts +=
          _toDouble(
            row['total_receipts'],
          );

      current.payments +=
          _toDouble(
            row['total_payments'],
          );

      current.closing +=
          _toDouble(
            row['closing_balance'],
          );

      current.ledger +=
          _toDouble(
            row['ledger_balance'],
          );

      current.discrepancy +=
          _toDouble(
            row['discrepancy'],
          );

      grouped[id] =
          current;
    }

    final values =
    grouped.values.toList();

    return _SectionCard(
      title: title,
      icon:
      title.contains('تنخواه')
          ? Icons.wallet_outlined
          : Icons.point_of_sale_outlined,
      child: values.isEmpty
          ? _empty(empty)
          : _ReportTable(
        columns: const [
          'عنوان',
          'افتتاحیه',
          'دریافت',
          'پرداخت',
          'پایانی',
          'دفتر',
          'اختلاف',
        ],
        rows:
        values.map(
              (e) => [
            e.name,
            _money(
                e.opening),
            _money(
                e.receipts),
            _money(
                e.payments),
            _money(
                e.closing),
            _money(
                e.ledger),
            _money(
                e.discrepancy),
          ],
        ).toList(),
      ),
    );
  }

  Widget _buildLoans(
      List<BankLoanReportRow>
      loans,
      ) {
    final remaining =
    loans.fold<double>(
      0,
          (sum, item) =>
      sum + item.remaining,
    );

    return _SectionCard(
      title:
      'تسهیلات بانکی جاری',
      icon:
      Icons.request_quote_outlined,
      trailing: Text(
        'باقی‌مانده: ${_money(remaining)}',
        style:
        const TextStyle(
          fontWeight:
          FontWeight.bold,
        ),
      ),
      child: loans.isEmpty
          ? _empty(
        'تسهیلات بانکی ثبت نشده است.',
      )
          : _ReportTable(
        columns: const [
          'بانک',
          'نوع تسهیلات',
          'اصل',
          'باقی‌مانده',
          'نرخ',
          'قسط ماهانه',
        ],
        rows:
        loans.map(
              (e) => [
            e.bankName,
            e.loanType,
            _money(
                e.principal),
            _money(
                e.remaining),
            '${_number(e.interestRate)}٪',
            _money(
                e.monthlyInstallment),
          ],
        ).toList(),
      ),
    );
  }

  Widget _buildChecks({
    required String title,
    required List<CheckReportRow>
    rows,
    required IconData icon,
  }) {
    final total =
    rows.fold<double>(
      0,
          (sum, item) =>
      sum + item.amount,
    );

    return _SectionCard(
      title: title,
      icon: icon,
      trailing: Text(
        'جمع: ${_money(total)}',
        style:
        const TextStyle(
          fontWeight:
          FontWeight.bold,
        ),
      ),
      child: rows.isEmpty
          ? _empty(
        'موردی ثبت نشده است.',
      )
          : _ReportTable(
        columns: const [
          'شماره چک',
          'بانک',
          'مبلغ',
          'سررسید',
          'وضعیت',
        ],
        rows:
        rows.map(
              (e) => [
            e.checkNumber,
            e.bankName,
            _money(
                e.amount),
            e.dueDate ?? '-',
            _checkStatus(
                e.status),
          ],
        ).toList(),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color:
        const Color(0xffedf5f1),
        borderRadius:
        BorderRadius.circular(
          14,
        ),
      ),
      child: const Text(
        'مبنای گزارش دوره‌ای فقط دوره‌های نقد و بانک با وضعیت «تأییدشده» یا «بسته» است. تسهیلات و چک‌ها به‌صورت وضعیت جاری نمایش داده می‌شوند.',
        textDirection:
        TextDirection.rtl,
        style: TextStyle(
          fontSize: 12,
          height: 1.7,
        ),
      ),
    );
  }

  Widget _buildError(
      BuildContext context,
      Object error,
      ) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 52,
              ),
              const SizedBox(
                height: 12,
              ),
              const Text(
                'خطا در دریافت گزارش‌های نقد و بانک',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                error.toString(),
                textDirection:
                TextDirection.ltr,
                textAlign:
                TextAlign.center,
              ),
              const SizedBox(
                height: 16,
              ),
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(
                    accountantBankingReportsProvider,
                  );
                },
                icon:
                const Icon(
                  Icons.refresh,
                ),
                label:
                const Text(
                  'تلاش مجدد',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(22),
      decoration:
      BoxDecoration(
        color:
        const Color(0xfff7f8f8),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),
      child: Text(
        text,
        textAlign:
        TextAlign.center,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ================================================================
// WIDGETS
// ================================================================

class _SummaryItem {
  final String title;
  final double value;
  final IconData icon;
  final bool danger;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    this.danger = false,
  });
}

class _SummaryCard
    extends StatelessWidget {
  final _SummaryItem item;

  const _SummaryCard({
    required this.item,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final color = item.danger
        ? Colors.red.shade700
        : const Color(0xff17775c);

    return Card(
      elevation: 0,
      child: Padding(
        padding:
        const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: color,
              size: 30,
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style:
                    const TextStyle(
                      color:
                      Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    _money(
                      item.value,
                    ),
                    style:
                    const TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.bold,
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

class _SectionCard
    extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Card(
      elevation: 0,
      child: Padding(
        padding:
        const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .stretch,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color:
                  const Color(
                    0xff17775c,
                  ),
                ),
                const SizedBox(
                  width: 9,
                ),
                Expanded(
                  child: Text(
                    title,
                    style:
                    const TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
                if (trailing != null)
                  trailing!,
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReportTable
    extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;

  const _ReportTable({
    required this.columns,
    required this.rows,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return SingleChildScrollView(
      scrollDirection:
      Axis.horizontal,
      child: DataTable(
        columns: columns
            .map(
              (e) => DataColumn(
            label: Text(
              e,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        )
            .toList(),
        rows: rows
            .map(
              (row) => DataRow(
            cells: row
                .map(
                  (cell) =>
                  DataCell(
                    Text(
                      cell,
                      style:
                      const TextStyle(
                        fontSize: 11,
                      ),
                    ),
                  ),
            )
                .toList(),
          ),
        )
            .toList(),
      ),
    );
  }
}

class _MetricLine
    extends StatelessWidget {
  final String title;
  final double value;

  const _MetricLine({
    required this.title,
    required this.value,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return SizedBox(
      width: 260,
      child: Container(
        padding:
        const EdgeInsets.all(13),
        decoration:
        BoxDecoration(
          color:
          const Color(0xfff7f8f8),
          borderRadius:
          BorderRadius.circular(
            11,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style:
                const TextStyle(
                  fontSize: 11,
                ),
              ),
            ),
            Text(
              _money(value),
              style:
              const TextStyle(
                fontWeight:
                FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip
    extends StatelessWidget {
  final String text;

  const _InfoChip({
    required this.text,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(0xffedf5f1),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 17,
            color:
            Color(0xff17775c),
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            text,
            style:
            const TextStyle(
              color:
              Color(0xff17775c),
              fontWeight:
              FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _BankAggregate {
  final String bankName;
  final String accountNumber;

  double opening = 0;
  double debit = 0;
  double credit = 0;
  double closing = 0;
  double ledger = 0;
  double discrepancy = 0;

  _BankAggregate({
    required this.bankName,
    required this.accountNumber,
  });
}

class _CashAggregate {
  final String name;

  double opening = 0;
  double receipts = 0;
  double payments = 0;
  double closing = 0;
  double ledger = 0;
  double discrepancy = 0;

  _CashAggregate({
    required this.name,
  });
}

// ================================================================
// HELPERS
// ================================================================

double _sum(
    List<Map<String, dynamic>> rows,
    String field,
    ) {
  return rows.fold<double>(
    0,
        (sum, row) =>
    sum + _toDouble(
      row[field],
    ),
  );
}

double _toDouble(
    dynamic value,
    ) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value
        .toString()
        .replaceAll(',', '')
        .trim(),
  ) ??
      0;
}

int _toInt(
    dynamic value,
    ) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    value.toString(),
  ) ??
      0;
}

String _money(
    double value,
    ) {
  final rounded =
  value.round();

  final negative =
      rounded < 0;

  final digits =
  rounded.abs().toString();

  final buffer =
  StringBuffer();

  for (
  var i = 0;
  i < digits.length;
  i++
  ) {
    if (i > 0 &&
        (digits.length - i) %
            3 ==
            0) {
      buffer.write(',');
    }

    buffer.write(
      digits[i],
    );
  }

  return '${negative ? '-' : ''}${buffer.toString()} ریال';
}

String _number(
    double value,
    ) {
  if (value ==
      value.roundToDouble()) {
    return value
        .toInt()
        .toString();
  }

  return value.toStringAsFixed(
    2,
  );
}

String _statusTitle(
    String status,
    ) {
  switch (status) {
    case 'approved':
      return 'تأییدشده';

    case 'closed':
      return 'بسته';

    default:
      return status;
  }
}

String _checkStatus(
    String status,
    ) {
  switch (status) {
    case 'pending':
      return 'در انتظار';

    case 'paid':
      return 'پرداخت‌شده';

    case 'received':
      return 'دریافت‌شده';

    case 'cleared':
      return 'وصول‌شده';

    case 'bounced':
      return 'برگشتی';

    case 'cancelled':
      return 'لغوشده';

    default:
      return status;
  }
}