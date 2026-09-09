class PayrollRecordModel {
  const PayrollRecordModel({
    required this.id,
    required this.companyId,
    required this.payrollPeriodId,
    required this.employeeId,
    this.contractId,
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
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

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

  final DateTime createdAt;
  final DateTime updatedAt;

  factory PayrollRecordModel.fromMap(Map<String, dynamic> map) {
    return PayrollRecordModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      payrollPeriodId: map['payroll_period_id'] as String,
      employeeId: map['employee_id'] as String,
      contractId: map['contract_id'] as String?,

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

      notes: map['notes'] as String?,

      createdBy: map['created_by'] as String?,

      createdAt: _toDateTime(map['created_at']),

      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'payroll_period_id': payrollPeriodId,
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
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
