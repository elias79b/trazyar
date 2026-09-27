import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantFiscalPeriodsProvider =
    FutureProvider.family<AccountantFiscalPeriodsData, String>((
      ref,
      companyId,
    ) async {
      return AccountantFiscalPeriodsRepository.fetch(companyId);
    });

class AccountantFiscalYear {
  final String id;
  final String companyId;
  final int year;
  final String? title;
  final String status;
  final DateTime? createdAt;

  const AccountantFiscalYear({
    required this.id,
    required this.companyId,
    required this.year,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  factory AccountantFiscalYear.fromMap(Map<String, dynamic> map) {
    return AccountantFiscalYear(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      year: _toInt(map['year']),
      title: map['title']?.toString(),
      status: map['status']?.toString() ?? 'open',
      createdAt:
          map['created_at'] == null
              ? null
              : DateTime.tryParse(map['created_at'].toString()),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool get isOpen => status == 'open';
}

class AccountantFiscalPeriod {
  final String id;
  final String fiscalYearId;
  final String companyId;
  final int year;
  final int month;
  final String? title;
  final String status;
  final DateTime? createdAt;

  const AccountantFiscalPeriod({
    required this.id,
    required this.fiscalYearId,
    required this.companyId,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  factory AccountantFiscalPeriod.fromMap(Map<String, dynamic> map) {
    return AccountantFiscalPeriod(
      id: map['id']?.toString() ?? '',
      fiscalYearId: map['fiscal_year_id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      year: _toInt(map['year']),
      month: _toInt(map['month']),
      title: map['title']?.toString(),
      status: map['status']?.toString() ?? 'open',
      createdAt:
          map['created_at'] == null
              ? null
              : DateTime.tryParse(map['created_at'].toString()),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool get isOpen => status == 'open';

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

class AccountantFiscalPeriodsData {
  final List<AccountantFiscalYear> years;
  final List<AccountantFiscalPeriod> periods;

  const AccountantFiscalPeriodsData({
    required this.years,
    required this.periods,
  });

  List<AccountantFiscalPeriod> periodsForYear(String yearId) {
    return periods.where((period) => period.fiscalYearId == yearId).toList()
      ..sort((a, b) => a.month.compareTo(b.month));
  }
}

class AccountantFiscalPeriodsRepository {
  AccountantFiscalPeriodsRepository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<AccountantFiscalPeriodsData> fetch(String companyId) async {
    final yearsResponse = await _supabase
        .from('cash_fiscal_years')
        .select('id, company_id, year, title, status, created_at')
        .eq('company_id', companyId)
        .order('year', ascending: false);

    final periodsResponse = await _supabase
        .from('cash_fiscal_periods')
        .select(
          'id, fiscal_year_id, company_id, year, month, title, status, created_at',
        )
        .eq('company_id', companyId)
        .order('year', ascending: false)
        .order('month', ascending: true);

    final years =
        (yearsResponse as List)
            .map(
              (row) => AccountantFiscalYear.fromMap(
                Map<String, dynamic>.from(row as Map),
              ),
            )
            .toList();

    final periods =
        (periodsResponse as List)
            .map(
              (row) => AccountantFiscalPeriod.fromMap(
                Map<String, dynamic>.from(row as Map),
              ),
            )
            .toList();

    return AccountantFiscalPeriodsData(years: years, periods: periods);
  }

  static Future<void> createYear({
    required String companyId,
    required int year,
    String? title,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    final yearResponse =
        await _supabase
            .from('cash_fiscal_years')
            .insert({
              'company_id': companyId,
              'year': year,
              'title': title?.trim().isEmpty == true ? null : title?.trim(),
              'status': 'open',
              'created_by': user.id,
            })
            .select('id')
            .single();

    final fiscalYearId = yearResponse['id'].toString();

    final periods = List.generate(12, (index) {
      final month = index + 1;

      return {
        'fiscal_year_id': fiscalYearId,
        'company_id': companyId,
        'year': year,
        'month': month,
        'title': _monthName(month),
        'status': 'open',
      };
    });

    await _supabase.from('cash_fiscal_periods').insert(periods);
  }

  static Future<void> createMissingPeriods({
    required String companyId,
    required AccountantFiscalYear fiscalYear,
  }) async {
    final existing = await _supabase
        .from('cash_fiscal_periods')
        .select('month')
        .eq('company_id', companyId)
        .eq('fiscal_year_id', fiscalYear.id);

    final existingMonths =
        (existing as List)
            .map((row) => int.tryParse(row['month'].toString()))
            .whereType<int>()
            .toSet();

    final missing = <Map<String, dynamic>>[];

    for (int month = 1; month <= 12; month++) {
      if (existingMonths.contains(month)) {
        continue;
      }

      missing.add({
        'fiscal_year_id': fiscalYear.id,
        'company_id': companyId,
        'year': fiscalYear.year,
        'month': month,
        'title': _monthName(month),
        'status': 'open',
      });
    }

    if (missing.isEmpty) {
      return;
    }

    await _supabase.from('cash_fiscal_periods').insert(missing);
  }

  static Future<void> setPeriodStatus({
    required String periodId,
    required String status,
  }) async {
    if (status != 'open' && status != 'closed') {
      throw Exception('وضعیت دوره نامعتبر است.');
    }

    await _supabase
        .from('cash_fiscal_periods')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', periodId);
  }

  static Future<void> setYearStatus({
    required String yearId,
    required String status,
  }) async {
    if (status != 'open' && status != 'closed') {
      throw Exception('وضعیت سال مالی نامعتبر است.');
    }

    await _supabase
        .from('cash_fiscal_years')
        .update({
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', yearId);
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
}
