import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantIncomeRecognitionProvider =
FutureProvider.family<AccountantIncomeRecognitionData, String>((
    ref,
    periodId,
    ) async {
  return AccountantIncomeRecognitionRepository.load(
    periodId: periodId,
  );
});

class AccountantIncomeRecognitionData {
  final AccountantIncomePeriod period;
  final List<AccountantIncomeCategory> categories;
  final List<AccountantIncomeRecognition> recognitions;

  const AccountantIncomeRecognitionData({
    required this.period,
    required this.categories,
    required this.recognitions,
  });

  double get operationalTotal {
    final operationalCategoryIds = categories
        .where((category) => category.isOperational)
        .map((category) => category.id)
        .toSet();

    return recognitions
        .where(
          (recognition) =>
          operationalCategoryIds.contains(
            recognition.categoryId,
          ),
    )
        .fold<double>(
      0,
          (sum, item) => sum + item.amount,
    );
  }

  double get nonOperationalTotal {
    final operationalCategoryIds = categories
        .where((category) => category.isOperational)
        .map((category) => category.id)
        .toSet();

    return recognitions
        .where(
          (recognition) =>
      !operationalCategoryIds.contains(
        recognition.categoryId,
      ),
    )
        .fold<double>(
      0,
          (sum, item) => sum + item.amount,
    );
  }

  double get totalIncome =>
      operationalTotal + nonOperationalTotal;

  AccountantIncomeRecognition? recognitionForCategory(
      String categoryId,
      ) {
    for (final item in recognitions) {
      if (item.categoryId == categoryId) {
        return item;
      }
    }

    return null;
  }

  AccountantIncomeCategory? categoryForRecognition(
      AccountantIncomeRecognition recognition,
      ) {
    for (final category in categories) {
      if (category.id == recognition.categoryId) {
        return category;
      }
    }

    return null;
  }
}

class AccountantIncomePeriod {
  final String id;
  final String companyId;
  final String fiscalYearId;
  final int year;
  final int month;
  final String title;
  final String status;

  const AccountantIncomePeriod({
    required this.id,
    required this.companyId,
    required this.fiscalYearId,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
  });

  bool get isOpen => status == 'open';

  bool get isSubmittedToCompanyAdmin =>
      status == 'submitted_to_company_admin';

  bool get isSubmittedToConsultant =>
      status == 'submitted_to_consultant';

  bool get isApproved => status == 'approved';

  bool get isClosed => status == 'closed';

  bool get canAccountantEdit => isOpen;

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
}

class AccountantIncomeCategory {
  final String id;
  final String companyId;
  final String name;
  final String? code;
  final String? description;
  final bool isActive;
  final bool isSystem;
  final String categoryType;

  const AccountantIncomeCategory({
    required this.id,
    required this.companyId,
    required this.name,
    required this.code,
    required this.description,
    required this.isActive,
    required this.isSystem,
    required this.categoryType,
  });

  bool get isOperational =>
      categoryType == 'operational';

  String get typeTitle =>
      isOperational
          ? 'درآمد عملیاتی'
          : 'درآمد غیرعملیاتی';
}

