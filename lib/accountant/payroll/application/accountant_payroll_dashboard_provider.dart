import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantPayrollDashboardProvider =
FutureProvider.family<AccountantPayrollDashboardData, String>(
      (ref, companyId) async {
    return AccountantPayrollDashboardRepository.load(companyId);
  },
);

class AccountantPayrollDashboardData {
  final String companyId;

  final int totalEmployees;
  final int activeEmployees;
  final int inactiveEmployees;

  final int totalContracts;
  final int activeContracts;
  final int expiredContracts;

  final int totalPeriods;
  final int openPeriods;
  final int closedPeriods;

  final int totalPayrollRecords;
  final int currentPeriodRecords;

  final double totalBaseSalary;
  final double totalOvertimeAmount;
  final double totalBonusAmount;
  final double totalAllowanceAmount;

  final double totalGrossSalary;
  final double totalEmployeeInsurance;
  final double totalEmployerInsurance;
  final double totalTax;
  final double totalAbsence;
  final double totalOtherDeductions;
  final double totalAdvance;
  final double totalDeductions;
  final double totalNetSalary;

  final List<AccountantPayrollPeriodSummary> periods;
  final List<AccountantPayrollDepartmentSummary> departments;
  final List<AccountantPayrollCostCenterOvertimeSummary>
  overtimeByCostCenter;

  const AccountantPayrollDashboardData({
    required this.companyId,
    required this.totalEmployees,
    required this.activeEmployees,
    required this.inactiveEmployees,
    required this.totalContracts,
    required this.activeContracts,
    required this.expiredContracts,
    required this.totalPeriods,
    required this.openPeriods,
    required this.closedPeriods,
    required this.totalPayrollRecords,
    required this.currentPeriodRecords,
    required this.totalBaseSalary,
    required this.totalOvertimeAmount,
    required this.totalBonusAmount,
    required this.totalAllowanceAmount,
    required this.totalGrossSalary,
    required this.totalEmployeeInsurance,
    required this.totalEmployerInsurance,
    required this.totalTax,
    required this.totalAbsence,
    required this.totalOtherDeductions,
    required this.totalAdvance,
    required this.totalDeductions,
    required this.totalNetSalary,
    required this.periods,
    required this.departments,
    required this.overtimeByCostCenter,
  });

  double get totalPayrollCost =>
      totalGrossSalary + totalEmployerInsurance;

  double get totalSalaryBenefits =>
      totalBaseSalary +
          totalOvertimeAmount +
          totalBonusAmount +
          totalAllowanceAmount;
}

class AccountantPayrollPeriodSummary {
  final String id;
  final int year;
  final int month;
  final String status;
  final int recordsCount;
  final double grossSalary;
  final double netSalary;
  final double overtimeAmount;

  const AccountantPayrollPeriodSummary({
    required this.id,
    required this.year,
    required this.month,
    required this.status,
    required this.recordsCount,
    required this.grossSalary,
    required this.netSalary,
    required this.overtimeAmount,
  });
}

class AccountantPayrollDepartmentSummary {
  final String department;
  final int employeeCount;
  final double grossSalary;
  final double netSalary;

  const AccountantPayrollDepartmentSummary({
    required this.department,
    required this.employeeCount,
    required this.grossSalary,
    required this.netSalary,
  });
}

class AccountantPayrollCostCenterOvertimeSummary {
  final String costCenterId;
  final String title;
  final double overtimeAmount;

  const AccountantPayrollCostCenterOvertimeSummary({
    required this.costCenterId,
    required this.title,
    required this.overtimeAmount,
  });
}

