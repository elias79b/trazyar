import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// INCOME PROVIDER
// ============================================================

final incomeProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      companyId,
    ) async {
      final client = Supabase.instance.client;

      final response = await client
          .from('income_records')
          .select('''
        id,
        company_id,
        category_id,
        title,
        description,
        amount,
        income_date,
        reference_number,
        status,
        created_by,
        created_at,
        updated_at,
        income_categories (
          id,
          name,
          code
        )
      ''')
          .eq('company_id', companyId)
          .order('income_date', ascending: false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    });

// ============================================================
// SERVICE PROVIDER
// ============================================================

final incomeServiceProvider = Provider<IncomeService>((ref) {
  return IncomeService(Supabase.instance.client);
});

// ============================================================
// INCOME SERVICE
// ============================================================

class IncomeService {
  final SupabaseClient client;

  IncomeService(this.client);

  // ==========================================================
  // CREATE
  // ==========================================================

  Future<Map<String, dynamic>> createIncome({
    required String companyId,
    required String title,
    required num amount,
    required DateTime incomeDate,
    String? categoryId,
    String? description,
    String? referenceNumber,
    String status = 'received',
  }) async {
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد حساب کاربری نشده است.');
    }

    if (title.trim().isEmpty) {
      throw Exception('عنوان درآمد الزامی است.');
    }

    if (amount < 0) {
      throw Exception('مبلغ درآمد نمی‌تواند منفی باشد.');
    }

    final result =
        await client
            .from('income_records')
            .insert({
              'company_id': companyId,
              'category_id': categoryId,
              'title': title.trim(),
              'description': _nullableText(description),
              'amount': amount,
              'income_date': _dateOnly(incomeDate),
              'reference_number': _nullableText(referenceNumber),
              'status': status,
              'created_by': user.id,
            })
            .select()
            .single();

    return Map<String, dynamic>.from(result);
  }

  // ==========================================================
  // UPDATE
  // ==========================================================

  Future<Map<String, dynamic>> updateIncome({
    required String id,
    required String title,
    required num amount,
    required DateTime incomeDate,
    String? categoryId,
    String? description,
    String? referenceNumber,
    required String status,
  }) async {
    if (title.trim().isEmpty) {
      throw Exception('عنوان درآمد الزامی است.');
    }

    if (amount < 0) {
      throw Exception('مبلغ درآمد نمی‌تواند منفی باشد.');
    }

    final result =
        await client
            .from('income_records')
            .update({
              'category_id': categoryId,
              'title': title.trim(),
              'description': _nullableText(description),
              'amount': amount,
              'income_date': _dateOnly(incomeDate),
              'reference_number': _nullableText(referenceNumber),
              'status': status,
            })
            .eq('id', id)
            .select()
            .single();

    return Map<String, dynamic>.from(result);
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  Future<void> deleteIncome(String id) async {
    await client.from('income_records').delete().eq('id', id);
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  String? _nullableText(String? value) {
    if (value == null) {
      return null;
    }

    final text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
