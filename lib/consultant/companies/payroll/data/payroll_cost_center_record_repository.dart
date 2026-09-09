import 'package:supabase_flutter/supabase_flutter.dart';

import 'payroll_cost_center_record_model.dart';

class PayrollCostCenterRecordRepository {
  PayrollCostCenterRecordRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'payroll_cost_center_records';

  static const String _select = '''
    *,
    cost_centers (
      id,
      name,
      code
    )
  ''';

  // ============================================================
  // GET BY PERIOD
  // ============================================================

  Future<List<PayrollCostCenterRecordModel>> getByPeriod(
    String payrollPeriodId,
  ) async {
    final response = await _client
        .from(_table)
        .select(_select)
        .eq('payroll_period_id', payrollPeriodId)
        .order('created_at', ascending: true);

    return (response as List)
        .map(
          (row) => PayrollCostCenterRecordModel.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  // ============================================================
  // GET ONE
  // ============================================================

  Future<PayrollCostCenterRecordModel?> getById(String id) async {
    final response =
        await _client.from(_table).select(_select).eq('id', id).maybeSingle();

    if (response == null) {
      return null;
    }

    return PayrollCostCenterRecordModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // GET BY PERIOD + COST CENTER
  // ============================================================

  Future<PayrollCostCenterRecordModel?> getByPeriodAndCostCenter({
    required String payrollPeriodId,
    required String costCenterId,
    String? excludeRecordId,
  }) async {
    var query = _client
        .from(_table)
        .select(_select)
        .eq('payroll_period_id', payrollPeriodId)
        .eq('cost_center_id', costCenterId);

    if (excludeRecordId != null) {
      query = query.neq('id', excludeRecordId);
    }

    final response = await query.maybeSingle();

    if (response == null) {
      return null;
    }

    return PayrollCostCenterRecordModel.fromMap(
      Map<String, dynamic>.from(response),
    );
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<PayrollCostCenterRecordModel> create({
    required String companyId,
    required String payrollPeriodId,
    required String costCenterId,
    required int employeeCount,
    required double baseSalary,
    required double senioritySalary,
    required double mealAllowance,
    required double housingAllowance,
    required double maritalAllowance,
    required double overtimeAmount,
    required double missionAllowance,
    required double performanceBonus,
    required double productionIncreaseBonus,
    required double monthlySeniorityBenefit,
    required double monthlyEndServiceBonus,
    required double missionTravelCost,
    required double employerInsurance,
    required double unemploymentInsurance,
  }) async {
    // ----------------------------------------------------------
    // DUPLICATE CHECK
    // ----------------------------------------------------------

    final existing = await getByPeriodAndCostCenter(
      payrollPeriodId: payrollPeriodId,
      costCenterId: costCenterId,
    );

    if (existing != null) {
      throw Exception(
        'برای این مرکز هزینه در این دوره حقوق قبلاً ثبت شده است.',
      );
    }

    final userId = _client.auth.currentUser?.id;

    // ----------------------------------------------------------
    // INSERT
    // ----------------------------------------------------------

    try {
      final response =
          await _client
              .from(_table)
              .insert({
                'company_id': companyId,
                'payroll_period_id': payrollPeriodId,
                'cost_center_id': costCenterId,
                'employee_count': employeeCount,
                'base_salary': baseSalary,
                'seniority_salary': senioritySalary,
                'meal_allowance': mealAllowance,
                'housing_allowance': housingAllowance,
                'marital_allowance': maritalAllowance,
                'overtime_amount': overtimeAmount,
                'mission_allowance': missionAllowance,
                'performance_bonus': performanceBonus,
                'production_increase_bonus': productionIncreaseBonus,
                'monthly_seniority_benefit': monthlySeniorityBenefit,
                'monthly_end_service_bonus': monthlyEndServiceBonus,
                'mission_travel_cost': missionTravelCost,
                'employer_insurance': employerInsurance,
                'unemployment_insurance': unemploymentInsurance,
                'created_by': userId,
              })
              .select(_select)
              .single();

      return PayrollCostCenterRecordModel.fromMap(
        Map<String, dynamic>.from(response),
      );
    } on PostgrestException catch (e) {
      if (e.code == '23505' ||
          e.message.contains('payroll_cost_center_records_unique')) {
        throw Exception(
          'برای این مرکز هزینه در این دوره حقوق قبلاً ثبت شده است.',
        );
      }

      rethrow;
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<PayrollCostCenterRecordModel> update({
    required String id,
    required String costCenterId,
    required int employeeCount,
    required double baseSalary,
    required double senioritySalary,
    required double mealAllowance,
    required double housingAllowance,
    required double maritalAllowance,
    required double overtimeAmount,
    required double missionAllowance,
    required double performanceBonus,
    required double productionIncreaseBonus,
    required double monthlySeniorityBenefit,
    required double monthlyEndServiceBonus,
    required double missionTravelCost,
    required double employerInsurance,
    required double unemploymentInsurance,
  }) async {
    // ----------------------------------------------------------
    // DUPLICATE CHECK
    // ----------------------------------------------------------

    final existing = await getByPeriodAndCostCenter(
      payrollPeriodId: await _getPayrollPeriodId(id),
      costCenterId: costCenterId,
      excludeRecordId: id,
    );

    if (existing != null) {
      throw Exception('این مرکز هزینه قبلاً در همین دوره ثبت شده است.');
    }

    try {
      final response =
          await _client
              .from(_table)
              .update({
                'cost_center_id': costCenterId,
                'employee_count': employeeCount,
                'base_salary': baseSalary,
                'seniority_salary': senioritySalary,
                'meal_allowance': mealAllowance,
                'housing_allowance': housingAllowance,
                'marital_allowance': maritalAllowance,
                'overtime_amount': overtimeAmount,
                'mission_allowance': missionAllowance,
                'performance_bonus': performanceBonus,
                'production_increase_bonus': productionIncreaseBonus,
                'monthly_seniority_benefit': monthlySeniorityBenefit,
                'monthly_end_service_bonus': monthlyEndServiceBonus,
                'mission_travel_cost': missionTravelCost,
                'employer_insurance': employerInsurance,
                'unemployment_insurance': unemploymentInsurance,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', id)
              .select(_select)
              .single();

      return PayrollCostCenterRecordModel.fromMap(
        Map<String, dynamic>.from(response),
      );
    } on PostgrestException catch (e) {
      if (e.code == '23505' ||
          e.message.contains('payroll_cost_center_records_unique')) {
        throw Exception('این مرکز هزینه قبلاً در همین دوره ثبت شده است.');
      }

      rethrow;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  // ============================================================
  // INTERNAL
  // ============================================================

  Future<String> _getPayrollPeriodId(String recordId) async {
    final response =
        await _client
            .from(_table)
            .select('payroll_period_id')
            .eq('id', recordId)
            .single();

    return response['payroll_period_id'].toString();
  }
}