class AccountantPayrollDashboardRepository {
  AccountantPayrollDashboardRepository._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  static Future<AccountantPayrollDashboardData> load(
      String companyId,
      ) async {
    final results = await Future.wait([
      _supabase
          .from('employees')
          .select(
        'id,department,status',
      )
          .eq('company_id', companyId),

      _supabase
          .from('employment_contracts')
          .select(
        'id,status,end_date',
      )
          .eq('company_id', companyId),

      _supabase
          .from('payroll_periods')
          .select(
        'id,period_year,period_month,status,cost_center_id',
      )
          .eq('company_id', companyId)
          .order('period_year', ascending: false)
          .order('period_month', ascending: false),

      _supabase
          .from('payroll_records')
          .select(
        '''
            id,
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
            payroll_periods(
              period_year,
              period_month,
              cost_center_id
            )
            ''',
      )
          .eq('company_id', companyId),
    ]);

    final employees =
    List<Map<String, dynamic>>.from(results[0] as List);

    final contracts =
    List<Map<String, dynamic>>.from(results[1] as List);

    final payrollPeriods =
    List<Map<String, dynamic>>.from(results[2] as List);

    final payrollRecords =
    List<Map<String, dynamic>>.from(results[3] as List);

    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    int activeEmployees = 0;

    for (final employee in employees) {
      final status =
      employee['status']?.toString().trim().toLowerCase();

      if (status == 'active') {
        activeEmployees++;
      }
    }

    int activeContracts = 0;
    int expiredContracts = 0;

    final now = DateTime.now();

    for (final contract in contracts) {
      final status =
      contract['status']?.toString().trim().toLowerCase();

      if (status == 'active') {
        activeContracts++;
      }

      final endDate = DateTime.tryParse(
        contract['end_date']?.toString() ?? '',
      );

      if (status == 'expired' ||
          (endDate != null &&
              endDate.isBefore(now) &&
              status != 'active')) {
        expiredContracts++;
      }
    }

    int openPeriods = 0;
    int closedPeriods = 0;

    for (final period in payrollPeriods) {
      final status =
      period['status']?.toString().trim().toLowerCase();

      if (status == 'open') {
        openPeriods++;
      }

      if (status == 'closed') {
        closedPeriods++;
      }
    }

    final employeeDepartmentMap = <String, String>{};

    for (final employee in employees) {
      final employeeId =
          employee['id']?.toString() ?? '';

      final department =
      employee['department']?.toString().trim();

      employeeDepartmentMap[employeeId] =
      department == null || department.isEmpty
          ? 'بدون واحد'
          : department;
    }

    final periodRecordCount = <String, int>{};
    final periodGross = <String, double>{};
    final periodNet = <String, double>{};
    final periodOvertime = <String, double>{};

    final departmentEmployeeIds =
    <String, Set<String>>{};

    final departmentGross =
    <String, double>{};

    final departmentNet =
    <String, double>{};

    final overtimeByCostCenter =
    <String, double>{};

    double totalBaseSalary = 0;
    double totalOvertimeAmount = 0;
    double totalBonusAmount = 0;
    double totalAllowanceAmount = 0;

    double totalGrossSalary = 0;
    double totalEmployeeInsurance = 0;
    double totalEmployerInsurance = 0;
    double totalTax = 0;
    double totalAbsence = 0;
    double totalOtherDeductions = 0;
    double totalAdvance = 0;
    double totalNetSalary = 0;

    for (final record in payrollRecords) {
      final periodId =
          record['payroll_period_id']?.toString() ?? '';

      final employeeId =
          record['employee_id']?.toString() ?? '';

      final baseSalary =
      toDouble(record['base_salary']);

      final overtimeAmount =
      toDouble(record['overtime_amount']);

      final bonusAmount =
      toDouble(record['bonus_amount']);

      final allowanceAmount =
      toDouble(record['allowance_amount']);

      final grossSalary =
      toDouble(record['gross_salary']);

      final employeeInsurance =
      toDouble(record['employee_insurance']);

      final employerInsurance =
      toDouble(record['employer_insurance']);

      final taxAmount =
      toDouble(record['tax_amount']);

      final absenceAmount =
      toDouble(record['absence_amount']);

      final otherDeductions =
      toDouble(record['other_deductions']);

      final advanceAmount =
      toDouble(record['advance_amount']);

      final netSalary =
      toDouble(record['net_salary']);

      totalBaseSalary += baseSalary;
      totalOvertimeAmount += overtimeAmount;
      totalBonusAmount += bonusAmount;
      totalAllowanceAmount += allowanceAmount;

      totalGrossSalary += grossSalary;
      totalEmployeeInsurance += employeeInsurance;
      totalEmployerInsurance += employerInsurance;
      totalTax += taxAmount;
      totalAbsence += absenceAmount;
      totalOtherDeductions += otherDeductions;
      totalAdvance += advanceAmount;
      totalNetSalary += netSalary;

      periodRecordCount[periodId] =
          (periodRecordCount[periodId] ?? 0) + 1;

      periodGross[periodId] =
          (periodGross[periodId] ?? 0) + grossSalary;

      periodNet[periodId] =
          (periodNet[periodId] ?? 0) + netSalary;

      periodOvertime[periodId] =
          (periodOvertime[periodId] ?? 0) + overtimeAmount;

      final department =
          employeeDepartmentMap[employeeId] ??
              'بدون واحد';

      departmentEmployeeIds
          .putIfAbsent(
        department,
            () => <String>{},
      )
          .add(employeeId);

      departmentGross[department] =
          (departmentGross[department] ?? 0) +
              grossSalary;

      departmentNet[department] =
          (departmentNet[department] ?? 0) +
              netSalary;

      final nestedPeriod =
      record['payroll_periods']
      as Map<String, dynamic>?;

      final costCenterId =
      nestedPeriod?['cost_center_id']?.toString();

      final normalizedCostCenter =
      costCenterId == null ||
          costCenterId.isEmpty
          ? 'none'
          : costCenterId;

      overtimeByCostCenter[normalizedCostCenter] =
          (overtimeByCostCenter[normalizedCostCenter] ??
              0) +
              overtimeAmount;
    }

    final periodSummaries =
    <AccountantPayrollPeriodSummary>[];

    for (final period in payrollPeriods) {
      final id =
          period['id']?.toString() ?? '';

      periodSummaries.add(
        AccountantPayrollPeriodSummary(
          id: id,
          year: toInt(period['period_year']),
          month: toInt(period['period_month']),
          status:
          period['status']?.toString() ?? '',
          recordsCount:
          periodRecordCount[id] ?? 0,
          grossSalary:
          periodGross[id] ?? 0,
          netSalary:
          periodNet[id] ?? 0,
          overtimeAmount:
          periodOvertime[id] ?? 0,
        ),
      );
    }

    final departmentSummaries =
    departmentGross.entries.map((entry) {
      final department = entry.key;

      return AccountantPayrollDepartmentSummary(
        department: department,
        employeeCount:
        departmentEmployeeIds[department]
            ?.length ??
            0,
        grossSalary: entry.value,
        netSalary:
        departmentNet[department] ?? 0,
      );
    }).toList();

    departmentSummaries.sort(
          (a, b) =>
          b.grossSalary.compareTo(a.grossSalary),
    );

    final overtimeSummaries =
    overtimeByCostCenter.entries.map((entry) {
      final isNone = entry.key == 'none';

      return AccountantPayrollCostCenterOvertimeSummary(
        costCenterId: entry.key,
        title: isNone
            ? 'بدون مرکز هزینه'
            : 'مرکز ${entry.key.length > 8 ? entry.key.substring(0, 8) : entry.key}',
        overtimeAmount: entry.value,
      );
    }).toList();

    overtimeSummaries.sort(
          (a, b) =>
          b.overtimeAmount.compareTo(
            a.overtimeAmount,
          ),
    );

    final totalDeductions =
        totalEmployeeInsurance +
            totalTax +
            totalAbsence +
            totalOtherDeductions +
            totalAdvance;

    final currentPeriodRecords =
    periodSummaries.isEmpty
        ? 0
        : periodSummaries.first.recordsCount;

    return AccountantPayrollDashboardData(
      companyId: companyId,
      totalEmployees: employees.length,
      activeEmployees: activeEmployees,
      inactiveEmployees:
      employees.length - activeEmployees,
      totalContracts: contracts.length,
      activeContracts: activeContracts,
      expiredContracts: expiredContracts,
      totalPeriods: payrollPeriods.length,
      openPeriods: openPeriods,
      closedPeriods: closedPeriods,
      totalPayrollRecords:
      payrollRecords.length,
      currentPeriodRecords:
      currentPeriodRecords,
      totalBaseSalary: totalBaseSalary,
      totalOvertimeAmount:
      totalOvertimeAmount,
      totalBonusAmount:
      totalBonusAmount,
      totalAllowanceAmount:
      totalAllowanceAmount,
      totalGrossSalary:
      totalGrossSalary,
      totalEmployeeInsurance:
      totalEmployeeInsurance,
      totalEmployerInsurance:
      totalEmployerInsurance,
      totalTax: totalTax,
      totalAbsence: totalAbsence,
      totalOtherDeductions:
      totalOtherDeductions,
      totalAdvance: totalAdvance,
      totalDeductions: totalDeductions,
      totalNetSalary: totalNetSalary,
      periods: periodSummaries,
      departments: departmentSummaries,
      overtimeByCostCenter:
      overtimeSummaries,
    );
  }
}