import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantPayrollPeriodsProvider =
    FutureProvider.family<AccountantPayrollPeriodsData, String>((
      ref,
      companyId,
    ) async {
      return AccountantPayrollPeriodsRepository.load(companyId);
    });

class AccountantPayrollPeriod {
  final String id;
  final String companyId;
  final int year;
  final int month;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final int employeeCount;
  final double totalGrossSalary;
  final double totalDeductions;
  final double totalNetSalary;

  const AccountantPayrollPeriod({
    required this.id,
    required this.companyId,
    required this.year,
    required this.month,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.employeeCount = 0,
    this.totalGrossSalary = 0,
    this.totalDeductions = 0,
    this.totalNetSalary = 0,
  });

  String get normalizedStatus => status.trim().toLowerCase();

  bool get isDraft => normalizedStatus == 'draft';

  bool get isPendingCeo => normalizedStatus == 'pending_ceo';

  bool get isConsultantApproved => normalizedStatus == 'consultant_approved';

  bool get isPaid => normalizedStatus == 'paid';

  bool get canEnterRecords => isDraft;

  bool get canEdit => isDraft;

  bool get canDelete => isDraft;

  bool get canSubmitToCeo => isDraft;

  String get monthTitle => payrollMonthName(month);

  String get title => '$monthTitle $year';

  String get statusTitle => payrollStatusName(status);
}

class AccountantPayrollYear {
  final int year;
  final List<AccountantPayrollPeriod> periods;

  const AccountantPayrollYear({required this.year, required this.periods});

  int get completedMonths =>
      periods.where((period) => period.normalizedStatus != 'draft').length;

  int get draftMonths =>
      periods.where((period) => period.normalizedStatus == 'draft').length;

  int get pendingCeoMonths =>
      periods
          .where((period) => period.normalizedStatus == 'pending_ceo')
          .length;

  int get approvedMonths =>
      periods
          .where((period) => period.normalizedStatus == 'consultant_approved')
          .length;

  int get paidMonths =>
      periods.where((period) => period.normalizedStatus == 'paid').length;
}

class AccountantPayrollPeriodsData {
  final List<AccountantPayrollYear> years;
  final List<AccountantPayrollPeriod> allPeriods;

  const AccountantPayrollPeriodsData({
    required this.years,
    required this.allPeriods,
  });

  AccountantPayrollYear? year(int value) {
    for (final item in years) {
      if (item.year == value) {
        return item;
      }
    }

    return null;
  }
}

class AccountantPayrollPeriodsRepository {
  AccountantPayrollPeriodsRepository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<AccountantPayrollPeriodsData> load(String companyId) async {
    final results = await Future.wait([
      _supabase
          .from('payroll_periods')
          .select(
            'id, company_id, period_year, period_month, status, '
            'notes, created_at, updated_at',
          )
          .eq('company_id', companyId)
          .order('period_year', ascending: false)
          .order('period_month', ascending: true),

      _supabase
          .from('payroll_records')
          .select(
            'payroll_period_id, employee_id, gross_salary, '
            'employee_insurance, tax_amount, absence_amount, '
            'other_deductions, advance_amount, net_salary',
          )
          .eq('company_id', companyId),
    ]);

    final periodRows = List<Map<String, dynamic>>.from(results[0] as List);

    final recordRows = List<Map<String, dynamic>>.from(results[1] as List);

    final stats = <String, _PayrollPeriodStats>{};

    for (final row in recordRows) {
      final periodId = row['payroll_period_id']?.toString();

      if (periodId == null || periodId.isEmpty) {
        continue;
      }

      final stat = stats.putIfAbsent(periodId, _PayrollPeriodStats.new);

      final employeeId = row['employee_id']?.toString();

      if (employeeId != null && employeeId.isNotEmpty) {
        stat.employeeIds.add(employeeId);
      }

      stat.totalGrossSalary += _toDouble(row['gross_salary']);

      stat.totalDeductions +=
          _toDouble(row['employee_insurance']) +
          _toDouble(row['tax_amount']) +
          _toDouble(row['absence_amount']) +
          _toDouble(row['other_deductions']) +
          _toDouble(row['advance_amount']);

      stat.totalNetSalary += _toDouble(row['net_salary']);
    }

    final periods =
        periodRows.map((row) {
          final id = row['id'].toString();
          final stat = stats[id];

          return AccountantPayrollPeriod(
            id: id,
            companyId: row['company_id'].toString(),
            year: _toInt(row['period_year']),
            month: _toInt(row['period_month']),
            status: row['status']?.toString() ?? 'draft',
            notes: row['notes']?.toString(),
            createdAt: _toDateTime(row['created_at']),
            updatedAt: _toDateTime(row['updated_at']),
            employeeCount: stat?.employeeIds.length ?? 0,
            totalGrossSalary: stat?.totalGrossSalary ?? 0,
            totalDeductions: stat?.totalDeductions ?? 0,
            totalNetSalary: stat?.totalNetSalary ?? 0,
          );
        }).toList();

    final grouped = <int, List<AccountantPayrollPeriod>>{};

    for (final period in periods) {
      grouped
          .putIfAbsent(period.year, () => <AccountantPayrollPeriod>[])
          .add(period);
    }

    final years =
        grouped.entries.map((entry) {
          final monthMap = <int, AccountantPayrollPeriod>{
            for (final period in entry.value) period.month: period,
          };

          final sortedPeriods = <AccountantPayrollPeriod>[];

          for (int month = 1; month <= 12; month++) {
            final existing = monthMap[month];

            if (existing != null) {
              sortedPeriods.add(existing);
            }
          }

          return AccountantPayrollYear(year: entry.key, periods: sortedPeriods);
        }).toList();

    years.sort((a, b) => b.year.compareTo(a.year));

    return AccountantPayrollPeriodsData(years: years, allPeriods: periods);
  }

