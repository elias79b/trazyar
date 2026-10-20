import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final payableFiscalYearsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, companyId) async {
  final rows = await Supabase.instance.client
      .from('payable_fiscal_years')
      .select('id, company_id, year, title, status, created_at')
      .eq('company_id', companyId)
      .order('year', ascending: false);
  return List<Map<String, dynamic>>.from(rows);
});

final payableFiscalPeriodsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, yearId) async {
  final rows = await Supabase.instance.client
      .from('payable_fiscal_periods')
      .select('id, fiscal_year_id, company_id, year, month, title, status, created_at')
      .eq('fiscal_year_id', yearId)
      .order('month');
  return List<Map<String, dynamic>>.from(rows);
});

final payableFiscalPeriodProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, periodId) async {
  final row = await Supabase.instance.client
      .from('payable_fiscal_periods')
      .select('id, fiscal_year_id, company_id, year, month, title, status, created_at')
      .eq('id', periodId)
      .maybeSingle();
  return row == null ? null : Map<String, dynamic>.from(row);
});

final payablesForPeriodProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, periodId) async {
  final rows = await Supabase.instance.client
      .from('payables')
      .select('id, company_id, fiscal_period_id, creditor_name, title, amount, due_date, reference_number, description, status, created_at')
      .eq('fiscal_period_id', periodId)
      .order('created_at');
  return List<Map<String, dynamic>>.from(rows);
});

class PayableFiscalWorkflowService {
  static Future<void> process({
    required String periodId,
    required String action,
    String? note,
  }) async {
    await Supabase.instance.client.rpc(
      'process_payable_fiscal_period',
      params: {
        'p_period_id': periodId,
        'p_action': action,
        'p_note': note,
      },
    );
  }
}
