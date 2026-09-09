import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:tarazyar/consultant/companies/expenses/application/expense_provider.dart';

import '../data/expense_model.dart';

class ExpenseCategorySummary {
  const ExpenseCategorySummary({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.expenseType,
  });

  final String name;
  final num amount;
  final double percentage;
  final String expenseType;
}

class ExpenseMonthlySummary {
  const ExpenseMonthlySummary({
    required this.year,
    required this.month,
    required this.amount,
  });

  final int year;
  final int month;
  final num amount;
}

class ExpenseDashboardData {
  const ExpenseDashboardData({
    required this.currentMonthExpense,
    required this.previousMonthExpense,
    required this.totalExpense,
    required this.operationalExpense,
    required this.nonOperationalExpense,
    required this.manualExpense,
    required this.payrollExpense,
    required this.expenseCount,
    required this.operationalShare,
    required this.nonOperationalShare,
    required this.monthlyGrowth,
    required this.categorySummaries,
    required this.monthlySummaries,
  });

  final num currentMonthExpense;
  final num previousMonthExpense;

  final num totalExpense;
  final num operationalExpense;
  final num nonOperationalExpense;

  final num manualExpense;
  final num payrollExpense;

  final int expenseCount;

  final double operationalShare;
  final double nonOperationalShare;

  final double? monthlyGrowth;

  final List<ExpenseCategorySummary> categorySummaries;
  final List<ExpenseMonthlySummary> monthlySummaries;

  static const empty = ExpenseDashboardData(
    currentMonthExpense: 0,
    previousMonthExpense: 0,
    totalExpense: 0,
    operationalExpense: 0,
    nonOperationalExpense: 0,
    manualExpense: 0,
    payrollExpense: 0,
    expenseCount: 0,
    operationalShare: 0,
    nonOperationalShare: 0,
    monthlyGrowth: null,
    categorySummaries: [],
    monthlySummaries: [],
  );
}

final expenseDashboardProvider = FutureProvider.family<
  ExpenseDashboardData,
  String
>((ref, companyId) async {
  final repository = ref.watch(expenseRepositoryProvider);

  final expenses = await repository.getExpenses(companyId);

  if (expenses.isEmpty) {
    return ExpenseDashboardData.empty;
  }

  final now = Jalali.now();

  final currentYear = now.year;
  final currentMonth = now.month;

  final previousJalali = now.addMonths(-1);

  final previousYear = previousJalali.year;
  final previousMonth = previousJalali.month;

  num totalExpense = 0;
  num currentMonthExpense = 0;
  num previousMonthExpense = 0;

  num operationalExpense = 0;
  num nonOperationalExpense = 0;

  num manualExpense = 0;
  num payrollExpense = 0;

  final categoryAmounts = <String, num>{};
  final categoryTypes = <String, String>{};

  final monthlyAmounts = <String, num>{};

  for (final ExpenseModel expense in expenses) {
    final amount = expense.amount;

    totalExpense += amount;

    // --------------------------------------------------------
    // TYPE
    // --------------------------------------------------------

    if (expense.expenseType == 'operational') {
      operationalExpense += amount;
    } else if (expense.expenseType == 'non_operational') {
      nonOperationalExpense += amount;
    }

    // --------------------------------------------------------
    // SOURCE
    // --------------------------------------------------------

    if (expense.sourceType == 'manual') {
      manualExpense += amount;
    } else if (expense.sourceType == 'payroll') {
      payrollExpense += amount;
    }

    // --------------------------------------------------------
    // JALALI DATE
    // --------------------------------------------------------

    final jalaliDate = Jalali.fromDateTime(expense.expenseDate);

    // Current month
    if (jalaliDate.year == currentYear && jalaliDate.month == currentMonth) {
      currentMonthExpense += amount;
    }

    // Previous month
    if (jalaliDate.year == previousYear && jalaliDate.month == previousMonth) {
      previousMonthExpense += amount;
    }

    // --------------------------------------------------------
    // CATEGORY
    // --------------------------------------------------------

    final categoryName =
        expense.categoryName?.trim().isNotEmpty == true
            ? expense.categoryName!.trim()
            : 'بدون دسته‌بندی';

    categoryAmounts[categoryName] =
        (categoryAmounts[categoryName] ?? 0) + amount;

    categoryTypes[categoryName] = expense.expenseType;

    // --------------------------------------------------------
    // MONTHLY
    // --------------------------------------------------------

    final monthKey = '${jalaliDate.year}-${jalaliDate.month}';

    monthlyAmounts[monthKey] = (monthlyAmounts[monthKey] ?? 0) + amount;
  }

  // ----------------------------------------------------------
  // SHARES
  // ----------------------------------------------------------

  final operationalShare =
      totalExpense == 0 ? 0.0 : (operationalExpense / totalExpense) * 100;

  final nonOperationalShare =
      totalExpense == 0 ? 0.0 : (nonOperationalExpense / totalExpense) * 100;

  // ----------------------------------------------------------
  // GROWTH
  // ----------------------------------------------------------

  double? monthlyGrowth;

  if (previousMonthExpense > 0) {
    monthlyGrowth =
        ((currentMonthExpense - previousMonthExpense) / previousMonthExpense) *
        100;
  }

  // ----------------------------------------------------------
  // CATEGORY SUMMARY
  // ----------------------------------------------------------

  final categorySummaries =
      categoryAmounts.entries.map((entry) {
        final percentage =
            totalExpense == 0 ? 0.0 : (entry.value / totalExpense) * 100;

        return ExpenseCategorySummary(
          name: entry.key,
          amount: entry.value,
          percentage: percentage,
          expenseType: categoryTypes[entry.key] ?? 'operational',
        );
      }).toList();

  categorySummaries.sort((a, b) => b.amount.compareTo(a.amount));

  // ----------------------------------------------------------
  // MONTHLY SUMMARY
  // ----------------------------------------------------------

  final monthlySummaries = <ExpenseMonthlySummary>[];

  for (var i = 5; i >= 0; i--) {
    final date = now.addMonths(-i);

    final key = '${date.year}-${date.month}';

    monthlySummaries.add(
      ExpenseMonthlySummary(
        year: date.year,
        month: date.month,
        amount: monthlyAmounts[key] ?? 0,
      ),
    );
  }

  return ExpenseDashboardData(
    currentMonthExpense: currentMonthExpense,
    previousMonthExpense: previousMonthExpense,
    totalExpense: totalExpense,
    operationalExpense: operationalExpense,
    nonOperationalExpense: nonOperationalExpense,
    manualExpense: manualExpense,
    payrollExpense: payrollExpense,
    expenseCount: expenses.length,
    operationalShare: operationalShare,
    nonOperationalShare: nonOperationalShare,
    monthlyGrowth: monthlyGrowth,
    categorySummaries: categorySummaries,
    monthlySummaries: monthlySummaries,
  );
});
