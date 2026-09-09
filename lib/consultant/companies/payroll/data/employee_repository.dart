import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'employee_model.dart';

class EmployeeRepository {
  EmployeeRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'employees';

  // ==========================================================
  // GET ALL
  // ==========================================================

  Future<List<EmployeeModel>> getEmployees(String companyId) async {
    final response = await _client
        .from(_table)
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => EmployeeModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  // ==========================================================
  // GET ONE
  // ==========================================================

  Future<EmployeeModel?> getEmployeeById(String id) async {
    final response =
        await _client.from(_table).select().eq('id', id).maybeSingle();

    if (response == null) {
      return null;
    }

    return EmployeeModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ==========================================================
  // CREATE
  // ==========================================================

  Future<EmployeeModel> createEmployee({
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
    String status = 'active',
  }) async {
    final currentUser =
        _client.auth.currentUser;

    debugPrint(
      '========================================',
    );
    debugPrint(
      'EMPLOYEE CREATE START',
    );
    debugPrint(
      'USER ID: ${currentUser?.id}',
    );
    debugPrint(
      'COMPANY ID: $companyId',
    );
    debugPrint(
      'PERSONNEL CODE: $personnelCode',
    );
    debugPrint(
      'FIRST NAME: $firstName',
    );
    debugPrint(
      'LAST NAME: $lastName',
    );
    debugPrint(
      'STATUS: $status',
    );

    final payload =
    <String, dynamic>{
      'company_id':
      companyId,
      'personnel_code':
      personnelCode.trim(),
      'first_name':
      firstName.trim(),
      'last_name':
      lastName.trim(),
      'national_id':
      _nullableText(nationalId),
      'mobile':
      _nullableText(mobile),
      'job_title':
      _nullableText(jobTitle),
      'department':
      _nullableText(department),
      'employment_type':
      _nullableText(employmentType),
      'hire_date':
      _formatDate(hireDate),
      'termination_date':
      _formatDate(terminationDate),
      'status':
      status,
      'created_by':
      currentUser?.id,
    };

    debugPrint(
      'PAYLOAD: $payload',
    );

    try {
      final response =
      await _client
          .from(_table)
          .insert(
        payload,
      )
          .select()
          .single();

      debugPrint(
        'EMPLOYEE CREATE SUCCESS',
      );

      debugPrint(
        'RESPONSE: $response',
      );

      debugPrint(
        '========================================',
      );

      return EmployeeModel.fromMap(
        Map<String, dynamic>.from(
          response,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'EMPLOYEE CREATE ERROR',
      );

      debugPrint(
        'ERROR: $error',
      );

      debugPrint(
        'STACK TRACE: $stackTrace',
      );

      debugPrint(
        '========================================',
      );

      rethrow;
    }
  }

  // ==========================================================
  // UPDATE
  // ==========================================================

  Future<EmployeeModel> updateEmployee({
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
    final payload = <String, dynamic>{
      'personnel_code': personnelCode.trim(),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'national_id': _nullableText(nationalId),
      'mobile': _nullableText(mobile),
      'job_title': _nullableText(jobTitle),
      'department': _nullableText(department),
      'employment_type': _nullableText(employmentType),
      'hire_date': _formatDate(hireDate),
      'termination_date': _formatDate(terminationDate),
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response =
        await _client
            .from(_table)
            .update(payload)
            .eq('id', id)
            .select()
            .single();

    return EmployeeModel.fromMap(Map<String, dynamic>.from(response));
  }

  // ==========================================================
  // DELETE
  // ==========================================================

  Future<void> deleteEmployee(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  Future<List<EmployeeModel>> searchEmployees({
    required String companyId,
    required String query,
  }) async {
    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      return getEmployees(companyId);
    }

    final response = await _client
        .from(_table)
        .select()
        .eq('company_id', companyId)
        .or(
          'personnel_code.ilike.%$cleanQuery%,'
          'first_name.ilike.%$cleanQuery%,'
          'last_name.ilike.%$cleanQuery%,'
          'national_id.ilike.%$cleanQuery%,'
          'mobile.ilike.%$cleanQuery%',
        )
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => EmployeeModel.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  String? _nullableText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  String? _formatDate(DateTime? value) {
    if (value == null) {
      return null;
    }

    final year = value.year.toString().padLeft(4, '0');

    final month = value.month.toString().padLeft(2, '0');

    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
