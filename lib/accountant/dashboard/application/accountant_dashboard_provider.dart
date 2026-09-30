import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantDashboardProvider =
FutureProvider.autoDispose<AccountantDashboardData>((ref) async {
  final client = Supabase.instance.client;

  final user = client.auth.currentUser;

  if (user == null) {
    throw Exception('کاربر وارد سیستم نشده است.');
  }

  // ============================================================
  // USER
  // ============================================================

  final userData = await client
      .from('users')
      .select('id, full_name, email, role, is_active')
      .eq('id', user.id)
      .maybeSingle();

  if (userData == null) {
    throw Exception('اطلاعات حسابدار پیدا نشد.');
  }

  final role = userData['role']?.toString();

  if (role != 'accountant') {
    throw Exception('این حساب کاربری حسابدار نیست.');
  }

  if (userData['is_active'] != true) {
    throw Exception('حساب کاربری شما غیرفعال است.');
  }

  // ============================================================
  // COMPANY ASSIGNMENT
  // ============================================================

  final assignment = await client
      .from('company_users')
      .select('''
        id,
        company_id,
        user_id,
        role,
        is_active,
        companies (
          id,
          name,
          legal_name,
          national_id,
          phone,
          email,
          city,
          province,
          logo_url,
          is_active
        )
      ''')
      .eq('user_id', user.id)
      .eq('role', 'accountant')
      .eq('is_active', true)
      .limit(1)
      .maybeSingle();

  if (assignment == null) {
    throw Exception(
      'هیچ شرکتی برای حسابدار تخصیص داده نشده است.',
    );
  }

  final companyData = assignment['companies'];

  if (companyData == null) {
    throw Exception(
      'اطلاعات شرکت حسابدار پیدا نشد.',
    );
  }

  final company = Map<String, dynamic>.from(
    companyData as Map,
  );

  if (company['is_active'] != true) {
    throw Exception(
      'شرکت تخصیص‌یافته غیرفعال است.',
    );
  }

  final companyId =
      assignment['company_id']?.toString() ?? '';

  if (companyId.isEmpty) {
    throw Exception(
      'شناسه شرکت حسابدار معتبر نیست.',
    );
  }

  // ============================================================
  // CURRENT JALALI MONTH
  // ============================================================

  final now = Jalali.now();

  final currentYear = now.year;
  final currentMonth = now.month;

  // ============================================================
  // CURRENT / LATEST PERIODS
  // ============================================================

  final incomePeriod = await _loadPeriod(
    client: client,
    table: 'income_fiscal_periods',
    companyId: companyId,
    year: currentYear,
    month: currentMonth,
  );

  final expensePeriod = await _loadPeriod(
    client: client,
    table: 'expense_fiscal_periods',
    companyId: companyId,
    year: currentYear,
    month: currentMonth,
  );

  final cashPeriod = await _loadPeriod(
    client: client,
    table: 'cash_fiscal_periods',
    companyId: companyId,
    year: currentYear,
    month: currentMonth,
  );

  // ============================================================
  // INCOME
  // ============================================================

  double monthlyIncome = 0;

  if (incomePeriod != null) {
    final incomeRows = await client
        .from('income_recognitions')
        .select('amount')
        .eq(
      'company_id',
      companyId,
    )
        .eq(
      'fiscal_period_id',
      incomePeriod['id'],
    );

    monthlyIncome = _sumAmount(
      incomeRows,
      'amount',
    );
  }

  // ============================================================
  // EXPENSE
  // ============================================================

  double monthlyExpense = 0;

  if (expensePeriod != null) {
    final expenseRows = await client
        .from('expense_recognitions')
        .select('amount')
        .eq(
      'company_id',
      companyId,
    )
        .eq(
      'fiscal_period_id',
      expensePeriod['id'],
    );

    monthlyExpense = _sumAmount(
      expenseRows,
      'amount',
    );
  }

  // ============================================================
  // CASH + BANK
  // ============================================================

  double bankBalance = 0;
  double cashBoxBalance = 0;
  double pettyCashBalance = 0;

  if (cashPeriod != null) {
    final periodId =
    cashPeriod['id']?.toString();

    if (periodId != null && periodId.isNotEmpty) {
      final bankRows = await client
          .from('bank_account_periods')
          .select('closing_balance')
          .eq(
        'company_id',
        companyId,
      )
          .eq(
        'period_id',
        periodId,
      );

      bankBalance = _sumAmount(
        bankRows,
        'closing_balance',
      );

      final cashRows = await client
          .from('cash_box_periods')
          .select('closing_balance')
          .eq(
        'company_id',
        companyId,
      )
          .eq(
        'period_id',
        periodId,
      );

      cashBoxBalance = _sumAmount(
        cashRows,
        'closing_balance',
      );

      final pettyRows = await client
          .from('petty_cash_periods')
          .select('closing_balance')
          .eq(
        'company_id',
        companyId,
      )
          .eq(
        'period_id',
        periodId,
      );

      pettyCashBalance = _sumAmount(
        pettyRows,
        'closing_balance',
      );
    }
  }

  final totalCashAndBank =
      bankBalance +
          cashBoxBalance +
          pettyCashBalance;

  // ============================================================
  // PAYABLES
  // ============================================================

  double pendingPayables = 0;

  final payableRows = await client
      .from('payables')
      .select('amount, status')
      .eq(
    'company_id',
    companyId,
  )
      .eq(
    'status',
    'pending',
  );

  pendingPayables = _sumAmount(
    payableRows,
    'amount',
  );

  // ============================================================
  // PROFIT / LOSS
  // ============================================================

  final profitLoss =
      monthlyIncome -
          monthlyExpense;

  // ============================================================
  // RETURN
  // ============================================================

  return AccountantDashboardData(
    userId: user.id,
    fullName:
    userData['full_name']?.toString() ?? '',
    email:
    userData['email']?.toString() ??
        user.email ??
        '',
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
    companyCity:
    company['city']?.toString(),
    companyProvince:
    company['province']?.toString(),
    companyLogoUrl:
    company['logo_url']?.toString(),
    currentYear: currentYear,
    currentMonth: currentMonth,
    currentMonthTitle:
    _monthTitle(currentMonth),
    monthlyIncome: monthlyIncome,
    monthlyExpense: monthlyExpense,
    profitLoss: profitLoss,
    bankBalance: bankBalance,
    cashBoxBalance: cashBoxBalance,
    pettyCashBalance: pettyCashBalance,
    totalCashAndBank: totalCashAndBank,
    pendingPayables: pendingPayables,
    hasIncomePeriod: incomePeriod != null,
    hasExpensePeriod: expensePeriod != null,
    hasCashPeriod: cashPeriod != null,
  );
});

