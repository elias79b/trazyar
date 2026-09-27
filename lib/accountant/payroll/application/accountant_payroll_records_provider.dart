import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantPayrollRecordsProvider =
    FutureProvider.family<AccountantPayrollRecordsData, String>((
      ref,
      periodId,
    ) async {
      return AccountantPayrollRecordsRepository.load(periodId);
    });

class AccountantPayrollPeriodInfo {
  final String id;
  final String companyId;
  final int year;
  final int month;
  final String status;
  final String? notes;

  const AccountantPayrollPeriodInfo({
    required this.id,
    required this.companyId,
    required this.year,
    required this.month,
    required this.status,
    required this.notes,
  });

  String get normalizedStatus => status.trim().toLowerCase();

  bool get isDraft => normalizedStatus == 'draft';

  String get monthTitle => payrollMonthName(month);

  String get title => '$monthTitle $year';
}

class AccountantPayrollEmployee {
  final String id;
  final String personnelCode;
  final String firstName;
  final String lastName;
  final String? nationalId;
  final String? mobile;
  final String? jobTitle;
  final String? department;
  final String? employmentType;
  final String status;

  const AccountantPayrollEmployee({
    required this.id,
    required this.personnelCode,
    required this.firstName,
    required this.lastName,
    required this.nationalId,
    required this.mobile,
    required this.jobTitle,
    required this.department,
    required this.employmentType,
    required this.status,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get displayName {
    if (personnelCode.trim().isEmpty) {
      return fullName;
    }

    return '$fullName — کد $personnelCode';
  }

  bool get isActive => status.trim().toLowerCase() == 'active';
}

class AccountantPayrollContract {
  final String id;
  final String companyId;
  final String employeeId;
  final String? contractNumber;
  final String contractType;
  final DateTime? startDate;
  final DateTime? endDate;
  final double baseSalary;
  final double workingHours;
  final String insuranceStatus;
  final String taxStatus;
  final String status;
  final String costCenterId;
  final String? costCenterName;

  const AccountantPayrollContract({
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
    required this.costCenterName,
  });

  bool get isActive => status.trim().toLowerCase() == 'active';

  String get displayName {
    if (contractNumber != null && contractNumber!.trim().isNotEmpty) {
      return '$contractType — $contractNumber';
    }

    return contractType;
  }

  String get costCenterTitle => costCenterName ?? 'مرکز هزینه نامشخص';
}

class AccountantPayrollRecord {
  final String id;
  final String companyId;
  final String payrollPeriodId;
  final String employeeId;
  final String? contractId;

  final double baseSalary;
  final double overtimeHours;
  final double overtimeAmount;
  final double bonusAmount;
  final double allowanceAmount;
  final double grossSalary;

  final double employeeInsurance;
  final double employerInsurance;
  final double taxAmount;
  final double absenceAmount;
  final double otherDeductions;
  final double advanceAmount;
  final double netSalary;

  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountantPayrollRecord({
    required this.id,
    required this.companyId,
    required this.payrollPeriodId,
    required this.employeeId,
    required this.contractId,
    required this.baseSalary,
    required this.overtimeHours,
    required this.overtimeAmount,
    required this.bonusAmount,
    required this.allowanceAmount,
    required this.grossSalary,
    required this.employeeInsurance,
    required this.employerInsurance,
    required this.taxAmount,
    required this.absenceAmount,
    required this.otherDeductions,
    required this.advanceAmount,
    required this.netSalary,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalDeductions =>
      employeeInsurance +
      taxAmount +
      absenceAmount +
      otherDeductions +
      advanceAmount;

  double get totalBenefits =>
      baseSalary + overtimeAmount + bonusAmount + allowanceAmount;

  double get totalPayrollCost => grossSalary + employerInsurance;
}

class AccountantPayrollRecordsData {
  final AccountantPayrollPeriodInfo period;
  final List<AccountantPayrollEmployee> employees;
  final List<AccountantPayrollContract> contracts;
  final List<AccountantPayrollRecord> records;

  const AccountantPayrollRecordsData({
    required this.period,
    required this.employees,
    required this.contracts,
    required this.records,
  });

  AccountantPayrollEmployee? employeeById(String? employeeId) {
    if (employeeId == null) {
      return null;
    }

    for (final employee in employees) {
      if (employee.id == employeeId) {
        return employee;
      }
    }

    return null;
  }

  AccountantPayrollContract? contractById(String? contractId) {
    if (contractId == null) {
      return null;
    }

    for (final contract in contracts) {
      if (contract.id == contractId) {
        return contract;
      }
    }

    return null;
  }

  AccountantPayrollContract? activeContractForEmployee(String employeeId) {
    for (final contract in contracts) {
      if (contract.employeeId == employeeId && contract.isActive) {
        return contract;
      }
    }

    return null;
  }

  double get totalBaseSalary =>
      records.fold(0, (sum, item) => sum + item.baseSalary);

  double get totalOvertime =>
      records.fold(0, (sum, item) => sum + item.overtimeAmount);

  double get totalBonus =>
      records.fold(0, (sum, item) => sum + item.bonusAmount);

  double get totalAllowance =>
      records.fold(0, (sum, item) => sum + item.allowanceAmount);

  double get totalGrossSalary =>
      records.fold(0, (sum, item) => sum + item.grossSalary);

  double get totalEmployeeInsurance =>
      records.fold(0, (sum, item) => sum + item.employeeInsurance);

  double get totalEmployerInsurance =>
      records.fold(0, (sum, item) => sum + item.employerInsurance);

  double get totalTax => records.fold(0, (sum, item) => sum + item.taxAmount);

  double get totalAbsence =>
      records.fold(0, (sum, item) => sum + item.absenceAmount);

  double get totalOtherDeductions =>
      records.fold(0, (sum, item) => sum + item.otherDeductions);

  double get totalAdvance =>
      records.fold(0, (sum, item) => sum + item.advanceAmount);

  double get totalDeductions =>
      records.fold(0, (sum, item) => sum + item.totalDeductions);

  double get totalNetSalary =>
      records.fold(0, (sum, item) => sum + item.netSalary);

  double get totalPayrollCost =>
      records.fold(0, (sum, item) => sum + item.totalPayrollCost);

  int get employeeCount => records.length;
}

class AccountantPayrollRecordsRepository {
  AccountantPayrollRecordsRepository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<AccountantPayrollRecordsData> load(String periodId) async {
    final periodRow =
        await _supabase
            .from('payroll_periods')
            .select('''
          id,
          company_id,
          period_year,
          period_month,
          status,
          notes
        ''')
            .eq('id', periodId)
            .maybeSingle();

    if (periodRow == null) {
      throw Exception('دوره حقوق پیدا نشد.');
    }

    final companyId = periodRow['company_id']?.toString() ?? '';

    if (companyId.isEmpty) {
      throw Exception('شرکت مربوط به دوره حقوق مشخص نیست.');
    }

    final results = await Future.wait([
      _loadEmployees(companyId),
      _loadContracts(companyId),
      _loadRecords(periodId),
    ]);

    final employees = _mapEmployees(results[0] as List<dynamic>);

    final costCenters = await _loadCostCenters(companyId);

    final costCenterMap = <String, String>{};

    for (final raw in costCenters) {
      final row = Map<String, dynamic>.from(raw as Map);

      final id = row['id']?.toString();

      if (id != null && id.isNotEmpty) {
        costCenterMap[id] = row['name']?.toString() ?? '';
      }
    }

    final contracts = _mapContracts(results[1] as List<dynamic>, costCenterMap);

    final records = _mapRecords(results[2] as List<dynamic>);

    final period = AccountantPayrollPeriodInfo(
      id: periodRow['id']?.toString() ?? '',
      companyId: companyId,
      year: _toInt(periodRow['period_year']),
      month: _toInt(periodRow['period_month']),
      status: periodRow['status']?.toString() ?? '',
      notes: _stringOrNull(periodRow['notes']),
    );

    return AccountantPayrollRecordsData(
      period: period,
      employees: employees,
      contracts: contracts,
      records: records,
    );
  }

  static Future<List<dynamic>> _loadEmployees(String companyId) async {
    return await _supabase
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
          status
        ''')
        .eq('company_id', companyId)
        .order('first_name')
        .order('last_name');
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
          cost_center_id
        ''')
        .eq('company_id', companyId)
        .order('created_at', ascending: false);
  }

  static Future<List<dynamic>> _loadCostCenters(String companyId) async {
    return await _supabase
        .from('cost_centers')
        .select('''
          id,
          company_id,
          name,
          code,
          is_active
        ''')
        .eq('company_id', companyId)
        .order('name');
  }

  static Future<List<dynamic>> _loadRecords(String periodId) async {
    return await _supabase
        .from('payroll_records')
        .select('''
          id,
          company_id,
          payroll_period_id,
          employee_id,
          contract_id,
          base_salary,
          overtime_hours,
          overtime_amount,
          bonus_amount,
          allowance_amount,
          gross_salary,
          employee_insurance,
          employer_insurance,
          tax_amount,
          absence_amount,
          other_deductions,
          advance_amount,
          net_salary,
          notes,
          created_at,
          updated_at
        ''')
        .eq('payroll_period_id', periodId)
        .order('created_at');
  }

  static List<AccountantPayrollEmployee> _mapEmployees(List<dynamic> rows) {
    return rows.map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);

      return AccountantPayrollEmployee(
        id: row['id']?.toString() ?? '',
        personnelCode: row['personnel_code']?.toString() ?? '',
        firstName: row['first_name']?.toString() ?? '',
        lastName: row['last_name']?.toString() ?? '',
        nationalId: _stringOrNull(row['national_id']),
        mobile: _stringOrNull(row['mobile']),
        jobTitle: _stringOrNull(row['job_title']),
        department: _stringOrNull(row['department']),
        employmentType: _stringOrNull(row['employment_type']),
        status: row['status']?.toString() ?? '',
      );
    }).toList();
  }

