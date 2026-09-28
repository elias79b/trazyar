import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantIncomeDashboardProvider =
FutureProvider.family<AccountantIncomeDashboardData, String>((
    ref,
    companyId,
    ) async {
  return AccountantIncomeDashboardRepository.fetch(
    companyId,
  );
});

class AccountantIncomeDashboardData {
  final String companyId;
  final int? fiscalYear;
  final String? fiscalYearTitle;

  final double totalIncome;
  final double operationalIncome;
  final double nonOperationalIncome;

  final List<AccountantIncomeCategorySummary> categorySummaries;
  final List<AccountantIncomeMonthlySummary> monthlySummaries;

  const AccountantIncomeDashboardData({
    required this.companyId,
    required this.fiscalYear,
    required this.fiscalYearTitle,
    required this.totalIncome,
    required this.operationalIncome,
    required this.nonOperationalIncome,
    required this.categorySummaries,
    required this.monthlySummaries,
  });

  double get operationalShare {
    if (totalIncome == 0.0) {
      return 0.0;
    }

    return operationalIncome / totalIncome * 100.0;
  }

  double get nonOperationalShare {
    if (totalIncome == 0.0) {
      return 0.0;
    }

    return nonOperationalIncome / totalIncome * 100.0;
  }
}

class AccountantIncomeCategorySummary {
  final String categoryId;
  final String categoryName;
  final String categoryType;
  final double amount;

  const AccountantIncomeCategorySummary({
    required this.categoryId,
    required this.categoryName,
    required this.categoryType,
    required this.amount,
  });

  bool get isOperational =>
      categoryType == 'operational';

  bool get isNonOperational =>
      categoryType == 'non_operational';
}

class AccountantIncomeMonthlySummary {
  final String periodId;
  final int month;
  final String title;
  final double operationalAmount;
  final double nonOperationalAmount;

  const AccountantIncomeMonthlySummary({
    required this.periodId,
    required this.month,
    required this.title,
    required this.operationalAmount,
    required this.nonOperationalAmount,
  });

  double get total =>
      operationalAmount + nonOperationalAmount;
}

