class PayrollCostCenterRecordModel {
  const PayrollCostCenterRecordModel({
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
    required this.createdAt,
    this.updatedAt,
    this.costCenterName,
    this.costCenterCode,
  });

  final String id;
  final String companyId;
  final String payrollPeriodId;
  final String costCenterId;

  final int employeeCount;

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

  final DateTime createdAt;
  final DateTime? updatedAt;

  final String? costCenterName;
  final String? costCenterCode;

  factory PayrollCostCenterRecordModel.fromMap(Map<String, dynamic> map) {
    final costCenter = map['cost_centers'];

    String? costCenterName;
    String? costCenterCode;

    if (costCenter is Map) {
      costCenterName = costCenter['name']?.toString();
      costCenterCode = costCenter['code']?.toString();
    }

    // اگر داده به صورت flat از View / RPC برگشته باشد
    costCenterName ??= map['cost_center_name']?.toString();
    costCenterCode ??= map['cost_center_code']?.toString();

    return PayrollCostCenterRecordModel(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      payrollPeriodId: map['payroll_period_id']?.toString() ?? '',
      costCenterId: map['cost_center_id']?.toString() ?? '',

      employeeCount: _toInt(map['employee_count']),

      baseSalary: _toDouble(map['base_salary']),
      senioritySalary: _toDouble(map['seniority_salary']),
      mealAllowance: _toDouble(map['meal_allowance']),
      housingAllowance: _toDouble(map['housing_allowance']),
      maritalAllowance: _toDouble(map['marital_allowance']),
      overtimeAmount: _toDouble(map['overtime_amount']),
      missionAllowance: _toDouble(map['mission_allowance']),
      performanceBonus: _toDouble(map['performance_bonus']),
      productionIncreaseBonus: _toDouble(map['production_increase_bonus']),

      monthlySeniorityBenefit: _toDouble(map['monthly_seniority_benefit']),
      monthlyEndServiceBonus: _toDouble(map['monthly_end_service_bonus']),
      missionTravelCost: _toDouble(map['mission_travel_cost']),

      employerInsurance: _toDouble(map['employer_insurance']),
      unemploymentInsurance: _toDouble(map['unemployment_insurance']),

      createdAt: _toDateTime(map['created_at']),
      updatedAt: _nullableDateTime(map['updated_at']),

      costCenterName: costCenterName,
      costCenterCode: costCenterCode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'payroll_period_id': payrollPeriodId,
      'cost_center_id': costCenterId,
      'employee_count': employeeCount,
      'base_salary': baseSalary,
      'seniority_salary': senioritySalary,
      'meal_allowance': mealAllowance,
      'housing_allowance': housingAllowance,
      'marital_allowance': maritalAllowance,
      'overtime_amount': overtimeAmount,
      'mission_allowance': missionAllowance,
      'performance_bonus': performanceBonus,
      'production_increase_bonus': productionIncreaseBonus,
      'monthly_seniority_benefit': monthlySeniorityBenefit,
      'monthly_end_service_bonus': monthlyEndServiceBonus,
      'mission_travel_cost': missionTravelCost,
      'employer_insurance': employerInsurance,
      'unemployment_insurance': unemploymentInsurance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  double get totalAllowances {
    return senioritySalary +
        mealAllowance +
        housingAllowance +
        maritalAllowance +
        overtimeAmount +
        missionAllowance +
        performanceBonus +
        productionIncreaseBonus;
  }

  double get totalPersonnelCosts {
    return monthlySeniorityBenefit + monthlyEndServiceBonus + missionTravelCost;
  }

  double get totalEmployerCosts {
    return employerInsurance + unemploymentInsurance;
  }

  double get totalPayrollCost {
    return baseSalary +
        totalAllowances +
        totalPersonnelCosts +
        totalEmployerCosts;
  }

  PayrollCostCenterRecordModel copyWith({
    String? costCenterId,
    int? employeeCount,
    double? baseSalary,
    double? senioritySalary,
    double? mealAllowance,
    double? housingAllowance,
    double? maritalAllowance,
    double? overtimeAmount,
    double? missionAllowance,
    double? performanceBonus,
    double? productionIncreaseBonus,
    double? monthlySeniorityBenefit,
    double? monthlyEndServiceBonus,
    double? missionTravelCost,
    double? employerInsurance,
    double? unemploymentInsurance,
    DateTime? updatedAt,
    String? costCenterName,
    String? costCenterCode,
  }) {
    return PayrollCostCenterRecordModel(
      id: id,
      companyId: companyId,
      payrollPeriodId: payrollPeriodId,
      costCenterId: costCenterId ?? this.costCenterId,
      employeeCount: employeeCount ?? this.employeeCount,
      baseSalary: baseSalary ?? this.baseSalary,
      senioritySalary: senioritySalary ?? this.senioritySalary,
      mealAllowance: mealAllowance ?? this.mealAllowance,
      housingAllowance: housingAllowance ?? this.housingAllowance,
      maritalAllowance: maritalAllowance ?? this.maritalAllowance,
      overtimeAmount: overtimeAmount ?? this.overtimeAmount,
      missionAllowance: missionAllowance ?? this.missionAllowance,
      performanceBonus: performanceBonus ?? this.performanceBonus,
      productionIncreaseBonus:
          productionIncreaseBonus ?? this.productionIncreaseBonus,
      monthlySeniorityBenefit:
          monthlySeniorityBenefit ?? this.monthlySeniorityBenefit,
      monthlyEndServiceBonus:
          monthlyEndServiceBonus ?? this.monthlyEndServiceBonus,
      missionTravelCost: missionTravelCost ?? this.missionTravelCost,
      employerInsurance: employerInsurance ?? this.employerInsurance,
      unemploymentInsurance:
          unemploymentInsurance ?? this.unemploymentInsurance,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      costCenterName: costCenterName ?? this.costCenterName,
      costCenterCode: costCenterCode ?? this.costCenterCode,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

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

  static DateTime? _nullableDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }
}
