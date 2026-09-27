import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantPayrollEmployeesProvider =
    FutureProvider.family<List<AccountantPayrollEmployee>, String>((
      ref,
      companyId,
    ) async {
      return AccountantPayrollEmployeesRepository.load(companyId);
    });

class AccountantPayrollEmployee {
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
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountantPayrollEmployee({
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
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  bool get isActive => status.trim().toLowerCase() == 'active';
}

class AccountantPayrollEmployeesRepository {
  AccountantPayrollEmployeesRepository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<List<AccountantPayrollEmployee>> load(String companyId) async {
    final rows = await _supabase
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
          created_at,
          updated_at
          ''')
        .eq('company_id', companyId)
        .order('personnel_code');

    return (rows as List)
        .map((row) => _fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<AccountantPayrollEmployee> create({
    required String companyId,
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
    final userId = _supabase.auth.currentUser?.id;

    final row =
        await _supabase
            .from('employees')
            .insert({
              'company_id': companyId,
              'personnel_code': personnelCode.trim(),
              'first_name': firstName.trim(),
              'last_name': lastName.trim(),
              'national_id': _nullable(nationalId),
              'mobile': _nullable(mobile),
              'job_title': _nullable(jobTitle),
              'department': _nullable(department),
              'employment_type': _nullable(employmentType),
              'hire_date': _dateToString(hireDate),
              'termination_date': _dateToString(terminationDate),
              'status': status,
              'created_by': userId,
            })
            .select()
            .single();

    return _fromMap(Map<String, dynamic>.from(row));
  }

  static Future<AccountantPayrollEmployee> update({
    required String id,
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
    final row =
        await _supabase
            .from('employees')
            .update({
              'personnel_code': personnelCode.trim(),
              'first_name': firstName.trim(),
              'last_name': lastName.trim(),
              'national_id': _nullable(nationalId),
              'mobile': _nullable(mobile),
              'job_title': _nullable(jobTitle),
              'department': _nullable(department),
              'employment_type': _nullable(employmentType),
              'hire_date': _dateToString(hireDate),
              'termination_date': _dateToString(terminationDate),
              'status': status,
            })
            .eq('id', id)
            .select()
            .single();

    return _fromMap(Map<String, dynamic>.from(row));
  }

  static Future<void> delete(String id) async {
    await _supabase.from('employees').delete().eq('id', id);
  }

  static AccountantPayrollEmployee _fromMap(Map<String, dynamic> row) {
    return AccountantPayrollEmployee(
      id: row['id']?.toString() ?? '',
      companyId: row['company_id']?.toString() ?? '',
      personnelCode: row['personnel_code']?.toString() ?? '',
      firstName: row['first_name']?.toString() ?? '',
      lastName: row['last_name']?.toString() ?? '',
      nationalId: _stringOrNull(row['national_id']),
      mobile: _stringOrNull(row['mobile']),
      jobTitle: _stringOrNull(row['job_title']),
      department: _stringOrNull(row['department']),
      employmentType: _stringOrNull(row['employment_type']),
      hireDate: _parseDate(row['hire_date']),
      terminationDate: _parseDate(row['termination_date']),
      status: row['status']?.toString() ?? '',
      createdAt: _parseDateTime(row['created_at']),
      updatedAt: _parseDateTime(row['updated_at']),
    );
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

    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  static DateTime _parseDateTime(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
