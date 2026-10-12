import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final companyAdminPayrollEmployeesProvider =
    FutureProvider.autoDispose<CompanyAdminPayrollEmployeesData>((ref) async {
      final repository = CompanyAdminPayrollEmployeesRepository(
        Supabase.instance.client,
      );

      return repository.load();
    });

class CompanyAdminPayrollEmployeesRepository {
  final SupabaseClient _supabase;

  CompanyAdminPayrollEmployeesRepository(this._supabase);

  Future<String> _resolveCompanyId() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    final membership =
        await _supabase
            .from('company_users')
            .select('company_id, role, is_active')
            .eq('user_id', user.id)
            .eq('role', 'company_admin')
            .eq('is_active', true)
            .limit(1)
            .maybeSingle();

    if (membership == null) {
      throw Exception('شرکت فعال برای مدیرعامل پیدا نشد.');
    }

    final companyId = membership['company_id']?.toString();

    if (companyId == null || companyId.isEmpty) {
      throw Exception('شناسه شرکت معتبر نیست.');
    }

    return companyId;
  }

  Future<CompanyAdminPayrollEmployeesData> load() async {
    final companyId = await _resolveCompanyId();

    final response = await _supabase
        .from('employees')
        .select('''
          id,
          company_id,
          personnel_code,
          first_name,
          last_name,
          national_id,
          mobile,
          job_title,
          department,
          employment_type,
          hire_date,
          termination_date,
          status,
          created_by,
          created_at,
          updated_at
        ''')
        .eq('company_id', companyId)
        .order('personnel_code', ascending: true);

    final employees =
        (response as List)
            .map(
              (item) => CompanyAdminPayrollEmployee.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();

    return CompanyAdminPayrollEmployeesData(
      companyId: companyId,
      employees: employees,
    );
  }

  Future<void> createEmployee({
    required String personnelCode,
    required String firstName,
    required String lastName,
    String? nationalId,
    String? mobile,
    String? jobTitle,
    String? department,
    String? employmentType,
    DateTime? hireDate,
    DateTime? terminationDate,
    required String status,
  }) async {
    final companyId = await _resolveCompanyId();
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    await _supabase.from('employees').insert({
      'company_id': companyId,
      'personnel_code': personnelCode.trim(),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'national_id': _clean(nationalId),
      'mobile': _clean(mobile),
      'job_title': _clean(jobTitle),
      'department': _clean(department),
      'employment_type': _clean(employmentType),
      'hire_date': _dateOnly(hireDate),
      'termination_date': _dateOnly(terminationDate),
      'status': status,
      'created_by': user.id,
    });
  }

  Future<void> updateEmployee({
    required String employeeId,
    required String personnelCode,
    required String firstName,
    required String lastName,
    String? nationalId,
    String? mobile,
    String? jobTitle,
    String? department,
    String? employmentType,
    DateTime? hireDate,
    DateTime? terminationDate,
    required String status,
  }) async {
    final companyId = await _resolveCompanyId();

    await _supabase
        .from('employees')
        .update({
          'personnel_code': personnelCode.trim(),
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'national_id': _clean(nationalId),
          'mobile': _clean(mobile),
          'job_title': _clean(jobTitle),
          'department': _clean(department),
          'employment_type': _clean(employmentType),
          'hire_date': _dateOnly(hireDate),
          'termination_date': _dateOnly(terminationDate),
          'status': status,
        })
        .eq('id', employeeId)
        .eq('company_id', companyId);
  }

  Future<void> updateStatus({
    required String employeeId,
    required String status,
  }) async {
    final companyId = await _resolveCompanyId();

    await _supabase
        .from('employees')
        .update({'status': status})
        .eq('id', employeeId)
        .eq('company_id', companyId);
  }

  Future<void> deleteEmployee(String employeeId) async {
    final companyId = await _resolveCompanyId();

    await _supabase
        .from('employees')
        .delete()
        .eq('id', employeeId)
        .eq('company_id', companyId);
  }

  static String? _clean(String? value) {
    if (value == null) return null;

    final result = value.trim();

    return result.isEmpty ? null : result;
  }

  static String? _dateOnly(DateTime? date) {
    if (date == null) return null;

    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}

class CompanyAdminPayrollEmployeesData {
  final String companyId;
  final List<CompanyAdminPayrollEmployee> employees;

  const CompanyAdminPayrollEmployeesData({
    required this.companyId,
    required this.employees,
  });

  int get totalCount => employees.length;

  int get activeCount =>
      employees.where((employee) => employee.status == 'active').length;

  int get inactiveCount =>
      employees.where((employee) => employee.status == 'inactive').length;

  int get terminatedCount =>
      employees.where((employee) => employee.status == 'terminated').length;

  int get suspendedCount =>
      employees.where((employee) => employee.status == 'suspended').length;
}

class CompanyAdminPayrollEmployee {
  final String id;
  final String companyId;
  final String personnelCode;
  final String firstName;
  final String lastName;
  final String? nationalId;
  final String? mobile;
  final String? jobTitle;
  final String? department;
  final String? employmentType;
  final DateTime? hireDate;
  final DateTime? terminationDate;
  final String status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyAdminPayrollEmployee({
    required this.id,
    required this.companyId,
    required this.personnelCode,
    required this.firstName,
    required this.lastName,
    required this.nationalId,
    required this.mobile,
    required this.jobTitle,
    required this.department,
    required this.employmentType,
    required this.hireDate,
    required this.terminationDate,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName {
    final value = '$firstName $lastName'.trim();
    return value.isEmpty ? 'بدون نام' : value;
  }

  factory CompanyAdminPayrollEmployee.fromMap(Map<String, dynamic> map) {
    return CompanyAdminPayrollEmployee(
      id: map['id'].toString(),
      companyId: map['company_id'].toString(),
      personnelCode: map['personnel_code']?.toString() ?? '',
      firstName: map['first_name']?.toString() ?? '',
      lastName: map['last_name']?.toString() ?? '',
      nationalId: map['national_id']?.toString(),
      mobile: map['mobile']?.toString(),
      jobTitle: map['job_title']?.toString(),
      department: map['department']?.toString(),
      employmentType: map['employment_type']?.toString(),
      hireDate: _parseDate(map['hire_date']),
      terminationDate: _parseDate(map['termination_date']),
      status: map['status']?.toString() ?? 'active',
      createdBy: map['created_by']?.toString(),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }
}
