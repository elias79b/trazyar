import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final companyAdminDashboardProvider =
FutureProvider.autoDispose<CompanyAdminDashboardData>((ref) async {
  final client = Supabase.instance.client;

  // ============================================================
  // AUTH USER
  // ============================================================

  final authUser = client.auth.currentUser;

  if (authUser == null) {
    throw Exception('کاربر وارد نشده است.');
  }

  debugPrint('========== TARAZYAR AUTH DEBUG ==========');
  debugPrint('AUTH USER ID: ${authUser.id}');
  debugPrint('AUTH USER EMAIL: ${authUser.email}');
  debugPrint('=========================================');

  // ============================================================
  // USER PROFILE
  // ============================================================

  final user = await client
      .from('users')
      .select(
    'id, full_name, email, role, is_active, avatar_url',
  )
      .eq('id', authUser.id)
      .maybeSingle();

  debugPrint('========== TARAZYAR USER DEBUG ==========');
  debugPrint('USER: $user');
  debugPrint('=========================================');

  if (user == null) {
    throw Exception(
      'اطلاعات کاربر در سیستم پیدا نشد.',
    );
  }

  final String role = user['role']?.toString() ?? '';

  final bool userIsActive =
      user['is_active'] == true;

  if (role != 'company_admin') {
    throw Exception(
      'کاربر فعلی مدیرعامل شرکت نیست. role=$role',
    );
  }

  if (!userIsActive) {
    throw Exception(
      'حساب کاربری شما غیرفعال است.',
    );
  }

  // ============================================================
  // COMPANY MEMBERSHIP
  // ============================================================

  final membership = await client
      .from('company_users')
      .select(
    'id, company_id, user_id, role, is_active',
  )
      .eq('user_id', authUser.id)
      .eq('role', 'company_admin')
      .eq('is_active', true)
      .maybeSingle();

  debugPrint(
    '========== TARAZYAR MEMBERSHIP DEBUG ==========',
  );
  debugPrint('MEMBERSHIP: $membership');
  debugPrint('===============================================');

  if (membership == null) {
    throw Exception(
      'هیچ شرکتی برای مدیرعامل تخصیص داده نشده است. '
          'authUserId=${authUser.id}',
    );
  }

  final String companyId =
  membership['company_id'].toString();

  debugPrint(
    'TARAZYAR COMPANY ID FROM MEMBERSHIP: $companyId',
  );

  // ============================================================
  // COMPANY
  // ============================================================

  final company = await client
      .from('companies')
      .select(
    '''
        id,
        name,
        legal_name,
        national_id,
        phone,
        email,
        website,
        address,
        city,
        province,
        postal_code,
        logo_url,
        is_active
        ''',
  )
      .eq('id', companyId)
      .maybeSingle();

  debugPrint(
    '========== TARAZYAR COMPANY DEBUG ==========',
  );
  debugPrint('COMPANY ID: $companyId');
  debugPrint('COMPANY: $company');
  debugPrint('============================================');

  if (company == null) {
    throw Exception(
      'اطلاعات شرکت پیدا نشد. companyId=$companyId',
    );
  }

  final bool companyIsActive =
      company['is_active'] == true;

  if (!companyIsActive) {
    throw Exception(
      'شرکت غیرفعال است. companyId=$companyId',
    );
  }

  // ============================================================
  // CURRENT JALALI PERIOD
  // ============================================================

  final Jalali now =
  Jalali.fromDateTime(DateTime.now());

  final int year = now.year;
  final int month = now.month;

  final String monthTitle =
  _monthTitle(month);

  debugPrint(
    '========== TARAZYAR PERIOD DEBUG =========',
  );
  debugPrint('YEAR: $year');
  debugPrint('MONTH: $month');
  debugPrint('MONTH TITLE: $monthTitle');
  debugPrint('==========================================');

  // ============================================================
  // FISCAL PERIODS
  // ============================================================

  final incomePeriod = await _loadPeriod(
    client: client,
    table: 'income_fiscal_periods',
    companyId: companyId,
    year: year,
    month: month,
  );

  final expensePeriod = await _loadPeriod(
    client: client,
    table: 'expense_fiscal_periods',
    companyId: companyId,
    year: year,
    month: month,
  );

  final cashPeriod = await _loadPeriod(
    client: client,
    table: 'cash_fiscal_periods',
    companyId: companyId,
    year: year,
    month: month,
  );

  debugPrint(
    '========== TARAZYAR PERIOD RESULT =========',
  );
  debugPrint('INCOME PERIOD: $incomePeriod');
  debugPrint('EXPENSE PERIOD: $expensePeriod');
  debugPrint('CASH PERIOD: $cashPeriod');
  debugPrint('===========================================');

  // ============================================================
  // INCOME
  // ============================================================

  double monthlyIncome = 0;

  if (incomePeriod != null) {
    monthlyIncome = await _sumAmount(
      client: client,
      table: 'income_recognitions',
      companyId: companyId,
      periodId: incomePeriod['id'].toString(),
    );
  }

  // ============================================================
  // EXPENSE
  // ============================================================

  double monthlyExpense = 0;

  if (expensePeriod != null) {
    monthlyExpense = await _sumAmount(
      client: client,
      table: 'expense_recognitions',
      companyId: companyId,
      periodId: expensePeriod['id'].toString(),
    );
  }

  // ============================================================
  // BANK BALANCE
  // ============================================================

  double bankBalance = 0;

  if (cashPeriod != null) {
    bankBalance = await _sumColumn(
      client: client,
      table: 'bank_account_periods',
      companyId: companyId,
      periodId: cashPeriod['id'].toString(),
      column: 'closing_balance',
    );
  }

  // ============================================================
  // CASH BOX BALANCE
  // ============================================================

  double cashBalance = 0;

  if (cashPeriod != null) {
    cashBalance = await _sumColumn(
      client: client,
      table: 'cash_box_periods',
      companyId: companyId,
      periodId: cashPeriod['id'].toString(),
      column: 'closing_balance',
    );
  }

  // ============================================================
  // PETTY CASH BALANCE
  // ============================================================

  double pettyCashBalance = 0;

  if (cashPeriod != null) {
    pettyCashBalance = await _sumColumn(
      client: client,
      table: 'petty_cash_periods',
      companyId: companyId,
      periodId: cashPeriod['id'].toString(),
      column: 'closing_balance',
    );
  }

  // ============================================================
  // PAYABLES
  // ============================================================

  double pendingPayables = 0;
  double paidPayables = 0;
  double cancelledPayables = 0;

  try {
    final payables = await client
        .from('payables')
        .select('amount, status')
        .eq('company_id', companyId);

    for (final row in payables) {
      final double amount =
      _toDouble(row['amount']);

      final String status =
          row['status']?.toString() ?? '';

      switch (status) {
        case 'pending':
          pendingPayables += amount;
          break;

        case 'paid':
          paidPayables += amount;
          break;

        case 'cancelled':
          cancelledPayables += amount;
          break;

        default:
          break;
      }
    }
  } catch (e) {
    debugPrint(
      '========== PAYABLES ERROR ==========',
    );
    debugPrint('$e');
    debugPrint('====================================');
  }

  // ============================================================
  // RECEIVABLES
  // ============================================================

  double receivables = 0;

  try {
    final rows = await client
        .from('income_receivables')
        .select(
      'amount, received_documents_amount',
    )
        .eq('company_id', companyId);

    for (final row in rows) {
      final double amount =
      _toDouble(row['amount']);

      final double received =
      _toDouble(
        row['received_documents_amount'],
      );

      final double remaining =
          amount - received;

      if (remaining > 0) {
        receivables += remaining;
      }
    }
  } catch (e) {
    debugPrint(
      '========== RECEIVABLES ERROR ==========',
    );
    debugPrint('$e');
    debugPrint('=======================================');

    receivables = 0;
  }

  // ============================================================
  // CALCULATIONS
  // ============================================================

  final double monthlyProfit =
      monthlyIncome - monthlyExpense;

  final double totalLiquidity =
      bankBalance +
          cashBalance +
          pettyCashBalance;

  debugPrint(
    '========== TARAZYAR DASHBOARD RESULT =========',
  );
  debugPrint('MONTHLY INCOME: $monthlyIncome');
  debugPrint('MONTHLY EXPENSE: $monthlyExpense');
  debugPrint('MONTHLY PROFIT: $monthlyProfit');
  debugPrint('BANK BALANCE: $bankBalance');
  debugPrint('CASH BALANCE: $cashBalance');
  debugPrint('PETTY CASH: $pettyCashBalance');
  debugPrint('TOTAL LIQUIDITY: $totalLiquidity');
  debugPrint('PAYABLES PENDING: $pendingPayables');
  debugPrint('PAYABLES PAID: $paidPayables');
  debugPrint('PAYABLES CANCELLED: $cancelledPayables');
  debugPrint('RECEIVABLES: $receivables');
  debugPrint('==============================================');

  // ============================================================
  // RETURN DATA
  // ============================================================

  return CompanyAdminDashboardData(
    userId:
    user['id']?.toString() ??
        authUser.id,

    userName:
    user['full_name']?.toString() ??
        authUser.email ??
        'مدیرعامل',

    userEmail:
    user['email']?.toString() ??
        authUser.email ??
        '',

    avatarUrl:
    user['avatar_url']?.toString(),

    companyId: companyId,

    companyName:
    company['name']?.toString() ?? '',

    companyLegalName:
    company['legal_name']?.toString(),

    companyNationalId:
    company['national_id']?.toString(),

    companyPhone:
    company['phone']?.toString(),

    companyEmail:
    company['email']?.toString(),

    companyWebsite:
    company['website']?.toString(),

    companyAddress:
    company['address']?.toString(),

    companyCity:
    company['city']?.toString(),

    companyProvince:
    company['province']?.toString(),

    companyPostalCode:
    company['postal_code']?.toString(),

    companyLogoUrl:
    company['logo_url']?.toString(),

    currentYear: year,
    currentMonth: month,
    currentMonthTitle: monthTitle,

    monthlyIncome: monthlyIncome,
    monthlyExpense: monthlyExpense,
    monthlyProfit: monthlyProfit,

    bankBalance: bankBalance,
    cashBalance: cashBalance,
    pettyCashBalance: pettyCashBalance,
    totalLiquidity: totalLiquidity,

    pendingPayables: pendingPayables,
    paidPayables: paidPayables,
    cancelledPayables: cancelledPayables,

    receivables: receivables,

    incomePeriodStatus:
    incomePeriod?['status']?.toString(),

    expensePeriodStatus:
    expensePeriod?['status']?.toString(),

    cashPeriodStatus:
    cashPeriod?['status']?.toString(),

    hasIncomePeriod:
    incomePeriod != null,

    hasExpensePeriod:
    expensePeriod != null,

    hasCashPeriod:
    cashPeriod != null,
  );
});

