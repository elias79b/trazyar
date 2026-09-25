import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final expenseFiscalYearsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      companyId,
    ) async {
      final client = Supabase.instance.client;

      final response = await client
          .from('expense_fiscal_years')
          .select('''
          id,
          company_id,
          year,
          title,
          status,
          created_by,
          created_at,
          updated_at
        ''')
          .eq('company_id', companyId)
          .order('year', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    });

final expenseFiscalPeriodsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      fiscalYearId,
    ) async {
      final client = Supabase.instance.client;

      final response = await client
          .from('expense_fiscal_periods')
          .select('''
          id,
          fiscal_year_id,
          company_id,
          year,
          month,
          title,
          status,
          created_at,
          updated_at
        ''')
          .eq('fiscal_year_id', fiscalYearId)
          .order('month', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    });

final expenseFiscalPeriodProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, periodId) async {
      final client = Supabase.instance.client;

      final response =
          await client
              .from('expense_fiscal_periods')
              .select('''
          id,
          fiscal_year_id,
          company_id,
          year,
          month,
          title,
          status,
          created_at,
          updated_at
        ''')
              .eq('id', periodId)
              .maybeSingle();

      if (response == null) {
        return null;
      }

      return Map<String, dynamic>.from(response);
    });

class ExpenseFiscalService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<String> createFiscalYear({
    required String companyId,
    required int year,
    String? title,
  }) async {
    final response = await _client.rpc(
      'create_expense_fiscal_year',
      params: {'p_company_id': companyId, 'p_year': year, 'p_title': title},
    );

    if (response == null) {
      throw Exception('ایجاد سال مالی هزینه انجام نشد.');
    }

    return response.toString();
  }

  static Future<void> closeFiscalYear(String yearId) async {
    final year =
        await _client
            .from('expense_fiscal_years')
            .select('status')
            .eq('id', yearId)
            .maybeSingle();

    if (year == null) {
      throw Exception('سال مالی پیدا نشد.');
    }

    if (year['status']?.toString() == 'closed') {
      return;
    }

    await _client
        .from('expense_fiscal_years')
        .update({
          'status': 'closed',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', yearId);
  }

  static Future<void> reopenFiscalYear(String yearId) async {
    final year =
        await _client
            .from('expense_fiscal_years')
            .select('status')
            .eq('id', yearId)
            .maybeSingle();

    if (year == null) {
      throw Exception('سال مالی پیدا نشد.');
    }

    if (year['status']?.toString() == 'open') {
      return;
    }

    await _client
        .from('expense_fiscal_years')
        .update({
          'status': 'open',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', yearId);
  }

  static Future<void> closeFiscalPeriod(String periodId) async {
    await _client.rpc(
      'set_expense_period_status',
      params: {'p_period_id': periodId, 'p_status': 'closed'},
    );
  }

  static Future<void> reopenFiscalPeriod(String periodId) async {
    await _client.rpc(
      'set_expense_period_status',
      params: {'p_period_id': periodId, 'p_status': 'open'},
    );
  }
}
