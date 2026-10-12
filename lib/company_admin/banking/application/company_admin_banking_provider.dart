import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final companyAdminBankingProvider =
FutureProvider<CompanyAdminBankingData>((ref) async {
  final supabase = Supabase.instance.client;

  final authUser = supabase.auth.currentUser;

  if (authUser == null) {
    throw Exception('کاربر وارد سیستم نشده است.');
  }

  // ============================================================
  // Company
  // ============================================================

  final membership = await supabase
      .from('company_users')
      .select('company_id, role, is_active')
      .eq('user_id', authUser.id)
      .eq('role', 'company_admin')
      .eq('is_active', true)
      .maybeSingle();

  if (membership == null) {
    throw Exception(
      'عضویت فعال مدیر شرکت پیدا نشد.',
    );
  }

  final companyId =
  membership['company_id'].toString();

  // ============================================================
  // Current Jalali date
  // ============================================================

  final now = Jalali.now();

  final currentYear = now.year;
  final currentMonth = now.month;

  // ============================================================
  // Last 6 Jalali months
  // ============================================================

  final months = <BankingMonth>[];

  for (int i = 5; i >= 0; i--) {
    int year = currentYear;
    int month = currentMonth - i;

    while (month <= 0) {
      month += 12;
      year--;
    }

    months.add(
      BankingMonth(
        year: year,
        month: month,
        title: _jalaliMonthName(month),
      ),
    );
  }

  // ============================================================
  // Approved fiscal periods
  // ============================================================

  final fiscalPeriods = await supabase
      .from('cash_fiscal_periods')
      .select(
    'id, year, month, title, status',
  )
      .eq('company_id', companyId)
      .eq('status', 'approved');

  final fiscalPeriodMap =
  <String, Map<String, dynamic>>{};

  for (final row in fiscalPeriods) {
    final year = _toInt(row['year']);
    final month = _toInt(row['month']);

    fiscalPeriodMap['$year-$month'] = row;
  }

  // ============================================================
  // Bank accounts
  // ============================================================

  final bankAccounts = await supabase
      .from('bank_accounts')
      .select(
    'id, bank_name, account_number',
  )
      .eq('company_id', companyId);

  final bankNames = <String, String>{};

  for (final row in bankAccounts) {
    final id = row['id'].toString();

    final bankName =
        row['bank_name']?.toString() ??
            'بانک';

    final accountNumber =
        row['account_number']?.toString() ??
            '';

    String title = bankName;

    if (accountNumber.length >= 4) {
      title =
      '$bankName ****${accountNumber.substring(accountNumber.length - 4)}';
    }

    bankNames[id] = title;
  }

  // ============================================================
  // Bank account periods
  // ============================================================

  final bankPeriods = await supabase
      .from('bank_account_periods')
      .select(
    '''
        id,
        period_id,
        bank_account_id,
        debit_turnover,
        credit_turnover,
        closing_balance,
        ledger_balance,
        discrepancy
        ''',
  )
      .eq('company_id', companyId);

  // ============================================================
  // Bank balance series
  // ============================================================

  final bankBalanceMap =
  <String, List<double>>{};

  for (final bank in bankAccounts) {
    bankBalanceMap[
    bank['id'].toString()
    ] = List<double>.filled(
      months.length,
      0,
    );
  }

  // ============================================================
  // Turnover
  // ============================================================

  final debitValues =
  List<double>.filled(
    months.length,
    0,
  );

  final creditValues =
  List<double>.filled(
    months.length,
    0,
  );

  // ============================================================
  // Discrepancy
  // ============================================================

  final discrepancyValues =
  List<double>.filled(
    months.length,
    0,
  );

  // ============================================================
  // Process bank periods
  // ============================================================

  for (final row in bankPeriods) {
    final periodId =
    row['period_id']?.toString();

    if (periodId == null) continue;

    Map<String, dynamic>? period;

    for (final item in fiscalPeriods) {
      if (item['id'].toString() == periodId) {
        period = item;
        break;
      }
    }

    if (period == null) continue;

    final year =
    _toInt(period['year']);

    final month =
    _toInt(period['month']);

    final monthIndex =
    months.indexWhere(
          (item) =>
      item.year == year &&
          item.month == month,
    );

    if (monthIndex == -1) continue;

    final accountId =
    row['bank_account_id']?.toString();

    if (accountId != null &&
        bankBalanceMap.containsKey(
          accountId,
        )) {
      bankBalanceMap[accountId]![
      monthIndex
      ] = _toDouble(
        row['closing_balance'],
      );
    }

    debitValues[monthIndex] +=
        _toDouble(
          row['debit_turnover'],
        );

    creditValues[monthIndex] +=
        _toDouble(
          row['credit_turnover'],
        );

    discrepancyValues[monthIndex] +=
        _toDouble(
          row['discrepancy'],
        );
  }

  // ============================================================
  // Received checks
  // ============================================================

  final receivedChecks = await supabase
      .from('received_checks')
      .select(
    'id, amount, due_date, status',
  )
      .eq('company_id', companyId);

  // ============================================================
  // Paid checks
  // ============================================================

  final paidChecks = await supabase
      .from('paid_checks')
      .select(
    'id, amount, due_date, status',
  )
      .eq('company_id', companyId);

  final receivedCheckValues =
  List<double>.filled(
    months.length,
    0,
  );

  final paidCheckValues =
  List<double>.filled(
    months.length,
    0,
  );

  final receivedCheckCounts =
  List<int>.filled(
    months.length,
    0,
  );

  final paidCheckCounts =
  List<int>.filled(
    months.length,
    0,
  );

  // ============================================================
  // Received checks by due date
  // ============================================================

  for (final row in receivedChecks) {
    final status =
    row['status']?.toString();

    if (status == 'cancelled') {
      continue;
    }

    final dueDate =
    DateTime.tryParse(
      row['due_date']?.toString() ?? '',
    );

    if (dueDate == null) {
      continue;
    }

    final jalali =
    Jalali.fromDateTime(dueDate);

    final monthIndex =
    months.indexWhere(
          (item) =>
      item.year == jalali.year &&
          item.month == jalali.month,
    );

    if (monthIndex == -1) {
      continue;
    }

    receivedCheckValues[monthIndex] +=
        _toDouble(
          row['amount'],
        );

    receivedCheckCounts[monthIndex]++;
  }

  // ============================================================
  // Paid checks by due date
  // ============================================================

  for (final row in paidChecks) {
    final status =
    row['status']?.toString();

    if (status == 'cancelled') {
      continue;
    }

    final dueDate =
    DateTime.tryParse(
      row['due_date']?.toString() ?? '',
    );

    if (dueDate == null) {
      continue;
    }

    final jalali =
    Jalali.fromDateTime(dueDate);

    final monthIndex =
    months.indexWhere(
          (item) =>
      item.year == jalali.year &&
          item.month == jalali.month,
    );

    if (monthIndex == -1) {
      continue;
    }

    paidCheckValues[monthIndex] +=
        _toDouble(
          row['amount'],
        );

    paidCheckCounts[monthIndex]++;
  }

  // ============================================================
  // Current loan balance
  //
  // توجه:
  // برای نمودار تاریخی کافی نیست.
  // ============================================================

  final loans = await supabase
      .from('bank_loans')
      .select(
    'id, bank_name, loan_type, remaining_amount',
  )
      .eq('company_id', companyId);

  double currentLoanBalance = 0;

  for (final row in loans) {
    currentLoanBalance +=
        _toDouble(
          row['remaining_amount'],
        );
  }

  // ============================================================
  // Total liquidity from latest approved period
  // ============================================================

  double latestBankBalance = 0;
  double latestBankLedgerBalance = 0;
  double latestBankDiscrepancy = 0;

  final latestPeriodKey =
      '${months.last.year}-${months.last.month}';

  final latestPeriod =
  fiscalPeriodMap[latestPeriodKey];

  if (latestPeriod != null) {
    final latestPeriodId =
    latestPeriod['id'].toString();

    final latestBankPeriods =
    bankPeriods.where(
          (row) =>
      row['period_id']?.toString() ==
          latestPeriodId,
    );

    for (final row in latestBankPeriods) {
      latestBankBalance +=
          _toDouble(
            row['closing_balance'],
          );

      latestBankLedgerBalance +=
          _toDouble(
            row['ledger_balance'],
          );

      latestBankDiscrepancy +=
          _toDouble(
            row['discrepancy'],
          );
    }
  }

  // ============================================================
  // Cash
  // ============================================================

  double cashBalance = 0;
  int cashBoxCount = 0;

  if (latestPeriod != null) {
    final periodId =
    latestPeriod['id'].toString();

    final cashPeriods = await supabase
        .from('cash_box_periods')
        .select(
      '''
          cash_box_id,
          closing_balance,
          ledger_balance,
          discrepancy
          ''',
    )
        .eq('company_id', companyId)
        .eq('period_id', periodId);

    cashBoxCount =
        cashPeriods.length;

    for (final row in cashPeriods) {
      cashBalance +=
          _toDouble(
            row['closing_balance'],
          );
    }
  }

  // ============================================================
  // Petty cash
  // ============================================================

  double pettyCashBalance = 0;
  int pettyCashCount = 0;

  if (latestPeriod != null) {
    final periodId =
    latestPeriod['id'].toString();

    final pettyPeriods = await supabase
        .from('petty_cash_periods')
        .select(
      '''
          petty_cash_id,
          closing_balance,
          ledger_balance,
          discrepancy
          ''',
    )
        .eq('company_id', companyId)
        .eq('period_id', periodId);

    pettyCashCount =
        pettyPeriods.length;

    for (final row in pettyPeriods) {
      pettyCashBalance +=
          _toDouble(
            row['closing_balance'],
          );
    }
  }

  final totalLiquidity =
      latestBankBalance +
          cashBalance +
          pettyCashBalance;

  final totalDiscrepancy =
      latestBankDiscrepancy;

  // ============================================================
  // Return
  // ============================================================

  return CompanyAdminBankingData(
    companyId: companyId,

    currentYear: currentYear,
    currentMonth: currentMonth,

    months: months,

    bankBalanceSeries:
    bankBalanceMap.entries.map(
          (entry) {
        return BankBalanceSeries(
          bankName:
          bankNames[entry.key] ??
              'بانک',
          values: entry.value,
        );
      },
    ).toList(),

    debitValues: debitValues,
    creditValues: creditValues,

    discrepancyValues:
    discrepancyValues,

    receivedCheckValues:
    receivedCheckValues,

    paidCheckValues:
    paidCheckValues,

    receivedCheckCounts:
    receivedCheckCounts,

    paidCheckCounts:
    paidCheckCounts,

    currentLoanBalance:
    currentLoanBalance,

    hasLoanHistory: false,

    bankBalance:
    latestBankBalance,

    bankLedgerBalance:
    latestBankLedgerBalance,

    bankDiscrepancy:
    latestBankDiscrepancy,

    bankAccountCount:
    bankAccounts.length,

    cashBalance:
    cashBalance,

    cashBoxCount:
    cashBoxCount,

    pettyCashBalance:
    pettyCashBalance,

    pettyCashCount:
    pettyCashCount,

    totalLiquidity:
    totalLiquidity,

    totalDiscrepancy:
    totalDiscrepancy,
  );
});

