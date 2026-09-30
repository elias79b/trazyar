import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantExpenseDashboardProvider =
    FutureProvider.family<AccountantExpenseDashboardData, String>((
      ref,
      companyId,
    ) async {
      return AccountantExpenseDashboardRepository(
        Supabase.instance.client,
      ).load(companyId);
    });

class AccountantExpenseDashboardRepository {
  AccountantExpenseDashboardRepository(this._client);

  final SupabaseClient _client;

  Future<AccountantExpenseDashboardData> load(String companyId) async {
    final yearsResponse = await _client
        .from('expense_fiscal_years')
        .select('id, company_id, year, title, status')
        .eq('company_id', companyId)
        .order('year', ascending: false);

    final categoriesResponse = await _client
        .from('expense_categories')
        .select(
          'id, company_id, name, code, description, expense_type, is_active',
        )
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order('name');

    final periodsResponse = await _client
        .from('expense_fiscal_periods')
        .select('id, fiscal_year_id, company_id, year, month, title, status')
        .eq('company_id', companyId)
        .order('year', ascending: false)
        .order('month', ascending: false);

    final recognitionsResponse = await _client
        .from('expense_recognitions')
        .select(
          'id, company_id, fiscal_period_id, category_id, amount, description',
        )
        .eq('company_id', companyId);

    final years =
        (yearsResponse as List)
            .map(
              (row) => AccountantExpenseFiscalYear.fromMap(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();

    final categories =
        (categoriesResponse as List)
            .map(
              (row) => AccountantExpenseCategory.fromMap(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();

    final periods =
        (periodsResponse as List)
            .map(
              (row) => AccountantExpenseFiscalPeriod.fromMap(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();

    final recognitions =
        (recognitionsResponse as List)
            .map(
              (row) => AccountantExpenseRecognition.fromMap(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();

    if (periods.isEmpty) {
      return AccountantExpenseDashboardData.empty(
        years: years,
        categories: categories,
        periods: periods,
      );
    }

    final selectedPeriod = _selectCurrentPeriod(periods);

    final previousPeriod = _findPreviousPeriod(periods, selectedPeriod);

    final currentRecognitions =
        recognitions
            .where((item) => item.fiscalPeriodId == selectedPeriod.id)
            .toList();

    final previousRecognitions =
        previousPeriod == null
            ? <AccountantExpenseRecognition>[]
            : recognitions
                .where((item) => item.fiscalPeriodId == previousPeriod.id)
                .toList();

    final categoryMap = <String, AccountantExpenseCategory>{
      for (final category in categories) category.id: category,
    };

    final currentCategoryTotals = _buildCategoryTotals(currentRecognitions);

    final previousCategoryTotals = _buildCategoryTotals(previousRecognitions);

    final currentCategoryBreakdown = <AccountantExpenseCategoryBreakdown>[];

    for (final entry in currentCategoryTotals.entries) {
      final category = categoryMap[entry.key];

      if (category == null) {
        continue;
      }

      currentCategoryBreakdown.add(
        AccountantExpenseCategoryBreakdown(
          categoryId: category.id,
          categoryName: category.name,
          categoryCode: category.code,
          expenseType: category.expenseType,
          amount: entry.value,
          sharePercent: 0.0,
          previousAmount: previousCategoryTotals[category.id] ?? 0.0,
        ),
      );
    }

    currentCategoryBreakdown.sort((a, b) => b.amount.compareTo(a.amount));

    final double totalExpense = currentCategoryBreakdown.fold<double>(
      0.0,
      (sum, item) => sum + item.amount,
    );

    final double operationalTotal = currentCategoryBreakdown
        .where((item) => item.expenseType == 'operational')
        .fold<double>(0.0, (sum, item) => sum + item.amount);

    final double nonOperationalTotal = currentCategoryBreakdown
        .where((item) => item.expenseType == 'non_operational')
        .fold<double>(0.0, (sum, item) => sum + item.amount);

    final double previousTotal = previousCategoryTotals.values.fold<double>(
      0.0,
      (sum, amount) => sum + amount,
    );

    final double changeAmount = totalExpense - previousTotal;

    final double changePercent =
        previousTotal == 0.0
            ? (totalExpense == 0.0 ? 0.0 : 100.0)
            : (changeAmount / previousTotal) * 100.0;

    final finalBreakdown =
        currentCategoryBreakdown.map((item) {
          final double share =
              totalExpense == 0.0 ? 0.0 : (item.amount / totalExpense) * 100.0;

          return item.copyWith(sharePercent: share);
        }).toList();

    final double operationalShare =
        totalExpense == 0.0 ? 0.0 : (operationalTotal / totalExpense) * 100.0;

    final double nonOperationalShare =
        totalExpense == 0.0
            ? 0.0
            : (nonOperationalTotal / totalExpense) * 100.0;

    return AccountantExpenseDashboardData(
      years: years,
      categories: categories,
      periods: periods,
      selectedPeriod: selectedPeriod,
      previousPeriod: previousPeriod,
      totalExpense: totalExpense,
      operationalTotal: operationalTotal,
      nonOperationalTotal: nonOperationalTotal,
      operationalShare: operationalShare,
      nonOperationalShare: nonOperationalShare,
      previousTotalExpense: previousTotal,
      changeAmount: changeAmount,
      changePercent: changePercent,
      categoryBreakdown: finalBreakdown,
    );
  }

  AccountantExpenseFiscalPeriod _selectCurrentPeriod(
    List<AccountantExpenseFiscalPeriod> periods,
  ) {
    final sorted = [...periods]..sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);

      if (yearCompare != 0) {
        return yearCompare;
      }

      return b.month.compareTo(a.month);
    });

    return sorted.first;
  }

  AccountantExpenseFiscalPeriod? _findPreviousPeriod(
    List<AccountantExpenseFiscalPeriod> periods,
    AccountantExpenseFiscalPeriod current,
  ) {
    final sorted = [...periods]..sort((a, b) {
      final yearCompare = b.year.compareTo(a.year);

      if (yearCompare != 0) {
        return yearCompare;
      }

      return b.month.compareTo(a.month);
    });

    for (final period in sorted) {
      if (period.year < current.year) {
        return period;
      }

      if (period.year == current.year && period.month < current.month) {
        return period;
      }
    }

    return null;
  }

  Map<String, double> _buildCategoryTotals(
    List<AccountantExpenseRecognition> recognitions,
  ) {
    final result = <String, double>{};

    for (final recognition in recognitions) {
      result.update(
        recognition.categoryId,
        (value) => value + recognition.amount,
        ifAbsent: () => recognition.amount,
      );
    }

    return result;
  }
}

class AccountantExpenseDashboardData {
  const AccountantExpenseDashboardData({
    required this.years,
    required this.categories,
    required this.periods,
    required this.selectedPeriod,
    required this.previousPeriod,
    required this.totalExpense,
    required this.operationalTotal,
    required this.nonOperationalTotal,
    required this.operationalShare,
    required this.nonOperationalShare,
    required this.previousTotalExpense,
    required this.changeAmount,
    required this.changePercent,
    required this.categoryBreakdown,
  });

  factory AccountantExpenseDashboardData.empty({
    required List<AccountantExpenseFiscalYear> years,
    required List<AccountantExpenseCategory> categories,
    required List<AccountantExpenseFiscalPeriod> periods,
  }) {
    return AccountantExpenseDashboardData(
      years: years,
      categories: categories,
      periods: periods,
      selectedPeriod: null,
      previousPeriod: null,
      totalExpense: 0.0,
      operationalTotal: 0.0,
      nonOperationalTotal: 0.0,
      operationalShare: 0.0,
      nonOperationalShare: 0.0,
      previousTotalExpense: 0.0,
      changeAmount: 0.0,
      changePercent: 0.0,
      categoryBreakdown: const [],
    );
  }

  final List<AccountantExpenseFiscalYear> years;
  final List<AccountantExpenseCategory> categories;
  final List<AccountantExpenseFiscalPeriod> periods;

  final AccountantExpenseFiscalPeriod? selectedPeriod;
  final AccountantExpenseFiscalPeriod? previousPeriod;

  final double totalExpense;
  final double operationalTotal;
  final double nonOperationalTotal;

  final double operationalShare;
  final double nonOperationalShare;

  final double previousTotalExpense;
  final double changeAmount;
  final double changePercent;

  final List<AccountantExpenseCategoryBreakdown> categoryBreakdown;

  List<AccountantExpenseCategoryBreakdown> get operationalCategories {
    return categoryBreakdown
        .where((item) => item.expenseType == 'operational')
        .toList();
  }

  List<AccountantExpenseCategoryBreakdown> get nonOperationalCategories {
    return categoryBreakdown
        .where((item) => item.expenseType == 'non_operational')
        .toList();
  }

  List<AccountantExpenseCategoryBreakdown> get topCategories {
    return [...categoryBreakdown]..sort((a, b) => b.amount.compareTo(a.amount));
  }

  bool get hasData => selectedPeriod != null;
}

class AccountantExpenseFiscalYear {
  const AccountantExpenseFiscalYear({
    required this.id,
    required this.companyId,
    required this.year,
    required this.title,
    required this.status,
  });

  factory AccountantExpenseFiscalYear.fromMap(Map<String, dynamic> map) {
    return AccountantExpenseFiscalYear(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      year: (map['year'] as num).toInt(),
      title: map['title'] as String?,
      status: map['status'] as String? ?? 'open',
    );
  }

  final String id;
  final String companyId;
  final int year;
  final String? title;
  final String status;
}

class AccountantExpenseFiscalPeriod {
  const AccountantExpenseFiscalPeriod({
    required this.id,
    required this.fiscalYearId,
    required this.companyId,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
  });

  factory AccountantExpenseFiscalPeriod.fromMap(Map<String, dynamic> map) {
    return AccountantExpenseFiscalPeriod(
      id: map['id'] as String,
      fiscalYearId: map['fiscal_year_id'] as String,
      companyId: map['company_id'] as String,
      year: (map['year'] as num).toInt(),
      month: (map['month'] as num).toInt(),
      title: map['title'] as String?,
      status: map['status'] as String? ?? 'open',
    );
  }

  final String id;
  final String fiscalYearId;
  final String companyId;
  final int year;
  final int month;
  final String? title;
  final String status;

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) {
      return title!;
    }

    return 'ماه $month';
  }
}

class AccountantExpenseCategory {
  const AccountantExpenseCategory({
    required this.id,
    required this.companyId,
    required this.name,
    required this.code,
    required this.description,
    required this.expenseType,
    required this.isActive,
  });

  factory AccountantExpenseCategory.fromMap(Map<String, dynamic> map) {
    return AccountantExpenseCategory(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      name: map['name'] as String,
      code: map['code'] as String?,
      description: map['description'] as String?,
      expenseType: map['expense_type'] as String? ?? 'operational',
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  final String id;
  final String companyId;
  final String name;
  final String? code;
  final String? description;
  final String expenseType;
  final bool isActive;

  bool get isOperational => expenseType == 'operational';

  bool get isNonOperational => expenseType == 'non_operational';
}

class AccountantExpenseRecognition {
  const AccountantExpenseRecognition({
    required this.id,
    required this.companyId,
    required this.fiscalPeriodId,
    required this.categoryId,
    required this.amount,
    required this.description,
  });

  factory AccountantExpenseRecognition.fromMap(Map<String, dynamic> map) {
    return AccountantExpenseRecognition(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      fiscalPeriodId: map['fiscal_period_id'] as String,
      categoryId: map['category_id'] as String,
      amount: _toDouble(map['amount']),
      description: map['description'] as String?,
    );
  }

  final String id;
  final String companyId;
  final String fiscalPeriodId;
  final String categoryId;
  final double amount;
  final String? description;
}

class AccountantExpenseCategoryBreakdown {
  const AccountantExpenseCategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.categoryCode,
    required this.expenseType,
    required this.amount,
    required this.sharePercent,
    required this.previousAmount,
  });

  final String categoryId;
  final String categoryName;
  final String? categoryCode;
  final String expenseType;
  final double amount;
  final double sharePercent;
  final double previousAmount;

  double get changeAmount => amount - previousAmount;

  double get changePercent {
    if (previousAmount == 0.0) {
      return amount == 0.0 ? 0.0 : 100.0;
    }

    return (changeAmount / previousAmount) * 100.0;
  }

  AccountantExpenseCategoryBreakdown copyWith({
    String? categoryId,
    String? categoryName,
    String? categoryCode,
    String? expenseType,
    double? amount,
    double? sharePercent,
    double? previousAmount,
  }) {
    return AccountantExpenseCategoryBreakdown(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryCode: categoryCode ?? this.categoryCode,
      expenseType: expenseType ?? this.expenseType,
      amount: amount ?? this.amount,
      sharePercent: sharePercent ?? this.sharePercent,
      previousAmount: previousAmount ?? this.previousAmount,
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) {
    return 0.0;
  }

  if (value is double) {
    return value;
  }

  if (value is int) {
    return value.toDouble();
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0.0;
}
