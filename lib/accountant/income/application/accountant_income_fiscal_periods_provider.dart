import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantIncomeFiscalPeriodsProvider =
    FutureProvider.family<AccountantIncomeFiscalPeriodsData, String>((
      ref,
      companyId,
    ) async {
      return AccountantIncomeFiscalPeriodsRepository.fetch(companyId);
    });

class AccountantIncomeFiscalPeriodsData {
  final String companyId;
  final List<AccountantIncomeFiscalYear> years;
  final String? selectedYearId;

  const AccountantIncomeFiscalPeriodsData({
    required this.companyId,
    required this.years,
    required this.selectedYearId,
  });

  AccountantIncomeFiscalYear? get selectedYear {
    if (selectedYearId == null) {
      return years.isEmpty ? null : years.first;
    }

    for (final year in years) {
      if (year.id == selectedYearId) {
        return year;
      }
    }

    return years.isEmpty ? null : years.first;
  }
}

class AccountantIncomeFiscalYear {
  final String id;
  final String companyId;
  final int year;
  final String title;
  final String status;
  final List<AccountantIncomeFiscalPeriod> periods;

  const AccountantIncomeFiscalYear({
    required this.id,
    required this.companyId,
    required this.year,
    required this.title,
    required this.status,
    required this.periods,
  });

  bool get isOpen => status == 'open';

  bool get isClosed => status == 'closed';

  int get completedMonths => periods.length;

  int get missingMonths => 12 - periods.length;

  bool get hasAllMonths => periods.length >= 12;

  int get openPeriods =>
      periods.where((period) => period.status == 'open').length;

  int get closedPeriods =>
      periods.where((period) => period.status == 'closed').length;
}

class AccountantIncomeFiscalPeriod {
  final String id;
  final String fiscalYearId;
  final String companyId;
  final int year;
  final int month;
  final String title;
  final String status;

  const AccountantIncomeFiscalPeriod({
    required this.id,
    required this.fiscalYearId,
    required this.companyId,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
  });

  bool get isOpen => status == 'open';

  bool get isClosed => status == 'closed';

  String get monthName => _monthNames[month.clamp(1, 12) - 1];

  String get statusTitle {
    switch (status) {
      case 'open':
        return 'باز';
      case 'closed':
        return 'بسته';
      default:
        return status;
    }
  }

  static const List<String> _monthNames = [
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
}

class AccountantIncomeFiscalPeriodsRepository {
  AccountantIncomeFiscalPeriodsRepository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<AccountantIncomeFiscalPeriodsData> fetch(
    String companyId,
  ) async {
    final response = await _supabase
        .from('income_fiscal_years')
        .select(
          'id, company_id, year, title, status, '
          'income_fiscal_periods('
          'id, fiscal_year_id, company_id, year, month, title, status'
          ')',
        )
        .eq('company_id', companyId)
        .order('year', ascending: false);

    final years = <AccountantIncomeFiscalYear>[];

    for (final rawRow in response as List) {
      final row = Map<String, dynamic>.from(rawRow);

      final yearId = row['id']?.toString() ?? '';

      if (yearId.isEmpty) {
        continue;
      }

      final rawPeriods = row['income_fiscal_periods'];

      final periods = <AccountantIncomeFiscalPeriod>[];

      if (rawPeriods is List) {
        for (final rawPeriod in rawPeriods) {
          final period = Map<String, dynamic>.from(rawPeriod);

          periods.add(
            AccountantIncomeFiscalPeriod(
              id: period['id']?.toString() ?? '',
              fiscalYearId: period['fiscal_year_id']?.toString() ?? yearId,
              companyId: period['company_id']?.toString() ?? companyId,
              year: _toInt(period['year']),
              month: _toInt(period['month']),
              title: period['title']?.toString() ?? '',
              status: period['status']?.toString() ?? 'open',
            ),
          );
        }
      }

      periods.sort((a, b) => a.month.compareTo(b.month));

      years.add(
        AccountantIncomeFiscalYear(
          id: yearId,
          companyId: row['company_id']?.toString() ?? companyId,
          year: _toInt(row['year']),
          title: row['title']?.toString() ?? 'سال مالی ${row['year']}',
          status: row['status']?.toString() ?? 'open',
          periods: periods,
        ),
      );
    }

    return AccountantIncomeFiscalPeriodsData(
      companyId: companyId,
      years: years,
      selectedYearId: years.isEmpty ? null : years.first.id,
    );
  }

  static Future<void> createFiscalYear({
    required String companyId,
    required int year,
    String? title,
  }) async {
    final existing =
        await _supabase
            .from('income_fiscal_years')
            .select('id, year, title, status')
            .eq('company_id', companyId)
            .eq('year', year)
            .maybeSingle();

    if (existing == null) {
      await _supabase.rpc(
        'create_income_fiscal_year',
        params: {
          'p_company_id': companyId,
          'p_year': year,
          'p_title':
              title?.trim().isEmpty == true ? 'سال مالی $year' : title?.trim(),
        },
      );

      return;
    }

    final fiscalYearId = existing['id']?.toString();

    if (fiscalYearId == null || fiscalYearId.isEmpty) {
      throw Exception('شناسه سال مالی درآمد معتبر نیست.');
    }

    await ensureMissingPeriods(
      companyId: companyId,
      fiscalYearId: fiscalYearId,
      year: year,
    );
  }

  static Future<void> ensureMissingPeriods({
    required String companyId,
    required String fiscalYearId,
    required int year,
  }) async {
    final response = await _supabase
        .from('income_fiscal_periods')
        .select('id, month')
        .eq('company_id', companyId)
        .eq('fiscal_year_id', fiscalYearId);

    final existingMonths = <int>{};

    for (final row in response as List) {
      existingMonths.add(_toInt(row['month']));
    }

    final missing = <Map<String, dynamic>>[];

    for (int month = 1; month <= 12; month++) {
      if (existingMonths.contains(month)) {
        continue;
      }

      missing.add({
        'fiscal_year_id': fiscalYearId,
        'company_id': companyId,
        'year': year,
        'month': month,
        'title': _monthTitle(year, month),
        'status': 'open',
      });
    }

    if (missing.isEmpty) {
      return;
    }

    await _supabase.from('income_fiscal_periods').insert(missing);
  }

  static Future<void> setPeriodStatus({
    required String periodId,
    required String status,
  }) async {
    if (status != 'open' && status != 'closed') {
      throw Exception('وضعیت دوره درآمد معتبر نیست.');
    }

    await _supabase.rpc(
      'set_income_period_status',
      params: {'p_period_id': periodId, 'p_status': status},
    );
  }

  static Future<void> setYearStatus({
    required String yearId,
    required String status,
  }) async {
    if (status != 'open' && status != 'closed') {
      throw Exception('وضعیت سال مالی معتبر نیست.');
    }

    await _supabase
        .from('income_fiscal_years')
        .update({
          'status': status,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', yearId);
  }

  static String _monthTitle(int year, int month) {
    return '${_monthName(month)} $year';
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

    if (month < 1 || month > 12) {
      return 'ماه';
    }

    return months[month - 1];
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
}