class AccountantIncomeRecognition {
  final String id;
  final String companyId;
  final String fiscalPeriodId;
  final String categoryId;
  final double amount;
  final String? description;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AccountantIncomeRecognition({
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
}

class AccountantIncomeRecognitionRepository {
  static final SupabaseClient _client =
      Supabase.instance.client;

  static Future<AccountantIncomeRecognitionData> load({
    required String periodId,
  }) async {
    final periodResponse = await _client
        .from('income_fiscal_periods')
        .select('''
          id,
          fiscal_year_id,
          company_id,
          year,
          month,
          title,
          status
        ''')
        .eq('id', periodId)
        .maybeSingle();

    if (periodResponse == null) {
      throw Exception(
        'دوره درآمد موردنظر پیدا نشد.',
      );
    }

    final period = AccountantIncomePeriod(
      id: periodResponse['id'].toString(),
      fiscalYearId:
      periodResponse['fiscal_year_id'].toString(),
      companyId:
      periodResponse['company_id'].toString(),
      year: _toInt(periodResponse['year']),
      month: _toInt(periodResponse['month']),
      title:
      periodResponse['title']?.toString() ?? '',
      status:
      periodResponse['status']?.toString() ??
          'open',
    );

    final categoriesFuture =
    _loadCategories(period.companyId);

    final recognitionsFuture =
    _loadRecognitions(periodId);

    final results = await Future.wait([
      categoriesFuture,
      recognitionsFuture,
    ]);

    return AccountantIncomeRecognitionData(
      period: period,
      categories:
      results[0] as List<AccountantIncomeCategory>,
      recognitions:
      results[1]
      as List<AccountantIncomeRecognition>,
    );
  }

  static Future<List<AccountantIncomeCategory>>
  _loadCategories(
      String companyId,
      ) async {
    final response = await _client
        .from('income_categories')
        .select('''
          id,
          company_id,
          name,
          code,
          description,
          is_active,
          is_system,
          category_type
        ''')
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order(
      'category_type',
      ascending: true,
    )
        .order(
      'is_system',
      ascending: false,
    )
        .order(
      'name',
      ascending: true,
    );

    return response
        .map<AccountantIncomeCategory>((row) {
      return AccountantIncomeCategory(
        id: row['id'].toString(),
        companyId:
        row['company_id'].toString(),
        name:
        row['name']?.toString() ?? '',
        code:
        row['code']?.toString(),
        description:
        row['description']?.toString(),
        isActive:
        row['is_active'] == true,
        isSystem:
        row['is_system'] == true,
        categoryType:
        row['category_type']?.toString() ??
            'operational',
      );
    }).toList();
  }

  static Future<List<AccountantIncomeRecognition>>
  _loadRecognitions(
      String periodId,
      ) async {
    final response = await _client
        .from('income_recognitions')
        .select('''
          id,
          company_id,
          fiscal_period_id,
          category_id,
          amount,
          description,
          created_by,
          created_at,
          updated_at
        ''')
        .eq(
      'fiscal_period_id',
      periodId,
    )
        .order(
      'created_at',
      ascending: true,
    );

    return response
        .map<AccountantIncomeRecognition>((row) {
      return AccountantIncomeRecognition(
        id: row['id'].toString(),
        companyId:
        row['company_id'].toString(),
        fiscalPeriodId:
        row['fiscal_period_id'].toString(),
        categoryId:
        row['category_id'].toString(),
        amount: _toDouble(row['amount']),
        description:
        row['description']?.toString(),
        createdBy:
        row['created_by']?.toString(),
        createdAt:
        _toDateTime(row['created_at']),
        updatedAt:
        _toDateTime(row['updated_at']),
      );
    }).toList();
  }

  static Future<void> saveRecognition({
    required String periodId,
    required String companyId,
    required String categoryId,
    required double amount,
    String? description,
  }) async {
    await _ensureEditable(periodId);

    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'کاربر وارد سیستم نشده است.',
      );
    }

    final existing = await _client
        .from('income_recognitions')
        .select('id')
        .eq(
      'fiscal_period_id',
      periodId,
    )
        .eq(
      'category_id',
      categoryId,
    )
        .maybeSingle();

    if (existing == null) {
      await _client
          .from('income_recognitions')
          .insert({
        'company_id': companyId,
        'fiscal_period_id': periodId,
        'category_id': categoryId,
        'amount': amount,
        'description':
        _cleanText(description),
        'created_by': user.id,
      });
    } else {
      await _client
          .from('income_recognitions')
          .update({
        'amount': amount,
        'description':
        _cleanText(description),
        'updated_at':
        DateTime.now().toIso8601String(),
      })
          .eq(
        'id',
        existing['id'].toString(),
      );
    }
  }

  static Future<void> deleteRecognition({
    required String periodId,
    required String recognitionId,
  }) async {
    await _ensureEditable(periodId);

    await _client
        .from('income_recognitions')
        .delete()
        .eq(
      'id',
      recognitionId,
    )
        .eq(
      'fiscal_period_id',
      periodId,
    );
  }

  static Future<void> submitToCompanyAdmin({
    required String periodId,
    String? note,
  }) async {
    await processWorkflow(
      periodId: periodId,
      action: 'submit_to_company_admin',
      note: note,
    );
  }

  static Future<void> processWorkflow({
    required String periodId,
    required String action,
    String? note,
  }) async {
    await _client.rpc(
      'process_income_fiscal_period',
      params: {
        'p_period_id': periodId,
        'p_action': action,
        'p_note': _cleanText(note),
      },
    );
  }

  static Future<List<Map<String, dynamic>>>
  loadWorkflow(
      String periodId,
      ) async {
    final response = await _client
        .from(
      'income_fiscal_period_workflow',
    )
        .select('''
          id,
          period_id,
          company_id,
          from_status,
          to_status,
          acted_by,
          note,
          created_at
        ''')
        .eq(
      'period_id',
      periodId,
    )
        .order(
      'created_at',
      ascending: false,
    );

    return List<Map<String, dynamic>>.from(
      response,
    );
  }

  static Future<void> _ensureEditable(
      String periodId,
      ) async {
    final period = await _client
        .from('income_fiscal_periods')
        .select('status')
        .eq(
      'id',
      periodId,
    )
        .maybeSingle();

    if (period == null) {
      throw Exception(
        'دوره درآمد موردنظر پیدا نشد.',
      );
    }

    final status =
    period['status']?.toString();

    if (status != 'open') {
      throw Exception(
        'این دوره در وضعیت «$status» قرار دارد و امکان ثبت یا ویرایش درآمد وجود ندارد.',
      );
    }
  }

  static String? _cleanText(
      String? value,
      ) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  static DateTime? _toDateTime(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}