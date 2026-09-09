class EmploymentContractModel {
  const EmploymentContractModel({
    required this.id,
    required this.companyId,
    this.employeeId,
    this.costCenterId,
    this.contractNumber,
    required this.contractType,
    this.startDate,
    this.endDate,
    required this.baseSalary,
    this.workingHours,
    required this.insuranceStatus,
    required this.taxStatus,
    required this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String companyId;

  /// قرارداد دیگر مستقیماً به پرسنل وابسته نیست.
  /// برای سازگاری با رکوردهای قدیمی nullable نگه داشته شده.
  final String? employeeId;

  /// مرکز هزینه اصلی قرارداد
  final String? costCenterId;

  final String? contractNumber;
  final String contractType;

  final DateTime? startDate;
  final DateTime? endDate;

  /// در دیتابیس فعلاً باقی مانده تا اطلاعات قدیمی خراب نشود.
  /// در فرم قرارداد نمایش داده نمی‌شود.
  final double baseSalary;

  /// در دیتابیس فعلاً باقی مانده تا اطلاعات قدیمی خراب نشود.
  /// در فرم قرارداد نمایش داده نمی‌شود.
  final double? workingHours;

  final String insuranceStatus;
  final String taxStatus;
  final String status;

  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory EmploymentContractModel.fromMap(Map<String, dynamic> map) {
    return EmploymentContractModel(
      id: (map['id'] ?? '').toString(),
      companyId: (map['company_id'] ?? '').toString(),

      employeeId:
          map['employee_id'] == null ? null : map['employee_id'].toString(),

      costCenterId:
          map['cost_center_id'] == null
              ? null
              : map['cost_center_id'].toString(),

      contractNumber:
          map['contract_number'] == null
              ? null
              : map['contract_number'].toString(),

      contractType: (map['contract_type'] ?? 'permanent').toString(),

      startDate:
          map['start_date'] == null
              ? null
              : DateTime.tryParse(map['start_date'].toString()),

      endDate:
          map['end_date'] == null
              ? null
              : DateTime.tryParse(map['end_date'].toString()),

      baseSalary: _toDouble(map['base_salary']) ?? 0,

      workingHours: _toDouble(map['working_hours']),

      insuranceStatus: (map['insurance_status'] ?? 'insured').toString(),

      taxStatus: (map['tax_status'] ?? 'taxable').toString(),

      status: (map['status'] ?? 'active').toString(),

      createdBy:
          map['created_by'] == null ? null : map['created_by'].toString(),

      createdAt:
          map['created_at'] == null
              ? null
              : DateTime.tryParse(map['created_at'].toString()),

      updatedAt:
          map['updated_at'] == null
              ? null
              : DateTime.tryParse(map['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'employee_id': employeeId,
      'cost_center_id': costCenterId,
      'contract_number': contractNumber,
      'contract_type': contractType,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'base_salary': baseSalary,
      'working_hours': workingHours,
      'insurance_status': insuranceStatus,
      'tax_status': taxStatus,
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}
