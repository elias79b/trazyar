import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantPayableFiscalPeriodsProvider = FutureProvider.autoDispose
    .family<AccountantPayableFiscalPeriodsData, String>((ref, companyId) async {
      final repository = AccountantPayableFiscalPeriodsRepository(
        Supabase.instance.client,
      );

      return repository.load(companyId);
    });

class AccountantPayableFiscalPeriodsRepository {
  final SupabaseClient client;

  AccountantPayableFiscalPeriodsRepository(this.client);

  Future<AccountantPayableFiscalPeriodsData> load(String companyId) async {
    final yearsResponse = await client
        .from('payable_fiscal_years')
        .select(
          'id, company_id, year, title, status, created_by, created_at, updated_at',
        )
        .eq('company_id', companyId)
        .order('year', ascending: false);

    final periodsResponse = await client
        .from('payable_fiscal_periods')
        .select(
          'id, fiscal_year_id, company_id, year, month, title, '
          'status, created_at, updated_at',
        )
        .eq('company_id', companyId)
        .order('year', ascending: false)
        .order('month');

    final years =
        yearsResponse
            .map(
              (item) => AccountantPayableFiscalYear.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

    final periods =
        periodsResponse
            .map(
              (item) => AccountantPayableFiscalPeriod.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

    return AccountantPayableFiscalPeriodsData(
      companyId: companyId,
      years: years,
      periods: periods,
    );
  }

  Future<String> createFiscalYear({
    required String companyId,
    required int year,
    String? title,
  }) async {
    final response = await client.rpc(
      'create_payable_fiscal_year',
      params: {
        'p_company_id': companyId,
        'p_year': year,
        'p_title': _nullableText(title),
      },
    );

    return response.toString();
  }

  Future<AccountantPayableFiscalPeriodsData> processPeriod({
    required String companyId,
    required String periodId,
    required String action,
    String? note,
  }) async {
    await client.rpc(
      'process_payable_fiscal_period',
      params: {
        'p_period_id': periodId,
        'p_action': action,
        'p_note': _nullableText(note),
      },
    );

    return load(companyId);
  }

  Future<List<PayableFiscalPeriodWorkflowItem>> loadWorkflow(
    String periodId,
  ) async {
    final response = await client
        .from('payable_fiscal_period_workflow')
        .select(
          'id, period_id, company_id, from_status, to_status, '
          'acted_by, note, created_at',
        )
        .eq('period_id', periodId)
        .order('created_at', ascending: false);

    return response
        .map(
          (item) => PayableFiscalPeriodWorkflowItem.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}

class AccountantPayableFiscalPeriodsData {
  final String companyId;
  final List<AccountantPayableFiscalYear> years;
  final List<AccountantPayableFiscalPeriod> periods;

  const AccountantPayableFiscalPeriodsData({
    required this.companyId,
    required this.years,
    required this.periods,
  });

  List<AccountantPayableFiscalPeriod> periodsForYear(String fiscalYearId) {
    return periods
        .where((period) => period.fiscalYearId == fiscalYearId)
        .toList()
      ..sort((a, b) => a.month.compareTo(b.month));
  }

  AccountantPayableFiscalYear? yearById(String id) {
    for (final year in years) {
      if (year.id == id) {
        return year;
      }
    }

    return null;
  }

  AccountantPayableFiscalPeriod? periodById(String id) {
    for (final period in periods) {
      if (period.id == id) {
        return period;
      }
    }

    return null;
  }
}

class AccountantPayableFiscalYear {
  final String id;
  final String companyId;
  final int year;
  final String? title;
  final String status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AccountantPayableFiscalYear({
    required this.id,
    required this.companyId,
    required this.year,
    required this.title,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountantPayableFiscalYear.fromMap(Map<String, dynamic> map) {
    return AccountantPayableFiscalYear(
      id: map['id'].toString(),
      companyId: map['company_id'].toString(),
      year: _toInt(map['year']),
      title: map['title']?.toString(),
      status: map['status']?.toString() ?? 'open',
      createdBy: map['created_by']?.toString(),
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  bool get isOpen => status == 'open';

  bool get isClosed => status == 'closed';

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) {
      return title!.trim();
    }

    return 'سال مالی پرداختنی $year';
  }

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
}

class AccountantPayableFiscalPeriod {
  final String id;
  final String fiscalYearId;
  final String companyId;
  final int year;
  final int month;
  final String? title;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AccountantPayableFiscalPeriod({
    required this.id,
    required this.fiscalYearId,
    required this.companyId,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountantPayableFiscalPeriod.fromMap(Map<String, dynamic> map) {
    return AccountantPayableFiscalPeriod(
      id: map['id'].toString(),
      fiscalYearId: map['fiscal_year_id'].toString(),
      companyId: map['company_id'].toString(),
      year: _toInt(map['year']),
      month: _toInt(map['month']),
      title: map['title']?.toString(),
      status: map['status']?.toString() ?? 'open',
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  bool get isOpen => status == 'open';

  bool get isSubmittedToCompanyAdmin => status == 'submitted_to_company_admin';

  bool get isSubmittedToConsultant => status == 'submitted_to_consultant';

  bool get isApproved => status == 'approved';

  bool get isClosed => status == 'closed';

  String get monthTitle {
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

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) {
      return title!.trim();
    }

    return '$monthTitle $year';
  }

  String get statusTitle {
    switch (status) {
      case 'open':
        return 'باز';
      case 'submitted_to_company_admin':
        return 'ارسال به مدیر شرکت';
      case 'submitted_to_consultant':
        return 'ارسال به مشاور';
      case 'approved':
        return 'تأییدشده';
      case 'closed':
        return 'بسته';
      default:
        return status;
    }
  }
}

class PayableFiscalPeriodWorkflowItem {
  final String id;
  final String periodId;
  final String companyId;
  final String? fromStatus;
  final String toStatus;
  final String? actedBy;
  final String? note;
  final DateTime? createdAt;

  const PayableFiscalPeriodWorkflowItem({
    required this.id,
    required this.periodId,
    required this.companyId,
    required this.fromStatus,
    required this.toStatus,
    required this.actedBy,
    required this.note,
    required this.createdAt,
  });

  factory PayableFiscalPeriodWorkflowItem.fromMap(Map<String, dynamic> map) {
    return PayableFiscalPeriodWorkflowItem(
      id: map['id'].toString(),
      periodId: map['period_id'].toString(),
      companyId: map['company_id'].toString(),
      fromStatus: map['from_status']?.toString(),
      toStatus: map['to_status']?.toString() ?? '',
      actedBy: map['acted_by']?.toString(),
      note: map['note']?.toString(),
      createdAt: _toDateTime(map['created_at']),
    );
  }

  String get fromStatusTitle {
    return _statusTitle(fromStatus);
  }

  String get toStatusTitle {
    return _statusTitle(toStatus);
  }
}

String? _nullableText(String? value) {
  final text = value?.trim();

  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
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

DateTime? _toDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(value.toString());
}

String _statusTitle(String? status) {
  switch (status) {
    case 'open':
      return 'باز';
    case 'submitted_to_company_admin':
      return 'ارسال به مدیر شرکت';
    case 'submitted_to_consultant':
      return 'ارسال به مشاور';
    case 'approved':
      return 'تأییدشده';
    case 'closed':
      return 'بسته';
    default:
      return status ?? '-';
  }
}
