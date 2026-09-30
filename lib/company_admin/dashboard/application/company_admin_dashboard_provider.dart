import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final companyAdminDashboardProvider =
FutureProvider.autoDispose<CompanyAdminDashboardData>((ref) async {
  final SupabaseClient client = Supabase.instance.client;

  final user = client.auth.currentUser;

  if (user == null) {
    throw Exception('کاربر وارد سیستم نشده است.');
  }

  // ============================================================
  // USER
  // ============================================================

  final Map<String, dynamic>? userData = await client
      .from('users')
      .select('id, full_name, email, role, is_active')
      .eq('id', user.id)
      .maybeSingle();

  if (userData == null) {
    throw Exception('اطلاعات کاربر در جدول users پیدا نشد.');
  }

  final String role = userData['role']?.toString() ?? '';

  if (role != 'company_admin') {
    throw Exception('این حساب کاربری مدیرعامل نیست.');
  }

  if (userData['is_active'] != true) {
    throw Exception('حساب کاربری شما غیرفعال است.');
  }

  // ============================================================
  // COMPANY
  // ============================================================

  final Map<String, dynamic>? companyUser = await client
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
          economic_code,
          phone,
          email,
          website,
          address,
          city,
          province,
          postal_code,
          logo_url,
          owner_user_id,
          owner_id,
          is_active
        )
      ''')
      .eq('user_id', user.id)
      .eq('role', 'company_admin')
      .eq('is_active', true)
      .limit(1)
      .maybeSingle();

  if (companyUser == null) {
    throw Exception('هیچ شرکتی برای مدیرعامل تخصیص داده نشده است.');
  }

  final dynamic rawCompany = companyUser['companies'];

  if (rawCompany == null) {
    throw Exception('اطلاعات شرکت پیدا نشد.');
  }

  final Map<String, dynamic> company =
  Map<String, dynamic>.from(rawCompany as Map);

  if (company['is_active'] != true) {
    throw Exception('شرکت تخصیص‌یافته غیرفعال است.');
  }

  final String companyId =
      companyUser['company_id']?.toString() ?? '';

  if (companyId.isEmpty) {
    throw Exception('شناسه شرکت معتبر نیست.');
  }

  // ============================================================
  // CURRENT JALALI DATE
  // ============================================================

  final Jalali now = Jalali.now();

  final int currentYear = now.year;
  final int currentMonth = now.month;

  // ============================================================
  // PERIODS
  // ============================================================

  final Map<String, dynamic>? incomePeriod = await _loadPeriod(
    client: client,
    table: 'income_fiscal_periods',
    companyId: companyId,
    year: currentYear,
    month: currentMonth,
  );

  final Map<String, dynamic>? expensePeriod = await _loadPeriod(
    client: client,
    table: 'expense_fiscal_periods',
    companyId: companyId,
    year: currentYear,
    month: currentMonth,
  );

  final Map<String, dynamic>? cashPeriod = await _loadPeriod(
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
    final dynamic incomeRows = await client
        .from('income_recognitions')
        .select('amount')
        .eq('company_id', companyId)
        .eq('fiscal_period_id', incomePeriod['id']);

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
    final dynamic expenseRows = await client
        .from('expense_recognitions')
        .select('amount')
        .eq('company_id', companyId)
        .eq('fiscal_period_id', expensePeriod['id']);

    monthlyExpense = _sumAmount(
      expenseRows,
      'amount',
    );
  }

  // ============================================================
  // BANK
  // ============================================================

  double bankBalance = 0;

  if (cashPeriod != null) {
    final String periodId =
        cashPeriod['id']?.toString() ?? '';

    if (periodId.isNotEmpty) {
      final dynamic bankRows = await client
          .from('bank_account_periods')
          .select('closing_balance')
          .eq('company_id', companyId)
          .eq('period_id', periodId);

      bankBalance = _sumAmount(
        bankRows,
        'closing_balance',
      );
    }
  }

  // ============================================================
  // CASH BOX
  // ============================================================

  double cashBoxBalance = 0;

  if (cashPeriod != null) {
    final String periodId =
        cashPeriod['id']?.toString() ?? '';

    if (periodId.isNotEmpty) {
      final dynamic cashRows = await client
          .from('cash_box_periods')
          .select('closing_balance')
          .eq('company_id', companyId)
          .eq('period_id', periodId);

      cashBoxBalance = _sumAmount(
        cashRows,
        'closing_balance',
      );
    }
  }

  // ============================================================
  // PETTY CASH
  // ============================================================

  double pettyCashBalance = 0;

  if (cashPeriod != null) {
    final String periodId =
        cashPeriod['id']?.toString() ?? '';

    if (periodId.isNotEmpty) {
      final dynamic pettyRows = await client
          .from('petty_cash_periods')
          .select('closing_balance')
          .eq('company_id', companyId)
          .eq('period_id', periodId);

      pettyCashBalance = _sumAmount(
        pettyRows,
        'closing_balance',
      );
    }
  }

  final double totalLiquidity =
      bankBalance +
          cashBoxBalance +
          pettyCashBalance;

  // ============================================================
  // PAYABLES
  // ============================================================

  double pendingPayables = 0;
  double paidPayables = 0;
  double cancelledPayables = 0;

  final dynamic payableRows = await client
      .from('payables')
      .select('amount, status')
      .eq('company_id', companyId);

  if (payableRows is List) {
    for (final dynamic item in payableRows) {
      if (item is! Map) {
        continue;
      }

      final double amount = _toDouble(item['amount']);
      final String status =
          item['status']?.toString() ?? '';

      if (status == 'pending') {
        pendingPayables += amount;
      } else if (status == 'paid') {
        paidPayables += amount;
      } else if (status == 'cancelled') {
        cancelledPayables += amount;
      }
    }
  }

  // ============================================================
  // RECEIVABLES
  // ============================================================

  double totalReceivables = 0;

  final dynamic receivableRows = await client
      .from('income_receivables')
      .select(
    'amount, received_documents_amount',
  )
      .eq('company_id', companyId);

  if (receivableRows is List) {
    for (final dynamic item in receivableRows) {
      if (item is! Map) {
        continue;
      }

      final double amount =
      _toDouble(item['amount']);

      final double received =
      _toDouble(item['received_documents_amount']);

      final double remaining =
          amount - received;

      if (remaining > 0) {
        totalReceivables += remaining;
      }
    }
  }

  // ============================================================
  // PROFIT / LOSS
  // ============================================================

  final double monthlyProfitLoss =
      monthlyIncome - monthlyExpense;

  // ============================================================
  // PERIOD STATUS
  // ============================================================

  final String? incomePeriodStatus =
  incomePeriod?['status']?.toString();

  final String? expensePeriodStatus =
  expensePeriod?['status']?.toString();

  final String? cashPeriodStatus =
  cashPeriod?['status']?.toString();

  // ============================================================
  // RETURN
  // ============================================================

  return CompanyAdminDashboardData(
    userId: user.id,
    fullName: userData['full_name']?.toString() ?? '',
    email: userData['email']?.toString() ??
        user.email ??
        '',
    companyId: companyId,
    companyName: company['name']?.toString() ?? '',
    companyLegalName: company['legal_name']?.toString(),
    companyNationalId: company['national_id']?.toString(),
    companyEconomicCode:
    company['economic_code']?.toString(),
    companyPhone: company['phone']?.toString(),
    companyEmail: company['email']?.toString(),
    companyWebsite: company['website']?.toString(),
    companyAddress: company['address']?.toString(),
    companyCity: company['city']?.toString(),
    companyProvince: company['province']?.toString(),
    companyPostalCode:
    company['postal_code']?.toString(),
    companyLogoUrl:
    company['logo_url']?.toString(),
    currentYear: currentYear,
    currentMonth: currentMonth,
    currentMonthTitle: _monthTitle(currentMonth),
    monthlyIncome: monthlyIncome,
    monthlyExpense: monthlyExpense,
    monthlyProfitLoss: monthlyProfitLoss,
    bankBalance: bankBalance,
    cashBoxBalance: cashBoxBalance,
    pettyCashBalance: pettyCashBalance,
    totalLiquidity: totalLiquidity,
    pendingPayables: pendingPayables,
    paidPayables: paidPayables,
    cancelledPayables: cancelledPayables,
    totalReceivables: totalReceivables,
    incomePeriodStatus: incomePeriodStatus,
    expensePeriodStatus: expensePeriodStatus,
    cashPeriodStatus: cashPeriodStatus,
    hasIncomePeriod: incomePeriod != null,
    hasExpensePeriod: expensePeriod != null,
    hasCashPeriod: cashPeriod != null,
  );
});

// ============================================================
// LOAD PERIOD
// ============================================================

Future<Map<String, dynamic>?> _loadPeriod({
  required SupabaseClient client,
  required String table,
  required String companyId,
  required int year,
  required int month,
}) async {
  final dynamic rows = await client
      .from(table)
      .select(
    'id, company_id, year, month, title, status',
  )
      .eq('company_id', companyId)
      .eq('year', year)
      .eq('month', month)
      .limit(1);

  if (rows is List && rows.isNotEmpty) {
    final dynamic first = rows.first;

    if (first is Map) {
      return Map<String, dynamic>.from(first);
    }
  }

  return null;
}

// ============================================================
// SUM AMOUNT
// ============================================================

double _sumAmount(
    dynamic rows,
    String field,
    ) {
  if (rows is! List) {
    return 0;
  }

  double total = 0;

  for (final dynamic row in rows) {
    if (row is! Map) {
      continue;
    }

    total += _toDouble(row[field]);
  }

  return total;
}

// ============================================================
// TO DOUBLE
// ============================================================

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  final String text = value.toString().trim();

  if (text.isEmpty) {
    return 0;
  }

  return double.tryParse(text) ?? 0;
}

// ============================================================
// MONTH TITLE
// ============================================================

String _monthTitle(int month) {
  const List<String> months = <String>[
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

// ============================================================
// MODEL
// ============================================================

class CompanyAdminDashboardData {
  final String userId;
  final String fullName;
  final String email;

  final String companyId;
  final String companyName;

  final String? companyLegalName;
  final String? companyNationalId;
  final String? companyEconomicCode;
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
  final double monthlyProfitLoss;

  final double bankBalance;
  final double cashBoxBalance;
  final double pettyCashBalance;
  final double totalLiquidity;

  final double pendingPayables;
  final double paidPayables;
  final double cancelledPayables;

  final double totalReceivables;

  final String? incomePeriodStatus;
  final String? expensePeriodStatus;
  final String? cashPeriodStatus;

  final bool hasIncomePeriod;
  final bool hasExpensePeriod;
  final bool hasCashPeriod;

  const CompanyAdminDashboardData({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.companyId,
    required this.companyName,
    this.companyLegalName,
    this.companyNationalId,
    this.companyEconomicCode,
    this.companyPhone,
    this.companyEmail,
    this.companyWebsite,
    this.companyAddress,
    this.companyCity,
    this.companyProvince,
    this.companyPostalCode,
    this.companyLogoUrl,
    required this.currentYear,
    required this.currentMonth,
    required this.currentMonthTitle,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlyProfitLoss,
    required this.bankBalance,
    required this.cashBoxBalance,
    required this.pettyCashBalance,
    required this.totalLiquidity,
    required this.pendingPayables,
    required this.paidPayables,
    required this.cancelledPayables,
    required this.totalReceivables,
    this.incomePeriodStatus,
    this.expensePeriodStatus,
    this.cashPeriodStatus,
    required this.hasIncomePeriod,
    required this.hasExpensePeriod,
    required this.hasCashPeriod,
  });
}