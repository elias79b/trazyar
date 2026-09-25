import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final expenseDashboardProvider =
FutureProvider.family<ExpenseDashboardData, String>(
      (ref, companyId) async {
    final client = Supabase.instance.client;

    final currentJalali = JalaliDate.now();
    final currentYear = currentJalali.year;
    final currentMonth = currentJalali.month;

    Map<String, dynamic>? fiscalYear;

    final currentYearResponse = await client
        .from('expense_fiscal_years')
        .select('id, company_id, year, title, status')
        .eq('company_id', companyId)
        .eq('year', currentYear)
        .maybeSingle();

    if (currentYearResponse != null) {
      fiscalYear = Map<String, dynamic>.from(currentYearResponse);
    } else {
      final latestYearResponse = await client
          .from('expense_fiscal_years')
          .select('id, company_id, year, title, status')
          .eq('company_id', companyId)
          .order('year', ascending: false)
          .limit(1)
          .maybeSingle();

      if (latestYearResponse != null) {
        fiscalYear = Map<String, dynamic>.from(
          latestYearResponse,
        );
      }
    }

    if (fiscalYear == null) {
      return ExpenseDashboardData.empty(
        year: currentYear,
        month: currentMonth,
      );
    }

    final fiscalYearId = fiscalYear['id']?.toString();

    if (fiscalYearId == null || fiscalYearId.isEmpty) {
      return ExpenseDashboardData.empty(
        year: currentYear,
        month: currentMonth,
      );
    }

    final fiscalYearValue = _toInt(
      fiscalYear['year'],
    );

    final periodsResponse = await client
        .from('expense_fiscal_periods')
        .select('''
          id,
          fiscal_year_id,
          company_id,
          year,
          month,
          title,
          status
        ''')
        .eq('fiscal_year_id', fiscalYearId)
        .order('month', ascending: true);

    final periods = List<Map<String, dynamic>>.from(
      periodsResponse,
    );

    if (periods.isEmpty) {
      return ExpenseDashboardData.empty(
        year: fiscalYearValue,
        month: currentMonth,
      );
    }

    final periodIds = periods
        .map(
          (period) => period['id']?.toString(),
    )
        .whereType<String>()
        .where(
          (id) => id.isNotEmpty,
    )
        .toList();

    if (periodIds.isEmpty) {
      return ExpenseDashboardData.empty(
        year: fiscalYearValue,
        month: currentMonth,
      );
    }

    final recognitionsResponse = await client
        .from('expense_recognitions')
        .select('''
          id,
          company_id,
          fiscal_period_id,
          category_id,
          amount,
          description,
          created_by,
          created_at,
          updated_at,
          expense_categories (
            id,
            name,
            code,
            expense_type,
            is_active
          )
        ''')
        .inFilter(
      'fiscal_period_id',
      periodIds,
    )
        .order(
      'created_at',
      ascending: true,
    );

    final recognitions =
    List<Map<String, dynamic>>.from(
      recognitionsResponse,
    );

    double totalExpense = 0;
    double operationalExpense = 0;
    double nonOperationalExpense = 0;

    final categoryTotals = <String, double>{};
    final categoryNames = <String, String>{};
    final categoryTypes = <String, String>{};

    final monthlyTotals = <int, double>{
      for (int month = 1; month <= 12; month++)
        month: 0,
    };

    final monthlyOperational = <int, double>{
      for (int month = 1; month <= 12; month++)
        month: 0,
    };

    final monthlyNonOperational = <int, double>{
      for (int month = 1; month <= 12; month++)
        month: 0,
    };

    final periodMonthById = <String, int>{};

    for (final period in periods) {
      final id = period['id']?.toString();
      final month = _toInt(
        period['month'],
      );

      if (id != null &&
          id.isNotEmpty &&
          month >= 1 &&
          month <= 12) {
        periodMonthById[id] = month;
      }
    }

    for (final recognition in recognitions) {
      final amount = _toDouble(
        recognition['amount'],
      );

      if (amount < 0) {
        continue;
      }

      final periodId =
      recognition['fiscal_period_id']?.toString();

      final month = periodId == null
          ? null
          : periodMonthById[periodId];

      final category =
      recognition['expense_categories'];

      String categoryId =
          recognition['category_id']?.toString() ?? '';

      String categoryName = 'بدون دسته‌بندی';

      String expenseType = 'operational';

      if (category is Map) {
        categoryId =
            category['id']?.toString() ??
                categoryId;

        categoryName =
            category['name']?.toString() ??
                categoryName;

        expenseType =
            category['expense_type']?.toString() ??
                expenseType;
      }

      totalExpense += amount;

      if (expenseType == 'non_operational') {
        nonOperationalExpense += amount;
      } else {
        operationalExpense += amount;
      }

      if (categoryId.isNotEmpty) {
        categoryTotals[categoryId] =
            (categoryTotals[categoryId] ?? 0) +
                amount;

        categoryNames[categoryId] = categoryName;

        categoryTypes[categoryId] = expenseType;
      }

      if (month != null &&
          month >= 1 &&
          month <= 12) {
        monthlyTotals[month] =
            (monthlyTotals[month] ?? 0) +
                amount;

        if (expenseType == 'non_operational') {
          monthlyNonOperational[month] =
              (monthlyNonOperational[month] ?? 0) +
                  amount;
        } else {
          monthlyOperational[month] =
              (monthlyOperational[month] ?? 0) +
                  amount;
        }
      }
    }

    double currentMonthExpense = 0;
    double previousMonthExpense = 0;

    if (fiscalYearValue == currentYear) {
      currentMonthExpense =
          monthlyTotals[currentMonth] ?? 0;

      final previousMonth =
      currentMonth == 1
          ? 12
          : currentMonth - 1;

      previousMonthExpense =
          monthlyTotals[previousMonth] ?? 0;
    } else {
      currentMonthExpense =
          monthlyTotals[currentMonth] ?? 0;

      final previousMonth =
      currentMonth == 1
          ? 12
          : currentMonth - 1;

      previousMonthExpense =
          monthlyTotals[previousMonth] ?? 0;
    }

    final categorySummaries =
    <ExpenseCategorySummary>[];

    for (final entry in categoryTotals.entries) {
      final amount = entry.value;

      final percentage = totalExpense <= 0
          ? 0.0
          : (amount / totalExpense) * 100;

      categorySummaries.add(
        ExpenseCategorySummary(
          categoryId: entry.key,
          name:
          categoryNames[entry.key] ??
              'بدون دسته‌بندی',
          expenseType:
          categoryTypes[entry.key] ??
              'operational',
          amount: amount,
          percentage: percentage,
        ),
      );
    }

    categorySummaries.sort(
          (a, b) => b.amount.compareTo(
        a.amount,
      ),
    );

    final monthlySummaries =
    <ExpenseMonthlySummary>[];

    const monthNames = [
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

    for (int month = 1; month <= 12; month++) {
      monthlySummaries.add(
        ExpenseMonthlySummary(
          year: fiscalYearValue,
          month: month,
          title: monthNames[month - 1],
          total:
          monthlyTotals[month] ?? 0,
          operational:
          monthlyOperational[month] ?? 0,
          nonOperational:
          monthlyNonOperational[month] ?? 0,
        ),
      );
    }

    return ExpenseDashboardData(
      fiscalYearId: fiscalYearId,
      fiscalYear: fiscalYearValue,
      currentMonth: currentMonth,
      currentMonthExpense:
      currentMonthExpense,
      previousMonthExpense:
      previousMonthExpense,
      totalExpense: totalExpense,
      operationalExpense:
      operationalExpense,
      nonOperationalExpense:
      nonOperationalExpense,
      expenseCount:
      recognitions.length,
      manualExpense: 0,
      payrollExpense: 0,
      categorySummaries:
      categorySummaries,
      monthlySummaries:
      monthlySummaries,
    );
  },
);

// ============================================================
// DASHBOARD DATA
// ============================================================

class ExpenseDashboardData {
  final String? fiscalYearId;

  final int fiscalYear;

  final int currentMonth;

  final double currentMonthExpense;

  final double previousMonthExpense;

  final double totalExpense;

  final double operationalExpense;

  final double nonOperationalExpense;

  final int expenseCount;

  final double manualExpense;

  final double payrollExpense;

  final List<ExpenseCategorySummary>
  categorySummaries;

  final List<ExpenseMonthlySummary>
  monthlySummaries;

  const ExpenseDashboardData({
    required this.fiscalYearId,
    required this.fiscalYear,
    required this.currentMonth,
    required this.currentMonthExpense,
    required this.previousMonthExpense,
    required this.totalExpense,
    required this.operationalExpense,
    required this.nonOperationalExpense,
    required this.expenseCount,
    required this.manualExpense,
    required this.payrollExpense,
    required this.categorySummaries,
    required this.monthlySummaries,
  });

  factory ExpenseDashboardData.empty({
    required int year,
    required int month,
  }) {
    return ExpenseDashboardData(
      fiscalYearId: null,
      fiscalYear: year,
      currentMonth: month,
      currentMonthExpense: 0,
      previousMonthExpense: 0,
      totalExpense: 0,
      operationalExpense: 0,
      nonOperationalExpense: 0,
      expenseCount: 0,
      manualExpense: 0,
      payrollExpense: 0,
      categorySummaries: const [],
      monthlySummaries: const [],
    );
  }

  // ----------------------------------------------------------
  // سهم عملیاتی
  // ----------------------------------------------------------

  double get operationalShare {
    if (totalExpense <= 0) {
      return 0;
    }

    return (operationalExpense /
        totalExpense) *
        100;
  }

  // ----------------------------------------------------------
  // سهم غیرعملیاتی
  // ----------------------------------------------------------

  double get nonOperationalShare {
    if (totalExpense <= 0) {
      return 0;
    }

    return (nonOperationalExpense /
        totalExpense) *
        100;
  }

  // ----------------------------------------------------------
  // رشد ماهانه
  // ----------------------------------------------------------

  double get monthlyGrowth {
    if (previousMonthExpense <= 0) {
      if (currentMonthExpense <= 0) {
        return 0;
      }

      return 100;
    }

    return ((currentMonthExpense -
        previousMonthExpense) /
        previousMonthExpense) *
        100;
  }

  // ----------------------------------------------------------
  // Aliases
  // ----------------------------------------------------------

  double get operationalPercent =>
      operationalShare;

  double get nonOperationalPercent =>
      nonOperationalShare;

  double get monthChangePercent =>
      monthlyGrowth;
}

// ============================================================
// CATEGORY SUMMARY
// ============================================================

class ExpenseCategorySummary {
  final String categoryId;

  final String name;

  final String expenseType;

  final double amount;

  final double percentage;

  const ExpenseCategorySummary({
    required this.categoryId,
    required this.name,
    required this.expenseType,
    required this.amount,
    required this.percentage,
  });

  // سازگاری با کدهای قبلی

  String get categoryName => name;

  String get code => categoryId;

  bool get isOperational =>
      expenseType != 'non_operational';

  bool get isNonOperational =>
      expenseType == 'non_operational';
}

// ============================================================
// MONTHLY SUMMARY
// ============================================================

class ExpenseMonthlySummary {
  final int year;

  final int month;

  final String title;

  final double total;

  final double operational;

  final double nonOperational;

  const ExpenseMonthlySummary({
    required this.year,
    required this.month,
    required this.title,
    required this.total,
    required this.operational,
    required this.nonOperational,
  });
}

// ============================================================
// JALALI
// ============================================================

class JalaliDate {
  final int year;

  final int month;

  const JalaliDate({
    required this.year,
    required this.month,
  });

  factory JalaliDate.now() {
    final now = DateTime.now();

    final gy = now.year;

    final gm = now.month;

    final gd = now.day;

    final gDaysInMonth = <int>[
      31,
      _isGregorianLeap(gy) ? 29 : 28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    ];

    int gy2 = gy;

    int jy;

    int jm;

    int jd;

    if (gy2 <= 1600) {
      gy2 = gy2 - 621;
    } else {
      gy2 = gy2 - 1600;
    }

    final gy3 =
    gm > 2 ? gy2 + 1 : gy2;

    int days =
        365 * gy2 +
            ((gy3 + 3) ~/ 4) -
            ((gy3 + 99) ~/ 100) +
            ((gy3 + 399) ~/ 400);

    for (int i = 0; i < gm - 1; i++) {
      days += gDaysInMonth[i];
    }

    days += gd;

    int jyDays = days - 79;

    jy =
        979 +
            33 * (jyDays ~/ 12053);

    jyDays %= 12053;

    jy +=
        4 * (jyDays ~/ 1461);

    jyDays %= 1461;

    if (jyDays > 365) {
      jy +=
          (jyDays - 1) ~/ 365;

      jyDays =
          (jyDays - 1) % 365;
    }

    if (jyDays < 186) {
      jm =
          1 + (jyDays ~/ 31);

      jd =
          1 + (jyDays % 31);
    } else {
      jm =
          7 +
              ((jyDays - 186) ~/ 30);

      jd =
          1 +
              ((jyDays - 186) % 30);
    }

    return JalaliDate(
      year: jy,
      month: jm,
    );
  }

  static bool _isGregorianLeap(
      int year,
      ) {
    return year % 4 == 0 &&
        (year % 100 != 0 ||
            year % 400 == 0);
  }
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
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    value.toString(),
  ) ??
      0;
}