class AccountantIncomeDashboardRepository {
  AccountantIncomeDashboardRepository._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  static Future<AccountantIncomeDashboardData> fetch(
      String companyId,
      ) async {
    // ==========================================================
    // سال جاری شمسی
    // ==========================================================

    final currentJalaliYear =
    _currentJalaliYear();

    // ==========================================================
    // فقط سال جاری را از دیتابیس می‌گیریم
    // ==========================================================

    final fiscalYearResponse = await _supabase
        .from('income_fiscal_years')
        .select(
      'id, year, title, status',
    )
        .eq(
      'company_id',
      companyId,
    )
        .eq(
      'year',
      currentJalaliYear,
    )
        .limit(1);

    // اگر سال جاری برای شرکت ساخته نشده باشد،
    // داشبورد نباید سال آینده یا آخرین سال موجود را نمایش دهد.
    if (fiscalYearResponse.isEmpty) {
      return AccountantIncomeDashboardData(
        companyId: companyId,
        fiscalYear: currentJalaliYear,
        fiscalYearTitle:
        'سال مالی $currentJalaliYear',
        totalIncome: 0.0,
        operationalIncome: 0.0,
        nonOperationalIncome: 0.0,
        categorySummaries: const [],
        monthlySummaries: const [],
      );
    }

    final fiscalYear =
    Map<String, dynamic>.from(
      fiscalYearResponse.first,
    );

    final fiscalYearId =
        fiscalYear['id']?.toString() ?? '';

    final year =
    _toInt(fiscalYear['year']);

    final yearTitle =
    fiscalYear['title']?.toString();

    if (fiscalYearId.isEmpty) {
      return AccountantIncomeDashboardData(
        companyId: companyId,
        fiscalYear: currentJalaliYear,
        fiscalYearTitle:
        yearTitle ??
            'سال مالی $currentJalaliYear',
        totalIncome: 0.0,
        operationalIncome: 0.0,
        nonOperationalIncome: 0.0,
        categorySummaries: const [],
        monthlySummaries: const [],
      );
    }

    // ==========================================================
    // دوره‌های سال جاری
    // ==========================================================

    final periodsResponse = await _supabase
        .from('income_fiscal_periods')
        .select(
      'id, year, month, title, status',
    )
        .eq(
      'company_id',
      companyId,
    )
        .eq(
      'fiscal_year_id',
      fiscalYearId,
    )
        .order(
      'month',
      ascending: true,
    );

    final periods = (periodsResponse as List)
        .map(
          (row) => Map<String, dynamic>.from(row),
    )
        .toList();

    if (periods.isEmpty) {
      return AccountantIncomeDashboardData(
        companyId: companyId,
        fiscalYear: year,
        fiscalYearTitle:
        yearTitle ??
            'سال مالی $currentJalaliYear',
        totalIncome: 0.0,
        operationalIncome: 0.0,
        nonOperationalIncome: 0.0,
        categorySummaries: const [],
        monthlySummaries: const [],
      );
    }

    final periodIds = periods
        .map(
          (period) =>
      period['id']?.toString() ?? '',
    )
        .where(
          (id) => id.isNotEmpty,
    )
        .toList();

    // ==========================================================
    // ثبت درآمدها
    // ==========================================================

    final recognitionsResponse =
    periodIds.isEmpty
        ? <dynamic>[]
        : await _supabase
        .from('income_recognitions')
        .select(
      'id, fiscal_period_id, category_id, amount, '
          'income_categories('
          'id, name, category_type'
          ')',
    )
        .eq(
      'company_id',
      companyId,
    )
        .inFilter(
      'fiscal_period_id',
      periodIds,
    );

    final categoryMap =
    <String, AccountantIncomeCategorySummary>{};

    final monthlyMap =
    <String, _MonthlyAccumulator>{};

    // ==========================================================
    // ایجاد ۱۲ ماه
    // ==========================================================

    for (final period in periods) {
      final periodId =
          period['id']?.toString() ?? '';

      if (periodId.isEmpty) {
        continue;
      }

      monthlyMap[periodId] =
          _MonthlyAccumulator(
            periodId: periodId,
            month: _toInt(
              period['month'],
            ),
            title:
            period['title']?.toString() ??
                '',
          );
    }

    // ==========================================================
    // پردازش درآمدها
    // ==========================================================

    for (final rawRow
    in recognitionsResponse as List) {
      final row =
      Map<String, dynamic>.from(rawRow);

      final categoryId =
          row['category_id']?.toString() ??
              '';

      final periodId =
          row['fiscal_period_id']?.toString() ??
              '';

      final amount =
      _toDouble(row['amount']);

      if (categoryId.isEmpty ||
          periodId.isEmpty) {
        continue;
      }

      final categoryRaw =
      row['income_categories'];

      if (categoryRaw == null) {
        continue;
      }

      final category =
      Map<String, dynamic>.from(
        categoryRaw,
      );

      final categoryName =
          category['name']?.toString() ??
              'بدون دسته‌بندی';

      final categoryType =
          category['category_type']
              ?.toString()
              .trim()
              .toLowerCase() ??
              'operational';

      // --------------------------------------------------------
      // دسته‌بندی
      // --------------------------------------------------------

      final existing =
      categoryMap[categoryId];

      if (existing == null) {
        categoryMap[categoryId] =
            AccountantIncomeCategorySummary(
              categoryId: categoryId,
              categoryName: categoryName,
              categoryType: categoryType,
              amount: amount,
            );
      } else {
        categoryMap[categoryId] =
            AccountantIncomeCategorySummary(
              categoryId:
              existing.categoryId,
              categoryName:
              existing.categoryName,
              categoryType:
              existing.categoryType,
              amount:
              existing.amount + amount,
            );
      }

      // --------------------------------------------------------
      // ماه
      // --------------------------------------------------------

      final monthly =
      monthlyMap[periodId];

      if (monthly != null) {
        if (categoryType ==
            'non_operational') {
          monthly.nonOperationalAmount +=
              amount;
        } else {
          monthly.operationalAmount +=
              amount;
        }
      }
    }

    // ==========================================================
    // مرتب‌سازی دسته‌ها
    // ==========================================================

    final categories =
    categoryMap.values.toList()
      ..sort(
            (a, b) => b.amount.compareTo(
          a.amount,
        ),
      );

    // ==========================================================
    // مرتب‌سازی ماه‌ها
    // ==========================================================

    final monthly =
    monthlyMap.values.toList()
      ..sort(
            (a, b) => a.month.compareTo(
          b.month,
        ),
      );

    // ==========================================================
    // جمع کل
    // ==========================================================

    double operationalIncome = 0.0;
    double nonOperationalIncome = 0.0;

    for (final category in categories) {
      if (category.isNonOperational) {
        nonOperationalIncome +=
            category.amount;
      } else {
        operationalIncome +=
            category.amount;
      }
    }

    return AccountantIncomeDashboardData(
      companyId: companyId,
      fiscalYear:
      year == 0
          ? currentJalaliYear
          : year,
      fiscalYearTitle:
      yearTitle ??
          'سال مالی $currentJalaliYear',
      totalIncome:
      operationalIncome +
          nonOperationalIncome,
      operationalIncome:
      operationalIncome,
      nonOperationalIncome:
      nonOperationalIncome,
      categorySummaries:
      categories,
      monthlySummaries:
      monthly
          .map(
            (item) =>
            AccountantIncomeMonthlySummary(
              periodId:
              item.periodId,
              month:
              item.month,
              title:
              item.title,
              operationalAmount:
              item.operationalAmount,
              nonOperationalAmount:
              item.nonOperationalAmount,
            ),
      )
          .toList(),
    );
  }

