import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantIncomeReportProvider =
FutureProvider.family<AccountantIncomeReportData, String>((ref,
    companyId,) async {
  return AccountantIncomeReportRepository.load(
    companyId: companyId,
  );
});

class AccountantIncomeReportData {
  final String companyId;
  final List<AccountantIncomeReportYear> years;

  const AccountantIncomeReportData({
    required this.companyId,
    required this.years,
  });

  AccountantIncomeReportYear? get latestYear {
    if (years.isEmpty) {
      return null;
    }

    return years.first;
  }

  double get totalIncome {
    return years.fold<double>(
      0,
          (sum, year) => sum + year.totalIncome,
    );
  }

  double get totalOperationalIncome {
    return years.fold<double>(
      0,
          (sum, year) => sum + year.operationalTotal,
    );
  }

  double get totalNonOperationalIncome {
    return years.fold<double>(
      0,
          (sum, year) => sum + year.nonOperationalTotal,
    );
  }

  double get totalReceivables {
    return years.fold<double>(
      0,
          (sum, year) => sum + year.receivablesTotal,
    );
  }

  double get totalReceivedDocuments {
    return years.fold<double>(
      0,
          (sum, year) => sum + year.totalReceivedDocuments,
    );
  }

  double get totalReceivablesRemaining {
    return years.fold<double>(
      0,
          (sum, year) => sum + year.totalReceivablesRemaining,
    );
  }
}

class AccountantIncomeReportYear {
  final String id;
  final String companyId;
  final int year;
  final String title;
  final String status;
  final List<AccountantIncomeReportPeriod> periods;

  const AccountantIncomeReportYear({
    required this.id,
    required this.companyId,
    required this.year,
    required this.title,
    required this.status,
    required this.periods,
  });

  double get operationalTotal {
    return periods.fold<double>(
      0,
          (sum, period) => sum + period.operationalTotal,
    );
  }

  double get nonOperationalTotal {
    return periods.fold<double>(
      0,
          (sum, period) => sum + period.nonOperationalTotal,
    );
  }

  double get totalIncome {
    return periods.fold<double>(
      0,
          (sum, period) => sum + period.totalIncome,
    );
  }

  double get receivablesTotal {
    return periods.fold<double>(
      0,
          (sum, period) => sum + period.receivablesTotal,
    );
  }

  double get totalReceivedDocuments {
    return periods.fold<double>(
      0,
          (sum, period) => sum + period.totalReceivedDocuments,
    );
  }

  double get totalReceivablesRemaining {
    return periods.fold<double>(
      0,
          (sum, period) => sum + period.receivablesRemaining,
    );
  }

  List<AccountantIncomeReportCategory> get categories {
    final grouped = <String, AccountantIncomeReportCategory>{};

    for (final period in periods) {
      for (final category in period.categories) {
        final existing = grouped[category.id];

        if (existing == null) {
          grouped[category.id] = category;
        } else {
          grouped[category.id] = AccountantIncomeReportCategory(
            id: existing.id,
            companyId: existing.companyId,
            name: existing.name,
            code: existing.code,
            categoryType: existing.categoryType,
            isSystem: existing.isSystem,
            amount: existing.amount + category.amount,
          );
        }
      }
    }

    final result = grouped.values.toList();

    result.sort(
          (a, b) => b.amount.compareTo(a.amount),
    );

    return result;
  }

  int get completedPeriods {
    return periods.length;
  }

  int get openPeriods {
    return periods
        .where((period) => period.status == 'open')
        .length;
  }

  int get closedPeriods {
    return periods
        .where((period) => period.status == 'closed')
        .length;
  }
}

class AccountantIncomeReportPeriod {
  final String id;
  final String fiscalYearId;
  final String companyId;
  final int year;
  final int month;
  final String title;
  final String status;
  final List<AccountantIncomeReportCategory> categories;
  final List<AccountantIncomeReportReceivable> receivables;

  const AccountantIncomeReportPeriod({
    required this.id,
    required this.fiscalYearId,
    required this.companyId,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
    required this.categories,
    required this.receivables,
  });

  bool get isOpen => status == 'open';

  bool get isClosed => status == 'closed';

  String get monthName {
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

  String get statusTitle {
    switch (status) {
      case 'open':
        return 'باز';

      case 'submitted_to_company_admin':
        return 'در انتظار تأیید مدیرعامل';

      case 'submitted_to_consultant':
        return 'در انتظار تأیید مشاور';

      case 'approved':
        return 'تأیید نهایی شده';

      case 'closed':
        return 'بسته';

      default:
        return status;
    }
  }

  double get operationalTotal {
    return categories
        .where((category) => category.isOperational)
        .fold<double>(
      0,
          (sum, category) => sum + category.amount,
    );
  }

  double get nonOperationalTotal {
    return categories
        .where((category) => !category.isOperational)
        .fold<double>(
      0,
          (sum, category) => sum + category.amount,
    );
  }

  double get totalIncome {
    return operationalTotal + nonOperationalTotal;
  }

  double get receivablesTotal {
    return receivables.fold<double>(
      0,
          (sum, item) => sum + item.amount,
    );
  }

  double get totalReceivedDocuments {
    return receivables.fold<double>(
      0,
          (sum, item) => sum + item.receivedDocumentsAmount,
    );
  }

  double get receivablesRemaining {
    return receivables.fold<double>(
      0,
          (sum, item) => sum + item.remainingAmount,
    );
  }

  AccountantIncomeReportCategory? categoryById(String categoryId,) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category;
      }
    }

    return null;
  }
}

