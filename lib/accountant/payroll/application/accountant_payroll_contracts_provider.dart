import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantPayrollContractsProvider =
    FutureProvider.family<List<AccountantPayrollContract>, String>((
      ref,
      companyId,
    ) async {
      return AccountantPayrollContractsRepository.load(companyId);
    });

class AccountantPayrollEmployeeOption {
  final String id;
  final String name;
  final String personnelCode;

  const AccountantPayrollEmployeeOption({
    required this.id,
    required this.name,
    required this.personnelCode,
  });

  String get label => '$name — $personnelCode';
}

class AccountantPayrollCostCenterOption {
  final String id;
  final String name;
  final String? code;

  const AccountantPayrollCostCenterOption({
    required this.id,
    required this.name,
    required this.code,
  });

  String get label {
    if (code != null && code!.trim().isNotEmpty) {
      return '$name — ${code!}';
    }

    return name;
  }
}

class AccountantPayrollContractFormData {
  final List<AccountantPayrollEmployeeOption> employees;
  final List<AccountantPayrollCostCenterOption> costCenters;

  const AccountantPayrollContractFormData({
    required this.employees,
    required this.costCenters,
  });
}

final accountantPayrollContractFormProvider =
    FutureProvider.family<AccountantPayrollContractFormData, String>((
      ref,
      companyId,
    ) async {
      return AccountantPayrollContractsRepository.loadFormData(companyId);
    });

