import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final expenseRecognitionsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      fiscalPeriodId,
    ) async {
      final client = Supabase.instance.client;

      final response = await client
          .from('expense_recognitions')
          .select('''
          id,
          company_id,
          fiscal_period_id,
          category_id,
          amount,
          description,
          created_by,
          created_at,
          updated_at,
          expense_categories (
            id,
            name,
            code,
            expense_type,
            is_active
          )
        ''')
          .eq('fiscal_period_id', fiscalPeriodId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    });

final expenseRecognitionSummaryProvider = FutureProvider.family<
  ExpenseRecognitionSummary,
  String
>((ref, fiscalPeriodId) async {
  final rows = await ref.watch(
    expenseRecognitionsProvider(fiscalPeriodId).future,
  );

  double operational = 0;
  double nonOperational = 0;

  for (final row in rows) {
    final amount = _toDouble(row['amount']);

    final category = row['expense_categories'];

    final type = category is Map ? category['expense_type']?.toString() : null;

    if (type == 'non_operational') {
      nonOperational += amount;
    } else {
      operational += amount;
    }
  }

  final total = operational + nonOperational;

  return ExpenseRecognitionSummary(
    operational: operational,
    nonOperational: nonOperational,
    total: total,
    categoryCount: rows.length,
  );
});

class ExpenseRecognitionService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<Map<String, dynamic>> saveRecognition({
    required String companyId,
    required String fiscalPeriodId,
    required String categoryId,
    required double amount,
    String? description,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    if (amount < 0) {
      throw Exception('مبلغ هزینه نمی‌تواند منفی باشد.');
    }

    final periodResponse =
        await _client
            .from('expense_fiscal_periods')
            .select('''
          id,
          company_id,
          status
        ''')
            .eq('id', fiscalPeriodId)
            .eq('company_id', companyId)
            .maybeSingle();

    if (periodResponse == null) {
      throw Exception('دوره مالی هزینه پیدا نشد.');
    }

    final period = Map<String, dynamic>.from(periodResponse);

    final status = period['status']?.toString() ?? 'open';

    if (status == 'closed') {
      throw Exception(
        'این دوره مالی بسته شده است و امکان ثبت یا ویرایش هزینه وجود ندارد.',
      );
    }

    final data = {
      'company_id': companyId,
      'fiscal_period_id': fiscalPeriodId,
      'category_id': categoryId,
      'amount': amount,
      'description': _cleanText(description),
      'created_by': user.id,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response =
        await _client
            .from('expense_recognitions')
            .upsert(data, onConflict: 'fiscal_period_id,category_id')
            .select('''
          id,
          company_id,
          fiscal_period_id,
          category_id,
          amount,
          description,
          created_by,
          created_at,
          updated_at,
          expense_categories (
            id,
            name,
            code,
            expense_type,
            is_active
          )
        ''')
            .single();

    return Map<String, dynamic>.from(response);
  }

  static Future<void> deleteRecognition(String id) async {
    final recognition =
        await _client
            .from('expense_recognitions')
            .select('fiscal_period_id')
            .eq('id', id)
            .maybeSingle();

    if (recognition == null) {
      throw Exception('رکورد هزینه پیدا نشد.');
    }

    final periodId = recognition['fiscal_period_id']?.toString();

    if (periodId == null || periodId.isEmpty) {
      throw Exception('دوره مالی رکورد مشخص نیست.');
    }

    final period =
        await _client
            .from('expense_fiscal_periods')
            .select('status')
            .eq('id', periodId)
            .maybeSingle();

    if (period == null) {
      throw Exception('دوره مالی پیدا نشد.');
    }

    if (period['status']?.toString() == 'closed') {
      throw Exception(
        'این دوره مالی بسته شده است و امکان حذف هزینه وجود ندارد.',
      );
    }

    await _client.from('expense_recognitions').delete().eq('id', id);
  }

  static Future<bool> isPeriodOpen(String periodId) async {
    final response =
        await _client
            .from('expense_fiscal_periods')
            .select('status')
            .eq('id', periodId)
            .maybeSingle();

    if (response == null) {
      return false;
    }

    return response['status']?.toString() == 'open';
  }

  static String? _cleanText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}

class ExpenseRecognitionSummary {
  final double operational;
  final double nonOperational;
  final double total;
  final int categoryCount;

  const ExpenseRecognitionSummary({
    required this.operational,
    required this.nonOperational,
    required this.total,
    required this.categoryCount,
  });

  double get operationalPercent {
    if (total <= 0) {
      return 0;
    }

    return (operational / total) * 100;
  }

  double get nonOperationalPercent {
    if (total <= 0) {
      return 0;
    }

    return (nonOperational / total) * 100;
  }
}

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString().replaceAll(',', '')) ?? 0;
}