  // ============================================================
  // سال جاری شمسی
  // ============================================================

  static int _currentJalaliYear() {
    final now = DateTime.now();

    return _gregorianToJalali(
      now.year,
      now.month,
      now.day,
    ).year;
  }

  // ============================================================
  // تبدیل میلادی به شمسی
  // ============================================================

  static _JalaliDate _gregorianToJalali(
      int gy,
      int gm,
      int gd,
      ) {
    final gDaysInMonth = <int>[
      31,
      28,
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

    final jDaysInMonth = <int>[
      31,
      31,
      31,
      31,
      31,
      31,
      30,
      30,
      30,
      30,
      30,
      29,
    ];

    int gy2 = gy - 1600;
    int gm2 = gm - 1;
    int gd2 = gd - 1;

    int gDayNo =
        365 * gy2 +
            ((gy2 + 3) ~/ 4) -
            ((gy2 + 99) ~/ 100) +
            ((gy2 + 399) ~/ 400);

    for (int i = 0; i < gm2; i++) {
      gDayNo += gDaysInMonth[i];
    }

    if (gm2 > 1 &&
        ((gy % 4 == 0 && gy % 100 != 0) ||
            gy % 400 == 0)) {
      gDayNo++;
    }

    gDayNo += gd2;

    int jDayNo = gDayNo - 79;

    int jNp =
        jDayNo ~/ 12053;

    int jy =
        979 + 33 * jNp;

    jDayNo %= 12053;

    jy +=
        4 * (jDayNo ~/ 1461);

    jDayNo %= 1461;

    if (jDayNo >= 366) {
      jy +=
          (jDayNo - 1) ~/ 365;

      jDayNo =
          (jDayNo - 1) % 365;
    }

    int jm = 0;

    for (int i = 0;
    i < 11 &&
        jDayNo >= jDaysInMonth[i];
    i++) {
      jDayNo -=
      jDaysInMonth[i];
      jm++;
    }

    return _JalaliDate(
      year: jy,
      month: jm + 1,
      day: jDayNo + 1,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    ) ??
        0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    ) ??
        0.0;
  }
}

class _JalaliDate {
  final int year;
  final int month;
  final int day;

  const _JalaliDate({
    required this.year,
    required this.month,
    required this.day,
  });
}

class _MonthlyAccumulator {
  final String periodId;
  final int month;
  final String title;

  double operationalAmount;
  double nonOperationalAmount;

  _MonthlyAccumulator({
    required this.periodId,
    required this.month,
    required this.title,
    this.operationalAmount = 0.0,
    this.nonOperationalAmount = 0.0,
  });
}