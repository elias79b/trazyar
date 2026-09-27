import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantIncomeDashboardProvider =
    FutureProvider.family<AccountantIncomeDashboardData, String>((
      ref,
      companyId,
    ) async {
      return AccountantIncomeDashboardRepository.fetch(companyId);
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

  double get operationalShare =>
      totalIncome == 0 ? 0 : operationalIncome / totalIncome * 100;

  double get nonOperationalShare =>
      totalIncome == 0 ? 0 : nonOperationalIncome / totalIncome * 100;
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

  bool get isOperational => categoryType == 'operational';

  bool get isNonOperational => categoryType == 'non_operational';
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

  double get total => operationalAmount + nonOperationalAmount;
}

class AccountantIncomeDashboardRepository {
  AccountantIncomeDashboardRepository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<AccountantIncomeDashboardData> fetch(String companyId) async {
    final fiscalYearResponse = await _supabase
        .from('income_fiscal_years')
        .select('id, year, title, status')
        .eq('company_id', companyId)
        .order('year', ascending: false)
        .limit(1);

    if (fiscalYearResponse.isEmpty) {
      return AccountantIncomeDashboardData(
        companyId: companyId,
        fiscalYear: null,
        fiscalYearTitle: null,
        totalIncome: 0,
        operationalIncome: 0,
        nonOperationalIncome: 0,
        categorySummaries: const [],
        monthlySummaries: const [],
      );
    }

    final fiscalYear = Map<String, dynamic>.from(fiscalYearResponse.first);

    final fiscalYearId = fiscalYear['id']?.toString() ?? '';

    final year = _toInt(fiscalYear['year']);

    final yearTitle = fiscalYear['title']?.toString();

    if (fiscalYearId.isEmpty) {
      return AccountantIncomeDashboardData(
        companyId: companyId,
        fiscalYear: year,
        fiscalYearTitle: yearTitle,
        totalIncome: 0,
        operationalIncome: 0,
        nonOperationalIncome: 0,
        categorySummaries: const [],
        monthlySummaries: const [],
      );
    }

    final periodsResponse = await _supabase
        .from('income_fiscal_periods')
        .select('id, year, month, title, status')
        .eq('company_id', companyId)
        .eq('fiscal_year_id', fiscalYearId)
        .order('month', ascending: true);

    final periods =
        (periodsResponse as List)
            .map((row) => Map<String, dynamic>.from(row))
            .toList();

    if (periods.isEmpty) {
      return AccountantIncomeDashboardData(
        companyId: companyId,
        fiscalYear: year,
        fiscalYearTitle: yearTitle,
        totalIncome: 0,
        operationalIncome: 0,
        nonOperationalIncome: 0,
        categorySummaries: const [],
        monthlySummaries: const [],
      );
    }

    final periodIds =
        periods
            .map((period) => period['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();

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
                .eq('company_id', companyId)
                .inFilter('fiscal_period_id', periodIds);

    final categoryMap = <String, AccountantIncomeCategorySummary>{};

    final monthlyMap = <String, _MonthlyAccumulator>{};

    for (final period in periods) {
      final periodId = period['id']?.toString() ?? '';

      if (periodId.isEmpty) {
        continue;
      }

      monthlyMap[periodId] = _MonthlyAccumulator(
        periodId: periodId,
        month: _toInt(period['month']),
        title: period['title']?.toString() ?? '',
      );
    }

    for (final rawRow in recognitionsResponse as List) {
      final row = Map<String, dynamic>.from(rawRow);

      final categoryId = row['category_id']?.toString() ?? '';

      final periodId = row['fiscal_period_id']?.toString() ?? '';

      final amount = _toDouble(row['amount']);

      if (categoryId.isEmpty || periodId.isEmpty) {
        continue;
      }

      final categoryRaw = row['income_categories'];

      if (categoryRaw == null) {
        continue;
      }

      final category = Map<String, dynamic>.from(categoryRaw);

      final categoryName = category['name']?.toString() ?? 'بدون دسته‌بندی';

      final categoryType =
          category['category_type']?.toString().trim().toLowerCase() ??
          'operational';

      final existing = categoryMap[categoryId];

      if (existing == null) {
        categoryMap[categoryId] = AccountantIncomeCategorySummary(
          categoryId: categoryId,
          categoryName: categoryName,
          categoryType: categoryType,
          amount: amount,
        );
      } else {
        categoryMap[categoryId] = AccountantIncomeCategorySummary(
          categoryId: existing.categoryId,
          categoryName: existing.categoryName,
          categoryType: existing.categoryType,
          amount: existing.amount + amount,
        );
      }

      final monthly = monthlyMap[periodId];

      if (monthly != null) {
        if (categoryType == 'non_operational') {
          monthly.nonOperationalAmount += amount;
        } else {
          monthly.operationalAmount += amount;
        }
      }
    }

    final categories =
        categoryMap.values.toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final monthly =
        monthlyMap.values.toList()..sort((a, b) => a.month.compareTo(b.month));

    var operationalIncome = 0.0;
    var nonOperationalIncome = 0.0;

    for (final category in categories) {
      if (category.isNonOperational) {
        nonOperationalIncome += category.amount;
      } else {
        operationalIncome += category.amount;
      }
    }

    return AccountantIncomeDashboardData(
      companyId: companyId,
      fiscalYear: year,
      fiscalYearTitle: yearTitle,
      totalIncome: operationalIncome + nonOperationalIncome,
      operationalIncome: operationalIncome,
      nonOperationalIncome: nonOperationalIncome,
      categorySummaries: categories,
      monthlySummaries:
          monthly
              .map(
                (item) => AccountantIncomeMonthlySummary(
                  periodId: item.periodId,
                  month: item.month,
                  title: item.title,
                  operationalAmount: item.operationalAmount,
                  nonOperationalAmount: item.nonOperationalAmount,
                ),
              )
              .toList(),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
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
    this.operationalAmount = 0,
    this.nonOperationalAmount = 0,
  });
}
