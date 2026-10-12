import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final companyAdminPayrollPeriodDetailProvider = FutureProvider.autoDispose
    .family<CompanyAdminPayrollPeriodDetailData, String>((ref, periodId) async {
  final client = Supabase.instance.client;

  final user = client.auth.currentUser;

  if (user == null) {
    throw Exception('کاربر وارد سیستم نشده است.');
  }

  final membership =
  await client
      .from('company_users')
      .select('company_id, user_id, role, is_active')
      .eq('user_id', user.id)
      .eq('role', 'company_admin')
      .eq('is_active', true)
      .maybeSingle();

  if (membership == null) {
    throw Exception('شرکت فعالی برای این مدیرعامل پیدا نشد.');
  }

  final companyId = membership['company_id']?.toString();

  if (companyId == null || companyId.isEmpty) {
    throw Exception('شناسه شرکت مدیرعامل پیدا نشد.');
  }

  final periodRows = await client
      .from('payroll_periods')
      .select('''
        id,
        company_id,
        period_year,
        period_month,
        status,
        notes,
        created_by,
        created_at,
        updated_at,
        cost_center_id
        ''')
      .eq('id', periodId)
      .eq('company_id', companyId)
      .limit(1);

  if (periodRows.isEmpty) {
    throw Exception('دوره حقوق موردنظر پیدا نشد.');
  }

  final period = CompanyAdminPayrollPeriodDetail.fromMap(
    Map<String, dynamic>.from(periodRows.first),
  );

  final payrollRows = await client
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
        created_by,
        created_at,
        updated_at
        ''')
      .eq('company_id', companyId)
      .eq('payroll_period_id', periodId)
      .order('created_at', ascending: true);

  final employeeIds =
  payrollRows
      .map((row) => row['employee_id']?.toString())
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  final Map<String, CompanyAdminPayrollEmployee> employees = {};

  if (employeeIds.isNotEmpty) {
    final employeeRows = await client
        .from('employees')
        .select('''
          id,
          company_id,
          personnel_code,
          first_name,
          last_name,
          job_title,
          department,
          employment_type,
          status
          ''')
        .eq('company_id', companyId)
        .inFilter('id', employeeIds);

    for (final row in employeeRows) {
      final employee = CompanyAdminPayrollEmployee.fromMap(
        Map<String, dynamic>.from(row),
      );

      employees[employee.id] = employee;
    }
  }

  final records =
  payrollRows.map((row) {
    final record = CompanyAdminPayrollRecord.fromMap(
      Map<String, dynamic>.from(row),
    );

    return record.copyWith(employee: employees[record.employeeId]);
  }).toList();

  final costCenterRows = await client
      .from('payroll_cost_center_records')
      .select('''
        id,
        company_id,
        payroll_period_id,
        cost_center_id,
        employee_count,
        base_salary,
        seniority_salary,
        meal_allowance,
        housing_allowance,
        marital_allowance,
        overtime_amount,
        mission_allowance,
        performance_bonus,
        production_increase_bonus,
        monthly_seniority_benefit,
        monthly_end_service_bonus,
        mission_travel_cost,
        employer_insurance,
        unemployment_insurance,
        created_by,
        created_at
        ''')
      .eq('company_id', companyId)
      .eq('payroll_period_id', periodId)
      .order('created_at', ascending: true);

  final costCenterIds =
  costCenterRows
      .map((row) => row['cost_center_id']?.toString())
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  final Map<String, String> costCenterNames = {};

  if (costCenterIds.isNotEmpty) {
    final costCenterNameRows = await client
        .from('cost_centers')
        .select('''
          id,
          company_id,
          name,
          code,
          is_active
          ''')
        .eq('company_id', companyId)
        .inFilter('id', costCenterIds);

    for (final row in costCenterNameRows) {
      final id = row['id']?.toString();

      if (id == null || id.isEmpty) {
        continue;
      }

      costCenterNames[id] =
          row['name']?.toString() ?? 'مرکز هزینه بدون نام';
    }
  }

  final costCenters =
  costCenterRows.map((row) {
    final record = CompanyAdminPayrollCostCenterRecord.fromMap(
      Map<String, dynamic>.from(row),
    );

    return record.copyWith(
      costCenterName: costCenterNames[record.costCenterId],
    );
  }).toList();

  final workflowRows = await client
      .from('payroll_period_workflow')
      .select('''
        id,
        period_id,
        company_id,
        from_status,
        to_status,
        acted_by,
        note,
        created_at
        ''')
      .eq('period_id', periodId)
      .eq('company_id', companyId)
      .order('created_at', ascending: false);

  final workflow =
  workflowRows
      .map(
        (row) => CompanyAdminPayrollWorkflowEntry.fromMap(
      Map<String, dynamic>.from(row),
    ),
  )
      .toList();

  return CompanyAdminPayrollPeriodDetailData(
    companyId: companyId,
    period: period,
    records: records,
    costCenters: costCenters,
    workflow: workflow,
  );
});

class CompanyAdminPayrollPeriodDetailData {
  final String companyId;
  final CompanyAdminPayrollPeriodDetail period;
  final List<CompanyAdminPayrollRecord> records;
  final List<CompanyAdminPayrollCostCenterRecord> costCenters;
  final List<CompanyAdminPayrollWorkflowEntry> workflow;

  const CompanyAdminPayrollPeriodDetailData({
    required this.companyId,
    required this.period,
    required this.records,
    required this.costCenters,
    required this.workflow,
  });

  int get employeeCount =>
      records
          .map((e) => e.employeeId)
          .where((e) => e.isNotEmpty)
          .toSet()
          .length;

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

  double get totalDeductions =>
      records.fold(0, (sum, item) => sum + item.totalDeductions);

  double get totalNetSalary =>
      records.fold(0, (sum, item) => sum + item.netSalary);

  double get totalEmployerCost => totalGrossSalary + totalEmployerInsurance;

  double get totalCostCenterEmployees =>
      costCenters.fold(0, (sum, item) => sum + item.employeeCount);
}

class CompanyAdminPayrollWorkflowEntry {
  final String id;
  final String periodId;
  final String companyId;
  final String? fromStatus;
  final String toStatus;
  final String? actedBy;
  final String? note;
  final DateTime? createdAt;

  const CompanyAdminPayrollWorkflowEntry({
    required this.id,
    required this.periodId,
    required this.companyId,
    required this.fromStatus,
    required this.toStatus,
    required this.actedBy,
    required this.note,
    required this.createdAt,
  });

  factory CompanyAdminPayrollWorkflowEntry.fromMap(
      Map<String, dynamic> map,
      ) {
    return CompanyAdminPayrollWorkflowEntry(
      id: map['id'].toString(),
      periodId: map['period_id'].toString(),
      companyId: map['company_id'].toString(),
      fromStatus: map['from_status']?.toString(),
      toStatus: map['to_status']?.toString() ?? '',
      actedBy: map['acted_by']?.toString(),
      note: map['note']?.toString(),
      createdAt: _toDateTime(map['created_at']),
    );
  }

  String get fromStatusTitle {
    return _workflowStatusTitle(fromStatus);
  }

  String get toStatusTitle {
    return _workflowStatusTitle(toStatus);
  }
}

class CompanyAdminPayrollPeriodDetail {
  final String id;
  final String companyId;
  final int periodYear;
  final int periodMonth;
  final String status;
  final String? notes;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? costCenterId;

  const CompanyAdminPayrollPeriodDetail({
    required this.id,
    required this.companyId,
    required this.periodYear,
    required this.periodMonth,
    required this.status,
    required this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.costCenterId,
  });

  factory CompanyAdminPayrollPeriodDetail.fromMap(
      Map<String, dynamic> map,
      ) {
    return CompanyAdminPayrollPeriodDetail(
      id: map['id'].toString(),
      companyId: map['company_id'].toString(),
      periodYear: _toInt(map['period_year']),
      periodMonth: _toInt(map['period_month']),
      status: map['status']?.toString() ?? 'draft',
      notes: map['notes']?.toString(),
      createdBy: map['created_by']?.toString(),
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
      costCenterId: map['cost_center_id']?.toString(),
    );
  }

  String get monthName {
    const months = [
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

    if (periodMonth < 1 || periodMonth > 12) {
      return 'ماه $periodMonth';
    }

    return months[periodMonth - 1];
  }

  String get title {
    return '$monthName $periodYear';
  }

  String get statusTitle {
    switch (status) {
      case 'draft':
        return 'پیش‌نویس';

      case 'pending_ceo':
        return 'در انتظار بررسی مدیرعامل';

      case 'ceo_approved':
        return 'تأیید مدیرعامل';

      case 'pending_consultant':
        return 'در انتظار بررسی مشاور';

      case 'consultant_approved':
        return 'تأیید نهایی';

      case 'rejected':
        return 'رد شده';

      case 'paid':
        return 'پرداخت شده';

      case 'cancelled':
        return 'لغو شده';

      default:
        return status;
    }
  }

  bool get isPendingCeo => status == 'pending_ceo';

  bool get isCeoApproved => status == 'ceo_approved';

  bool get isPendingConsultant => status == 'pending_consultant';

  bool get isConsultantApproved => status == 'consultant_approved';
}

class CompanyAdminPayrollEmployee {
  final String id;
  final String companyId;
  final String? personnelCode;
  final String? firstName;
  final String? lastName;
  final String? jobTitle;
  final String? department;
  final String? employmentType;
  final String? status;

  const CompanyAdminPayrollEmployee({
    required this.id,
    required this.companyId,
    required this.personnelCode,
    required this.firstName,
    required this.lastName,
    required this.jobTitle,
    required this.department,
    required this.employmentType,
    required this.status,
  });

  factory CompanyAdminPayrollEmployee.fromMap(Map<String, dynamic> map) {
    return CompanyAdminPayrollEmployee(
      id: map['id'].toString(),
      companyId: map['company_id'].toString(),
      personnelCode: map['personnel_code']?.toString(),
      firstName: map['first_name']?.toString(),
      lastName: map['last_name']?.toString(),
      jobTitle: map['job_title']?.toString(),
      department: map['department']?.toString(),
      employmentType: map['employment_type']?.toString(),
      status: map['status']?.toString(),
    );
  }

  String get fullName {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';

    final result = '$first $last'.trim();

    if (result.isEmpty) {
      return 'کارمند بدون نام';
    }

    return result;
  }
}

class CompanyAdminPayrollRecord {
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
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final CompanyAdminPayrollEmployee? employee;

  const CompanyAdminPayrollRecord({
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
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.employee,
  });

  factory CompanyAdminPayrollRecord.fromMap(Map<String, dynamic> map) {
    return CompanyAdminPayrollRecord(
      id: map['id'].toString(),
      companyId: map['company_id'].toString(),
      payrollPeriodId: map['payroll_period_id'].toString(),
      employeeId: map['employee_id'].toString(),
      contractId: map['contract_id']?.toString(),
      baseSalary: _toDouble(map['base_salary']),
      overtimeHours: _toDouble(map['overtime_hours']),
      overtimeAmount: _toDouble(map['overtime_amount']),
      bonusAmount: _toDouble(map['bonus_amount']),
      allowanceAmount: _toDouble(map['allowance_amount']),
      grossSalary: _toDouble(map['gross_salary']),
      employeeInsurance: _toDouble(map['employee_insurance']),
      employerInsurance: _toDouble(map['employer_insurance']),
      taxAmount: _toDouble(map['tax_amount']),
      absenceAmount: _toDouble(map['absence_amount']),
      otherDeductions: _toDouble(map['other_deductions']),
      advanceAmount: _toDouble(map['advance_amount']),
      netSalary: _toDouble(map['net_salary']),
      notes: map['notes']?.toString(),
      createdBy: map['created_by']?.toString(),
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
      employee: null,
    );
  }

  CompanyAdminPayrollRecord copyWith({
    CompanyAdminPayrollEmployee? employee,
  }) {
    return CompanyAdminPayrollRecord(
      id: id,
      companyId: companyId,
      payrollPeriodId: payrollPeriodId,
      employeeId: employeeId,
      contractId: contractId,
      baseSalary: baseSalary,
      overtimeHours: overtimeHours,
      overtimeAmount: overtimeAmount,
      bonusAmount: bonusAmount,
      allowanceAmount: allowanceAmount,
      grossSalary: grossSalary,
      employeeInsurance: employeeInsurance,
      employerInsurance: employerInsurance,
      taxAmount: taxAmount,
      absenceAmount: absenceAmount,
      otherDeductions: otherDeductions,
      advanceAmount: advanceAmount,
      netSalary: netSalary,
      notes: notes,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      employee: employee,
    );
  }

  double get totalDeductions {
    return employeeInsurance +
        taxAmount +
        absenceAmount +
        otherDeductions +
        advanceAmount;
  }
}

class CompanyAdminPayrollCostCenterRecord {
  final String id;
  final String companyId;
  final String payrollPeriodId;
  final String costCenterId;

  final double employeeCount;
  final double baseSalary;
  final double senioritySalary;
  final double mealAllowance;
  final double housingAllowance;
  final double maritalAllowance;
  final double overtimeAmount;
  final double missionAllowance;
  final double performanceBonus;
  final double productionIncreaseBonus;
  final double monthlySeniorityBenefit;
  final double monthlyEndServiceBonus;
  final double missionTravelCost;
  final double employerInsurance;
  final double unemploymentInsurance;

  final String? createdBy;
  final DateTime? createdAt;

  final String? costCenterName;

  const CompanyAdminPayrollCostCenterRecord({
    required this.id,
    required this.companyId,
    required this.payrollPeriodId,
    required this.costCenterId,
    required this.employeeCount,
    required this.baseSalary,
    required this.senioritySalary,
    required this.mealAllowance,
    required this.housingAllowance,
    required this.maritalAllowance,
    required this.overtimeAmount,
    required this.missionAllowance,
    required this.performanceBonus,
    required this.productionIncreaseBonus,
    required this.monthlySeniorityBenefit,
    required this.monthlyEndServiceBonus,
    required this.missionTravelCost,
    required this.employerInsurance,
    required this.unemploymentInsurance,
    required this.createdBy,
    required this.createdAt,
    required this.costCenterName,
  });

  factory CompanyAdminPayrollCostCenterRecord.fromMap(
      Map<String, dynamic> map,
      ) {
    return CompanyAdminPayrollCostCenterRecord(
      id: map['id'].toString(),
      companyId: map['company_id'].toString(),
      payrollPeriodId: map['payroll_period_id'].toString(),
      costCenterId: map['cost_center_id'].toString(),
      employeeCount: _toDouble(map['employee_count']),
      baseSalary: _toDouble(map['base_salary']),
      senioritySalary: _toDouble(map['seniority_salary']),
      mealAllowance: _toDouble(map['meal_allowance']),
      housingAllowance: _toDouble(map['housing_allowance']),
      maritalAllowance: _toDouble(map['marital_allowance']),
      overtimeAmount: _toDouble(map['overtime_amount']),
      missionAllowance: _toDouble(map['mission_allowance']),
      performanceBonus: _toDouble(map['performance_bonus']),
      productionIncreaseBonus: _toDouble(map['production_increase_bonus']),
      monthlySeniorityBenefit: _toDouble(
        map['monthly_seniority_benefit'],
      ),
      monthlyEndServiceBonus: _toDouble(
        map['monthly_end_service_bonus'],
      ),
      missionTravelCost: _toDouble(map['mission_travel_cost']),
      employerInsurance: _toDouble(map['employer_insurance']),
      unemploymentInsurance: _toDouble(map['unemployment_insurance']),
      createdBy: map['created_by']?.toString(),
      createdAt: _toDateTime(map['created_at']),
      costCenterName: null,
    );
  }

  CompanyAdminPayrollCostCenterRecord copyWith({
    String? costCenterName,
  }) {
    return CompanyAdminPayrollCostCenterRecord(
      id: id,
      companyId: companyId,
      payrollPeriodId: payrollPeriodId,
      costCenterId: costCenterId,
      employeeCount: employeeCount,
      baseSalary: baseSalary,
      senioritySalary: senioritySalary,
      mealAllowance: mealAllowance,
      housingAllowance: housingAllowance,
      maritalAllowance: maritalAllowance,
      overtimeAmount: overtimeAmount,
      missionAllowance: missionAllowance,
      performanceBonus: performanceBonus,
      productionIncreaseBonus: productionIncreaseBonus,
      monthlySeniorityBenefit: monthlySeniorityBenefit,
      monthlyEndServiceBonus: monthlyEndServiceBonus,
      missionTravelCost: missionTravelCost,
      employerInsurance: employerInsurance,
      unemploymentInsurance: unemploymentInsurance,
      createdBy: createdBy,
      createdAt: createdAt,
      costCenterName: costCenterName,
    );
  }

  double get totalCost {
    return baseSalary +
        senioritySalary +
        mealAllowance +
        housingAllowance +
        maritalAllowance +
        overtimeAmount +
        missionAllowance +
        performanceBonus +
        productionIncreaseBonus +
        monthlySeniorityBenefit +
        monthlyEndServiceBonus +
        missionTravelCost +
        employerInsurance +
        unemploymentInsurance;
  }
}

String _workflowStatusTitle(String? status) {
  switch (status) {
    case null:
      return '—';

    case 'draft':
      return 'پیش‌نویس';

    case 'pending_ceo':
      return 'در انتظار بررسی مدیرعامل';

    case 'ceo_approved':
      return 'تأیید مدیرعامل';

    case 'pending_consultant':
      return 'در انتظار بررسی مشاور';

    case 'consultant_approved':
      return 'تأیید نهایی';

    case 'rejected':
      return 'رد شده';

    case 'paid':
      return 'پرداخت شده';

    case 'cancelled':
      return 'لغو شده';

    default:
      return status;
  }
}

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}