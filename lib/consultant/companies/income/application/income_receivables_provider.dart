import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final incomeReceivablesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      fiscalPeriodId,
    ) async {
      final client = Supabase.instance.client;

      final response = await client
          .from('income_receivables')
          .select('''
            id,
            company_id,
            fiscal_period_id,
            title,
            amount,
            received_documents_amount,
            description,
            created_by,
            created_at,
            updated_at
          ''')
          .eq('fiscal_period_id', fiscalPeriodId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    });

final incomeReceivablesSummaryProvider =
    FutureProvider.family<IncomeReceivablesSummary, String>((
      ref,
      fiscalPeriodId,
    ) async {
      final rows = await ref.watch(
        incomeReceivablesProvider(fiscalPeriodId).future,
      );

      double total = 0;
      double receivedDocuments = 0;

      for (final row in rows) {
        total += _toDouble(row['amount']);
        receivedDocuments += _toDouble(row['received_documents_amount']);
      }

      final remaining = total - receivedDocuments;

      return IncomeReceivablesSummary(
        total: total,
        receivedDocumentsAmount: receivedDocuments,
        remainingAmount: remaining < 0 ? 0 : remaining,
        documentCount: rows.length,
      );
    });

class IncomeReceivablesService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<Map<String, dynamic>> saveReceivable({
    required String companyId,
    required String fiscalPeriodId,
    required String title,
    required double amount,
    required double receivedDocumentsAmount,
    String? description,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw Exception('عنوان حساب دریافتنی الزامی است.');
    }

    if (amount < 0) {
      throw Exception('مبلغ حساب دریافتنی نمی‌تواند منفی باشد.');
    }

    if (receivedDocumentsAmount < 0) {
      throw Exception('مبلغ اسناد دریافت‌شده نمی‌تواند منفی باشد.');
    }

    if (receivedDocumentsAmount > amount) {
      throw Exception(
        'مبلغ اسناد دریافت‌شده نمی‌تواند بیشتر از مبلغ دریافتنی باشد.',
      );
    }

    final data = {
      'company_id': companyId,
      'fiscal_period_id': fiscalPeriodId,
      'title': cleanTitle,
      'amount': amount,
      'received_documents_amount': receivedDocumentsAmount,
      'description': _cleanText(description),
      'created_by': user.id,
    };

    final response =
        await _client.from('income_receivables').insert(data).select('''
          id,
          company_id,
          fiscal_period_id,
          title,
          amount,
          received_documents_amount,
          description,
          created_by,
          created_at,
          updated_at
        ''').single();

    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>> updateReceivable({
    required String id,
    required String title,
    required double amount,
    required double receivedDocumentsAmount,
    String? description,
  }) async {
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) {
      throw Exception('عنوان حساب دریافتنی الزامی است.');
    }

    if (amount < 0) {
      throw Exception('مبلغ حساب دریافتنی نمی‌تواند منفی باشد.');
    }

    if (receivedDocumentsAmount < 0) {
      throw Exception('مبلغ اسناد دریافت‌شده نمی‌تواند منفی باشد.');
    }

    if (receivedDocumentsAmount > amount) {
      throw Exception(
        'مبلغ اسناد دریافت‌شده نمی‌تواند بیشتر از مبلغ دریافتنی باشد.',
      );
    }

    final response =
        await _client
            .from('income_receivables')
            .update({
              'title': cleanTitle,
              'amount': amount,
              'received_documents_amount': receivedDocumentsAmount,
              'description': _cleanText(description),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id)
            .select('''
          id,
          company_id,
          fiscal_period_id,
          title,
          amount,
          received_documents_amount,
          description,
          created_by,
          created_at,
          updated_at
        ''')
            .single();

    return Map<String, dynamic>.from(response);
  }

  static Future<void> deleteReceivable(String id) async {
    await _client.from('income_receivables').delete().eq('id', id);
  }

  static String? _cleanText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}

class IncomeReceivablesSummary {
  final double total;
  final double receivedDocumentsAmount;
  final double remainingAmount;
  final int documentCount;

  const IncomeReceivablesSummary({
    required this.total,
    required this.receivedDocumentsAmount,
    required this.remainingAmount,
    required this.documentCount,
  });

  double get receivedPercent {
    if (total <= 0) return 0;
    return (receivedDocumentsAmount / total) * 100;
  }

  double get remainingPercent {
    if (total <= 0) return 0;
    return (remainingAmount / total) * 100;
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}
