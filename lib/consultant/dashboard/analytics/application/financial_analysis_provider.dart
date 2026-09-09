import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final financialAnalysisProvider = FutureProvider.family<
  FinancialAnalysisData,
  String
>((ref, companyId) async {
  final client = Supabase.instance.client;

  final results = await Future.wait([
    client
        .from('income_records')
        .select(
          'id, amount, income_date, status, category_id, income_categories(id,name)',
        )
        .eq('company_id', companyId),

    client
        .from('expenses')
        .select(
          'id, amount, expense_date, expense_type, source_type, category_id, expense_categories(id,name)',
        )
        .eq('company_id', companyId),

    client
        .from('bank_accounts')
        .select('closing_balance')
        .eq('company_id', companyId),

    client
        .from('cash_boxes')
        .select('closing_balance')
        .eq('company_id', companyId),

    client
        .from('petty_cash_accounts')
        .select('closing_balance')
        .eq('company_id', companyId),

    client
        .from('bank_loans')
        .select('remaining_amount')
        .eq('company_id', companyId),

    client
        .from('received_checks')
        .select('amount, status')
        .eq('company_id', companyId),

    client
        .from('paid_checks')
        .select('amount, status')
        .eq('company_id', companyId),

    client.from('employees').select('id, status').eq('company_id', companyId),

    client
        .from('payroll_records')
        .select(
          'gross_salary, employer_insurance, payroll_period_id, payroll_periods(period_year,period_month)',
        )
        .eq('company_id', companyId),
  ]);

  return FinancialAnalysisData.fromRaw(
    incomeRows: _rows(results[0]),
    expenseRows: _rows(results[1]),
    bankRows: _rows(results[2]),
    cashRows: _rows(results[3]),
    pettyRows: _rows(results[4]),
    loanRows: _rows(results[5]),
    receivedCheckRows: _rows(results[6]),
    paidCheckRows: _rows(results[7]),
    employeeRows: _rows(results[8]),
    payrollRows: _rows(results[9]),
  );
});

