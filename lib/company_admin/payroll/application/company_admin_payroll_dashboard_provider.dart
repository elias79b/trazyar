import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shamsi_date/shamsi_date.dart';

final companyAdminPayrollDashboardProvider =
    FutureProvider.autoDispose<CompanyAdminPayrollDashboardData>((ref) async {
      final client = Supabase.instance.client;

      final authUser = client.auth.currentUser;

      if (authUser == null) {
        throw Exception('کاربر وارد سیستم نشده است.');
      }

      final membership =
          await client
              .from('company_users')
              .select('company_id, user_id, role, is_active')
              .eq('user_id', authUser.id)
              .eq('role', 'company_admin')
              .eq('is_active', true)
              .maybeSingle();

      if (membership == null) {
        throw Exception('هیچ شرکت فعالی برای این مدیرعامل پیدا نشد.');
      }

      final companyId = membership['company_id']?.toString();

      if (companyId == null || companyId.isEmpty) {
        throw Exception('شناسه شرکت مدیرعامل پیدا نشد.');
      }

      return CompanyAdminPayrollDashboardRepository(client).load(companyId);
    });

class CompanyAdminPayrollDashboardRepository {
  final SupabaseClient client;

  CompanyAdminPayrollDashboardRepository(this.client);

  Future<CompanyAdminPayrollDashboardData> load(String companyId) async {
    /*
     * فقط اطلاعاتی که تأیید نهایی مشاور/مدیر مؤسسه را گرفته‌اند
     * وارد داشبورد مدیریتی می‌شوند.
     */
    final periodsResponse = await client
        .from('payroll_periods')
        .select('id, company_id, period_year, period_month, status, notes')
        .eq('company_id', companyId)
        .eq('status', 'consultant_approved')
        .order('period_year', ascending: true)
        .order('period_month', ascending: true);

    final periods =
        (periodsResponse as List)
            .map(
              (row) => PayrollDashboardPeriod.fromMap(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();

    if (periods.isEmpty) {
      return CompanyAdminPayrollDashboardData.empty(companyId: companyId);
    }

    /*
     * برای داشبورد، حداکثر 12 دوره آخر را نمایش می‌دهیم.
     */
    final visiblePeriods =
        periods.length > 12 ? periods.sublist(periods.length - 12) : periods;

    final periodIds = visiblePeriods.map((e) => e.id).toList();

    final payrollRecordsResponse = await client
        .from('payroll_records')
        .select('''
          id,
          company_id,
          payroll_period_id,
          employee_id,
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
          net_salary
          ''')
        .eq('company_id', companyId)
        .inFilter('payroll_period_id', periodIds);

    final payrollRecords =
        (payrollRecordsResponse as List)
            .map(
              (row) => PayrollDashboardRecord.fromMap(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();

    final costCenterResponse = await client
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
          unemployment_insurance
          ''')
        .eq('company_id', companyId)
        .inFilter('payroll_period_id', periodIds);

    final costCenterRecords =
        (costCenterResponse as List)
            .map(
              (row) => PayrollCostCenterDashboardRecord.fromMap(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList();

    final costCenterIds =
        costCenterRecords
            .map((e) => e.costCenterId)
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

    Map<String, String> costCenterNames = {};

    if (costCenterIds.isNotEmpty) {
      final centersResponse = await client
          .from('cost_centers')
          .select('id, name')
          .eq('company_id', companyId)
          .inFilter('id', costCenterIds);

      costCenterNames = {
        for (final row in (centersResponse as List))
          row['id'].toString(): row['name']?.toString() ?? 'بدون نام',
      };
    }

    final monthly = <PayrollDashboardMonthlyData>[];

    for (final period in visiblePeriods) {
      final records =
          payrollRecords
              .where((record) => record.payrollPeriodId == period.id)
              .toList();

      final centerRecords =
          costCenterRecords
              .where((record) => record.payrollPeriodId == period.id)
              .toList();

      final employeeIds =
          records.map((e) => e.employeeId).where((e) => e.isNotEmpty).toSet();

      final overtimeAmount = records.fold<double>(
        0,
        (sum, item) => sum + item.overtimeAmount,
      );

      /*
       * هزینه کل حقوق و دستمزد:
       * حقوق ناخالص + بیمه سهم کارفرما
       */
      final totalPayrollCost = records.fold<double>(
        0,
        (sum, item) => sum + item.grossSalary + item.employerInsurance,
      );

      final employeeCount = employeeIds.length;

      final perCapitaCost =
          employeeCount == 0 ? 0.0 : totalPayrollCost / employeeCount;

      final centerCosts = <String, double>{};

      for (final record in centerRecords) {
        final name =
            costCenterNames[record.costCenterId] ?? 'مرکز هزینه نامشخص';

        final amount = record.totalCost;

        centerCosts[name] = (centerCosts[name] ?? 0) + amount;
      }

      monthly.add(
        PayrollDashboardMonthlyData(
          period: period,
          overtimeAmount: overtimeAmount,
          employeeCount: employeeCount,
          totalPayrollCost: totalPayrollCost,
          perCapitaCost: perCapitaCost,
          costCenterCosts: centerCosts,
        ),
      );
    }

    return CompanyAdminPayrollDashboardData(
      companyId: companyId,
      periods: visiblePeriods,
      monthly: monthly,
      availableYears: periods.map((e) => e.periodYear).toSet().toList()..sort(),
      currentJalaliYear: Jalali.now().year,
    );
  }
}

class CompanyAdminPayrollDashboardData {
  final String companyId;
  final List<PayrollDashboardPeriod> periods;
  final List<PayrollDashboardMonthlyData> monthly;
  final List<int> availableYears;
  final int currentJalaliYear;

  const CompanyAdminPayrollDashboardData({
    required this.companyId,
    required this.periods,
    required this.monthly,
    required this.availableYears,
    required this.currentJalaliYear,
  });

  factory CompanyAdminPayrollDashboardData.empty({required String companyId}) {
    return CompanyAdminPayrollDashboardData(
      companyId: companyId,
      periods: const [],
      monthly: const [],
      availableYears: const [],
      currentJalaliYear: Jalali.now().year,
    );
  }
}

class PayrollDashboardPeriod {
  final String id;
  final int periodYear;
  final int periodMonth;
  final String status;

  const PayrollDashboardPeriod({
    required this.id,
    required this.periodYear,
    required this.periodMonth,
    required this.status,
  });

  factory PayrollDashboardPeriod.fromMap(Map<String, dynamic> map) {
    return PayrollDashboardPeriod(
      id: map['id'].toString(),
      periodYear: _toInt(map['period_year']),
      periodMonth: _toInt(map['period_month']),
      status: map['status']?.toString() ?? '',
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

    if (periodMonth >= 1 && periodMonth <= 12) {
      return months[periodMonth - 1];
    }

    return 'ماه $periodMonth';
  }

  String get label => '$monthName $periodYear';

  String get shortLabel => monthName;
}

class PayrollDashboardRecord {
  final String id;
  final String payrollPeriodId;
  final String employeeId;

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

  const PayrollDashboardRecord({
    required this.id,
    required this.payrollPeriodId,
    required this.employeeId,
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
  });

  factory PayrollDashboardRecord.fromMap(Map<String, dynamic> map) {
    return PayrollDashboardRecord(
      id: map['id'].toString(),
      payrollPeriodId: map['payroll_period_id'].toString(),
      employeeId: map['employee_id'].toString(),
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
    );
  }
}

class PayrollCostCenterDashboardRecord {
  final String id;
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

  const PayrollCostCenterDashboardRecord({
    required this.id,
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
  });

  factory PayrollCostCenterDashboardRecord.fromMap(Map<String, dynamic> map) {
    return PayrollCostCenterDashboardRecord(
      id: map['id'].toString(),
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
      monthlySeniorityBenefit: _toDouble(map['monthly_seniority_benefit']),
      monthlyEndServiceBonus: _toDouble(map['monthly_end_service_bonus']),
      missionTravelCost: _toDouble(map['mission_travel_cost']),
      employerInsurance: _toDouble(map['employer_insurance']),
      unemploymentInsurance: _toDouble(map['unemployment_insurance']),
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

class PayrollDashboardMonthlyData {
  final PayrollDashboardPeriod period;

  final double overtimeAmount;
  final int employeeCount;
  final double totalPayrollCost;
  final double perCapitaCost;

  final Map<String, double> costCenterCosts;

  const PayrollDashboardMonthlyData({
    required this.period,
    required this.overtimeAmount,
    required this.employeeCount,
    required this.totalPayrollCost,
    required this.perCapitaCost,
    required this.costCenterCosts,
  });
}

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString().replaceAll(',', '')) ?? 0;
}

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
}
