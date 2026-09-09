import 'package:supabase_flutter/supabase_flutter.dart';

import 'employment_contract_model.dart';

class EmploymentContractRepository {
  EmploymentContractRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'employment_contracts';

  // ==========================================================
  // GET ALL BY COMPANY
  // ==========================================================

  Future<List<EmploymentContractModel>> getContracts(String companyId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) =>
              EmploymentContractModel.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  // ==========================================================
  // GET ONE
  // ==========================================================

  Future<EmploymentContractModel?> getContractById(String id) async {
    final response =
        await _client.from(_table).select().eq('id', id).maybeSingle();

    if (response == null) {
      return null;
    }

    return EmploymentContractModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ==========================================================
  // GET BY COST CENTER
  // ==========================================================

  Future<List<EmploymentContractModel>> getContractsByCostCenter(
    String costCenterId,
  ) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('cost_center_id', costCenterId)
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) =>
              EmploymentContractModel.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  // ==========================================================
  // GET ACTIVE BY COST CENTER
  // ==========================================================

  Future<List<EmploymentContractModel>> getActiveContractsByCostCenter(
    String costCenterId,
  ) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('cost_center_id', costCenterId)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) =>
              EmploymentContractModel.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  // ==========================================================
  // GET ACTIVE BY COMPANY
  // ==========================================================

  Future<List<EmploymentContractModel>> getActiveContracts(
    String companyId,
  ) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('company_id', companyId)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return (response as List)
        .map(
          (row) =>
              EmploymentContractModel.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  // ==========================================================
  // CREATE
  // ==========================================================

  Future<EmploymentContractModel> createContract({
    required String companyId,
    required String costCenterId,
    String? contractNumber,
    required String contractType,
    DateTime? startDate,
    DateTime? endDate,
    required double baseSalary,
    double? workingHours,
    String status = 'active',
    String? notes,
  }) async {
    _validateContract(
      companyId: companyId,
      costCenterId: costCenterId,
      contractType: contractType,
      startDate: startDate,
      endDate: endDate,
      baseSalary: baseSalary,
      workingHours: workingHours,
    );

    await _ensureCostCenterBelongsToCompany(
      companyId: companyId,
      costCenterId: costCenterId,
    );

    final userId = _client.auth.currentUser?.id;

    final response =
        await _client
            .from(_table)
            .insert({
              'company_id': companyId,
              'cost_center_id': costCenterId,
              'contract_number': _nullableText(contractNumber),
              'contract_type': contractType,
              'start_date': startDate?.toIso8601String(),
              'end_date': endDate?.toIso8601String(),
              'base_salary': baseSalary,
              'working_hours': workingHours,
              'status': status,
              'notes': _nullableText(notes),
              'created_by': userId,
            })
            .select()
            .single();

    return EmploymentContractModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ==========================================================
  // UPDATE
  // ==========================================================

  Future<EmploymentContractModel> updateContract({
    required String id,
    required String costCenterId,
    String? contractNumber,
    required String contractType,
    DateTime? startDate,
    DateTime? endDate,
    required double baseSalary,
    double? workingHours,
    required String status,
    String? notes,
  }) async {
    final existing = await getContractById(id);

    if (existing == null) {
      throw Exception('قرارداد موردنظر پیدا نشد.');
    }

    _validateContract(
      companyId: existing.companyId,
      costCenterId: costCenterId,
      contractType: contractType,
      startDate: startDate,
      endDate: endDate,
      baseSalary: baseSalary,
      workingHours: workingHours,
    );

    await _ensureCostCenterBelongsToCompany(
      companyId: existing.companyId,
      costCenterId: costCenterId,
    );

    final response =
        await _client
            .from(_table)
            .update({
              'cost_center_id': costCenterId,
              'contract_number': _nullableText(contractNumber),
              'contract_type': contractType,
              'start_date': startDate?.toIso8601String(),
              'end_date': endDate?.toIso8601String(),
              'base_salary': baseSalary,
              'working_hours': workingHours,
              'status': status,
              'notes': _nullableText(notes),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id)
            .select()
            .single();

    return EmploymentContractModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  Future<void> deleteContract(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  // ==========================================================
  // VALIDATION
  // ==========================================================

  void _validateContract({
    required String companyId,
    required String costCenterId,
    required String contractType,
    required DateTime? startDate,
    required DateTime? endDate,
    required double baseSalary,
    required double? workingHours,
  }) {
    if (companyId.trim().isEmpty) {
      throw Exception('شناسه شرکت معتبر نیست.');
    }

    if (costCenterId.trim().isEmpty) {
      throw Exception('مرکز هزینه را انتخاب کنید.');
    }

    if (contractType.trim().isEmpty) {
      throw Exception('نوع قرارداد را انتخاب کنید.');
    }

    if (baseSalary < 0) {
      throw Exception('حقوق پایه نمی‌تواند منفی باشد.');
    }

    if (workingHours != null && workingHours < 0) {
      throw Exception('ساعات کاری نمی‌تواند منفی باشد.');
    }

    if (startDate != null && endDate != null && endDate.isBefore(startDate)) {
      throw Exception('تاریخ پایان نمی‌تواند قبل از تاریخ شروع باشد.');
    }
  }

  // ==========================================================
  // COST CENTER VALIDATION
  // ==========================================================

  Future<void> _ensureCostCenterBelongsToCompany({
    required String companyId,
    required String costCenterId,
  }) async {
    final response =
        await _client
            .from('cost_centers')
            .select('id')
            .eq('id', costCenterId)
            .eq('company_id', companyId)
            .eq('is_active', true)
            .maybeSingle();

    if (response == null) {
      throw Exception(
        'مرکز هزینه انتخاب‌شده متعلق به این شرکت نیست یا فعال نیست.',
      );
    }
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