// ============================================================
// DATA MODEL
// ============================================================

class CompanyAdminBankingData {
  final String companyId;

  final int currentYear;
  final int currentMonth;

  final List<BankingMonth> months;

  final List<BankBalanceSeries>
  bankBalanceSeries;

  final List<double> debitValues;
  final List<double> creditValues;

  final List<double> discrepancyValues;

  final List<double>
  receivedCheckValues;

  final List<double>
  paidCheckValues;

  final List<int>
  receivedCheckCounts;

  final List<int>
  paidCheckCounts;

  final double currentLoanBalance;

  final bool hasLoanHistory;

  final double bankBalance;
  final double bankLedgerBalance;
  final double bankDiscrepancy;

  final int bankAccountCount;

  final double cashBalance;
  final int cashBoxCount;

  final double pettyCashBalance;
  final int pettyCashCount;

  final double totalLiquidity;
  final double totalDiscrepancy;

  const CompanyAdminBankingData({
    required this.companyId,
    required this.currentYear,
    required this.currentMonth,
    required this.months,
    required this.bankBalanceSeries,
    required this.debitValues,
    required this.creditValues,
    required this.discrepancyValues,
    required this.receivedCheckValues,
    required this.paidCheckValues,
    required this.receivedCheckCounts,
    required this.paidCheckCounts,
    required this.currentLoanBalance,
    required this.hasLoanHistory,
    required this.bankBalance,
    required this.bankLedgerBalance,
    required this.bankDiscrepancy,
    required this.bankAccountCount,
    required this.cashBalance,
    required this.cashBoxCount,
    required this.pettyCashBalance,
    required this.pettyCashCount,
    required this.totalLiquidity,
    required this.totalDiscrepancy,
  });
}

class BankingMonth {
  final int year;
  final int month;
  final String title;

  const BankingMonth({
    required this.year,
    required this.month,
    required this.title,
  });
}

class BankBalanceSeries {
  final String bankName;
  final List<double> values;

  const BankBalanceSeries({
    required this.bankName,
    required this.values,
  });
}

// ============================================================
// HELPERS
// ============================================================

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value.toString(),
  ) ??
      0;
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(
    value?.toString() ?? '',
  ) ??
      0;
}

String _jalaliMonthName(int month) {
  const months = [
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
    return '';
  }

  return months[month - 1];
}