  /// ایجاد یا تکمیل سال مالی.
  ///
  /// اگر سال وجود نداشته باشد:
  /// تمام ۱۲ ماه ایجاد می‌شوند.
  ///
  /// اگر سال از قبل وجود داشته باشد:
  /// فقط ماه‌های ناقص ایجاد می‌شوند
  /// و ماه‌های موجود دست‌نخورده باقی می‌مانند.
  static Future<void> createFiscalYear({
    required String companyId,
    required int year,
    String? notes,
  }) async {
    if (year < 1300 || year > 1600) {
      throw Exception('سال مالی نامعتبر است.');
    }

    final existingRows = await _supabase
        .from('payroll_periods')
        .select('id, period_month, status, notes')
        .eq('company_id', companyId)
        .eq('period_year', year);

    final existing = List<Map<String, dynamic>>.from(existingRows as List);

    final existingMonths = <int>{};

    for (final row in existing) {
      final month = _toInt(row['period_month']);

      if (month >= 1 && month <= 12) {
        existingMonths.add(month);
      }
    }

    final missingMonths = <int>[];

    for (int month = 1; month <= 12; month++) {
      if (!existingMonths.contains(month)) {
        missingMonths.add(month);
      }
    }

    // اگر هر ۱۲ ماه از قبل وجود دارند،
    // چیزی ایجاد نمی‌کنیم.
    if (missingMonths.isEmpty) {
      throw Exception(
        'سال مالی $year کامل است و هر ۱۲ ماه آن قبلاً ایجاد شده‌اند.',
      );
    }

    final userId = _supabase.auth.currentUser?.id;

    final rows =
        missingMonths.map((month) {
          return {
            'company_id': companyId,
            'period_year': year,
            'period_month': month,
            'status': 'draft',
            'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
            'created_by': userId,
            'cost_center_id': null,
          };
        }).toList();

    try {
      await _supabase.from('payroll_periods').insert(rows);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception(
          'بخشی از ماه‌های این سال هم‌زمان توسط کاربر دیگری ایجاد شده‌اند. صفحه را تازه‌سازی کنید.',
        );
      }

      rethrow;
    }
  }

  static Future<void> updateNotes({
    required String periodId,
    required String? notes,
  }) async {
    final period =
        await _supabase
            .from('payroll_periods')
            .select('id, status')
            .eq('id', periodId)
            .single();

    final status = period['status']?.toString() ?? '';

    if (status != 'draft') {
      throw Exception('فقط دوره‌های پیش‌نویس قابل ویرایش هستند.');
    }

    await _supabase
        .from('payroll_periods')
        .update({
          'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', periodId);
  }

  static Future<void> deleteFiscalYear({
    required String companyId,
    required int year,
  }) async {
    final periods = await _supabase
        .from('payroll_periods')
        .select('id, status')
        .eq('company_id', companyId)
        .eq('period_year', year);

    final rows = List<Map<String, dynamic>>.from(periods as List);

    if (rows.isEmpty) {
      throw Exception('سال مالی موردنظر پیدا نشد.');
    }

    final hasNonDraft = rows.any((row) => row['status']?.toString() != 'draft');

    if (hasNonDraft) {
      throw Exception(
        'سال مالی دارای دوره ارسال‌شده یا تأییدشده است و قابل حذف نیست.',
      );
    }

    await _supabase
        .from('payroll_periods')
        .delete()
        .eq('company_id', companyId)
        .eq('period_year', year);
  }

  static Future<void> submitToCeo(String periodId) async {
    final period =
        await _supabase
            .from('payroll_periods')
            .select('id, status')
            .eq('id', periodId)
            .single();

    final status = period['status']?.toString() ?? '';

    if (status != 'draft') {
      throw Exception('فقط دوره پیش‌نویس قابل ارسال برای مدیرعامل است.');
    }

    await _supabase
        .from('payroll_periods')
        .update({
          'status': 'pending_ceo',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', periodId);
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }
}

class _PayrollPeriodStats {
  final Set<String> employeeIds = <String>{};

  double totalGrossSalary = 0;
  double totalDeductions = 0;
  double totalNetSalary = 0;
}

String payrollMonthName(int month) {
  const months = <String>[
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

String payrollStatusName(String status) {
  switch (status.trim().toLowerCase()) {
    case 'draft':
      return 'پیش‌نویس';

    case 'pending_ceo':
      return 'در انتظار تأیید مدیرعامل';

    case 'ceo_approved':
      return 'تأیید مدیرعامل';

    case 'pending_consultant':
      return 'در انتظار مشاور';

    case 'consultant_approved':
      return 'تأیید نهایی مشاور';

    case 'rejected':
      return 'رد شده';

    case 'paid':
      return 'پرداخت شده';

    case 'cancelled':
      return 'لغو شده';

    default:
      return status;
  }
}