// ============================================================
// PERIOD LOADER
// ============================================================

Future<Map<String, dynamic>?> _loadPeriod({
  required SupabaseClient client,
  required String table,
  required String companyId,
  required int year,
  required int month,
}) async {
  final current = await client
      .from(table)
      .select(
    'id, company_id, year, month, title, status',
  )
      .eq(
    'company_id',
    companyId,
  )
      .eq(
    'year',
    year,
  )
      .eq(
    'month',
    month,
  )
      .limit(1);

  if (current.isNotEmpty) {
    return Map<String, dynamic>.from(
      current.first,
    );
  }

  // اگر ماه جاری هنوز ساخته نشده باشد،
  // آخرین دوره ثبت‌شده استفاده می‌شود.
  final latest = await client
      .from(table)
      .select(
    'id, company_id, year, month, title, status',
  )
      .eq(
    'company_id',
    companyId,
  )
      .order(
    'year',
    ascending: false,
  )
      .order(
    'month',
    ascending: false,
  )
      .limit(1);

  if (latest.isEmpty) {
    return null;
  }

  return Map<String, dynamic>.from(
    latest.first,
  );
}

// ============================================================
// SUM
// ============================================================

double _sumAmount(
    dynamic rows,
    String field,
    ) {
  if (rows is! List) {
    return 0;
  }

  double total = 0;

  for (final row in rows) {
    if (row is! Map) {
      continue;
    }

    final value = row[field];

    if (value is num) {
      total += value.toDouble();
    } else {
      total +=
          double.tryParse(
            value?.toString() ?? '',
          ) ??
              0;
    }
  }

  return total;
}

// ============================================================
// MODEL
// ============================================================

class AccountantDashboardData {
  final String userId;
  final String fullName;
  final String email;

  final String companyId;
  final String companyName;

  final String? companyLegalName;
  final String? companyNationalId;
  final String? companyPhone;
  final String? companyEmail;
  final String? companyCity;
  final String? companyProvince;
  final String? companyLogoUrl;

  final int currentYear;
  final int currentMonth;
  final String currentMonthTitle;

  final double monthlyIncome;
  final double monthlyExpense;
  final double profitLoss;

  final double bankBalance;
  final double cashBoxBalance;
  final double pettyCashBalance;
  final double totalCashAndBank;

  final double pendingPayables;

  final bool hasIncomePeriod;
  final bool hasExpensePeriod;
  final bool hasCashPeriod;

  const AccountantDashboardData({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.companyId,
    required this.companyName,
    this.companyLegalName,
    this.companyNationalId,
    this.companyPhone,
    this.companyEmail,
    this.companyCity,
    this.companyProvince,
    this.companyLogoUrl,
    required this.currentYear,
    required this.currentMonth,
    required this.currentMonthTitle,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.profitLoss,
    required this.bankBalance,
    required this.cashBoxBalance,
    required this.pettyCashBalance,
    required this.totalCashAndBank,
    required this.pendingPayables,
    required this.hasIncomePeriod,
    required this.hasExpensePeriod,
    required this.hasCashPeriod,
  });
}

// ============================================================
// PERSIAN MONTH
// ============================================================

String _monthTitle(int month) {
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
    return 'ماه';
  }

  return months[month - 1];
}