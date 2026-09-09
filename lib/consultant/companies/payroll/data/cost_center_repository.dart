import 'package:supabase_flutter/supabase_flutter.dart';

import 'cost_center_model.dart';

class CostCenterRepository {
  CostCenterRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'cost_centers';

  // ============================================================
  // GET ALL
  // ============================================================

  Future<List<CostCenterModel>> getCostCenters(String companyId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('company_id', companyId)
        .order('name', ascending: true);

    return (response as List)
        .map((row) => CostCenterModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  // ============================================================
  // GET ONE
  // ============================================================

  Future<CostCenterModel?> getCostCenterById(String id) async {
    final response =
        await _client.from(_table).select().eq('id', id).maybeSingle();

    if (response == null) {
      return null;
    }

    return CostCenterModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<CostCenterModel> createCostCenter({
    required String companyId,
    required String name,
    String? code,
    String? description,
    bool isActive = true,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('نام مرکز هزینه الزامی است.');
    }

    if (companyId.trim().isEmpty) {
      throw Exception('شناسه شرکت معتبر نیست.');
    }

    final existing =
        await _client
            .from(_table)
            .select('id')
            .eq('company_id', companyId)
            .eq('name', cleanName)
            .maybeSingle();

    if (existing != null) {
      throw Exception('این مرکز هزینه قبلاً ثبت شده است.');
    }

    final userId = _client.auth.currentUser?.id;

    final response =
        await _client
            .from(_table)
            .insert({
              'company_id': companyId,
              'name': cleanName,
              'code': _nullableText(code),
              'description': _nullableText(description),
              'is_active': isActive,
              'created_by': userId,
            })
            .select()
            .single();

    return CostCenterModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<CostCenterModel> updateCostCenter({
    required String id,
    required String name,
    String? code,
    String? description,
    required bool isActive,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('نام مرکز هزینه الزامی است.');
    }

    if (id.trim().isEmpty) {
      throw Exception('شناسه مرکز هزینه معتبر نیست.');
    }

    final response =
        await _client
            .from(_table)
            .update({
              'name': cleanName,
              'code': _nullableText(code),
              'description': _nullableText(description),
              'is_active': isActive,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', id)
            .select()
            .single();

    return CostCenterModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ============================================================
  // CHECK DEPENDENCIES
  // ============================================================

  Future<CostCenterDependencyInfo> getDeleteDependencies(
    String costCenterId,
  ) async {
    if (costCenterId.trim().isEmpty) {
      throw Exception('شناسه مرکز هزینه معتبر نیست.');
    }

    // ----------------------------------------------------------
    // قراردادها
    // ----------------------------------------------------------

    final contractsResponse = await _client
        .from('employment_contracts')
        .select('id')
        .eq('cost_center_id', costCenterId);

    final contractsCount = (contractsResponse as List).length;

    // ----------------------------------------------------------
    // حقوق دوره‌ها
    // ----------------------------------------------------------

    final payrollResponse = await _client
        .from('payroll_cost_center_records')
        .select('id')
        .eq('cost_center_id', costCenterId);

    final payrollRecordsCount = (payrollResponse as List).length;

    return CostCenterDependencyInfo(
      contractsCount: contractsCount,
      payrollRecordsCount: payrollRecordsCount,
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteCostCenter(String id) async {
    if (id.trim().isEmpty) {
      throw Exception('شناسه مرکز هزینه معتبر نیست.');
    }

    // ----------------------------------------------------------
    // ابتدا وابستگی‌ها را بررسی می‌کنیم
    // ----------------------------------------------------------

    final dependencies = await getDeleteDependencies(id);

    // ----------------------------------------------------------
    // اگر حقوق دوره وجود داشته باشد
    // ----------------------------------------------------------

    if (dependencies.payrollRecordsCount > 0) {
      final payrollCount = dependencies.payrollRecordsCount;

      final contractCount = dependencies.contractsCount;

      if (contractCount > 0) {
        throw Exception(
          'این مرکز هزینه قابل حذف نیست.\n\n'
          'برای این مرکز هزینه '
          '$payrollCount رکورد حقوق در دوره‌های حقوق '
          'و $contractCount قرارداد ثبت شده است.\n\n'
          'ابتدا از بخش «دوره‌های حقوق» '
          'رکوردهای حقوق این مرکز هزینه را حذف کنید. '
          'سپس قراردادهای مرتبط را تعیین تکلیف کنید '
          'و بعد دوباره برای حذف مرکز هزینه اقدام کنید.',
        );
      }

      throw Exception(
        'این مرکز هزینه قابل حذف نیست.\n\n'
        'برای این مرکز هزینه '
        '$payrollCount رکورد حقوق در دوره‌های حقوق ثبت شده است.\n\n'
        'ابتدا رکوردهای حقوق این مرکز هزینه را '
        'از بخش «دوره‌های حقوق» حذف کنید، '
        'سپس دوباره برای حذف مرکز هزینه اقدام کنید.',
      );
    }

    // ----------------------------------------------------------
    // اگر قرارداد وجود داشته باشد
    // ----------------------------------------------------------

    if (dependencies.contractsCount > 0) {
      final contractCount = dependencies.contractsCount;

      throw Exception(
        'این مرکز هزینه قابل حذف نیست.\n\n'
        'این مرکز هزینه در '
        '$contractCount قرارداد استفاده شده است.\n\n'
        'ابتدا قراردادهای مرتبط با این مرکز هزینه '
        'را تعیین تکلیف کنید و سپس دوباره برای حذف '
        'مرکز هزینه اقدام کنید.',
      );
    }

    // ----------------------------------------------------------
    // حذف نهایی
    // ----------------------------------------------------------

    try {
      await _client.from(_table).delete().eq('id', id);
    } on PostgrestException catch (error) {
      // --------------------------------------------------------
      // اگر Database هنوز وابستگی دیگری داشته باشد
      // --------------------------------------------------------

      if (error.code == '23503') {
        throw Exception(
          'این مرکز هزینه به اطلاعات دیگری در سیستم متصل است '
          'و فعلاً قابل حذف نیست.\n\n'
          'ابتدا اطلاعات مرتبط با این مرکز هزینه را '
          'از بخش‌های مربوطه حذف یا تعیین تکلیف کنید، '
          'سپس دوباره اقدام کنید.',
        );
      }

      rethrow;
    }
  }

  // ============================================================
  // CHECK CAN DELETE
  // ============================================================

  Future<bool> canDeleteCostCenter(String id) async {
    final dependencies = await getDeleteDependencies(id);

    return dependencies.contractsCount == 0 &&
        dependencies.payrollRecordsCount == 0;
  }

  // ============================================================
  // HELPER
  // ============================================================

  String? _nullableText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }
}

// ================================================================
// DEPENDENCY MODEL
// ================================================================

class CostCenterDependencyInfo {
  const CostCenterDependencyInfo({
    required this.contractsCount,
    required this.payrollRecordsCount,
  });

  final int contractsCount;
  final int payrollRecordsCount;

  bool get hasContracts => contractsCount > 0;

  bool get hasPayrollRecords => payrollRecordsCount > 0;

  bool get hasDependencies => hasContracts || hasPayrollRecords;
}