// ============================================================
// LOAD FISCAL PERIOD
// ============================================================

Future<Map<String, dynamic>?> _loadPeriod({
  required SupabaseClient client,
  required String table,
  required String companyId,
  required int year,
  required int month,
}) async {
  try {
    final result = await client
        .from(table)
        .select(
      'id, company_id, year, month, title, status',
    )
        .eq('company_id', companyId)
        .eq('year', year)
        .eq('month', month)
        .maybeSingle();

    return result;
  } catch (e) {
    debugPrint(
      'LOAD PERIOD ERROR [$table]: $e',
    );

    return null;
  }
}

// ============================================================
// SUM AMOUNT
// ============================================================

Future<double> _sumAmount({
  required SupabaseClient client,
  required String table,
  required String companyId,
  required String periodId,
}) async {
  try {
    final rows = await client
        .from(table)
        .select('amount')
        .eq('company_id', companyId)
        .eq('period_id', periodId);

    double total = 0;

    for (final row in rows) {
      total += _toDouble(row['amount']);
    }

    return total;
  } catch (e) {
    debugPrint(
      'SUM AMOUNT ERROR [$table]: $e',
    );

    return 0;
  }
}

// ============================================================
// SUM COLUMN
// ============================================================

Future<double> _sumColumn({
  required SupabaseClient client,
  required String table,
  required String companyId,
  required String periodId,
  required String column,
}) async {
  try {
    final rows = await client
        .from(table)
        .select(column)
        .eq('company_id', companyId)
        .eq('period_id', periodId);

    double total = 0;

    for (final row in rows) {
      total += _toDouble(row[column]);
    }

    return total;
  } catch (e) {
    debugPrint(
      'SUM COLUMN ERROR [$table.$column]: $e',
    );

    return 0;
  }
}

