import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String _receivableColumns = '''
  id,
  company_id,
  fiscal_period_id,
  title,
  amount,
  received_documents_amount,
  description,
  created_by,
  created_at,
  updated_at,
  status
''';

/// دریافت حساب‌های دریافتنی یک دوره مالی
final incomeReceivablesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      fiscalPeriodId,
    ) async {
      final response = await Supabase.instance.client
          .from('income_receivables')
          .select(_receivableColumns)
          .eq('fiscal_period_id', fiscalPeriodId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    });

/// محاسبه خلاصه حساب‌های دریافتنی یک دوره مالی
final incomeReceivablesSummaryProvider =
    FutureProvider.family<IncomeReceivablesSummary, String>((
      ref,
      fiscalPeriodId,
    ) async {
      final rows = await ref.watch(
        incomeReceivablesProvider(fiscalPeriodId).future,
      );

      double total = 0;
      double received = 0;

      for (final row in rows) {
        total += _toDouble(row['amount']);
        received += _toDouble(row['received_documents_amount']);
      }

      return IncomeReceivablesSummary(
        total: total,
        receivedDocumentsAmount: received,
        remainingAmount: (total - received).clamp(0.0, double.infinity),
        documentCount: rows.length,
      );
    });

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

  // نام‌های سازگار با استفاده‌های موجود در صفحه
  double get receivedDocuments => receivedDocumentsAmount;

  double get remaining => remainingAmount;

  int get count => documentCount;

  double get receivedPercent =>
      total <= 0 ? 0 : receivedDocumentsAmount / total * 100;

  double get remainingPercent => total <= 0 ? 0 : remainingAmount / total * 100;
}

/// سرویس عملیات حساب‌های دریافتنی و گردش کار مشاور
class IncomeReceivablesService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// ثبت حساب دریافتنی
  static Future<Map<String, dynamic>> saveReceivable({
    required String companyId,
    required String fiscalPeriodId,
    required String title,
    required double amount,
    required double receivedDocumentsAmount,
    String? description,
  }) async {
    _validate(
      title: title,
      amount: amount,
      receivedDocumentsAmount: receivedDocumentsAmount,
    );

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('برای ثبت اطلاعات ابتدا وارد حساب کاربری شوید.');
    }

    final response =
        await _client
            .from('income_receivables')
            .insert({
              'company_id': companyId,
              'fiscal_period_id': fiscalPeriodId,
              'title': title.trim(),
              'amount': amount,
              'received_documents_amount': receivedDocumentsAmount,
              'description': _cleanText(description),
              'created_by': userId,
            })
            .select(_receivableColumns)
            .single();

    return Map<String, dynamic>.from(response);
  }

  /// ویرایش حساب دریافتنی
  static Future<Map<String, dynamic>> updateReceivable({
    required String id,
    required String title,
    required double amount,
    required double receivedDocumentsAmount,
    String? description,
  }) async {
    _validate(
      title: title,
      amount: amount,
      receivedDocumentsAmount: receivedDocumentsAmount,
    );

    final response =
        await _client
            .from('income_receivables')
            .update({
              'title': title.trim(),
              'amount': amount,
              'received_documents_amount': receivedDocumentsAmount,
              'description': _cleanText(description),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', id)
            .select(_receivableColumns)
            .single();

    return Map<String, dynamic>.from(response);
  }

  /// حذف حساب دریافتنی
  static Future<void> deleteReceivable(String id) async {
    await _client.from('income_receivables').delete().eq('id', id);
  }

  /// تأیید حساب دریافتنی توسط مشاور
  static Future<Map<String, dynamic>> approveByConsultant({
    required String receivableId,
    String? note,
  }) async {
    final response = await _client.rpc(
      'process_income_receivable',
      params: {
        'p_receivable_id': receivableId,
        'p_action': 'approve_by_consultant',
        'p_note': _cleanText(note),
      },
    );

    return Map<String, dynamic>.from(response as Map);
  }

  /// برگشت حساب دریافتنی توسط مشاور
  static Future<Map<String, dynamic>> returnByConsultant({
    required String receivableId,
    required String note,
  }) async {
    if (note.trim().isEmpty) {
      throw Exception('لطفاً علت برگشت را وارد کنید.');
    }

    final response = await _client.rpc(
      'process_income_receivable',
      params: {
        'p_receivable_id': receivableId,
        'p_action': 'return_by_consultant',
        'p_note': note.trim(),
      },
    );

    return Map<String, dynamic>.from(response as Map);
  }

  static void _validate({
    required String title,
    required double amount,
    required double receivedDocumentsAmount,
  }) {
    if (title.trim().isEmpty) {
      throw Exception('عنوان حساب دریافتنی را وارد کنید.');
    }

    if (amount < 0) {
      throw Exception('مبلغ حساب دریافتنی نمی‌تواند منفی باشد.');
    }

    if (receivedDocumentsAmount < 0) {
      throw Exception('مبلغ مدارک دریافت‌شده نمی‌تواند منفی باشد.');
    }

    if (receivedDocumentsAmount > amount) {
      throw Exception('مبلغ مدارک دریافت‌شده نمی‌تواند از مبلغ کل بیشتر باشد.');
    }
  }

  static String? _cleanText(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
