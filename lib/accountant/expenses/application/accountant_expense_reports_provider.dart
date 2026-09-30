import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantExpenseReportsProvider = FutureProvider.autoDispose
    .family<AccountantExpenseReportsData, String>((ref, companyId) async {
      final repository = AccountantExpenseReportsRepository(
        Supabase.instance.client,
      );

      return repository.load(companyId);
    });

class AccountantExpenseReportsRepository {
  final SupabaseClient supabase;

  AccountantExpenseReportsRepository(this.supabase);

  Future<AccountantExpenseReportsData> load(String companyId) async {
    final yearsResponse = await supabase
        .from('expense_fiscal_years')
        .select('id, company_id, year, title, status')
        .eq('company_id', companyId)
        .order('year', ascending: false);

    final periodsResponse = await supabase
        .from('expense_fiscal_periods')
        .select('id, fiscal_year_id, company_id, year, month, title, status')
        .eq('company_id', companyId)
        .order('year', ascending: false)
        .order('month', ascending: false);

    final categoriesResponse = await supabase
        .from('expense_categories')
        .select('id, company_id, name, code, expense_type, is_active')
        .eq('company_id', companyId)
        .order('name');

    final recognitionsResponse = await supabase
        .from('expense_recognitions')
        .select(
          'id, company_id, fiscal_period_id, category_id, amount, description',
        )
        .eq('company_id', companyId);

    final payablePeriodsResponse = await supabase
        .from('payable_fiscal_periods')
        .select('id, company_id, fiscal_year_id, year, month, title, status')
        .eq('company_id', companyId)
        .order('year', ascending: false)
        .order('month', ascending: false);

    final payablesResponse = await supabase
        .from('payables')
        .select(
          'id, company_id, fiscal_period_id, creditor_name, title, amount, due_date, reference_number, description, status',
        )
        .eq('company_id', companyId);

    final years =
        (yearsResponse as List)
            .map(
              (row) => AccountantExpenseReportFiscalYear.fromMap(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();

    final periods =
        (periodsResponse as List)
            .map(
              (row) => AccountantExpenseReportFiscalPeriod.fromMap(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();

    final categories =
        (categoriesResponse as List)
            .map(
              (row) => AccountantExpenseReportCategory.fromMap(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();

    final recognitions =
        (recognitionsResponse as List)
            .map(
              (row) => AccountantExpenseReportRecognition.fromMap(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();

    final payablePeriods =
        (payablePeriodsResponse as List)
            .map(
              (row) => AccountantExpenseReportPayablePeriod.fromMap(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();

    final payables =
        (payablesResponse as List)
            .map(
              (row) => AccountantExpenseReportPayable.fromMap(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();

    return AccountantExpenseReportsData(
      years: years,
      periods: periods,
      categories: categories,
      recognitions: recognitions,
      payablePeriods: payablePeriods,
      payables: payables,
    );
  }
}

class AccountantExpenseReportsData {
  final List<AccountantExpenseReportFiscalYear> years;
  final List<AccountantExpenseReportFiscalPeriod> periods;
  final List<AccountantExpenseReportCategory> categories;
  final List<AccountantExpenseReportRecognition> recognitions;
  final List<AccountantExpenseReportPayablePeriod> payablePeriods;
  final List<AccountantExpenseReportPayable> payables;

  const AccountantExpenseReportsData({
    required this.years,
    required this.periods,
    required this.categories,
    required this.recognitions,
    required this.payablePeriods,
    required this.payables,
  });

  List<AccountantExpenseReportFiscalYear> get openYears {
    return years.where((item) => item.status == 'open').toList();
  }

  AccountantExpenseReportFiscalPeriod? periodById(String id) {
    for (final period in periods) {
      if (period.id == id) {
        return period;
      }
    }

    return null;
  }

  AccountantExpenseReportFiscalPeriod? periodByYearMonth(int year, int month) {
    for (final period in periods) {
      if (period.year == year && period.month == month) {
        return period;
      }
    }

    return null;
  }

  List<AccountantExpenseReportRecognition> recognitionsForPeriod(
    String periodId,
  ) {
    return recognitions
        .where((item) => item.fiscalPeriodId == periodId)
        .toList();
  }

  List<AccountantExpenseReportPayable> payablesForPeriod(String periodId) {
    return payables.where((item) => item.fiscalPeriodId == periodId).toList();
  }

  double totalForPeriod(String periodId) {
    double total = 0;

    for (final recognition in recognitions) {
      if (recognition.fiscalPeriodId == periodId) {
        total += recognition.amount;
      }
    }

    return total;
  }

  double operationalTotalForPeriod(String periodId) {
    final categoryMap = <String, AccountantExpenseReportCategory>{
      for (final category in categories) category.id: category,
    };

    double total = 0;

    for (final recognition in recognitions) {
      if (recognition.fiscalPeriodId != periodId) {
        continue;
      }

      final category = categoryMap[recognition.categoryId];

      if (category == null) {
        continue;
      }

      if (category.expenseType == 'operational') {
        total += recognition.amount;
      }
    }

    return total;
  }

  double nonOperationalTotalForPeriod(String periodId) {
    final categoryMap = <String, AccountantExpenseReportCategory>{
      for (final category in categories) category.id: category,
    };

    double total = 0;

    for (final recognition in recognitions) {
      if (recognition.fiscalPeriodId != periodId) {
        continue;
      }

      final category = categoryMap[recognition.categoryId];

      if (category == null) {
        continue;
      }

      if (category.expenseType == 'non_operational') {
        total += recognition.amount;
      }
    }

    return total;
  }

  double categoryTotalForPeriod(String periodId, String categoryId) {
    double total = 0;

    for (final recognition in recognitions) {
      if (recognition.fiscalPeriodId == periodId &&
          recognition.categoryId == categoryId) {
        total += recognition.amount;
      }
    }

    return total;
  }

  List<AccountantExpenseReportCategoryBreakdown> categoryBreakdownForPeriod(
    String periodId,
  ) {
    final total = totalForPeriod(periodId);

    final result = <AccountantExpenseReportCategoryBreakdown>[];

    for (final category in categories) {
      if (!category.isActive) {
        continue;
      }

      final amount = categoryTotalForPeriod(periodId, category.id);

      if (amount <= 0) {
        continue;
      }

      final percentage = total <= 0 ? 0.0 : (amount / total) * 100;

      result.add(
        AccountantExpenseReportCategoryBreakdown(
          categoryId: category.id,
          categoryName: category.name,
          categoryCode: category.code,
          expenseType: category.expenseType,
          amount: amount,
          percentage: percentage,
        ),
      );
    }

    result.sort((a, b) => b.amount.compareTo(a.amount));

    return result;
  }

  List<AccountantExpenseReportMonthlyPoint> monthlyTrendForYear(int year) {
    final result = <AccountantExpenseReportMonthlyPoint>[];

    for (int month = 1; month <= 12; month++) {
      final period = periodByYearMonth(year, month);

      final amount = period == null ? 0.0 : totalForPeriod(period.id);

      result.add(
        AccountantExpenseReportMonthlyPoint(
          year: year,
          month: month,
          amount: amount,
        ),
      );
    }

    return result;
  }

  List<AccountantExpenseReportQuarterPoint> quarterlyTrendForYear(int year) {
    final result = <AccountantExpenseReportQuarterPoint>[];

    for (int quarter = 1; quarter <= 4; quarter++) {
      double total = 0;

      final startMonth = ((quarter - 1) * 3) + 1;

      final endMonth = startMonth + 2;

      for (int month = startMonth; month <= endMonth; month++) {
        final period = periodByYearMonth(year, month);

        if (period != null) {
          total += totalForPeriod(period.id);
        }
      }

      result.add(
        AccountantExpenseReportQuarterPoint(
          year: year,
          quarter: quarter,
          amount: total,
        ),
      );
    }

    return result;
  }

  double payableTotal() {
    double total = 0;

    for (final payable in payables) {
      total += payable.amount;
    }

    return total;
  }

  double payablePendingTotal() {
    double total = 0;

    for (final payable in payables) {
      if (payable.status == 'pending') {
        total += payable.amount;
      }
    }

    return total;
  }

  double payablePaidTotal() {
    double total = 0;

    for (final payable in payables) {
      if (payable.status == 'paid') {
        total += payable.amount;
      }
    }

    return total;
  }

  double payableCancelledTotal() {
    double total = 0;

    for (final payable in payables) {
      if (payable.status == 'cancelled') {
        total += payable.amount;
      }
    }

    return total;
  }

  List<AccountantExpenseReportPayable> get pendingPayables {
    return payables.where((item) => item.status == 'pending').toList();
  }

  List<AccountantExpenseReportPayable> get overduePayables {
    final today = DateTime.now();

    return payables.where((payable) {
      if (payable.status != 'pending') {
        return false;
      }

      final dueDate = payable.parsedDueDate;

      if (dueDate == null) {
        return false;
      }

      return dueDate.isBefore(DateTime(today.year, today.month, today.day));
    }).toList();
  }
}

class AccountantExpenseReportFiscalYear {
  final String id;
  final String companyId;
  final int year;
  final String? title;
  final String status;

  const AccountantExpenseReportFiscalYear({
    required this.id,
    required this.companyId,
    required this.year,
    required this.title,
    required this.status,
  });

  factory AccountantExpenseReportFiscalYear.fromMap(Map<String, dynamic> map) {
    return AccountantExpenseReportFiscalYear(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      year: _toInt(map['year']),
      title: map['title']?.toString(),
      status: map['status']?.toString() ?? 'open',
    );
  }
}

class AccountantExpenseReportFiscalPeriod {
  final String id;
  final String fiscalYearId;
  final String companyId;
  final int year;
  final int month;
  final String? title;
  final String status;

  const AccountantExpenseReportFiscalPeriod({
    required this.id,
    required this.fiscalYearId,
    required this.companyId,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
  });

  factory AccountantExpenseReportFiscalPeriod.fromMap(
    Map<String, dynamic> map,
  ) {
    return AccountantExpenseReportFiscalPeriod(
      id: map['id']?.toString() ?? '',
      fiscalYearId: map['fiscal_year_id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      year: _toInt(map['year']),
      month: _toInt(map['month']),
      title: map['title']?.toString(),
      status: map['status']?.toString() ?? 'open',
    );
  }

  String get monthTitle {
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
      return 'ماه $month';
    }

    return months[month - 1];
  }

  String get displayTitle {
    final customTitle = title?.trim();

    if (customTitle != null && customTitle.isNotEmpty) {
      return customTitle;
    }

    return '$monthTitle $year';
  }
}

class AccountantExpenseReportCategory {
  final String id;
  final String companyId;
  final String name;
  final String? code;
  final String expenseType;
  final bool isActive;

  const AccountantExpenseReportCategory({
    required this.id,
    required this.companyId,
    required this.name,
    required this.code,
    required this.expenseType,
    required this.isActive,
  });

  factory AccountantExpenseReportCategory.fromMap(Map<String, dynamic> map) {
    return AccountantExpenseReportCategory(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'بدون عنوان',
      code: map['code']?.toString(),
      expenseType: map['expense_type']?.toString() ?? 'operational',
      isActive: map['is_active'] == true,
    );
  }

  String get expenseTypeTitle {
    if (expenseType == 'non_operational') {
      return 'غیرعملیاتی';
    }

    return 'عملیاتی';
  }
}

class AccountantExpenseReportRecognition {
  final String id;
  final String companyId;
  final String fiscalPeriodId;
  final String categoryId;
  final double amount;
  final String? description;

  const AccountantExpenseReportRecognition({
    required this.id,
    required this.companyId,
    required this.fiscalPeriodId,
    required this.categoryId,
    required this.amount,
    required this.description,
  });

  factory AccountantExpenseReportRecognition.fromMap(Map<String, dynamic> map) {
    return AccountantExpenseReportRecognition(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      fiscalPeriodId: map['fiscal_period_id']?.toString() ?? '',
      categoryId: map['category_id']?.toString() ?? '',
      amount: _toDouble(map['amount']),
      description: map['description']?.toString(),
    );
  }
}

class AccountantExpenseReportCategoryBreakdown {
  final String categoryId;
  final String categoryName;
  final String? categoryCode;
  final String expenseType;
  final double amount;
  final double percentage;

  const AccountantExpenseReportCategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.categoryCode,
    required this.expenseType,
    required this.amount,
    required this.percentage,
  });

  String get expenseTypeTitle {
    if (expenseType == 'non_operational') {
      return 'غیرعملیاتی';
    }

    return 'عملیاتی';
  }
}

class AccountantExpenseReportMonthlyPoint {
  final int year;
  final int month;
  final double amount;

  const AccountantExpenseReportMonthlyPoint({
    required this.year,
    required this.month,
    required this.amount,
  });

  String get monthTitle {
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
      return 'ماه $month';
    }

    return months[month - 1];
  }
}

class AccountantExpenseReportQuarterPoint {
  final int year;
  final int quarter;
  final double amount;

  const AccountantExpenseReportQuarterPoint({
    required this.year,
    required this.quarter,
    required this.amount,
  });

  String get title {
    return 'فصل $quarter';
  }
}

class AccountantExpenseReportPayablePeriod {
  final String id;
  final String companyId;
  final String fiscalYearId;
  final int year;
  final int month;
  final String? title;
  final String status;

  const AccountantExpenseReportPayablePeriod({
    required this.id,
    required this.companyId,
    required this.fiscalYearId,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
  });

  factory AccountantExpenseReportPayablePeriod.fromMap(
    Map<String, dynamic> map,
  ) {
    return AccountantExpenseReportPayablePeriod(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      fiscalYearId: map['fiscal_year_id']?.toString() ?? '',
      year: _toInt(map['year']),
      month: _toInt(map['month']),
      title: map['title']?.toString(),
      status: map['status']?.toString() ?? 'open',
    );
  }

  String get monthTitle {
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
      return 'ماه $month';
    }

    return months[month - 1];
  }

  String get displayTitle {
    final customTitle = title?.trim();

    if (customTitle != null && customTitle.isNotEmpty) {
      return customTitle;
    }

    return '$monthTitle $year';
  }
}

class AccountantExpenseReportPayable {
  final String id;
  final String companyId;
  final String fiscalPeriodId;
  final String creditorName;
  final String title;
  final double amount;
  final String? dueDate;
  final String? referenceNumber;
  final String? description;
  final String status;

  const AccountantExpenseReportPayable({
    required this.id,
    required this.companyId,
    required this.fiscalPeriodId,
    required this.creditorName,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.referenceNumber,
    required this.description,
    required this.status,
  });

  factory AccountantExpenseReportPayable.fromMap(Map<String, dynamic> map) {
    return AccountantExpenseReportPayable(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      fiscalPeriodId: map['fiscal_period_id']?.toString() ?? '',
      creditorName: map['creditor_name']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      amount: _toDouble(map['amount']),
      dueDate: map['due_date']?.toString(),
      referenceNumber: map['reference_number']?.toString(),
      description: map['description']?.toString(),
      status: map['status']?.toString() ?? 'pending',
    );
  }

  String get statusTitle {
    switch (status) {
      case 'paid':
        return 'پرداخت شده';

      case 'cancelled':
        return 'لغو شده';

      case 'pending':
      default:
        return 'در انتظار پرداخت';
    }
  }

  DateTime? get parsedDueDate {
    final value = dueDate;

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final parts = value.split('-');

    if (parts.length != 3) {
      return null;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) {
      return null;
    }

    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }
}

double _toDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