  static List<AccountantPayrollContract> _mapContracts(
    List<dynamic> rows,
    Map<String, String> costCenterMap,
  ) {
    return rows
        .map((raw) {
          final row = Map<String, dynamic>.from(raw as Map);

          final costCenterId = row['cost_center_id']?.toString() ?? '';

          return AccountantPayrollContract(
            id: row['id']?.toString() ?? '',
            companyId: row['company_id']?.toString() ?? '',
            employeeId: row['employee_id']?.toString() ?? '',
            contractNumber: _stringOrNull(row['contract_number']),
            contractType: row['contract_type']?.toString() ?? '',
            startDate: _parseNullableDate(row['start_date']),
            endDate: _parseNullableDate(row['end_date']),
            baseSalary: _toDouble(row['base_salary']),
            workingHours: _toDouble(row['working_hours']),
            insuranceStatus: row['insurance_status']?.toString() ?? '',
            taxStatus: row['tax_status']?.toString() ?? '',
            status: row['status']?.toString() ?? '',
            costCenterId: costCenterId,
            costCenterName: costCenterMap[costCenterId],
          );
        })
        .where((item) {
          return item.employeeId.isNotEmpty;
        })
        .toList();
  }

  static List<AccountantPayrollRecord> _mapRecords(List<dynamic> rows) {
    return rows.map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);

