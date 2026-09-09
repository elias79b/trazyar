import 'package:supabase_flutter/supabase_flutter.dart';

import 'payroll_period_model.dart';

class PayrollPeriodRepository {
  PayrollPeriodRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'payroll_periods';

  // ============================================================
  // VALID DATABASE STATUSES
  // ============================================================

  static const Set<String> validStatuses = {
    'draft',
    'pending_ceo',
    'ceo_approved',
    'pending_consultant',
    'consultant_approved',
    'rejected',
    'paid',
    'cancelled',
  };

  // ============================================================
  // GET ALL
  // ============================================================

  Future<List<PayrollPeriodModel>> getPeriods(String companyId) async {
    if (companyId.trim().isEmpty) {
      throw Exception('شناسه شرکت خالی است.');
    }

    final response = await _client
        .from(_table)
        .select()
        .eq('company_id', companyId)
        .order('period_year', ascending: false)
        .order('period_month', ascending: false);

    return (response as List)
        .map(
          (row) => PayrollPeriodModel.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  // ============================================================
  // GET ALL - NEW NAME
  // ============================================================

  Future<List<PayrollPeriodModel>> fetchPeriods(String companyId) async {
    return getPeriods(companyId);
  }

  // ============================================================
  // GET ONE
  // ============================================================

  Future<PayrollPeriodModel?> getPeriodById(String id) async {
    if (id.trim().isEmpty) {
      throw Exception('شناسه دوره خالی است.');
    }

    final response =
        await _client.from(_table).select().eq('id', id).maybeSingle();

    if (response == null) {
      return null;
    }

    return PayrollPeriodModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ============================================================
  // GET ONE - NEW NAME
  // ============================================================

  Future<PayrollPeriodModel?> fetchPeriodById(String id) async {
    return getPeriodById(id);
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<PayrollPeriodModel> createPeriod({
    required String companyId,
    required int periodYear,
    required int periodMonth,

    // دوره جدید به صورت پیش‌فرض draft است.
    String status = 'draft',

    String? notes,
  }) async {
    if (companyId.trim().isEmpty) {
      throw Exception('شناسه شرکت خالی است.');
    }

    if (periodYear < 1300 || periodYear > 1600) {
      throw Exception('سال دوره حقوق معتبر نیست.');
    }

    if (periodMonth < 1 || periodMonth > 12) {
      throw Exception('ماه دوره حقوق معتبر نیست.');
    }

    if (!validStatuses.contains(status)) {
      throw Exception('وضعیت دوره حقوق معتبر نیست: $status');
    }

    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد نشده است.');
    }

    // ==========================================================
    // CHECK DUPLICATE
    // ==========================================================

    final existing =
        await _client
            .from(_table)
            .select('id')
            .eq('company_id', companyId)
            .eq('period_year', periodYear)
            .eq('period_month', periodMonth)
            .maybeSingle();

    if (existing != null) {
      throw Exception('این دوره حقوق قبلاً برای این شرکت ثبت شده است.');
    }

    // ==========================================================
    // INSERT
    // ==========================================================

    final response =
        await _client
            .from(_table)
            .insert({
              'company_id': companyId,
              'period_year': periodYear,
              'period_month': periodMonth,

              // مهم:
              // فقط Status معتبر دیتابیس
              'status': status,

              'notes': _nullableText(notes),
              'created_by': user.id,
            })
            .select()
            .single();

    return PayrollPeriodModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<PayrollPeriodModel> updatePeriod({
    required String id,
    required int periodYear,
    required int periodMonth,
    required String status,
    String? notes,
  }) async {
    if (id.trim().isEmpty) {
      throw Exception('شناسه دوره خالی است.');
    }

    if (periodYear < 1300 || periodYear > 1600) {
      throw Exception('سال دوره حقوق معتبر نیست.');
    }

    if (periodMonth < 1 || periodMonth > 12) {
      throw Exception('ماه دوره حقوق معتبر نیست.');
    }

    if (!validStatuses.contains(status)) {
      throw Exception('وضعیت دوره حقوق معتبر نیست: $status');
    }

    final response =
        await _client
            .from(_table)
            .update({
              'period_year': periodYear,
              'period_month': periodMonth,
              'status': status,
              'notes': _nullableText(notes),
            })
            .eq('id', id)
            .select()
            .single();

    return PayrollPeriodModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ============================================================
  // UPDATE STATUS ONLY
  // ============================================================

  Future<PayrollPeriodModel> updateStatus({
    required String id,
    required String status,
  }) async {
    if (id.trim().isEmpty) {
      throw Exception('شناسه دوره خالی است.');
    }

    if (!validStatuses.contains(status)) {
      throw Exception('وضعیت دوره حقوق معتبر نیست: $status');
    }

    final response =
        await _client
            .from(_table)
            .update({'status': status})
            .eq('id', id)
            .select()
            .single();

    return PayrollPeriodModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deletePeriod(String id) async {
    if (id.trim().isEmpty) {
      throw Exception('شناسه دوره خالی است.');
    }

    await _client.from(_table).delete().eq('id', id);
  }

  // ============================================================
  // CHECK EXISTS
  // ============================================================

  Future<bool> periodExists({
    required String companyId,
    required int periodYear,
    required int periodMonth,
    String? exceptId,
  }) async {
    if (companyId.trim().isEmpty) {
      return false;
    }

    final response = await _client
        .from(_table)
        .select('id')
        .eq('company_id', companyId)
        .eq('period_year', periodYear)
        .eq('period_month', periodMonth);

    final rows = response as List;

    if (exceptId == null || exceptId.trim().isEmpty) {
      return rows.isNotEmpty;
    }

    return rows.any((row) => row['id']?.toString() != exceptId);
  }

  // ============================================================
  // FIND PERIOD
  // ============================================================

  Future<PayrollPeriodModel?> findPeriod({
    required String companyId,
    required int periodYear,
    required int periodMonth,
  }) async {
    final response =
        await _client
            .from(_table)
            .select()
            .eq('company_id', companyId)
            .eq('period_year', periodYear)
            .eq('period_month', periodMonth)
            .maybeSingle();

    if (response == null) {
      return null;
    }

    return PayrollPeriodModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ============================================================
  // HELPER
  // ============================================================

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
}
