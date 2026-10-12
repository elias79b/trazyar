
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final companyAdminIncomeDashboardProvider =
FutureProvider.autoDispose<CompanyAdminIncomeDashboardData>(
      (ref) async {
    final repository = CompanyAdminIncomeDashboardRepository(
      Supabase.instance.client,
    );
    return repository.load();
  },
);

class CompanyAdminIncomeDashboardRepository {
  final SupabaseClient _supabase;

  CompanyAdminIncomeDashboardRepository(this._supabase);

  Future<String> _resolveCompanyId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    final membership = await _supabase
        .from('company_users')
        .select('company_id')
        .eq('user_id', user.id)
        .eq('role', 'company_admin')
        .eq('is_active', true)
        .limit(1)
        .maybeSingle();

    if (membership == null ||
        membership['company_id'] == null) {
      throw Exception('شرکت فعال برای مدیرعامل پیدا نشد.');
    }

    return membership['company_id'].toString();
  }

  Future<CompanyAdminIncomeDashboardData> load() async {
    final companyId = await _resolveCompanyId();

    final responses = await Future.wait([
      _supabase
          .from('income_fiscal_years')
          .select('id, year, title, status')
          .eq('company_id', companyId)
          .order('year', ascending: false),

      _supabase
          .from('income_categories')
          .select('id, name, category_type, is_active')
          .eq('company_id', companyId),

      _supabase
          .from('income_records')
          .select(
        'id, category_id, title, amount, income_date, status',
      )
          .eq('company_id', companyId)
          .neq('status', 'cancelled')
          .order('income_date'),

      _supabase
          .from('income_fiscal_periods')
          .select('id, fiscal_year_id, year, month, title, status')
          .eq('company_id', companyId)
          .order('year')
          .order('month'),

      _supabase
          .from('income_recognitions')
          .select(
        'id, fiscal_period_id, category_id, amount, description',
      )
          .eq('company_id', companyId),

      _supabase
          .from('income_receivables')
          .select(
        'id, fiscal_period_id, title, amount, received_documents_amount, status',
      )
          .eq('company_id', companyId),
    ]);

    final years = _maps(responses[0]);
    final categories = _maps(responses[1]);
    final records = _maps(responses[2]);
    final periods = _maps(responses[3]);
    final recognitions = _maps(responses[4]);
    final receivables = _maps(responses[5]);

    return CompanyAdminIncomeDashboardData.build(
      companyId: companyId,
      years: years,
      categories: categories,
      records: records,
      periods: periods,
      recognitions: recognitions,
      receivables: receivables,
    );
  }

  static List<Map<String, dynamic>> _maps(dynamic response) {
    return (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}

class CompanyAdminIncomeDashboardData {
  final String companyId;
  final List<IncomeFiscalYearOption> fiscalYears;
  final int? selectedYear;
  final double totalIncome;
  final double previousPeriodIncome;
  final double growthPercent;
  final double operationalIncome;
  final double nonOperationalIncome;
  final double totalReceivables;
  final double receivedDocuments;
  final double outstandingReceivables;
  final List<IncomeMonthlyPoint> monthlyTrend;
  final List<IncomeCategoryPoint> categoryBreakdown;
  final List<IncomeMonthlyPoint> receivablesTrend;

  const CompanyAdminIncomeDashboardData({
    required this.companyId,
    required this.fiscalYears,
    required this.selectedYear,
    required this.totalIncome,
    required this.previousPeriodIncome,
    required this.growthPercent,
    required this.operationalIncome,
    required this.nonOperationalIncome,
    required this.totalReceivables,
    required this.receivedDocuments,
    required this.outstandingReceivables,
    required this.monthlyTrend,
    required this.categoryBreakdown,
    required this.receivablesTrend,
  });

  factory CompanyAdminIncomeDashboardData.build({
    required String companyId,
    required List<Map<String, dynamic>> years,
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> records,
    required List<Map<String, dynamic>> periods,
    required List<Map<String, dynamic>> recognitions,
    required List<Map<String, dynamic>> receivables,
  }) {
    final fiscalYears = years.map(IncomeFiscalYearOption.fromMap).toList();

    final selectedYear = fiscalYears.isEmpty ? null : fiscalYears.first.year;
    final selectedYearRow = fiscalYears.isEmpty ? null : fiscalYears.first;

    final selectedYearId = selectedYearRow?.id;
    final yearPeriods = periods.where(
          (p) => p['fiscal_year_id']?.toString() == selectedYearId,
    ).toList();

    final periodIds = yearPeriods
        .map((p) => p['id']?.toString())
        .whereType<String>()
        .toSet();

    final categoryById = <String, Map<String, dynamic>>{
      for (final category in categories)
        if (category['id'] != null)
          category['id'].toString(): category,
    };

    final yearStart = selectedYear == null
        ? null
        : Jalali(selectedYear, 1, 1).toDateTime();

    final yearEnd = selectedYear == null
        ? null
        : Jalali(selectedYear + 1, 1, 1).toDateTime();

    final yearRecords = records.where((record) {
      final date = DateTime.tryParse(record['income_date']?.toString() ?? '');
      if (date == null || yearStart == null || yearEnd == null) return false;
      return !date.isBefore(yearStart) && date.isBefore(yearEnd);
    }).toList();

    final totalIncome = yearRecords.fold<double>(
      0,
          (sum, record) => sum + _number(record['amount']),
    );

    final monthlyIncome = List<double>.filled(12, 0);

    for (final record in yearRecords) {
      final date = DateTime.tryParse(record['income_date']?.toString() ?? '');
      if (date == null) continue;
      final jalali = Gregorian.fromDateTime(date).toJalali();
      if (jalali.year == selectedYear &&
          jalali.month >= 1 &&
          jalali.month <= 12) {
        monthlyIncome[jalali.month - 1] += _number(record['amount']);
      }
    }

    final monthlyTrend = List.generate(
      12,
          (index) => IncomeMonthlyPoint(
        month: index + 1,
        label: _monthName(index + 1),
        amount: monthlyIncome[index],
      ),
    );

    final categoryTotals = <String, double>{};

    for (final record in yearRecords) {
      final categoryId = record['category_id']?.toString() ?? 'uncategorized';
      categoryTotals[categoryId] =
          (categoryTotals[categoryId] ?? 0) + _number(record['amount']);
    }

    final categoryBreakdown = categoryTotals.entries.map((entry) {
      final category = categoryById[entry.key];
      return IncomeCategoryPoint(
        categoryId: entry.key,
        name: category?['name']?.toString() ?? 'بدون دسته‌بندی',
        categoryType: category?['category_type']?.toString() ?? 'operational',
        amount: entry.value,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    var operationalIncome = 0.0;
    var nonOperationalIncome = 0.0;

    for (final point in categoryBreakdown) {
      if (point.categoryType == 'non_operational') {
        nonOperationalIncome += point.amount;
      } else {
        operationalIncome += point.amount;
      }
    }

    final yearReceivables = receivables.where(
          (r) => periodIds.contains(r['fiscal_period_id']?.toString()),
    );

    var totalReceivables = 0.0;
    var receivedDocuments = 0.0;

    final receivablesByMonth = <int, double>{};
    final documentsByMonth = <int, double>{};
    final periodById = {
      for (final period in yearPeriods)
        period['id'].toString(): period,
    };

    for (final item in yearReceivables) {
      final amount = _number(item['amount']);
      final documents = _number(item['received_documents_amount']);

      totalReceivables += amount;
      receivedDocuments += documents;

      final period = periodById[item['fiscal_period_id']?.toString()];
      final month = _intValue(period?['month']);

      if (month >= 1 && month <= 12) {
        receivablesByMonth[month] =
            (receivablesByMonth[month] ?? 0) + amount;
        documentsByMonth[month] =
            (documentsByMonth[month] ?? 0) + documents;
      }
    }

    final recognitionTotal = recognitions
        .where((r) => periodIds.contains(r['fiscal_period_id']?.toString()))
        .fold<double>(
      0,
          (sum, item) => sum + _number(item['amount']),
    );

    final previousIncome = selectedYear == null
        ? 0.0
        : _previousYearIncome(records, selectedYear - 1);

    final growth = previousIncome == 0
        ? 0.0
        : ((totalIncome - previousIncome) / previousIncome) * 100;

    final receivablesTrend = List.generate(
      12,
          (index) {
        final month = index + 1;
        return IncomeMonthlyPoint(
          month: month,
          label: _monthName(month),
          amount: receivablesByMonth[month] ?? 0,
          secondaryAmount: documentsByMonth[month] ?? 0,
        );
      },
    );

    return CompanyAdminIncomeDashboardData(
      companyId: companyId,
      fiscalYears: fiscalYears,
      selectedYear: selectedYear,
      totalIncome: totalIncome,
      previousPeriodIncome: previousIncome,
      growthPercent: growth,
      operationalIncome: operationalIncome,
      nonOperationalIncome: nonOperationalIncome,
      totalReceivables: totalReceivables,
      receivedDocuments: receivedDocuments,
      outstandingReceivables:
      (totalReceivables - receivedDocuments).clamp(0, double.infinity),
      monthlyTrend: monthlyTrend,
      categoryBreakdown: categoryBreakdown,
      receivablesTrend: receivablesTrend,
    );
  }

  static double _previousYearIncome(
      List<Map<String, dynamic>> records,
      int year,
      ) {
    final start = Jalali(year, 1, 1).toDateTime();
    final end = Jalali(year + 1, 1, 1).toDateTime();

    return records.where((record) {
      final date = DateTime.tryParse(record['income_date']?.toString() ?? '');
      return date != null && !date.isBefore(start) && date.isBefore(end);
    }).fold<double>(
      0,
          (sum, record) => sum + _number(record['amount']),
    );
  }

  static String _monthName(int month) {
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
    return months[month - 1];
  }

  static double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class IncomeFiscalYearOption {
  final String id;
  final int year;
  final String title;
  final String status;

  const IncomeFiscalYearOption({
    required this.id,
    required this.year,
    required this.title,
    required this.status,
  });

  factory IncomeFiscalYearOption.fromMap(Map<String, dynamic> map) {
    return IncomeFiscalYearOption(
      id: map['id'].toString(),
      year: int.tryParse(map['year'].toString()) ?? 0,
      title: map['title']?.toString() ?? '',
      status: map['status']?.toString() ?? 'open',
    );
  }
}

class IncomeMonthlyPoint {
  final int month;
  final String label;
  final double amount;
  final double secondaryAmount;

  const IncomeMonthlyPoint({
    required this.month,
    required this.label,
    required this.amount,
    this.secondaryAmount = 0,
  });
}

class IncomeCategoryPoint {
  final String categoryId;
  final String name;
  final String categoryType;
  final double amount;

  const IncomeCategoryPoint({
    required this.categoryId,
    required this.name,
    required this.categoryType,
    required this.amount,
  });
}
