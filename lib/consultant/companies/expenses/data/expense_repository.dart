import 'package:supabase_flutter/supabase_flutter.dart';

import 'expense_category_model.dart';
import 'expense_model.dart';

class ExpenseRepository {
  ExpenseRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // ---------------------------------------------------------------------------
  // EXPENSES
  // ---------------------------------------------------------------------------

  Future<List<ExpenseModel>> getExpenses(String companyId) async {
    final response = await _client
        .from('expenses')
        .select('''
          *,
          expense_categories (
            id,
            name,
            code,
            expense_type
          ),
          payroll_periods (
            id,
            period_year,
            period_month,
            status
          )
        ''')
        .eq('company_id', companyId)
        .order('expense_date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (item) =>
              ExpenseModel.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<ExpenseModel?> getExpenseById(String expenseId) async {
    final response =
        await _client
            .from('expenses')
            .select('''
          *,
          expense_categories (
            id,
            name,
            code,
            expense_type
          ),
          payroll_periods (
            id,
            period_year,
            period_month,
            status
          )
        ''')
            .eq('id', expenseId)
            .maybeSingle();

    if (response == null) return null;

    return ExpenseModel.fromMap(Map<String, dynamic>.from(response));
  }

  Future<ExpenseModel> createExpense({
    required String companyId,
    required String categoryId,
    required String title,
    String? description,
    required num amount,
    required DateTime expenseDate,
    String? referenceNumber,
    required String expenseType,
    required String sourceType,
    String? payrollPeriodId,
  }) async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    if (sourceType == 'manual' && payrollPeriodId != null) {
      throw Exception('برای هزینه دستی نباید دوره حقوق انتخاب شود.');
    }

    if (sourceType == 'payroll' && payrollPeriodId == null) {
      throw Exception('برای هزینه حقوق باید دوره حقوق انتخاب شود.');
    }

    final data = <String, dynamic>{
      'company_id': companyId,
      'category_id': categoryId,
      'title': title.trim(),
      'description': _nullableText(description),
      'amount': amount,
      'expense_date': _dateOnly(expenseDate),
      'reference_number': _nullableText(referenceNumber),
      'expense_type': expenseType,
      'source_type': sourceType,
      'payroll_period_id': payrollPeriodId,
      'created_by': userId,
    };

    final response =
        await _client.from('expenses').insert(data).select('''
          *,
          expense_categories (
            id,
            name,
            code,
            expense_type
          ),
          payroll_periods (
            id,
            period_year,
            period_month,
            status
          )
        ''').single();

    return ExpenseModel.fromMap(Map<String, dynamic>.from(response));
  }

  Future<ExpenseModel> updateExpense({
    required String expenseId,
    required String categoryId,
    required String title,
    String? description,
    required num amount,
    required DateTime expenseDate,
    String? referenceNumber,
    required String expenseType,
    required String sourceType,
    String? payrollPeriodId,
  }) async {
    if (sourceType == 'manual' && payrollPeriodId != null) {
      throw Exception('برای هزینه دستی نباید دوره حقوق انتخاب شود.');
    }

    if (sourceType == 'payroll' && payrollPeriodId == null) {
      throw Exception('برای هزینه حقوق باید دوره حقوق انتخاب شود.');
    }

    final data = <String, dynamic>{
      'category_id': categoryId,
      'title': title.trim(),
      'description': _nullableText(description),
      'amount': amount,
      'expense_date': _dateOnly(expenseDate),
      'reference_number': _nullableText(referenceNumber),
      'expense_type': expenseType,
      'source_type': sourceType,
      'payroll_period_id': payrollPeriodId,
    };

    final response =
        await _client.from('expenses').update(data).eq('id', expenseId).select(
          '''
          *,
          expense_categories (
            id,
            name,
            code,
            expense_type
          ),
          payroll_periods (
            id,
            period_year,
            period_month,
            status
          )
        ''',
        ).single();

    return ExpenseModel.fromMap(Map<String, dynamic>.from(response));
  }

  Future<void> deleteExpense(String expenseId) async {
    await _client.from('expenses').delete().eq('id', expenseId);
  }

  // ---------------------------------------------------------------------------
  // EXPENSE CATEGORIES
  // ---------------------------------------------------------------------------

  Future<List<ExpenseCategoryModel>> getCategories(
    String companyId, {
    bool activeOnly = false,
  }) async {
    var query = _client
        .from('expense_categories')
        .select()
        .eq('company_id', companyId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final response = await query.order('expense_type').order('name');

    return (response as List)
        .map(
          (item) => ExpenseCategoryModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<ExpenseCategoryModel?> getCategoryById(String categoryId) async {
    final response =
        await _client
            .from('expense_categories')
            .select()
            .eq('id', categoryId)
            .maybeSingle();

    if (response == null) return null;

    return ExpenseCategoryModel.fromMap(Map<String, dynamic>.from(response));
  }

  Future<ExpenseCategoryModel> createCategory({
    required String companyId,
    required String name,
    String? code,
    String? description,
    required String expenseType,
  }) async {
    final userId = _client.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    final response =
        await _client
            .from('expense_categories')
            .insert({
              'company_id': companyId,
              'name': name.trim(),
              'code': _nullableText(code),
              'description': _nullableText(description),
              'expense_type': expenseType,
              'is_active': true,
              'created_by': userId,
            })
            .select()
            .single();

    return ExpenseCategoryModel.fromMap(Map<String, dynamic>.from(response));
  }

  Future<ExpenseCategoryModel> updateCategory({
    required String categoryId,
    required String name,
    String? code,
    String? description,
    required String expenseType,
    required bool isActive,
  }) async {
    final response =
        await _client
            .from('expense_categories')
            .update({
              'name': name.trim(),
              'code': _nullableText(code),
              'description': _nullableText(description),
              'expense_type': expenseType,
              'is_active': isActive,
            })
            .eq('id', categoryId)
            .select()
            .single();

    return ExpenseCategoryModel.fromMap(Map<String, dynamic>.from(response));
  }

  Future<void> deleteCategory(String categoryId) async {
    await _client.from('expense_categories').delete().eq('id', categoryId);
  }

  // ---------------------------------------------------------------------------
  // PAYROLL SOURCE
  // ---------------------------------------------------------------------------

  Future<num> getPayrollEmployerCost(String payrollPeriodId) async {
    final response = await _client.rpc(
      'calculate_payroll_employer_cost',
      params: {'target_payroll_period_id': payrollPeriodId},
    );

    if (response == null) return 0;

    if (response is num) return response;

    return num.tryParse(response.toString()) ?? 0;
  }

  Future<PayrollExpenseSource?> getPayrollExpenseSource(
    String payrollPeriodId,
  ) async {
    final period =
        await _client
            .from('payroll_periods')
            .select('''
          id,
          company_id,
          period_year,
          period_month,
          status
        ''')
            .eq('id', payrollPeriodId)
            .maybeSingle();

    if (period == null) return null;

    final records = await _client
        .from('payroll_records')
        .select('''
          id,
          gross_salary,
          employer_insurance
        ''')
        .eq('payroll_period_id', payrollPeriodId);

    final rows = (records as List);

    num grossSalary = 0;
    num employerInsurance = 0;

    for (final row in rows) {
      final map = Map<String, dynamic>.from(row as Map);

      grossSalary += _parseNum(map['gross_salary']);
      employerInsurance += _parseNum(map['employer_insurance']);
    }

    return PayrollExpenseSource(
      id: period['id'].toString(),
      companyId: period['company_id'].toString(),
      periodYear: _parseInt(period['period_year']) ?? 0,
      periodMonth: _parseInt(period['period_month']) ?? 0,
      status: period['status']?.toString() ?? 'draft',
      employeeCount: rows.length,
      grossSalary: grossSalary,
      employerInsurance: employerInsurance,
      employerCost: grossSalary + employerInsurance,
    );
  }

  Future<List<PayrollExpenseSource>> getPayrollExpenseSources(
    String companyId,
  ) async {
    final periods = await _client
        .from('payroll_periods')
        .select('''
          id,
          company_id,
          period_year,
          period_month,
          status
        ''')
        .eq('company_id', companyId)
        .order('period_year', ascending: false)
        .order('period_month', ascending: false);

    final result = <PayrollExpenseSource>[];

    for (final row in (periods as List)) {
      final period = Map<String, dynamic>.from(row as Map);

      final periodId = period['id'].toString();

      final records = await _client
          .from('payroll_records')
          .select('''
            id,
            gross_salary,
            employer_insurance
          ''')
          .eq('payroll_period_id', periodId);

      final rows = records as List;

      if (rows.isEmpty) {
        continue;
      }

      num grossSalary = 0;
      num employerInsurance = 0;

      for (final record in rows) {
        final map = Map<String, dynamic>.from(record as Map);

        grossSalary += _parseNum(map['gross_salary']);

        employerInsurance += _parseNum(map['employer_insurance']);
      }

      result.add(
        PayrollExpenseSource(
          id: periodId,
          companyId: period['company_id'].toString(),
          periodYear: _parseInt(period['period_year']) ?? 0,
          periodMonth: _parseInt(period['period_month']) ?? 0,
          status: period['status']?.toString() ?? 'draft',
          employeeCount: rows.length,
          grossSalary: grossSalary,
          employerInsurance: employerInsurance,
          employerCost: grossSalary + employerInsurance,
        ),
      );
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  static String? _nullableText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  static num _parseNum(dynamic value) {
    if (value == null) return 0;

    if (value is num) return value;

    return num.tryParse(value.toString()) ?? 0;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    return int.tryParse(value.toString());
  }

  static String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}

class PayrollExpenseSource {
  const PayrollExpenseSource({
    required this.id,
    required this.companyId,
    required this.periodYear,
    required this.periodMonth,
    required this.status,
    required this.employeeCount,
    required this.grossSalary,
    required this.employerInsurance,
    required this.employerCost,
  });

  final String id;
  final String companyId;
  final int periodYear;
  final int periodMonth;
  final String status;
  final int employeeCount;
  final num grossSalary;
  final num employerInsurance;
  final num employerCost;
}