      return AccountantPayrollRecord(
        id: row['id']?.toString() ?? '',
        companyId: row['company_id']?.toString() ?? '',
        payrollPeriodId: row['payroll_period_id']?.toString() ?? '',
        employeeId: row['employee_id']?.toString() ?? '',
        contractId: _stringOrNull(row['contract_id']),
        baseSalary: _toDouble(row['base_salary']),
        overtimeHours: _toDouble(row['overtime_hours']),
        overtimeAmount: _toDouble(row['overtime_amount']),
        bonusAmount: _toDouble(row['bonus_amount']),
        allowanceAmount: _toDouble(row['allowance_amount']),
        grossSalary: _toDouble(row['gross_salary']),
        employeeInsurance: _toDouble(row['employee_insurance']),
        employerInsurance: _toDouble(row['employer_insurance']),
        taxAmount: _toDouble(row['tax_amount']),
        absenceAmount: _toDouble(row['absence_amount']),
        otherDeductions: _toDouble(row['other_deductions']),
        advanceAmount: _toDouble(row['advance_amount']),
        netSalary: _toDouble(row['net_salary']),
        notes: _stringOrNull(row['notes']),
        createdAt: _parseDateTime(row['created_at']),
        updatedAt: _parseDateTime(row['updated_at']),
      );
    }).toList();
  }

  static Future<AccountantPayrollRecord> create({
    required String periodId,
    required String companyId,
    required String employeeId,
    required String contractId,
    required double baseSalary,
    required double overtimeHours,
    required double overtimeAmount,
    required double bonusAmount,
    required double allowanceAmount,
    required double employeeInsurance,
    required double employerInsurance,
    required double taxAmount,
    required double absenceAmount,
    required double otherDeductions,
    required double advanceAmount,
    String? notes,
  }) async {
    await _ensureEditable(periodId);

    final existing =
        await _supabase
            .from('payroll_records')
            .select('id')
            .eq('payroll_period_id', periodId)
            .eq('employee_id', employeeId)
            .maybeSingle();

    if (existing != null) {
      throw Exception(
        'برای این پرسنل در این دوره قبلاً رکورد حقوق ثبت شده است.',
      );
    }

    final grossSalary =
        baseSalary + overtimeAmount + bonusAmount + allowanceAmount;

    final netSalary =
        grossSalary -
        employeeInsurance -
        taxAmount -
        absenceAmount -
        otherDeductions -
        advanceAmount;

    final userId = _supabase.auth.currentUser?.id;

    final row =
        await _supabase
            .from('payroll_records')
            .insert({
              'company_id': companyId,
              'payroll_period_id': periodId,
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
              'notes': _nullable(notes),
              'created_by': userId,
            })
            .select('''
          id,
          company_id,
          payroll_period_id,
          employee_id,
          contract_id,
          base_salary,
          overtime_hours,
          overtime_amount,
          bonus_amount,
          allowance_amount,
          gross_salary,
          employee_insurance,
          employer_insurance,
          tax_amount,
          absence_amount,
          other_deductions,
          advance_amount,
          net_salary,
          notes,
          created_at,
          updated_at
        ''')
            .single();

    return _mapRecord(row);
  }

  static Future<AccountantPayrollRecord> update({
    required String id,
    required String periodId,
    required String employeeId,
    required String contractId,
    required double baseSalary,
    required double overtimeHours,
    required double overtimeAmount,
    required double bonusAmount,
    required double allowanceAmount,
    required double employeeInsurance,
    required double employerInsurance,
    required double taxAmount,
    required double absenceAmount,
    required double otherDeductions,
    required double advanceAmount,
    String? notes,
  }) async {
    await _ensureEditable(periodId);

    final grossSalary =
        baseSalary + overtimeAmount + bonusAmount + allowanceAmount;

    final netSalary =
        grossSalary -
        employeeInsurance -
        taxAmount -
        absenceAmount -
        otherDeductions -
        advanceAmount;

    final row =
        await _supabase
            .from('payroll_records')
            .update({
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
              'notes': _nullable(notes),
            })
            .eq('id', id)
            .select('''
          id,
          company_id,
          payroll_period_id,
          employee_id,
          contract_id,
          base_salary,
          overtime_hours,
          overtime_amount,
          bonus_amount,
          allowance_amount,
          gross_salary,
          employee_insurance,
          employer_insurance,
          tax_amount,
          absence_amount,
          other_deductions,
          advance_amount,
          net_salary,
          notes,
          created_at,
          updated_at
        ''')
            .single();

    return _mapRecord(row);
  }

  static Future<void> delete({
    required String id,
    required String periodId,
  }) async {
    await _ensureEditable(periodId);

    await _supabase.from('payroll_records').delete().eq('id', id);
  }

  static Future<void> _ensureEditable(String periodId) async {
    final row =
        await _supabase
            .from('payroll_periods')
            .select('status')
            .eq('id', periodId)
            .maybeSingle();

    if (row == null) {
      throw Exception('دوره حقوق پیدا نشد.');
    }

    final status = row['status']?.toString().trim().toLowerCase();

    if (status != 'draft') {
      throw Exception(
        'این دوره در وضعیت «${payrollStatusName(status ?? '')}» '
        'قرار دارد و قابل ویرایش نیست.',
      );
    }
  }

  static AccountantPayrollRecord _mapRecord(dynamic raw) {
    final row = Map<String, dynamic>.from(raw as Map);

    return AccountantPayrollRecord(
      id: row['id']?.toString() ?? '',
      companyId: row['company_id']?.toString() ?? '',
      payrollPeriodId: row['payroll_period_id']?.toString() ?? '',
      employeeId: row['employee_id']?.toString() ?? '',
      contractId: _stringOrNull(row['contract_id']),
      baseSalary: _toDouble(row['base_salary']),
      overtimeHours: _toDouble(row['overtime_hours']),
      overtimeAmount: _toDouble(row['overtime_amount']),
      bonusAmount: _toDouble(row['bonus_amount']),
      allowanceAmount: _toDouble(row['allowance_amount']),
      grossSalary: _toDouble(row['gross_salary']),
      employeeInsurance: _toDouble(row['employee_insurance']),
      employerInsurance: _toDouble(row['employer_insurance']),
      taxAmount: _toDouble(row['tax_amount']),
      absenceAmount: _toDouble(row['absence_amount']),
      otherDeductions: _toDouble(row['other_deductions']),
      advanceAmount: _toDouble(row['advance_amount']),
      netSalary: _toDouble(row['net_salary']),
      notes: _stringOrNull(row['notes']),
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

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
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

  static DateTime? _parseNullableDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }

  static DateTime _parseDateTime(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}

String payrollMonthName(int month) {
  const names = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  if (month < 1 || month > 12) {
    return 'ماه $month';
  }

  return names[month - 1];
}

String payrollStatusName(String status) {
  switch (status.trim().toLowerCase()) {
    case 'draft':
      return 'پیش‌نویس';

    case 'pending_ceo':
      return 'در انتظار مدیرعامل';

    case 'consultant_approved':
      return 'تأیید نهایی مشاور';

    case 'paid':
      return 'پرداخت شده';

    default:
      return status.isEmpty ? 'نامشخص' : status;
  }
}