class AccountantIncomeReportCategory {
  final String id;
  final String companyId;
  final String name;
  final String? code;
  final String categoryType;
  final bool isSystem;
  final double amount;

  const AccountantIncomeReportCategory({
    required this.id,
    required this.companyId,
    required this.name,
    required this.code,
    required this.categoryType,
    required this.isSystem,
    required this.amount,
  });

  bool get isOperational {
    return categoryType == 'operational';
  }

  bool get isNonOperational {
    return categoryType == 'non_operational';
  }

  String get typeTitle {
    if (isOperational) {
      return 'درآمد عملیاتی';
    }

    return 'درآمد غیرعملیاتی';
  }

  double get sharePercent {
    return 0;
  }
}

class AccountantIncomeReportReceivable {
  final String id;
  final String fiscalPeriodId;
  final String title;
  final double amount;
  final double receivedDocumentsAmount;
  final String? description;

  const AccountantIncomeReportReceivable({
    required this.id,
    required this.fiscalPeriodId,
    required this.title,
    required this.amount,
    required this.receivedDocumentsAmount,
    required this.description,
  });

  double get remainingAmount {
    final remaining = amount - receivedDocumentsAmount;

    if (remaining < 0) {
      return 0;
    }

    return remaining;
  }
}

class AccountantIncomeReportRepository {
  AccountantIncomeReportRepository._();

  static final SupabaseClient _client =
      Supabase.instance.client;

