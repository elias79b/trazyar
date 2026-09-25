import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// PROVIDER
// ============================================================

final incomeRecognitionsProvider =
FutureProvider.family<List<Map<String, dynamic>>, String>(
      (
      ref,
      fiscalPeriodId,
      ) async {
    final client = Supabase.instance.client;

    final response = await client
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
          updated_at,
          income_categories(
            id,
            name,
            code,
            category_type,
            is_system
          )
        ''')
        .eq(
      'fiscal_period_id',
      fiscalPeriodId,
    )
        .order(
      'created_at',
      ascending: true,
    );

    return List<Map<String, dynamic>>.from(
      response,
    );
  },
);

// ============================================================
// SUMMARY
// ============================================================

final incomeRecognitionSummaryProvider =
FutureProvider.family<IncomeRecognitionSummary, String>(
      (
      ref,
      fiscalPeriodId,
      ) async {
    final rows = await ref.watch(
      incomeRecognitionsProvider(
        fiscalPeriodId,
      ).future,
    );

    double operational = 0;
    double nonOperational = 0;

    for (final row in rows) {
      final amount = _toDouble(
        row['amount'],
      );

      final category =
      row['income_categories'];

      final categoryType =
      category is Map
          ? category['category_type']?.toString()
          : null;

      if (categoryType == 'non_operational') {
        nonOperational += amount;
      } else {
        operational += amount;
      }
    }

    return IncomeRecognitionSummary(
      operational: operational,
      nonOperational: nonOperational,
    );
  },
);

// ============================================================
// SERVICE
// ============================================================

class IncomeRecognitionService {
  static final SupabaseClient _client =
      Supabase.instance.client;

  static Future<Map<String, dynamic>>
  saveRecognition({
    required String companyId,
    required String fiscalPeriodId,
    required String categoryId,
    required double amount,
    String? description,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'کاربر وارد سیستم نشده است.',
      );
    }

    if (companyId.trim().isEmpty) {
      throw Exception(
        'شناسه شرکت معتبر نیست.',
      );
    }

    if (fiscalPeriodId.trim().isEmpty) {
      throw Exception(
        'شناسه دوره مالی معتبر نیست.',
      );
    }

    if (categoryId.trim().isEmpty) {
      throw Exception(
        'دسته‌بندی درآمد معتبر نیست.',
      );
    }

    if (amount < 0) {
      throw Exception(
        'مبلغ درآمد نمی‌تواند منفی باشد.',
      );
    }

    final data = <String, dynamic>{
      'company_id': companyId,
      'fiscal_period_id': fiscalPeriodId,
      'category_id': categoryId,
      'amount': amount,
      'description': _cleanText(
        description,
      ),
      'created_by': user.id,
      'updated_at':
      DateTime.now().toIso8601String(),
    };

    try {
      final response = await _client
          .from('income_recognitions')
          .upsert(
        data,
        onConflict:
        'fiscal_period_id,category_id',
      )
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
          .single();

      return Map<String, dynamic>.from(
        response,
      );
    } on PostgrestException catch (error) {
      throw Exception(
        'خطای دیتابیس درآمد:\n'
            '${error.message}'
            '${error.code != null ? '\nکد: ${error.code}' : ''}'
            '${error.details != null ? '\nجزئیات: ${error.details}' : ''}',
      );
    } catch (error) {
      throw Exception(
        'خطا در ثبت درآمد:\n$error',
      );
    }
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  static Future<void> deleteRecognition(
      String id,
      ) async {
    if (id.trim().isEmpty) {
      throw Exception(
        'شناسه ثبت درآمد معتبر نیست.',
      );
    }

    try {
      await _client
          .from('income_recognitions')
          .delete()
          .eq(
        'id',
        id,
      );
    } on PostgrestException catch (error) {
      throw Exception(
        'خطای حذف ثبت درآمد:\n'
            '${error.message}'
            '${error.code != null ? '\nکد: ${error.code}' : ''}'
            '${error.details != null ? '\nجزئیات: ${error.details}' : ''}',
      );
    }
  }
}

// ============================================================
// SUMMARY MODEL
// ============================================================

class IncomeRecognitionSummary {
  final double operational;
  final double nonOperational;

  const IncomeRecognitionSummary({
    required this.operational,
    required this.nonOperational,
  });

  double get total =>
      operational + nonOperational;

  double get operationalPercent {
    if (total <= 0) {
      return 0;
    }

    return (
        operational / total
    ) *
        100;
  }

  double get nonOperationalPercent {
    if (total <= 0) {
      return 0;
    }

    return (
        nonOperational / total
    ) *
        100;
  }
}

// ============================================================
// HELPERS
// ============================================================

String? _cleanText(
    String? value,
    ) {
  final text = value?.trim();

  if (text == null ||
      text.isEmpty) {
    return null;
  }

  return text;
}

double _toDouble(
    dynamic value,
    ) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value.toString(),
  ) ??
      0;
}