List<Map<String, dynamic>> _rows(dynamic value) {
  if (value is! List) {
    return <Map<String, dynamic>>[];
  }

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

class FinancialAnalysisData {
  final double totalIncome;
  final double receivedIncome;
  final double pendingIncome;

  final double totalExpense;
  final double operationalExpense;
  final double nonOperationalExpense;

  final double profit;
  final double profitMargin;

  final double liquidity;
  final double loans;
  final double receivedChecks;
  final double paidChecks;

  final int activeEmployees;
  final double personnelCost;

  final List<FinancialMonthData> monthlyData;

  final List<FinancialCategoryData> incomeCategories;
  final List<FinancialCategoryData> expenseCategories;

  final double currentMonthIncome;
  final double previousMonthIncome;

  final double currentMonthExpense;
  final double previousMonthExpense;

  const FinancialAnalysisData({
    required this.totalIncome,
    required this.receivedIncome,
    required this.pendingIncome,
    required this.totalExpense,
    required this.operationalExpense,
    required this.nonOperationalExpense,
    required this.profit,
    required this.profitMargin,
    required this.liquidity,
    required this.loans,
    required this.receivedChecks,
    required this.paidChecks,
    required this.activeEmployees,
    required this.personnelCost,
    required this.monthlyData,
    required this.incomeCategories,
    required this.expenseCategories,
    required this.currentMonthIncome,
    required this.previousMonthIncome,
    required this.currentMonthExpense,
    required this.previousMonthExpense,
  });

  factory FinancialAnalysisData.fromRaw({
    required List<Map<String, dynamic>> incomeRows,
    required List<Map<String, dynamic>> expenseRows,
    required List<Map<String, dynamic>> bankRows,
    required List<Map<String, dynamic>> cashRows,
    required List<Map<String, dynamic>> pettyRows,
    required List<Map<String, dynamic>> loanRows,
    required List<Map<String, dynamic>> receivedCheckRows,
    required List<Map<String, dynamic>> paidCheckRows,
    required List<Map<String, dynamic>> employeeRows,
    required List<Map<String, dynamic>> payrollRows,
  }) {
    double totalIncome = 0;
    double receivedIncome = 0;
    double pendingIncome = 0;

    double totalExpense = 0;
    double operationalExpense = 0;
    double nonOperationalExpense = 0;

    double liquidity = 0;
    double loans = 0;

    double receivedChecks = 0;
    double paidChecks = 0;

    int activeEmployees = 0;

    double personnelCost = 0;

    final incomeCategoryTotals = <String, double>{};
    final incomeCategoryNames = <String, String>{};

    final expenseCategoryTotals = <String, double>{};
    final expenseCategoryNames = <String, String>{};

    final now = DateTime.now();

    final currentJalali = Jalali.fromDateTime(now);

    final previousJalali = _subtractMonths(currentJalali, 1);

    double currentMonthIncome = 0;
    double previousMonthIncome = 0;

    double currentMonthExpense = 0;
    double previousMonthExpense = 0;

    final monthly = <String, FinancialMonthData>{};

    /*
     * ایجاد ۶ ماه اخیر شمسی
     */
    for (int offset = 5; offset >= 0; offset--) {
      final month = _subtractMonths(currentJalali, offset);

      final key = '${month.year}-${month.month}';

      monthly[key] = FinancialMonthData(
        year: month.year,
        month: month.month,
        label: _monthName(month.month),
        income: 0,
        expense: 0,
        profit: 0,
      );
    }

    /*
     * درآمدها
     */
    for (final row in incomeRows) {
      final amount = _num(row['amount']);

      totalIncome += amount;

      final status =
          row['status']?.toString().trim().toLowerCase() ?? 'received';

      if (status == 'received') {
        receivedIncome += amount;
      } else if (status == 'pending') {
        pendingIncome += amount;
      }

      final date = _parseDate(row['income_date']);

      if (date != null) {
        final jalali = Jalali.fromDateTime(date);

        final key = '${jalali.year}-${jalali.month}';

        if (monthly.containsKey(key)) {
          final old = monthly[key]!;

          monthly[key] = old.copyWith(income: old.income + amount);
        }

        if (jalali.year == currentJalali.year &&
            jalali.month == currentJalali.month) {
          currentMonthIncome += amount;
        }

        if (jalali.year == previousJalali.year &&
            jalali.month == previousJalali.month) {
          previousMonthIncome += amount;
        }
      }

      /*
       * دسته درآمد
       */
      final category = row['income_categories'];

      if (category is Map) {
        final id = category['id']?.toString();

        final name = category['name']?.toString().trim();

        if (id != null && id.isNotEmpty) {
          incomeCategoryNames[id] =
              (name == null || name.isEmpty) ? 'بدون دسته‌بندی' : name;

          incomeCategoryTotals[id] = (incomeCategoryTotals[id] ?? 0) + amount;
        }
      }
    }

    /*
     * هزینه‌ها
     */
    for (final row in expenseRows) {
      final amount = _num(row['amount']);

      totalExpense += amount;

      final type =
          row['expense_type']?.toString().trim().toLowerCase() ?? 'operational';

      if (type == 'operational') {
        operationalExpense += amount;
      } else {
        nonOperationalExpense += amount;
      }

      final date = _parseDate(row['expense_date']);

      if (date != null) {
        final jalali = Jalali.fromDateTime(date);

        final key = '${jalali.year}-${jalali.month}';

        if (monthly.containsKey(key)) {
          final old = monthly[key]!;

          monthly[key] = old.copyWith(expense: old.expense + amount);
        }

        if (jalali.year == currentJalali.year &&
            jalali.month == currentJalali.month) {
          currentMonthExpense += amount;
        }

        if (jalali.year == previousJalali.year &&
            jalali.month == previousJalali.month) {
          previousMonthExpense += amount;
        }
      }

      /*
       * دسته هزینه
       */
      final category = row['expense_categories'];

      if (category is Map) {
        final id = category['id']?.toString();

        final name = category['name']?.toString().trim();

        if (id != null && id.isNotEmpty) {
          expenseCategoryNames[id] =
              (name == null || name.isEmpty) ? 'بدون دسته‌بندی' : name;

          expenseCategoryTotals[id] = (expenseCategoryTotals[id] ?? 0) + amount;
        }
      }
    }

    /*
     * موجودی بانک
     */
    for (final row in bankRows) {
      liquidity += _num(row['closing_balance']);
    }

    /*
     * موجودی صندوق
     */
    for (final row in cashRows) {
      liquidity += _num(row['closing_balance']);
    }

    /*
     * موجودی تنخواه
     */
    for (final row in pettyRows) {
      liquidity += _num(row['closing_balance']);
    }

    /*
     * وام‌ها
     */
    for (final row in loanRows) {
      loans += _num(row['remaining_amount']);
    }

    /*
     * چک‌های دریافتی باز
     */
    for (final row in receivedCheckRows) {
      final status = row['status']?.toString().trim().toLowerCase();

      if (status != 'cancelled' && status != 'cleared') {
        receivedChecks += _num(row['amount']);
      }
    }

    /*
     * چک‌های پرداختی باز
     */
    for (final row in paidCheckRows) {
      final status = row['status']?.toString().trim().toLowerCase();

      if (status != 'cancelled' && status != 'cleared') {
        paidChecks += _num(row['amount']);
      }
    }

    /*
     * کارکنان فعال
     */
    for (final row in employeeRows) {
      final status = row['status']?.toString().trim().toLowerCase();

      if (status == 'active') {
        activeEmployees++;
      }
    }

    /*
     * هزینه پرسنلی ماه جاری
     *
     * gross_salary
     * +
     * employer_insurance
     */
    final currentPayrollKey = '${currentJalali.year}-${currentJalali.month}';

    for (final row in payrollRows) {
      final period = row['payroll_periods'];

      if (period is! Map) {
        continue;
      }

      final year = int.tryParse(period['period_year']?.toString() ?? '') ?? 0;

      final month = int.tryParse(period['period_month']?.toString() ?? '') ?? 0;

      final payrollKey = '$year-$month';

      if (payrollKey == currentPayrollKey) {
        personnelCost += _num(row['gross_salary']);

        personnelCost += _num(row['employer_insurance']);
      }
    }

    /*
     * سود / زیان
     */
    final profit = totalIncome - totalExpense;

    /*
     * حاشیه سود
     */
    final profitMargin = totalIncome <= 0 ? 0.0 : (profit / totalIncome) * 100;

    /*
     * تکمیل سود ماهانه
     */
    final monthlyData =
        monthly.values.map((item) {
          return item.copyWith(profit: item.income - item.expense);
        }).toList();

    /*
     * دسته‌بندی درآمد
     */
    final incomeCategories =
        incomeCategoryTotals.entries
            .map(
              (entry) => FinancialCategoryData(
                id: entry.key,
                name: incomeCategoryNames[entry.key] ?? 'بدون دسته‌بندی',
                amount: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    /*
     * دسته‌بندی هزینه
     */
    final expenseCategories =
        expenseCategoryTotals.entries
            .map(
              (entry) => FinancialCategoryData(
                id: entry.key,
                name: expenseCategoryNames[entry.key] ?? 'بدون دسته‌بندی',
                amount: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    return FinancialAnalysisData(
      totalIncome: totalIncome,
      receivedIncome: receivedIncome,
      pendingIncome: pendingIncome,

      totalExpense: totalExpense,
      operationalExpense: operationalExpense,
      nonOperationalExpense: nonOperationalExpense,

      profit: profit,
      profitMargin: profitMargin,

      liquidity: liquidity,
      loans: loans,

      receivedChecks: receivedChecks,
      paidChecks: paidChecks,

      activeEmployees: activeEmployees,
      personnelCost: personnelCost,

      monthlyData: monthlyData,

      incomeCategories: incomeCategories,

      expenseCategories: expenseCategories,

      currentMonthIncome: currentMonthIncome,

      previousMonthIncome: previousMonthIncome,

      currentMonthExpense: currentMonthExpense,

      previousMonthExpense: previousMonthExpense,
    );
  }

  /*
   * رشد درآمد نسبت به ماه قبل
   */
  double get incomeGrowth {
    if (previousMonthIncome == 0) {
      if (currentMonthIncome > 0) {
        return 100;
      }

      return 0;
    }

    return ((currentMonthIncome - previousMonthIncome) / previousMonthIncome) *
        100;
  }

  /*
   * رشد هزینه نسبت به ماه قبل
   */
  double get expenseGrowth {
    if (previousMonthExpense == 0) {
      if (currentMonthExpense > 0) {
        return 100;
      }

      return 0;
    }

    return ((currentMonthExpense - previousMonthExpense) /
            previousMonthExpense) *
        100;
  }

  /*
   * نسبت هزینه به درآمد
   */
  double get expenseToIncome {
    if (totalIncome <= 0) {
      return 0;
    }

    return (totalExpense / totalIncome) * 100;
  }

  /*
   * وضعیت مالی
   */
  String get financialStatus {
    if (totalIncome == 0 && totalExpense == 0) {
      return 'اطلاعات کافی وجود ندارد';
    }

    if (profit > 0) {
      return 'وضعیت سودده';
    }

    if (profit < 0) {
      return 'وضعیت زیان‌ده';
    }

    return 'نقطه سربه‌سر';
  }

  /*
   * تبدیل عدد به double
   */
  static double _num(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return 0;
    }

    return double.tryParse(text) ?? 0;
  }

  /*
   * تبدیل تاریخ
   */
  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  /*
   * کم کردن ماه شمسی
   */
  static Jalali _subtractMonths(Jalali date, int count) {
    var year = date.year;
    var month = date.month - count;

    while (month <= 0) {
      month += 12;
      year--;
    }

    return Jalali(year, month, 1);
  }

  /*
   * نام ماه شمسی
   */
  static String _monthName(int month) {
    const names = [
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

    return names[month - 1];
  }
}

class FinancialMonthData {
  final int year;
  final int month;
  final String label;

  final double income;
  final double expense;
  final double profit;

  const FinancialMonthData({
    required this.year,
    required this.month,
    required this.label,
    required this.income,
    required this.expense,
    required this.profit,
  });

  FinancialMonthData copyWith({
    double? income,
    double? expense,
    double? profit,
  }) {
    return FinancialMonthData(
      year: year,
      month: month,
      label: label,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      profit: profit ?? this.profit,
    );
  }
}

class FinancialCategoryData {
  final String id;
  final String name;
  final double amount;

  const FinancialCategoryData({
    required this.id,
    required this.name,
    required this.amount,
  });

  double percentage(double total) {
    if (total <= 0) {
      return 0;
    }

    return (amount / total) * 100;
  }
}
