
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final companyAdminEmploymentContractsProvider =
FutureProvider.autoDispose<EmploymentContractsData>((ref) async {
final repository = CompanyAdminEmploymentContractsRepository(
Supabase.instance.client,
);

return repository.load();
});

class CompanyAdminEmploymentContractsRepository {
final SupabaseClient _supabase;

CompanyAdminEmploymentContractsRepository(this._supabase);

Future<String> _resolveCompanyId() async {
final user = _supabase.auth.currentUser;

if (user == null) {
throw Exception('کاربر وارد سیستم نشده است.');
}

final membership = await _supabase
    .from('company_users')
    .select('company_id')
    .eq('user_id', user.id)
    .eq('role', 'company_admin')
    .eq('is_active', true)
    .limit(1)
    .maybeSingle();

final companyId = membership?['company_id']?.toString();

if (companyId == null || companyId.isEmpty) {
throw Exception('شرکت فعال مدیرعامل پیدا نشد.');
}

return companyId;
}

Future<EmploymentContractsData> load() async {
final companyId = await _resolveCompanyId();

final results = await Future.wait([
_supabase
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
            created_by,
            created_at,
            updated_at,
            cost_center_id
          ''')
    .eq('company_id', companyId)
    .order('created_at', ascending: false),
_supabase
    .from('employees')
    .select('id, first_name, last_name, personnel_code')
    .eq('company_id', companyId)
    .order('personnel_code'),
_supabase
    .from('cost_centers')
    .select('id, name, code')
    .eq('company_id', companyId)
    .order('name'),
]);

final contracts = (results[0] as List)
    .map(
(row) => EmploymentContract.fromMap(
Map<String, dynamic>.from(row as Map),
),
)
    .toList();

final employees = (results[1] as List)
    .map(
(row) => ContractEmployee.fromMap(
Map<String, dynamic>.from(row as Map),
),
)
    .toList();

final costCenters = (results[2] as List)
    .map(
(row) => ContractCostCenter.fromMap(
Map<String, dynamic>.from(row as Map),
),
)
    .toList();

return EmploymentContractsData(
companyId: companyId,
contracts: contracts,
employees: employees,
costCenters: costCenters,
);
}

Future<void> create({
String? employeeId,
String? contractNumber,
required String contractType,
DateTime? startDate,
DateTime? endDate,
required double baseSalary,
double? workingHours,
required String insuranceStatus,
required String taxStatus,
required String status,
required String costCenterId,
}) async {
final companyId = await _resolveCompanyId();
final user = _supabase.auth.currentUser;

if (user == null) {
throw Exception('کاربر وارد سیستم نشده است.');
}

await _supabase.from('employment_contracts').insert({
'company_id': companyId,
'employee_id': employeeId,
'contract_number': _clean(contractNumber),
'contract_type': contractType,
'start_date': _dateOnly(startDate),
'end_date': _dateOnly(endDate),
'base_salary': baseSalary,
'working_hours': workingHours,
'insurance_status': insuranceStatus,
'tax_status': taxStatus,
'status': status,
'cost_center_id': costCenterId,
'created_by': user.id,
});
}

Future<void> update({
required String id,
String? employeeId,
String? contractNumber,
required String contractType,
DateTime? startDate,
DateTime? endDate,
required double baseSalary,
double? workingHours,
required String insuranceStatus,
required String taxStatus,
required String status,
required String costCenterId,
}) async {
final companyId = await _resolveCompanyId();

await _supabase
    .from('employment_contracts')
    .update({
'employee_id': employeeId,
'contract_number': _clean(contractNumber),
'contract_type': contractType,
'start_date': _dateOnly(startDate),
'end_date': _dateOnly(endDate),
'base_salary': baseSalary,
'working_hours': workingHours,
'insurance_status': insuranceStatus,
'tax_status': taxStatus,
'status': status,
'cost_center_id': costCenterId,
'updated_at': DateTime.now().toUtc().toIso8601String(),
})
    .eq('id', id)
    .eq('company_id', companyId);
}

Future<void> delete(String id) async {
final companyId = await _resolveCompanyId();

await _supabase
    .from('employment_contracts')
    .delete()
    .eq('id', id)
    .eq('company_id', companyId);
}

static String? _clean(String? value) {
final result = value?.trim();

if (result == null || result.isEmpty) {
return null;
}

return result;
}

static String? _dateOnly(DateTime? date) {
if (date == null) return null;

final year = date.year.toString().padLeft(4, '0');
final month = date.month.toString().padLeft(2, '0');
final day = date.day.toString().padLeft(2, '0');

return '$year-$month-$day';
}
}

class EmploymentContractsData {
final String companyId;
final List<EmploymentContract> contracts;
final List<ContractEmployee> employees;
final List<ContractCostCenter> costCenters;

const EmploymentContractsData({
required this.companyId,
required this.contracts,
required this.employees,
required this.costCenters,
});

int get activeCount =>
contracts.where((contract) => contract.status == 'active').length;

int get expiredCount =>
contracts.where((contract) => contract.status == 'expired').length;

int get terminatedCount =>
contracts.where((contract) => contract.status == 'terminated').length;
}

class EmploymentContract {
final String id;
final String companyId;
final String? employeeId;
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

const EmploymentContract({
required this.id,
required this.companyId,
required this.employeeId,
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
});

factory EmploymentContract.fromMap(Map<String, dynamic> map) {
return EmploymentContract(
id: map['id'].toString(),
companyId: map['company_id'].toString(),
employeeId: map['employee_id']?.toString(),
contractNumber: map['contract_number']?.toString(),
contractType: map['contract_type']?.toString() ?? 'permanent',
startDate: _parseDate(map['start_date']),
endDate: _parseDate(map['end_date']),
baseSalary: _parseNumber(map['base_salary']),
workingHours: map['working_hours'] == null
? null
    : _parseNumber(map['working_hours']),
insuranceStatus:
map['insurance_status']?.toString() ?? 'insured',
taxStatus: map['tax_status']?.toString() ?? 'taxable',
status: map['status']?.toString() ?? 'active',
costCenterId: map['cost_center_id'].toString(),
);
}

static DateTime? _parseDate(dynamic value) {
if (value == null) return null;
return DateTime.tryParse(value.toString());
}

static double _parseNumber(dynamic value) {
if (value is num) return value.toDouble();
return double.tryParse(value.toString()) ?? 0;
}
}

class ContractEmployee {
final String id;
final String name;
final String personnelCode;

const ContractEmployee({
required this.id,
required this.name,
required this.personnelCode,
});

factory ContractEmployee.fromMap(Map<String, dynamic> map) {
final firstName = map['first_name']?.toString() ?? '';
final lastName = map['last_name']?.toString() ?? '';

return ContractEmployee(
id: map['id'].toString(),
name: '$firstName $lastName'.trim(),
personnelCode: map['personnel_code']?.toString() ?? '',
);
}
}

class ContractCostCenter {
final String id;
final String name;
final String? code;

const ContractCostCenter({
required this.id,
required this.name,
required this.code,
});

factory ContractCostCenter.fromMap(Map<String, dynamic> map) {
return ContractCostCenter(
id: map['id'].toString(),
name: map['name']?.toString() ?? '',
code: map['code']?.toString(),
);
}
}