class AccountantPayrollContract {
  final String id;
  final String companyId;
  final String? employeeId;
  final String? employeeName;
  final String? personnelCode;
  final String? contractNumber;
  final String contractType;
  final DateTime? startDate;
  final DateTime? endDate;
  final double baseSalary;
  final double? workingHours;
  final String insuranceStatus;
  final String taxStatus;
  final String status;
  final String costCenterId;
  final String? costCenterName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountantPayrollContract({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.employeeName,
    required this.personnelCode,
    required this.contractNumber,
    required this.contractType,
    required this.startDate,
    required this.endDate,
    required this.baseSalary,
    required this.workingHours,
    required this.insuranceStatus,
    required this.taxStatus,
    required this.status,
    required this.costCenterId,
    required this.costCenterName,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status.trim().toLowerCase() == 'active';
}

class AccountantPayrollContractsRepository {
  AccountantPayrollContractsRepository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<List<AccountantPayrollContract>> load(String companyId) async {
    final results = await Future.wait([
      _loadContracts(companyId),
      _loadEmployees(companyId),
      _loadCostCenters(companyId),
    ]);

    final contractRows = results[0] as List<dynamic>;

    final employeeRows = results[1] as List<dynamic>;

    final costCenterRows = results[2] as List<dynamic>;

    final employeesById = <String, Map<String, dynamic>>{};

    for (final rawEmployee in employeeRows) {
      final employee = Map<String, dynamic>.from(rawEmployee as Map);

      final id = employee['id']?.toString();

      if (id != null && id.isNotEmpty) {
        employeesById[id] = employee;
      }
    }

    final costCentersById = <String, Map<String, dynamic>>{};

    for (final rawCostCenter in costCenterRows) {
      final costCenter = Map<String, dynamic>.from(rawCostCenter as Map);

      final id = costCenter['id']?.toString();

      if (id != null && id.isNotEmpty) {
        costCentersById[id] = costCenter;
      }
    }

    return contractRows.map((rawContract) {
      final contract = Map<String, dynamic>.from(rawContract as Map);

      final employeeId = contract['employee_id']?.toString();

      final costCenterId = contract['cost_center_id']?.toString();

      return _fromMap(
        contract,
        employee: employeeId == null ? null : employeesById[employeeId],
        costCenter: costCenterId == null ? null : costCentersById[costCenterId],
      );
    }).toList();
  }

  static Future<AccountantPayrollContractFormData> loadFormData(
    String companyId,
  ) async {
    final results = await Future.wait([
      _loadEmployees(companyId),
      _loadCostCenters(companyId),
    ]);

    final employeeRows = results[0] as List<dynamic>;

    final costCenterRows = results[1] as List<dynamic>;

    final employees =
        employeeRows
            .map((raw) {
              final row = Map<String, dynamic>.from(raw as Map);

              final firstName = row['first_name']?.toString().trim() ?? '';

              final lastName = row['last_name']?.toString().trim() ?? '';

              return AccountantPayrollEmployeeOption(
                id: row['id']?.toString() ?? '',
                name: '$firstName $lastName'.trim(),
                personnelCode: row['personnel_code']?.toString() ?? '',
              );
            })
            .where((employee) {
              return employee.id.isNotEmpty;
            })
            .toList();

    final costCenters =
        costCenterRows
            .map((raw) {
              final row = Map<String, dynamic>.from(raw as Map);

              return AccountantPayrollCostCenterOption(
                id: row['id']?.toString() ?? '',
                name: row['name']?.toString() ?? '',
                code: _stringOrNull(row['code']),
              );
            })
            .where((center) {
              return center.id.isNotEmpty && center.name.trim().isNotEmpty;
            })
            .toList();

    return AccountantPayrollContractFormData(
      employees: employees,
      costCenters: costCenters,
    );
  }

  static Future<List<dynamic>> _loadContracts(String companyId) async {
    return await _supabase
        .from('employment_contracts')
        .select('''
          id,
          company_id,
          employee_id,
          contract_number,
          contract_type,
          start_date,
          end_date,
          base_salary,
          working_hours,
          insurance_status,
          tax_status,
          status,
          cost_center_id,
          created_at,
          updated_at
          ''')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
  }

  static Future<List<dynamic>> _loadEmployees(String companyId) async {
    return await _supabase
        .from('employees')
        .select('''
          id,
          first_name,
          last_name,
          personnel_code,
          status
          ''')
        .eq('company_id', companyId)
        .order('personnel_code');
  }

  static Future<List<dynamic>> _loadCostCenters(String companyId) async {
    return await _supabase
        .from('cost_centers')
        .select('''
          id,
          company_id,
          name,
          code,
          description,
          is_active
          ''')
        .eq('company_id', companyId)
        .eq('is_active', true)
        .order('name');
  }

  static Future<AccountantPayrollContract> create({
    required String companyId,
    required String employeeId,
    required String costCenterId,
    String? contractNumber,
    required String contractType,
    DateTime? startDate,
    DateTime? endDate,
    required double baseSalary,
    double? workingHours,
    required String insuranceStatus,
    required String taxStatus,
    required String status,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    final row =
        await _supabase
            .from('employment_contracts')
            .insert({
              'company_id': companyId,
              'employee_id': employeeId,
              'cost_center_id': costCenterId,
              'contract_number': _nullable(contractNumber),
              'contract_type': contractType.trim(),
              'start_date': _dateToString(startDate),
              'end_date': _dateToString(endDate),
              'base_salary': baseSalary,
              'working_hours': workingHours,
              'insurance_status': insuranceStatus.trim(),
              'tax_status': taxStatus.trim(),
              'status': status.trim(),
              'created_by': userId,
            })
            .select('''
          id,
          company_id,
          employee_id,
          contract_number,
          contract_type,
          start_date,
          end_date,
          base_salary,
          working_hours,
          insurance_status,
          tax_status,
          status,
          cost_center_id,
          created_at,
          updated_at
          ''')
            .single();

    final employee = await _loadSingleEmployee(
      companyId: companyId,
      employeeId: employeeId,
    );

    final costCenter = await _loadSingleCostCenter(
      companyId: companyId,
      costCenterId: costCenterId,
    );

    return _fromMap(
      Map<String, dynamic>.from(row),
      employee: employee,
      costCenter: costCenter,
    );
  }

  static Future<AccountantPayrollContract> update({
    required String id,
    required String employeeId,
    required String costCenterId,
    String? contractNumber,
    required String contractType,
    DateTime? startDate,
    DateTime? endDate,
    required double baseSalary,
    double? workingHours,
    required String insuranceStatus,
    required String taxStatus,
    required String status,
  }) async {
    final row =
        await _supabase
            .from('employment_contracts')
            .update({
              'employee_id': employeeId,
              'cost_center_id': costCenterId,
              'contract_number': _nullable(contractNumber),
              'contract_type': contractType.trim(),
              'start_date': _dateToString(startDate),
              'end_date': _dateToString(endDate),
              'base_salary': baseSalary,
              'working_hours': workingHours,
              'insurance_status': insuranceStatus.trim(),
              'tax_status': taxStatus.trim(),
              'status': status.trim(),
            })
            .eq('id', id)
            .select('''
          id,
          company_id,
          employee_id,
          contract_number,
          contract_type,
          start_date,
          end_date,
          base_salary,
          working_hours,
          insurance_status,
          tax_status,
          status,
          cost_center_id,
          created_at,
          updated_at
          ''')
            .single();

    final companyId = row['company_id']?.toString() ?? '';

    final employee = await _loadSingleEmployee(
      companyId: companyId,
      employeeId: employeeId,
    );

    final costCenter = await _loadSingleCostCenter(
      companyId: companyId,
      costCenterId: costCenterId,
    );

    return _fromMap(
      Map<String, dynamic>.from(row),
      employee: employee,
      costCenter: costCenter,
    );
  }

  static Future<void> delete(String id) async {
    await _supabase.from('employment_contracts').delete().eq('id', id);
  }

  static Future<Map<String, dynamic>?> _loadSingleEmployee({
    required String companyId,
    required String employeeId,
  }) async {
    final row =
        await _supabase
            .from('employees')
            .select('''
          id,
          first_name,
          last_name,
          personnel_code
          ''')
            .eq('company_id', companyId)
            .eq('id', employeeId)
            .maybeSingle();

    if (row == null) return null;

    return Map<String, dynamic>.from(row);
  }

  static Future<Map<String, dynamic>?> _loadSingleCostCenter({
    required String companyId,
    required String costCenterId,
  }) async {
    final row =
        await _supabase
            .from('cost_centers')
            .select('''
          id,
          name,
          code
          ''')
            .eq('company_id', companyId)
            .eq('id', costCenterId)
            .maybeSingle();

    if (row == null) return null;

    return Map<String, dynamic>.from(row);
  }

  static AccountantPayrollContract _fromMap(
    Map<String, dynamic> row, {
    Map<String, dynamic>? employee,
    Map<String, dynamic>? costCenter,
  }) {
    final firstName = employee?['first_name']?.toString().trim() ?? '';

    final lastName = employee?['last_name']?.toString().trim() ?? '';

    final fullName = '$firstName $lastName'.trim();

    return AccountantPayrollContract(
      id: row['id']?.toString() ?? '',
      companyId: row['company_id']?.toString() ?? '',
      employeeId: _stringOrNull(row['employee_id']),
      employeeName: fullName.isEmpty ? null : fullName,
      personnelCode: _stringOrNull(employee?['personnel_code']),
      contractNumber: _stringOrNull(row['contract_number']),
      contractType: row['contract_type']?.toString() ?? '',
      startDate: _parseDate(row['start_date']),
      endDate: _parseDate(row['end_date']),
      baseSalary: _toDouble(row['base_salary']),
      workingHours: _nullableDouble(row['working_hours']),
      insuranceStatus: row['insurance_status']?.toString() ?? '',
      taxStatus: row['tax_status']?.toString() ?? '',
      status: row['status']?.toString() ?? '',
      costCenterId: row['cost_center_id']?.toString() ?? '',
      costCenterName: _stringOrNull(costCenter?['name']),
      createdAt: _parseDateTime(row['created_at']),
      updatedAt: _parseDateTime(row['updated_at']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _nullableDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static String? _nullable(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  static String? _stringOrNull(dynamic value) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  static String? _dateToString(DateTime? value) {
    if (value == null) return null;

    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  static DateTime _parseDateTime(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