// ============================================================
// SAFE DOUBLE PARSER
// ============================================================

double _toDouble(dynamic value) {
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

// ============================================================
// JALALI MONTH TITLE
// ============================================================

String _monthTitle(int month) {
  switch (month) {
    case 1:
      return 'فروردین';

    case 2:
      return 'اردیبهشت';

    case 3:
      return 'خرداد';

    case 4:
      return 'تیر';

    case 5:
      return 'مرداد';

    case 6:
      return 'شهریور';

    case 7:
      return 'مهر';

    case 8:
      return 'آبان';

    case 9:
      return 'آذر';

    case 10:
      return 'دی';

    case 11:
      return 'بهمن';

    case 12:
      return 'اسفند';

    default:
      return '';
  }
}

// ============================================================
// DASHBOARD DATA MODEL
// ============================================================

class CompanyAdminDashboardData {
  final String userId;
  final String userName;
  final String userEmail;
  final String? avatarUrl;

  final String companyId;
  final String companyName;
  final String? companyLegalName;
  final String? companyNationalId;
  final String? companyPhone;
  final String? companyEmail;
  final String? companyWebsite;
  final String? companyAddress;
  final String? companyCity;
  final String? companyProvince;
  final String? companyPostalCode;
  final String? companyLogoUrl;

  final int currentYear;
  final int currentMonth;
  final String currentMonthTitle;

  final double monthlyIncome;
  final double monthlyExpense;
  final double monthlyProfit;

  final double bankBalance;
  final double cashBalance;
  final double pettyCashBalance;
  final double totalLiquidity;

  final double pendingPayables;
  final double paidPayables;
  final double cancelledPayables;

  final double receivables;

  final String? incomePeriodStatus;
  final String? expensePeriodStatus;
  final String? cashPeriodStatus;

  final bool hasIncomePeriod;
  final bool hasExpensePeriod;
  final bool hasCashPeriod;

  const CompanyAdminDashboardData({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.avatarUrl,

    required this.companyId,
    required this.companyName,
    required this.companyLegalName,
    required this.companyNationalId,
    required this.companyPhone,
    required this.companyEmail,
    required this.companyWebsite,
    required this.companyAddress,
    required this.companyCity,
    required this.companyProvince,
    required this.companyPostalCode,
    required this.companyLogoUrl,

    required this.currentYear,
    required this.currentMonth,
    required this.currentMonthTitle,

    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlyProfit,

    required this.bankBalance,
    required this.cashBalance,
    required this.pettyCashBalance,
    required this.totalLiquidity,

    required this.pendingPayables,
    required this.paidPayables,
    required this.cancelledPayables,

    required this.receivables,

    required this.incomePeriodStatus,
    required this.expensePeriodStatus,
    required this.cashPeriodStatus,

    required this.hasIncomePeriod,
    required this.hasExpensePeriod,
    required this.hasCashPeriod,
  });
}