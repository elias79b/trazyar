import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantBankingReportsProvider =
    FutureProvider.family<AccountantBankingReportsData, String>((
      ref,
      companyId,
    ) async {
      return AccountantBankingReportsRepository.load(companyId: companyId);
    });

class AccountantBankingReportsData {
  final String companyId;
  final List<AccountantBankingReportRow> rows;

  const AccountantBankingReportsData({
    required this.companyId,
    required this.rows,
  });

  double get totalOpening =>
      rows.fold(0, (sum, item) => sum + item.openingBalance);

  double get totalDebit =>
      rows.fold(0, (sum, item) => sum + item.debitTurnover);

  double get totalCredit =>
      rows.fold(0, (sum, item) => sum + item.creditTurnover);

  double get totalClosing =>
      rows.fold(0, (sum, item) => sum + item.closingBalance);

  double get totalLedger =>
      rows.fold(0, (sum, item) => sum + item.ledgerBalance);

  double get totalDiscrepancy =>
      rows.fold(0, (sum, item) => sum + item.discrepancy);

  int get discrepancyCount =>
      rows.where((item) => item.discrepancy.abs() > 0.009).length;
}

class AccountantBankingReportRow {
  final String periodId;
  final String periodTitle;
  final int year;
  final int month;

  final String bankAccountId;
  final String bankName;
  final String accountNumber;

  final double openingBalance;
  final double debitTurnover;
  final double creditTurnover;
  final double closingBalance;
  final double ledgerBalance;
  final double discrepancy;

  const AccountantBankingReportRow({
    required this.periodId,
    required this.periodTitle,
    required this.year,
    required this.month,
    required this.bankAccountId,
    required this.bankName,
    required this.accountNumber,
    required this.openingBalance,
    required this.debitTurnover,
    required this.creditTurnover,
    required this.closingBalance,
    required this.ledgerBalance,
    required this.discrepancy,
  });

  bool get hasDiscrepancy => discrepancy.abs() > 0.009;
}

class AccountantBankingReportsRepository {
  AccountantBankingReportsRepository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<AccountantBankingReportsData> load({
    required String companyId,
  }) async {
    final result = await _supabase
        .from('bank_account_periods')
        .select('''
          id,
          company_id,
          period_id,
          bank_account_id,
          opening_balance,
          debit_turnover,
          credit_turnover,
          closing_balance,
          ledger_balance,
          discrepancy,
          cash_fiscal_periods(
            id,
            year,
            month,
            title
          ),
          bank_accounts(
            id,
            bank_name,
            account_number
          )
        ''')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    final rows = <AccountantBankingReportRow>[];

    for (final raw in result) {
      final row = Map<String, dynamic>.from(raw);

      final periodRaw = row['cash_fiscal_periods'];
      final accountRaw = row['bank_accounts'];

      final period =
          periodRaw is Map
              ? Map<String, dynamic>.from(periodRaw)
              : <String, dynamic>{};

      final account =
          accountRaw is Map
              ? Map<String, dynamic>.from(accountRaw)
              : <String, dynamic>{};

      rows.add(
        AccountantBankingReportRow(
          periodId: row['period_id']?.toString() ?? '',
          periodTitle:
              period['title']?.toString().trim().isNotEmpty == true
                  ? period['title'].toString()
                  : _periodTitle(period['year'], period['month']),
          year: _toInt(period['year']),
          month: _toInt(period['month']),
          bankAccountId: row['bank_account_id']?.toString() ?? '',
          bankName: account['bank_name']?.toString() ?? 'بدون نام بانک',
          accountNumber: account['account_number']?.toString() ?? '',
          openingBalance: _toDouble(row['opening_balance']),
          debitTurnover: _toDouble(row['debit_turnover']),
          creditTurnover: _toDouble(row['credit_turnover']),
          closingBalance: _toDouble(row['closing_balance']),
          ledgerBalance: _toDouble(row['ledger_balance']),
          discrepancy: _toDouble(row['discrepancy']),
        ),
      );
    }

    return AccountantBankingReportsData(companyId: companyId, rows: rows);
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '')) ?? 0;
  }

  static String _periodTitle(dynamic year, dynamic month) {
    final y = _toInt(year);
    final m = _toInt(month);

    const months = <String>[
      '',
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

    final monthName = m >= 1 && m <= 12 ? months[m] : 'ماه $m';

    return '$monthName $y';
  }
}
