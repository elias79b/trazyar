import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سال‌های مالی اختصاصی حساب‌های دریافتنی.
final incomeReceivableFiscalYearsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, companyId) async {
    final response = await Supabase.instance.client
        .from('income_receivable_fiscal_years')
        .select('id, company_id, year, title, status, created_by, created_at, updated_at')
        .eq('company_id', companyId)
        .order('year', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  },
);

/// دوره‌های ماهانه یک سال مالی حساب‌های دریافتنی.
final incomeReceivableFiscalPeriodsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, fiscalYearId) async {
    final response = await Supabase.instance.client
        .from('income_receivable_fiscal_periods')
        .select('id, fiscal_year_id, company_id, year, month, title, status, created_at, updated_at')
        .eq('fiscal_year_id', fiscalYearId)
        .order('month', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  },
);

/// اطلاعات دوره‌ای که صفحه جزئیات دریافتنی‌ها به آن وابسته است.
final incomeReceivableFiscalPeriodProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, periodId) async {
    final response = await Supabase.instance.client
        .from('income_receivable_fiscal_periods')
        .select('id, fiscal_year_id, company_id, year, month, title, status, created_at, updated_at')
        .eq('id', periodId)
        .maybeSingle();
    return response == null ? null : Map<String, dynamic>.from(response);
  },
);
