import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantExpenseFiscalPeriodsProvider = FutureProvider.autoDispose
    .family<AccountantExpenseFiscalPeriodsData, String>((ref, companyId) async {
      final repository = AccountantExpenseFiscalPeriodsRepository(
        Supabase.instance.client,
      );

      return repository.load(companyId);
    });

class AccountantExpenseFiscalPeriodsRepository {
  AccountantExpenseFiscalPeriodsRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<AccountantExpenseFiscalPeriodsData> load(String companyId) async {
    final yearsResponse = await _supabase
        .from('expense_fiscal_years')
        .select()
        .eq('company_id', companyId)
        .order('year', ascending: false);

    final years =
        (yearsResponse as List)
            .map(
              (row) => AccountantExpenseFiscalYear.fromMap(
                Map<String, dynamic>.from(row as Map),
              ),
            )
            .toList();

    final periodsResponse = await _supabase
        .from('expense_fiscal_periods')
        .select()
        .eq('company_id', companyId)
        .order('year', ascending: false)
        .order('month', ascending: true);

    final periods =
        (periodsResponse as List)
            .map(
              (row) => AccountantExpenseFiscalPeriod.fromMap(
                Map<String, dynamic>.from(row as Map),
              ),
            )
            .toList();

    return AccountantExpenseFiscalPeriodsData(years: years, periods: periods);
  }

  Future<String> createFiscalYear({
    required String companyId,
    required int year,
    String? title,
  }) async {
    final result = await _supabase.rpc(
      'create_expense_fiscal_year',
      params: {'p_company_id': companyId, 'p_year': year, 'p_title': title},
    );

    if (result == null) {
      throw Exception('ایجاد سال مالی هزینه انجام نشد.');
    }

    return result.toString();
  }

  Future<AccountantExpenseFiscalPeriod> processPeriod({
    required String periodId,
    required String action,
    String? note,
  }) async {
    final result = await _supabase.rpc(
      'process_expense_fiscal_period',
      params: {'p_period_id': periodId, 'p_action': action, 'p_note': note},
    );

    if (result == null) {
      throw Exception('تغییر وضعیت دوره انجام نشد.');
    }

    if (result is Map) {
      return AccountantExpenseFiscalPeriod.fromMap(
        Map<String, dynamic>.from(result),
      );
    }

    if (result is List && result.isNotEmpty && result.first is Map) {
      return AccountantExpenseFiscalPeriod.fromMap(
        Map<String, dynamic>.from(result.first as Map),
      );
    }

    throw Exception('پاسخ نامعتبر از سرور دریافت شد.');
  }

  Future<List<ExpenseFiscalPeriodWorkflowItem>> loadWorkflow(
    String periodId,
  ) async {
    final response = await _supabase
        .from('expense_fiscal_period_workflow')
        .select()
        .eq('period_id', periodId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) => ExpenseFiscalPeriodWorkflowItem.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }
}

class AccountantExpenseFiscalPeriodsData {
  const AccountantExpenseFiscalPeriodsData({
    required this.years,
    required this.periods,
  });

  final List<AccountantExpenseFiscalYear> years;
  final List<AccountantExpenseFiscalPeriod> periods;

  List<AccountantExpenseFiscalPeriod> periodsForYear(
    AccountantExpenseFiscalYear year,
  ) {
    return periods
        .where(
          (period) =>
              period.fiscalYearId == year.id ||
              (period.companyId == year.companyId && period.year == year.year),
        )
        .toList()
      ..sort((a, b) => a.month.compareTo(b.month));
  }
}

class AccountantExpenseFiscalYear {
  const AccountantExpenseFiscalYear({
    required this.id,
    required this.companyId,
    required this.year,
    required this.title,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory AccountantExpenseFiscalYear.fromMap(Map<String, dynamic> map) {
    return AccountantExpenseFiscalYear(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      year: _toInt(map['year']),
      title: map['title']?.toString() ?? 'سال مالی',
      status: map['status']?.toString() ?? 'open',
      createdBy: map['created_by']?.toString(),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  final String id;
  final String companyId;
  final int year;
  final String title;
  final String status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOpen => status == 'open';

  bool get isClosed => status == 'closed';
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
    this.createdAt,
    this.updatedAt,
  });

  factory AccountantExpenseFiscalPeriod.fromMap(Map<String, dynamic> map) {
    return AccountantExpenseFiscalPeriod(
      id: map['id']?.toString() ?? '',
      fiscalYearId: map['fiscal_year_id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      year: _toInt(map['year']),
      month: _toInt(map['month']),
      title: map['title']?.toString() ?? '',
      status: map['status']?.toString() ?? 'open',
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  final String id;
  final String fiscalYearId;
  final String companyId;
  final int year;
  final int month;
  final String title;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOpen => status == 'open';

  bool get isSubmittedToCompanyAdmin => status == 'submitted_to_company_admin';

  bool get isSubmittedToConsultant => status == 'submitted_to_consultant';

  bool get isApproved => status == 'approved';

  bool get isClosed => status == 'closed';

  bool get canAccountantEdit => status == 'open';

  String get statusTitle {
    switch (status) {
      case 'open':
        return 'باز';
      case 'submitted_to_company_admin':
        return 'ارسال‌شده برای مدیرعامل';
      case 'submitted_to_consultant':
        return 'ارسال‌شده برای مشاور';
      case 'approved':
        return 'تأیید نهایی';
      case 'closed':
        return 'بسته';
      default:
        return status;
    }
  }
}

class ExpenseFiscalPeriodWorkflowItem {
  const ExpenseFiscalPeriodWorkflowItem({
    required this.id,
    required this.periodId,
    required this.companyId,
    required this.fromStatus,
    required this.toStatus,
    required this.actedBy,
    required this.note,
    required this.createdAt,
  });

  factory ExpenseFiscalPeriodWorkflowItem.fromMap(Map<String, dynamic> map) {
    return ExpenseFiscalPeriodWorkflowItem(
      id: map['id']?.toString() ?? '',
      periodId: map['period_id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      fromStatus: map['from_status']?.toString(),
      toStatus: map['to_status']?.toString() ?? '',
      actedBy: map['acted_by']?.toString(),
      note: map['note']?.toString(),
      createdAt:
          _parseDate(map['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String periodId;
  final String companyId;
  final String? fromStatus;
  final String toStatus;
  final String? actedBy;
  final String? note;
  final DateTime createdAt;

  String get fromStatusTitle {
    switch (fromStatus) {
      case 'open':
        return 'باز';
      case 'submitted_to_company_admin':
        return 'ارسال‌شده برای مدیرعامل';
      case 'submitted_to_consultant':
        return 'ارسال‌شده برای مشاور';
      case 'approved':
        return 'تأیید نهایی';
      case 'closed':
        return 'بسته';
      case null:
        return '—';
      default:
        return fromStatus!;
    }
  }

  String get toStatusTitle {
    switch (toStatus) {
      case 'open':
        return 'باز';
      case 'submitted_to_company_admin':
        return 'ارسال‌شده برای مدیرعامل';
      case 'submitted_to_consultant':
        return 'ارسال‌شده برای مشاور';
      case 'approved':
        return 'تأیید نهایی';
      case 'closed':
        return 'بسته';
      default:
        return toStatus;
    }
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
