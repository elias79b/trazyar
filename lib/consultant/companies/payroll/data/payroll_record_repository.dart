import 'package:supabase_flutter/supabase_flutter.dart';

import 'payroll_record_model.dart';

class PayrollRecordRepository {
  PayrollRecordRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'payroll_records';

  // ==========================================================
  // GET ALL BY COMPANY
  // ==========================================================

  Future<List<PayrollRecordModel>> getRecords(String companyId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) => PayrollRecordModel.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  // ==========================================================
  // GET BY PERIOD
  // ==========================================================

  Future<List<PayrollRecordModel>> getRecordsByPeriod(
    String payrollPeriodId,
  ) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('payroll_period_id', payrollPeriodId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) => PayrollRecordModel.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  // ==========================================================
  // GET ONE
  // ==========================================================

  Future<PayrollRecordModel?> getRecordById(String id) async {
    final response =
        await _client.from(_table).select().eq('id', id).maybeSingle();

    if (response == null) {
      return null;
    }

    return PayrollRecordModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ==========================================================
  // GET EMPLOYEE RECORD IN PERIOD
  // ==========================================================

  Future<PayrollRecordModel?> getEmployeeRecord({
    required String payrollPeriodId,
    required String employeeId,
  }) async {
    final response =
        await _client
            .from(_table)
            .select()
            .eq('payroll_period_id', payrollPeriodId)
            .eq('employee_id', employeeId)
            .maybeSingle();

    if (response == null) {
      return null;
    }

    return PayrollRecordModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ==========================================================
  // CHECK DUPLICATE
  // ==========================================================

  Future<bool> employeeHasPayrollRecord({
    required String payrollPeriodId,
    required String employeeId,
    String? excludeRecordId,
  }) async {
    final response = await _client
        .from(_table)
        .select('id')
        .eq('payroll_period_id', payrollPeriodId)
        .eq('employee_id', employeeId);

    final rows = List<Map<String, dynamic>>.from(
      (response as List).map((row) => Map<String, dynamic>.from(row)),
    );

    if (excludeRecordId == null) {
      return rows.isNotEmpty;
    }

    return rows.any((row) => row['id'] != excludeRecordId);
  }

  // ==========================================================
  // CREATE
  // ==========================================================

  Future<PayrollRecordModel> createRecord({
    required String companyId,
    required String payrollPeriodId,
    required String employeeId,
    String? contractId,

    required double baseSalary,

    double overtimeHours = 0,
    double overtimeAmount = 0,

    double bonusAmount = 0,
    double allowanceAmount = 0,

    required double grossSalary,

    double employeeInsurance = 0,
    double employerInsurance = 0,

    double taxAmount = 0,

    double absenceAmount = 0,
    double otherDeductions = 0,
    double advanceAmount = 0,

    required double netSalary,

    String? notes,
  }) async {
    // ----------------------------------------------------------
    // CHECK DUPLICATE
    // ----------------------------------------------------------

    final existing = await getEmployeeRecord(
      payrollPeriodId: payrollPeriodId,
      employeeId: employeeId,
    );

    if (existing != null) {
      throw Exception('برای این پرسنل در این دوره حقوق قبلاً ثبت شده است.');
    }

    final userId = _client.auth.currentUser?.id;

    // ----------------------------------------------------------
    // INSERT
    // ----------------------------------------------------------

    final response =
        await _client
            .from(_table)
            .insert({
              'company_id': companyId,
              'payroll_period_id': payrollPeriodId,
              'employee_id': employeeId,
              'contract_id': contractId,

              'base_salary': baseSalary,

              'overtime_hours': overtimeHours,
              'overtime_amount': overtimeAmount,

              'bonus_amount': bonusAmount,
              'allowance_amount': allowanceAmount,

              'gross_salary': grossSalary,

              'employee_insurance': employeeInsurance,
              'employer_insurance': employerInsurance,

              'tax_amount': taxAmount,

              'absence_amount': absenceAmount,
              'other_deductions': otherDeductions,
              'advance_amount': advanceAmount,

              'net_salary': netSalary,

              'notes': _nullableText(notes),

              'created_by': userId,
            })
            .select()
            .single();

    return PayrollRecordModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ==========================================================
  // UPDATE
  // ==========================================================

  Future<PayrollRecordModel> updateRecord({
    required String id,

    String? contractId,

    required double baseSalary,

    double overtimeHours = 0,
    double overtimeAmount = 0,

    double bonusAmount = 0,
    double allowanceAmount = 0,

    required double grossSalary,

    double employeeInsurance = 0,
    double employerInsurance = 0,

    double taxAmount = 0,

    double absenceAmount = 0,
    double otherDeductions = 0,
    double advanceAmount = 0,

    required double netSalary,

    String? notes,
  }) async {
    final response =
        await _client
            .from(_table)
            .update({
              'contract_id': contractId,

              'base_salary': baseSalary,

              'overtime_hours': overtimeHours,
              'overtime_amount': overtimeAmount,

              'bonus_amount': bonusAmount,
              'allowance_amount': allowanceAmount,

              'gross_salary': grossSalary,

              'employee_insurance': employeeInsurance,
              'employer_insurance': employerInsurance,

              'tax_amount': taxAmount,

              'absence_amount': absenceAmount,
              'other_deductions': otherDeductions,
              'advance_amount': advanceAmount,

              'net_salary': netSalary,

              'notes': _nullableText(notes),

              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id)
            .select()
            .single();

    return PayrollRecordModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  Future<void> deleteRecord(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  // ==========================================================
  // HELPER
  // ==========================================================

  String? _nullableText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}
