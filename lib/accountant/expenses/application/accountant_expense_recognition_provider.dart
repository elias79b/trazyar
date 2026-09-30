import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantExpenseRecognitionProvider = FutureProvider.autoDispose
    .family<AccountantExpenseRecognitionData, String>((ref, periodId) async {
      final repository = AccountantExpenseRecognitionRepository(
        Supabase.instance.client,
      );

      return repository.load(periodId);
    });

class AccountantExpenseRecognitionRepository {
  final SupabaseClient client;

  AccountantExpenseRecognitionRepository(this.client);

  Future<AccountantExpenseRecognitionData> load(String periodId) async {
    final periodResponse =
        await client
            .from('expense_fiscal_periods')
            .select(
              'id, fiscal_year_id, company_id, year, month, title, status, created_at, updated_at',
            )
            .eq('id', periodId)
            .maybeSingle();

    if (periodResponse == null) {
      throw Exception('دوره مالی هزینه پیدا نشد.');
    }

    final period = AccountantExpensePeriod.fromMap(periodResponse);

    final categoriesResponse = await client
        .from('expense_categories')
        .select(
          'id, company_id, name, code, description, expense_type, '
          'is_active, created_by, created_at, updated_at',
        )
        .eq('company_id', period.companyId)
        .eq('is_active', true)
        .order('expense_type')
        .order('name');

    final recognitionsResponse = await client
        .from('expense_recognitions')
        .select(
          'id, company_id, fiscal_period_id, category_id, amount, '
          'description, created_by, created_at, updated_at',
        )
        .eq('fiscal_period_id', periodId)
        .order('created_at');

    final workflowResponse = await client
        .from('expense_fiscal_period_workflow')
        .select(
          'id, period_id, company_id, from_status, to_status, '
          'acted_by, note, created_at',
        )
        .eq('period_id', periodId)
        .order('created_at', ascending: false);

    final categories =
        categoriesResponse
            .map(
              (item) => AccountantExpenseCategory.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

    final recognitions =
        recognitionsResponse
            .map(
              (item) => AccountantExpenseRecognition.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

    final workflow =
        workflowResponse
            .map(
              (item) => ExpenseRecognitionWorkflowItem.fromMap(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

    return AccountantExpenseRecognitionData(
      period: period,
      categories: categories,
      recognitions: recognitions,
      workflow: workflow,
    );
  }

  Future<void> saveRecognition({
    required String periodId,
    required String companyId,
    required String categoryId,
    required double amount,
    String? description,
    String? recognitionId,
  }) async {
    final periodResponse =
        await client
            .from('expense_fiscal_periods')
            .select('id, status, company_id')
            .eq('id', periodId)
            .maybeSingle();

    if (periodResponse == null) {
      throw Exception('دوره مالی پیدا نشد.');
    }

    if (periodResponse['company_id'] != companyId) {
      throw Exception('دوره مالی متعلق به این شرکت نیست.');
    }

    if (periodResponse['status'] != 'open') {
      throw Exception('ثبت و ویرایش هزینه فقط در دوره باز امکان‌پذیر است.');
    }

    if (amount < 0) {
      throw Exception('مبلغ هزینه نمی‌تواند منفی باشد.');
    }

    final userId = client.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    final payload = <String, dynamic>{
      'company_id': companyId,
      'fiscal_period_id': periodId,
      'category_id': categoryId,
      'amount': amount,
      'description': _nullableText(description),
      'created_by': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (recognitionId == null) {
      await client.from('expense_recognitions').insert(payload);
    } else {
      await client
          .from('expense_recognitions')
          .update({
            'category_id': categoryId,
            'amount': amount,
            'description': _nullableText(description),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', recognitionId)
          .eq('company_id', companyId)
          .eq('fiscal_period_id', periodId);
    }
  }

  Future<void> deleteRecognition({
    required String periodId,
    required String companyId,
    required String recognitionId,
  }) async {
    final periodResponse =
        await client
            .from('expense_fiscal_periods')
            .select('id, status, company_id')
            .eq('id', periodId)
            .maybeSingle();

    if (periodResponse == null) {
      throw Exception('دوره مالی پیدا نشد.');
    }

    if (periodResponse['company_id'] != companyId) {
      throw Exception('دوره مالی متعلق به این شرکت نیست.');
    }

    if (periodResponse['status'] != 'open') {
      throw Exception('حذف هزینه فقط در دوره باز امکان‌پذیر است.');
    }

    await client
        .from('expense_recognitions')
        .delete()
        .eq('id', recognitionId)
        .eq('company_id', companyId)
        .eq('fiscal_period_id', periodId);
  }

  Future<void> processPeriod({
    required String periodId,
    required String action,
    String? note,
  }) async {
    await client.rpc(
      'process_expense_fiscal_period',
      params: {
        'p_period_id': periodId,
        'p_action': action,
        'p_note': _nullableText(note),
      },
    );
  }

  Future<List<ExpenseRecognitionWorkflowItem>> loadWorkflow(
    String periodId,
  ) async {
    final response = await client
        .from('expense_fiscal_period_workflow')
        .select(
          'id, period_id, company_id, from_status, to_status, '
          'acted_by, note, created_at',
        )
        .eq('period_id', periodId)
        .order('created_at', ascending: false);

    return response
        .map(
          (item) => ExpenseRecognitionWorkflowItem.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  String? _nullableText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}

class AccountantExpenseRecognitionData {
  final AccountantExpensePeriod period;
  final List<AccountantExpenseCategory> categories;
  final List<AccountantExpenseRecognition> recognitions;
  final List<ExpenseRecognitionWorkflowItem> workflow;

  const AccountantExpenseRecognitionData({
    required this.period,
    required this.categories,
    required this.recognitions,
    required this.workflow,
  });

  double get totalExpense {
    return recognitions.fold<double>(0, (sum, item) => sum + item.amount);
  }

  double get operationalTotal {
    final operationalIds =
        categories
            .where((category) => category.isOperational)
            .map((category) => category.id)
            .toSet();

    return recognitions.fold<double>(0, (sum, item) {
      if (operationalIds.contains(item.categoryId)) {
        return sum + item.amount;
      }

      return sum;
    });
  }

  double get nonOperationalTotal {
    final operationalIds =
        categories
            .where((category) => category.isOperational)
            .map((category) => category.id)
            .toSet();

    return recognitions.fold<double>(0, (sum, item) {
      if (!operationalIds.contains(item.categoryId)) {
        return sum + item.amount;
      }

      return sum;
    });
  }

  double get operationalShare {
    if (totalExpense == 0) {
      return 0;
    }

    return operationalTotal / totalExpense;
  }

  double get nonOperationalShare {
    if (totalExpense == 0) {
      return 0;
    }

    return nonOperationalTotal / totalExpense;
  }

  AccountantExpenseRecognition? recognitionForCategory(String categoryId) {
    for (final item in recognitions) {
      if (item.categoryId == categoryId) {
        return item;
      }
    }

    return null;
  }
}

class AccountantExpensePeriod {
  final String id;
  final String fiscalYearId;
  final String companyId;
  final int year;
  final int month;
  final String? title;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AccountantExpensePeriod({
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

  factory AccountantExpensePeriod.fromMap(Map<String, dynamic> map) {
    return AccountantExpensePeriod(
      id: map['id'] as String,
      fiscalYearId: map['fiscal_year_id'] as String,
      companyId: map['company_id'] as String,
      year: _toInt(map['year']),
      month: _toInt(map['month']),
      title: map['title'] as String?,
      status: (map['status'] ?? 'open').toString(),
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  bool get isOpen => status == 'open';

  bool get isSubmittedToCompanyAdmin => status == 'submitted_to_company_admin';

  bool get isSubmittedToConsultant => status == 'submitted_to_consultant';

  bool get isApproved => status == 'approved';

  bool get isClosed => status == 'closed';

  String get statusTitle {
    switch (status) {
      case 'open':
        return 'باز';
      case 'submitted_to_company_admin':
        return 'ارسال‌شده به مدیر شرکت';
      case 'submitted_to_consultant':
        return 'ارسال‌شده به مشاور';
      case 'approved':
        return 'تأییدشده';
      case 'closed':
        return 'بسته';
      default:
        return status;
    }
  }

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
}

class AccountantExpenseCategory {
  final String id;
  final String companyId;
  final String name;
  final String? code;
  final String? description;
  final String expenseType;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AccountantExpenseCategory({
    required this.id,
    required this.companyId,
    required this.name,
    required this.code,
    required this.description,
    required this.expenseType,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountantExpenseCategory.fromMap(Map<String, dynamic> map) {
    return AccountantExpenseCategory(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      name: (map['name'] ?? '').toString(),
      code: map['code'] as String?,
      description: map['description'] as String?,
      expenseType: (map['expense_type'] ?? 'operational').toString(),
      isActive: map['is_active'] == true,
      createdBy: map['created_by'] as String?,
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  bool get isOperational => expenseType == 'operational';

  bool get isNonOperational => expenseType == 'non_operational';

  String get expenseTypeTitle {
    return isOperational ? 'عملیاتی' : 'غیرعملیاتی';
  }
}

class AccountantExpenseRecognition {
  final String id;
  final String companyId;
  final String fiscalPeriodId;
  final String categoryId;
  final double amount;
  final String? description;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AccountantExpenseRecognition({
    required this.id,
    required this.companyId,
    required this.fiscalPeriodId,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountantExpenseRecognition.fromMap(Map<String, dynamic> map) {
    return AccountantExpenseRecognition(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      fiscalPeriodId: map['fiscal_period_id'] as String,
      categoryId: map['category_id'] as String,
      amount: _toDouble(map['amount']),
      description: map['description'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }
}

class ExpenseRecognitionWorkflowItem {
  final String id;
  final String periodId;
  final String companyId;
  final String? fromStatus;
  final String toStatus;
  final String? actedBy;
  final String? note;
  final DateTime? createdAt;

  const ExpenseRecognitionWorkflowItem({
    required this.id,
    required this.periodId,
    required this.companyId,
    required this.fromStatus,
    required this.toStatus,
    required this.actedBy,
    required this.note,
    required this.createdAt,
  });

  factory ExpenseRecognitionWorkflowItem.fromMap(Map<String, dynamic> map) {
    return ExpenseRecognitionWorkflowItem(
      id: map['id'] as String,
      periodId: map['period_id'] as String,
      companyId: map['company_id'] as String,
      fromStatus: map['from_status'] as String?,
      toStatus: (map['to_status'] ?? '').toString(),
      actedBy: map['acted_by'] as String?,
      note: map['note'] as String?,
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

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
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
      return 'تأیید';
    case 'closed':
      return 'بسته';
    default:
      return status ?? '-';
  }
}