  static Future<AccountantIncomeReportData> load({
    required String companyId,
  }) async {
    final yearsResponse = await _client
        .from('income_fiscal_years')
        .select(
      'id, company_id, year, title, status',
    )
        .eq('company_id', companyId)
        .order('year', ascending: false);

    final categoriesResponse = await _client
        .from('income_categories')
        .select(
      'id, company_id, name, code, category_type, is_system',
    )
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order(
      'category_type',
      ascending: true,
    )
        .order(
      'name',
      ascending: true,
    );

    final periodsResponse = await _client
        .from('income_fiscal_periods')
        .select(
      'id, fiscal_year_id, company_id, '
          'year, month, title, status',
    )
        .eq('company_id', companyId)
        .order(
      'year',
      ascending: false,
    )
        .order(
      'month',
      ascending: true,
    );

    final recognitionsResponse = await _client
        .from('income_recognitions')
        .select(
      'id, company_id, fiscal_period_id, '
          'category_id, amount',
    )
        .eq('company_id', companyId);

    final receivablePeriodsResponse = await _client
        .from('income_receivable_fiscal_periods')
        .select(
      'id, company_id, year, month',
    )
        .eq('company_id', companyId);

    final receivablesResponse = await _client
        .from('income_receivables')
        .select(
      'id, fiscal_period_id, title, amount, '
          'received_documents_amount, description',
    )
        .eq('company_id', companyId);

    final categories =
    <String, AccountantIncomeReportCategory>{};

    for (final rawRow in categoriesResponse as List) {
      final row = Map<String, dynamic>.from(rawRow);

      final id = row['id']?.toString() ?? '';

      if (id.isEmpty) {
        continue;
      }

      categories[id] =
          AccountantIncomeReportCategory(
            id: id,
            companyId:
            row['company_id']?.toString() ??
                companyId,
            name: row['name']?.toString() ?? '',
            code: row['code']?.toString(),
            categoryType:
            row['category_type']?.toString() ??
                'operational',
            isSystem: row['is_system'] == true,
            amount: 0,
          );
    }

    final recognitionsByPeriod =
    <String, List<Map<String, dynamic>>>{};

    for (final rawRow
    in recognitionsResponse as List) {
      final row = Map<String, dynamic>.from(rawRow);

      final periodId =
          row['fiscal_period_id']?.toString() ?? '';

      if (periodId.isEmpty) {
        continue;
      }

      recognitionsByPeriod
          .putIfAbsent(
        periodId,
            () => [],
      )
          .add(row);
    }

    /*
     * مطالبات مستقل از سال مالی درآمد هستند.
     * فقط برای گزارش، سال و ماه مشترک به عنوان
     * محور نمایش استفاده می‌شود.
     *
     * اینجا دیگر برای هر مطالبه Query جداگانه
     * اجرا نمی‌شود.
     */
    final receivablePeriodInfo =
    <String, _ReceivablePeriodInfo>{};

    for (final rawRow
    in receivablePeriodsResponse as List) {
      final row = Map<String, dynamic>.from(rawRow);

      final id = row['id']?.toString() ?? '';

      if (id.isEmpty) {
        continue;
      }

      receivablePeriodInfo[id] =
          _ReceivablePeriodInfo(
            year: _toInt(row['year']),
            month: _toInt(row['month']),
          );
    }

    final receivablesByYearMonth =
    <String,
        List<AccountantIncomeReportReceivable>>{};

    for (final rawRow
    in receivablesResponse as List) {
      final row = Map<String, dynamic>.from(rawRow);

      final periodId =
          row['fiscal_period_id']?.toString() ?? '';

      if (periodId.isEmpty) {
        continue;
      }

      final periodInfo =
      receivablePeriodInfo[periodId];

      if (periodInfo == null) {
        continue;
      }

      final key =
          '${periodInfo.year}-${periodInfo.month}';

      receivablesByYearMonth
          .putIfAbsent(
        key,
            () => [],
      )
          .add(
        AccountantIncomeReportReceivable(
          id: row['id']?.toString() ?? '',
          fiscalPeriodId: periodId,
          title:
          row['title']?.toString() ?? '',
          amount:
          _toDouble(row['amount']),
          receivedDocumentsAmount:
          _toDouble(
            row[
            'received_documents_amount'],
          ),
          description:
          row['description']?.toString(),
        ),
      );
    }

    final periodsByYearId =
    <String,
        List<AccountantIncomeReportPeriod>>{};

    for (final rawYear
    in yearsResponse as List) {
      final yearRow =
      Map<String, dynamic>.from(rawYear);

      final yearId =
          yearRow['id']?.toString() ?? '';

      if (yearId.isEmpty) {
        continue;
      }

      periodsByYearId[yearId] = [];
    }

    for (final rawPeriod
    in periodsResponse as List) {
      final periodRow =
      Map<String, dynamic>.from(rawPeriod);

      final periodId =
          periodRow['id']?.toString() ?? '';

      final yearId =
          periodRow['fiscal_year_id']
              ?.toString() ??
              '';

      if (periodId.isEmpty ||
          yearId.isEmpty) {
        continue;
      }

      final recognitionRows =
          recognitionsByPeriod[periodId] ??
              [];

      final categoryAmounts =
      <String, double>{};

      for (final recognition
      in recognitionRows) {
        final categoryId =
            recognition['category_id']
                ?.toString() ??
                '';

        if (categoryId.isEmpty) {
          continue;
        }

        categoryAmounts[categoryId] =
            (categoryAmounts[categoryId] ??
                0) +
                _toDouble(
                  recognition['amount'],
                );
      }

      final periodCategories =
      <AccountantIncomeReportCategory>[];

      for (final entry
      in categoryAmounts.entries) {
        final category =
        categories[entry.key];

        if (category == null) {
          continue;
        }

        periodCategories.add(
          AccountantIncomeReportCategory(
            id: category.id,
            companyId:
            category.companyId,
            name: category.name,
            code: category.code,
            categoryType:
            category.categoryType,
            isSystem:
            category.isSystem,
            amount: entry.value,
          ),
        );
      }

      periodCategories.sort(
            (a, b) =>
            b.amount.compareTo(
              a.amount,
            ),
      );

      final year =
      _toInt(periodRow['year']);

      final month =
      _toInt(periodRow['month']);

      final receivables =
      receivablesByYearMonth[
      '$year-$month'

    ] ??
    [];

    periodsByYearId
        .putIfAbsent(
    yearId,
    () => [],
    )
        .add(
    AccountantIncomeReportPeriod(
    id: periodId,
    fiscalYearId: yearId,
    companyId:
    periodRow['company_id']
        ?.toString() ??
    companyId,
    year: year,
    month: month,
    title:
    periodRow['title']
        ?.toString() ??
    '',
    status:
    periodRow['status']
        ?.toString() ??
    'open',
    categories:
    periodCategories,
    receivables:
    receivables,
    ),
    );
    }

    final years =
    <AccountantIncomeReportYear>[];

    for (final rawYear
    in yearsResponse as List) {
    final yearRow =
    Map<String, dynamic>.from(rawYear);

    final yearId =
    yearRow['id']?.toString() ?? '';

    if (yearId.isEmpty) {
    continue;
    }

    final periods =
    periodsByYearId[yearId] ?? [];

    periods.sort(
    (a, b) =>
    a.month.compareTo(b.month),
    );

    years.add(
    AccountantIncomeReportYear(
    id: yearId,
    companyId:
    yearRow['company_id']
        ?.toString() ??
    companyId,
    year: _toInt(
    yearRow['year'],
    ),
    title:
    yearRow['title']
        ?.toString() ??
    'سال مالی ${yearRow['year']}',
    status:
    yearRow['status']
        ?.toString() ??
    'open',
    periods: periods,
    ),
    );
    }

    years.sort(
    (a, b) => b.year.compareTo(a.year),
    );

    return AccountantIncomeReportData(
    companyId: companyId,
    years
    :
    years
    ,
    );
  }

  static double _toDouble(dynamic value,) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  static int _toInt(dynamic value,) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }
}

class _ReceivablePeriodInfo {
  final int year;
  final int month;

  const _ReceivablePeriodInfo({
    required this.year,
    required this.month,
  });
}