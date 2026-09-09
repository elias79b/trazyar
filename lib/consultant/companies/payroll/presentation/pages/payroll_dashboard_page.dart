import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class PayrollDashboardPage extends StatefulWidget {
  const PayrollDashboardPage({super.key, required this.companyId});

  final String companyId;

  @override
  State<PayrollDashboardPage> createState() => _PayrollDashboardPageState();
}

class _PayrollDashboardPageState extends State<PayrollDashboardPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  List<_PayrollPeriod> _periods = [];
  List<_PayrollRecord> _records = [];
  List<_CostCenterSummary> _costCenters = [];

  int _employeeCount = 0;

  double _grossSalary = 0;
  double _employerInsurance = 0;
  double _unemploymentInsurance = 0;
  double _totalPersonnelCost = 0;

  _PayrollPeriod? get _latestPeriod {
    if (_periods.isEmpty) return null;

    final sorted = List<_PayrollPeriod>.from(_periods)
      ..sort((a, b) => b.sortKey.compareTo(a.sortKey));

    return sorted.first;
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([_loadPeriods(), _loadRecords(), _loadEmployeeCount()]);

      _calculateTotals();

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadPeriods() async {
    final response = await _supabase
        .from('payroll_periods')
        .select('''
          id,
          company_id,
          period_year,
          period_month,
          status,
          notes,
          created_at,
          updated_at
        ''')
        .eq('company_id', widget.companyId)
        .order('period_year', ascending: true)
        .order('period_month', ascending: true);

    final rows = List<Map<String, dynamic>>.from(response as List);

    _periods = rows.map(_PayrollPeriod.fromMap).toList();
  }

  Future<void> _loadRecords() async {
    final response = await _supabase
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
          created_at,
          updated_at,
          cost_centers (
            id,
            name,
            code
          )
        ''')
        .eq('company_id', widget.companyId);

    final rows = List<Map<String, dynamic>>.from(response as List);

    _records = rows.map(_PayrollRecord.fromMap).toList();
  }

  Future<void> _loadEmployeeCount() async {
    try {
      final response = await _supabase
          .from('employees')
          .select('id')
          .eq('company_id', widget.companyId)
          .count(CountOption.exact);

      _employeeCount = response.count ?? 0;
    } catch (_) {
      _employeeCount = 0;
    }
  }

  void _calculateTotals() {
    double gross = 0;
    double employerInsurance = 0;
    double unemploymentInsurance = 0;

    final Map<String, _CostCenterSummary> centerMap = {};

    for (final record in _records) {
      gross += record.grossSalary;
      employerInsurance += record.employerInsurance;
      unemploymentInsurance += record.unemploymentInsurance;

      final existing = centerMap[record.costCenterId];

      if (existing == null) {
        centerMap[record.costCenterId] = _CostCenterSummary(
          id: record.costCenterId,
          name: record.costCenterName,
          code: record.costCenterCode,
          employeeCount: record.employeeCount,
          grossSalary: record.grossSalary,
          employerInsurance: record.employerInsurance,
          totalCost: record.totalPersonnelCost,
        );
      } else {
        centerMap[record.costCenterId] = existing.copyWith(
          employeeCount: existing.employeeCount + record.employeeCount,
          grossSalary: existing.grossSalary + record.grossSalary,
          employerInsurance:
              existing.employerInsurance + record.employerInsurance,
          totalCost: existing.totalCost + record.totalPersonnelCost,
        );
      }
    }

    if (_employeeCount == 0) {
      final latest = _latestPeriod;

      if (latest != null) {
        _employeeCount = _records
            .where((record) => record.payrollPeriodId == latest.id)
            .fold<int>(0, (sum, record) => sum + record.employeeCount);
      }
    }

    _grossSalary = gross;
    _employerInsurance = employerInsurance;
    _unemploymentInsurance = unemploymentInsurance;

    _totalPersonnelCost = gross + employerInsurance + unemploymentInsurance;

    _costCenters =
        centerMap.values.toList()
          ..sort((a, b) => b.totalCost.compareTo(a.totalCost));
  }

  List<_PeriodChartData> _buildPeriodChartData() {
    final map = <String, _PeriodChartData>{};

    for (final period in _periods) {
      map[period.id] = _PeriodChartData(period: period);
    }

    for (final record in _records) {
      final item = map[record.payrollPeriodId];

      if (item == null) continue;

      item.employeeCount += record.employeeCount;
      item.baseSalary += record.baseSalary;
      item.benefits += record.benefits;
      item.overtime += record.overtimeAmount;
      item.bonus += record.performanceBonus + record.productionIncreaseBonus;
      item.mission += record.missionAllowance + record.missionTravelCost;

      item.employerInsurance += record.employerInsurance;
      item.unemploymentInsurance += record.unemploymentInsurance;

      item.grossSalary += record.grossSalary;
      item.totalCost += record.totalPersonnelCost;

      item.benefitsForEmployer +=
          record.senioritySalary +
          record.mealAllowance +
          record.housingAllowance +
          record.maritalAllowance +
          record.monthlySeniorityBenefit +
          record.monthlyEndServiceBonus +
          record.employerInsurance +
          record.unemploymentInsurance;
    }

    final result =
        map.values.toList()
          ..sort((a, b) => a.period.sortKey.compareTo(b.period.sortKey));

    if (result.length > 12) {
      return result.sublist(result.length - 12);
    }

    return result;
  }

  List<_TrendPoint> _salaryTrend() {
    return _buildPeriodChartData()
        .map(
          (item) => _TrendPoint(
            label: item.period.shortTitle,
            value: item.grossSalary / 1000000000.0,
            secondaryValue: item.employeeCount.toDouble(),
          ),
        )
        .toList();
  }

  List<_TrendPoint> _benefitTrend() {
    return _buildPeriodChartData()
        .map(
          (item) => _TrendPoint(
            label: item.period.shortTitle,
            value: item.benefitsForEmployer / 1000000.0,
          ),
        )
        .toList();
  }

  List<_CompositionPoint> _compositionTrend() {
    return _buildPeriodChartData()
        .map(
          (item) => _CompositionPoint(
            label: item.period.shortTitle,
            base: item.baseSalary / 1000000000.0,
            benefits: item.benefits / 1000000000.0,
            overtime: item.overtime / 1000000000.0,
            bonus: item.bonus / 1000000000.0,
            mission: item.mission / 1000000000.0,
          ),
        )
        .toList();
  }

  List<_TrendPoint> _overtimeTrend() {
    return _buildPeriodChartData().map((item) {
      final percentage =
          item.totalCost == 0 ? 0.0 : (item.overtime / item.totalCost * 100.0);

      return _TrendPoint(
        label: item.period.shortTitle,
        value: item.overtime / 1000000.0,
        secondaryValue: percentage,
      );
    }).toList();
  }

  List<_TrendPoint> _insuranceTrend() {
    return _buildPeriodChartData()
        .map(
          (item) => _TrendPoint(
            label: item.period.shortTitle,
            value: item.employerInsurance / 1000000000.0,
            secondaryValue:
                (item.employerInsurance + item.unemploymentInsurance) /
                1000000.0,
          ),
        )
        .toList();
  }

  List<_HorizontalPoint> _costAnalysis() {
    return _costCenters
        .take(6)
        .map(
          (item) => _HorizontalPoint(
            label: item.name,
            value: item.totalCost / 1000000.0,
          ),
        )
        .toList();
  }

  String _formatMoney(double value) {
    final number = value.round().toString();

    if (number.length <= 3) return number;

    final chars = number.split('');
    final result = <String>[];

    int counter = 0;

    for (int i = chars.length - 1; i >= 0; i--) {
      result.add(chars[i]);
      counter++;

      if (counter == 3 && i != 0) {
        result.add('٬');
        counter = 0;
      }
    }

    return result.reversed.join();
  }

  String _formatCompact(double value) {
    if (value >= 1000) {
      return '${(value / 1000.0).toStringAsFixed(1)} میلیارد';
    }

    if (value >= 1) {
      return '${value.toStringAsFixed(0)} میلیون';
    }

    return '۰';
  }

  String _statusTitle(String status) {
    switch (status) {
      case 'draft':
        return 'پیش‌نویس';
      case 'pending_ceo':
        return 'در انتظار تأیید مدیرعامل';
      case 'ceo_approved':
        return 'تأیید مدیرعامل';
      case 'pending_consultant':
        return 'در انتظار تأیید مشاور';
      case 'consultant_approved':
        return 'تأیید نهایی مشاور';
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

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
      case 'consultant_approved':
      case 'ceo_approved':
        return const Color(0xFF16805C);
      case 'pending_ceo':
      case 'pending_consultant':
        return const Color(0xFFE38B22);
      case 'rejected':
        return const Color(0xFFD94C4C);
      case 'cancelled':
        return const Color(0xFF777777);
      default:
        return const Color(0xFF3978B8);
    }
  }

  void _go(String route) {
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute:
          '/consultant/companies/${widget.companyId}/payroll/dashboard',
      title: 'داشبورد حقوق و دستمزد',
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 35),
        children: [
          _buildHero(),
          const SizedBox(height: 14),
          _buildKpis(),
          const SizedBox(height: 14),
          _buildOverallSummary(),
          const SizedBox(height: 14),
          _buildCharts(),
          const SizedBox(height: 14),
          _buildQuickAccess(),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(25),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E9E8)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 55,
              color: Colors.red,
            ),
            const SizedBox(height: 14),
            const Text(
              'خطا در دریافت اطلاعات داشبورد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    final latest = _latestPeriod;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0D6249), Color(0xFF063D2F)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroText(latest),
                const SizedBox(height: 14),
                _heroButtons(),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _heroText(latest)),
              const SizedBox(width: 20),
              _heroButtons(),
            ],
          );
        },
      ),
    );
  }

  Widget _heroText(_PayrollPeriod? latest) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'داشبورد حقوق و دستمزد',
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'نمای کلی و تجمیعی اطلاعات حقوق و دستمزد شرکت',
          style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 12),
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          latest == null
                              ? Colors.grey
                              : _statusColor(latest.status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    latest == null ? 'بدون دوره' : _statusTitle(latest.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (latest != null)
              Text(
                'آخرین دوره: ${latest.title}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _heroButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            _go('/consultant/companies/${widget.companyId}/payroll/periods');
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.35)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          icon: const Icon(Icons.calendar_month_outlined, size: 18),
          label: const Text('دوره‌های حقوق'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            _go(
              '/consultant/companies/${widget.companyId}/payroll/cost-centers',
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withOpacity(0.35)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          icon: const Icon(Icons.account_tree_outlined, size: 18),
          label: const Text('مراکز هزینه'),
        ),
      ],
    );
  }

  Widget _buildKpis() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;

        if (constraints.maxWidth >= 1050) {
          columns = 4;
        } else if (constraints.maxWidth >= 650) {
          columns = 2;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 4 ? 2.9 : 3.0,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _KpiCard(
              title: 'تعداد پرسنل',
              value: _employeeCount.toString(),
              unit: 'نفر',
              icon: Icons.groups_rounded,
              iconColor: const Color(0xFF116149),
            ),
            _KpiCard(
              title: 'جمع حقوق و مزایای ناخالص',
              value: _formatMoney(_grossSalary),
              unit: 'تومان',
              icon: Icons.account_balance_wallet_outlined,
              iconColor: const Color(0xFF3475C4),
            ),
            _KpiCard(
              title: 'جمع تعهدات کارفرما',
              value: _formatMoney(_employerInsurance + _unemploymentInsurance),
              unit: 'تومان',
              icon: Icons.verified_user_outlined,
              iconColor: const Color(0xFF7651B8),
            ),
            _KpiCard(
              title: 'هزینه کل پرسنلی',
              value: _formatMoney(_totalPersonnelCost),
              unit: 'تومان',
              icon: Icons.bar_chart_rounded,
              iconColor: const Color(0xFFE27832),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverallSummary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 950) {
          return Column(
            children: [
              _buildWorkflow(),
              const SizedBox(height: 12),
              _buildCostCenters(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 4, child: _buildWorkflow()),
            const SizedBox(width: 12),
            Expanded(flex: 6, child: _buildCostCenters()),
          ],
        );
      },
    );
  }

  Widget _buildWorkflow() {
    final latest = _latestPeriod;
    final status = latest?.status ?? 'draft';

    final steps = [
      _WorkflowStep(
        title: 'ثبت اطلاعات',
        subtitle: 'اطلاعات حقوق',
        active: true,
        done: status != 'draft',
      ),
      _WorkflowStep(
        title: 'تأیید مدیرعامل',
        subtitle: 'بررسی مدیرعامل',
        active: [
          'pending_ceo',
          'ceo_approved',
          'pending_consultant',
          'consultant_approved',
          'paid',
        ].contains(status),
        done: [
          'ceo_approved',
          'pending_consultant',
          'consultant_approved',
          'paid',
        ].contains(status),
      ),
      _WorkflowStep(
        title: 'تأیید مشاور',
        subtitle: 'بررسی نهایی',
        active: [
          'pending_consultant',
          'consultant_approved',
          'paid',
        ].contains(status),
        done: ['consultant_approved', 'paid'].contains(status),
      ),
      _WorkflowStep(
        title: 'پرداخت',
        subtitle: 'ثبت پرداخت',
        active: status == 'paid',
        done: status == 'paid',
      ),
    ];

    return _DashboardPanel(
      title: 'وضعیت آخرین دوره حقوق',
      trailing: TextButton(
        onPressed: () {
          _go('/consultant/companies/${widget.companyId}/payroll/periods');
        },
        child: const Text('مدیریت'),
      ),
      child: SizedBox(
        height: 145,
        child: Row(
          children: List.generate(steps.length, (index) {
            final step = steps[index];

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color:
                                step.done
                                    ? const Color(0xFF116149)
                                    : step.active
                                    ? const Color(0xFFEAF4F0)
                                    : const Color(0xFFF0F2F3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            step.done
                                ? Icons.check
                                : Icons.description_outlined,
                            size: 18,
                            color:
                                step.done
                                    ? Colors.white
                                    : step.active
                                    ? const Color(0xFF116149)
                                    : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color:
                                step.active
                                    ? const Color(0xFF174C3E)
                                    : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          step.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color:
                            step.done
                                ? const Color(0xFF116149)
                                : const Color(0xFFE2E5E5),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCostCenters() {
    return _DashboardPanel(
      title: 'تجمیع هزینه به تفکیک مرکز هزینه',
      trailing: TextButton(
        onPressed: () {
          _go('/consultant/companies/${widget.companyId}/payroll/cost-centers');
        },
        child: const Text('جزئیات'),
      ),
      child: SizedBox(
        height: 145,
        child:
            _costCenters.isEmpty
                ? const Center(
                  child: Text(
                    'هنوز اطلاعات مرکز هزینه ثبت نشده است.',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                )
                : SingleChildScrollView(
                  child: Column(
                    children: [
                      _costCenterHeader(),
                      ..._costCenters.take(4).map(_costCenterRow),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _costCenterHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'مرکز هزینه',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              'پرسنل',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'حقوق',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'هزینه کل',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _costCenterRow(_CostCenterSummary item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16805C),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              item.employeeCount.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatCompact(item.grossSalary / 1000000.0),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatCompact(item.totalCost / 1000000.0),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    final salary = _salaryTrend();
    final benefits = _benefitTrend();
    final composition = _compositionTrend();
    final overtime = _overtimeTrend();
    final insurance = _insuranceTrend();
    final costs = _costAnalysis();

    return _DashboardPanel(
      title: 'تحلیل تجمیعی حقوق و دستمزد',
      trailing: const Text(
        'تمام دوره‌های ثبت‌شده',
        style: TextStyle(
          color: Color(0xFF7B8581),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int columns = 1;

          if (constraints.maxWidth >= 700) {
            columns = 2;
          }

          return GridView.count(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.82,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ChartCard(
                title: 'حقوق و تعداد کارمندان',
                subtitle: 'روند دوره‌های ثبت‌شده',
                legend: const [
                  _ChartLegend(label: 'حقوق', color: Color(0xFF116149)),
                  _ChartLegend(label: 'تعداد پرسنل', color: Color(0xFFE17B31)),
                ],
                child: _SalaryChart(points: salary),
              ),
              _ChartCard(
                title: 'روند هزینه مزایای کارفرما',
                subtitle: 'مبلغ تعهدات و مزایای کارفرما',
                child: _LineChart(
                  points: benefits,
                  color: const Color(0xFF7651B8),
                  unit: 'میلیون',
                ),
              ),
              _ChartCard(
                title: 'ترکیب هزینه حقوق',
                subtitle: 'تفکیک اجزای حقوق و مزایا',
                legend: const [
                  _ChartLegend(label: 'حقوق پایه', color: Color(0xFF3475C4)),
                  _ChartLegend(label: 'مزایا', color: Color(0xFF19A56F)),
                  _ChartLegend(label: 'اضافه‌کاری', color: Color(0xFFE38B22)),
                  _ChartLegend(label: 'پاداش', color: Color(0xFFD95454)),
                  _ChartLegend(label: 'مأموریت', color: Color(0xFF7651B8)),
                ],
                child: _CompositionChart(points: composition),
              ),
              _ChartCard(
                title: 'اضافه‌کاری و سهم آن',
                subtitle: 'مبلغ اضافه‌کاری و درصد از هزینه کل',
                legend: const [
                  _ChartLegend(
                    label: 'مبلغ اضافه‌کاری',
                    color: Color(0xFF7651B8),
                  ),
                  _ChartLegend(label: 'سهم', color: Color(0xFF19A56F)),
                ],
                child: _OvertimeChart(points: overtime),
              ),
              _ChartCard(
                title: 'روند بیمه و هزینه کارفرما',
                subtitle: 'مقایسه بیمه سهم کارفرما',
                legend: const [
                  _ChartLegend(label: 'بیمه کارفرما', color: Color(0xFF3475C4)),
                  _ChartLegend(label: 'مجموع تعهدات', color: Color(0xFFE38B22)),
                ],
                child: _InsuranceChart(points: insurance),
              ),
              _ChartCard(
                title: 'تحلیل هزینه مراکز',
                subtitle: 'مقایسه هزینه کل مراکز',
                child: _HorizontalChart(points: costs),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickAccess() {
    final items = [
      _QuickAccess(
        title: 'دوره‌های حقوق',
        subtitle: 'مدیریت دوره‌ها',
        icon: Icons.calendar_month_outlined,
        route: '/consultant/companies/${widget.companyId}/payroll/periods',
      ),
      _QuickAccess(
        title: 'مراکز هزینه',
        subtitle: 'مدیریت مراکز',
        icon: Icons.account_tree_outlined,
        route: '/consultant/companies/${widget.companyId}/payroll/cost-centers',
      ),
      _QuickAccess(
        title: 'پرسنل',
        subtitle: 'مدیریت پرسنل',
        icon: Icons.groups_outlined,
        route: '/consultant/companies/${widget.companyId}/payroll/employees',
      ),
      _QuickAccess(
        title: 'قراردادها',
        subtitle: 'مدیریت قراردادها',
        icon: Icons.description_outlined,
        route: '/consultant/companies/${widget.companyId}/payroll/contracts',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 4, bottom: 10),
          child: Text(
            'دسترسی سریع',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            int columns = 1;

            if (constraints.maxWidth >= 1000) {
              columns = 4;
            } else if (constraints.maxWidth >= 650) {
              columns = 2;
            }

            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 4 ? 3 : 2.8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children:
                  items.map((item) {
                    return InkWell(
                      onTap: () => _go(item.route),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E9E8)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF4F0),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                item.icon,
                                color: const Color(0xFF116149),
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.subtitle,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF116149),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }
}

/* ========================================================================== */
/* MODELS                                                                     */
/* ========================================================================== */

class _PayrollPeriod {
  const _PayrollPeriod({
    required this.id,
    required this.companyId,
    required this.year,
    required this.month,
    required this.status,
    this.notes,
  });

  final String id;
  final String companyId;
  final int year;
  final int month;
  final String status;
  final String? notes;

  int get sortKey => year * 100 + month;

  String get monthName {
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

    if (month >= 1 && month <= 12) {
      return names[month - 1];
    }

    return 'ماه $month';
  }

  String get title => '$monthName $year';

  String get shortTitle {
    final y = year.toString();

    if (y.length >= 2) {
      return '$monthName ${y.substring(y.length - 2)}';
    }

    return title;
  }

  factory _PayrollPeriod.fromMap(Map<String, dynamic> map) {
    return _PayrollPeriod(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      year: _toInt(map['period_year']),
      month: _toInt(map['period_month']),
      status: map['status']?.toString() ?? 'draft',
      notes: map['notes']?.toString(),
    );
  }
}

class _PayrollRecord {
  const _PayrollRecord({
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
    required this.costCenterName,
    required this.costCenterCode,
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

  final String costCenterName;
  final String? costCenterCode;

  double get benefits =>
      senioritySalary +
      mealAllowance +
      housingAllowance +
      maritalAllowance +
      monthlySeniorityBenefit +
      monthlyEndServiceBonus;

  double get bonus => performanceBonus + productionIncreaseBonus;

  double get mission => missionAllowance + missionTravelCost;

  double get grossSalary =>
      baseSalary + benefits + overtimeAmount + bonus + mission;

  double get totalPersonnelCost =>
      grossSalary + employerInsurance + unemploymentInsurance;

  factory _PayrollRecord.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> center = {};

    final raw = map['cost_centers'];

    if (raw is Map) {
      center = Map<String, dynamic>.from(raw);
    }

    return _PayrollRecord(
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
      costCenterName: center['name']?.toString() ?? 'مرکز هزینه',
      costCenterCode: center['code']?.toString(),
    );
  }
}

class _PeriodChartData {
  _PeriodChartData({required this.period});

  final _PayrollPeriod period;

  int employeeCount = 0;

  double baseSalary = 0;
  double benefits = 0;
  double overtime = 0;
  double bonus = 0;
  double mission = 0;

  double employerInsurance = 0;
  double unemploymentInsurance = 0;

  double grossSalary = 0;
  double totalCost = 0;
  double benefitsForEmployer = 0;
}

class _CostCenterSummary {
  const _CostCenterSummary({
    required this.id,
    required this.name,
    required this.code,
    required this.employeeCount,
    required this.grossSalary,
    required this.employerInsurance,
    required this.totalCost,
  });

  final String id;
  final String name;
  final String? code;

  final int employeeCount;
  final double grossSalary;
  final double employerInsurance;
  final double totalCost;

  _CostCenterSummary copyWith({
    int? employeeCount,
    double? grossSalary,
    double? employerInsurance,
    double? totalCost,
  }) {
    return _CostCenterSummary(
      id: id,
      name: name,
      code: code,
      employeeCount: employeeCount ?? this.employeeCount,
      grossSalary: grossSalary ?? this.grossSalary,
      employerInsurance: employerInsurance ?? this.employerInsurance,
      totalCost: totalCost ?? this.totalCost,
    );
  }
}

class _TrendPoint {
  const _TrendPoint({
    required this.label,
    required this.value,
    this.secondaryValue = 0,
  });

  final String label;
  final double value;
  final double secondaryValue;
}

class _CompositionPoint {
  const _CompositionPoint({
    required this.label,
    required this.base,
    required this.benefits,
    required this.overtime,
    required this.bonus,
    required this.mission,
  });

  final String label;
  final double base;
  final double benefits;
  final double overtime;
  final double bonus;
  final double mission;
}

class _HorizontalPoint {
  const _HorizontalPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class _WorkflowStep {
  const _WorkflowStep({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.done,
  });

  final String title;
  final String subtitle;
  final bool active;
  final bool done;
}

class _QuickAccess {
  const _QuickAccess({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

/* ========================================================================== */
/* PANELS                                                                     */
/* ========================================================================== */

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF183E34),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E9E8)),
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF727A78),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      unit,
                      style: const TextStyle(color: Colors.grey, fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ========================================================================== */
/* CHART CARD                                                                 */
/* ========================================================================== */

class _ChartLegend {
  const _ChartLegend({required this.label, required this.color});

  final String label;
  final Color color;
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.legend = const [],
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<_ChartLegend> legend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF183E34),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 8.5, color: Color(0xFF858C89)),
          ),
          if (legend.isNotEmpty) ...[
            const SizedBox(height: 7),
            Wrap(
              spacing: 12,
              runSpacing: 5,
              children:
                  legend.map((item) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 7.5,
                            color: Color(0xFF6F7774),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ],
          const SizedBox(height: 5),
          SizedBox(height: 190, child: child),
        ],
      ),
    );
  }
}

/* ========================================================================== */
/* CHARTS                                                                     */
/* ========================================================================== */

class _SalaryChart extends StatelessWidget {
  const _SalaryChart({required this.points});

  final List<_TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SalaryPainter(points),
      child: const SizedBox.expand(),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.points,
    required this.color,
    required this.unit,
  });

  final List<_TrendPoint> points;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LinePainter(points: points, color: color, unit: unit),
      child: const SizedBox.expand(),
    );
  }
}

class _CompositionChart extends StatelessWidget {
  const _CompositionChart({required this.points});

  final List<_CompositionPoint> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CompositionPainter(points),
      child: const SizedBox.expand(),
    );
  }
}

class _OvertimeChart extends StatelessWidget {
  const _OvertimeChart({required this.points});

  final List<_TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OvertimePainter(points),
      child: const SizedBox.expand(),
    );
  }
}

class _InsuranceChart extends StatelessWidget {
  const _InsuranceChart({required this.points});

  final List<_TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _InsurancePainter(points),
      child: const SizedBox.expand(),
    );
  }
}

class _HorizontalChart extends StatelessWidget {
  const _HorizontalChart({required this.points});

  final List<_HorizontalPoint> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HorizontalPainter(points),
      child: const SizedBox.expand(),
    );
  }
}

/* ========================================================================== */
/* PAINTER BASE                                                               */
/* ========================================================================== */

abstract class _ChartPainter extends CustomPainter {
  TextPainter _text(
    String value, {
    double fontSize = 7,
    FontWeight weight = FontWeight.w500,
    Color color = const Color(0xFF707876),
  }) {
    return TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(fontSize: fontSize, fontWeight: weight, color: color),
      ),
      textDirection: TextDirection.rtl,
    );
  }

  double _maxDouble(Iterable<double> values) {
    double result = 0.0;

    for (final value in values) {
      if (value > result) {
        result = value;
      }
    }

    return result <= 0.0 ? 1.0 : result;
  }

  double _niceMax(double value) {
    if (value <= 0.0) return 1.0;

    final magnitude = _pow10((value.abs()).toStringAsFixed(0).length - 1);

    final normalized = value / magnitude;

    double nice;

    if (normalized <= 1.0) {
      nice = 1.0;
    } else if (normalized <= 2.0) {
      nice = 2.0;
    } else if (normalized <= 5.0) {
      nice = 5.0;
    } else {
      nice = 10.0;
    }

    return nice * magnitude;
  }

  double _pow10(int exponent) {
    double result = 1.0;

    if (exponent > 0) {
      for (int i = 0; i < exponent; i++) {
        result *= 10.0;
      }
    } else if (exponent < 0) {
      for (int i = 0; i > exponent; i--) {
        result /= 10.0;
      }
    }

    return result;
  }

  void _grid(
    Canvas canvas,
    double left,
    double right,
    double top,
    double bottom,
  ) {
    final paint =
        Paint()
          ..color = const Color(0xFFE9EDEC)
          ..strokeWidth = 0.7;

    final height = bottom - top;

    for (int i = 0; i <= 4; i++) {
      final y = top + height * i / 4.0;

      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }
  }

  void _labels(
    Canvas canvas,
    List<String> labels,
    double left,
    double right,
    double bottom,
  ) {
    if (labels.isEmpty) return;

    final width = right - left;

    for (int i = 0; i < labels.length; i++) {
      final x =
          labels.length == 1
              ? left + width / 2.0
              : left + width * i / (labels.length - 1).toDouble();

      final tp = _text(
        labels[i],
        fontSize: 7,
        color: const Color(0xFF7E8784),
        weight: FontWeight.w600,
      );

      tp.layout(maxWidth: 70);

      tp.paint(canvas, Offset(x - tp.width / 2.0, bottom + 6));
    }
  }

  void _yLabels(
    Canvas canvas,
    double maxValue,
    double left,
    double top,
    double bottom,
    String suffix,
  ) {
    for (int i = 0; i <= 4; i++) {
      final value = maxValue * (4 - i).toDouble() / 4.0;

      String text;

      if (value >= 1000.0) {
        text = '${(value / 1000.0).toStringAsFixed(1)}k';
      } else if (value >= 10.0) {
        text = value.toStringAsFixed(0);
      } else {
        text = value.toStringAsFixed(1);
      }

      if (suffix.isNotEmpty) {
        text = '$text $suffix';
      }

      final tp = _text(text, fontSize: 6.5, color: const Color(0xFF8A918F));

      tp.layout(maxWidth: 50);

      tp.paint(
        canvas,
        Offset(
          left - tp.width - 6,
          top + (bottom - top) * i.toDouble() / 4.0 - tp.height / 2.0,
        ),
      );
    }
  }

  void _empty(Canvas canvas, Size size) {
    final tp = _text(
      'داده‌ای برای نمایش وجود ندارد',
      fontSize: 9,
      weight: FontWeight.w600,
    );

    tp.layout();

    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2.0, (size.height - tp.height) / 2.0),
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return true;
  }
}

/* ========================================================================== */
/* SALARY PAINTER                                                             */
/* ========================================================================== */

class _SalaryPainter extends _ChartPainter {
  _SalaryPainter(this.points);

  final List<_TrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      _empty(canvas, size);
      return;
    }

    const left = 42.0;
    const top = 8.0;
    const bottomPadding = 30.0;
    const rightPadding = 8.0;

    final right = size.width - rightPadding;
    final bottom = size.height - bottomPadding;

    _grid(canvas, left, right, top, bottom);

    final maxSalary = _niceMax(_maxDouble(points.map((e) => e.value)));

    double maxEmployees = 1.0;

    for (final point in points) {
      if (point.secondaryValue > maxEmployees) {
        maxEmployees = point.secondaryValue;
      }
    }

    final barPaint = Paint()..color = const Color(0xFF116149);

    final linePaint =
        Paint()
          ..color = const Color(0xFFE17B31)
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = const Color(0xFFE17B31);

    final width = right - left;

    final spacing =
        points.length <= 2 ? width / 3.0 : width / points.length.toDouble();

    final barWidth =
        points.length <= 2
            ? 55.0.clamp(25.0, width / 4.0).toDouble()
            : (spacing * 0.48).clamp(20.0, 52.0).toDouble();

    final path = Path();

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      final x =
          points.length == 1
              ? left + width / 2.0
              : points.length == 2
              ? left + width * (i + 1).toDouble() / 3.0
              : left + width * i.toDouble() / (points.length - 1).toDouble();

      final barHeight = (point.value / maxSalary) * (bottom - top);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - barWidth / 2.0,
            bottom - barHeight,
            barWidth,
            barHeight,
          ),
          const Radius.circular(5),
        ),
        barPaint,
      );

      final y = bottom - point.secondaryValue / maxEmployees * (bottom - top);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      final x =
          points.length == 1
              ? left + width / 2.0
              : points.length == 2
              ? left + width * (i + 1).toDouble() / 3.0
              : left + width * i.toDouble() / (points.length - 1).toDouble();

      final y = bottom - point.secondaryValue / maxEmployees * (bottom - top);

      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }

    _yLabels(canvas, maxSalary, left, top, bottom, 'میلیارد');

    _labels(canvas, points.map((e) => e.label).toList(), left, right, bottom);
  }
}

/* ========================================================================== */
/* LINE PAINTER                                                               */
/* ========================================================================== */

class _LinePainter extends _ChartPainter {
  _LinePainter({required this.points, required this.color, required this.unit});

  final List<_TrendPoint> points;
  final Color color;
  final String unit;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      _empty(canvas, size);
      return;
    }

    const left = 48.0;
    const top = 8.0;
    const bottomPadding = 30.0;
    const rightPadding = 8.0;

    final right = size.width - rightPadding;
    final bottom = size.height - bottomPadding;

    _grid(canvas, left, right, top, bottom);

    final maxValue = _niceMax(_maxDouble(points.map((e) => e.value)));

    final linePaint =
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = color;

    final width = right - left;
    final path = Path();

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      final x =
          points.length == 1
              ? left + width / 2.0
              : points.length == 2
              ? left + width * (i + 1).toDouble() / 3.0
              : left + width * i.toDouble() / (points.length - 1).toDouble();

      final y = bottom - point.value / maxValue * (bottom - top);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      final x =
          points.length == 1
              ? left + width / 2.0
              : points.length == 2
              ? left + width * (i + 1).toDouble() / 3.0
              : left + width * i.toDouble() / (points.length - 1).toDouble();

      final y = bottom - point.value / maxValue * (bottom - top);

      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);

      _drawValueLabel(canvas, point.value, x, y, unit, color);
    }

    _yLabels(canvas, maxValue, left, top, bottom, '');

    _labels(canvas, points.map((e) => e.label).toList(), left, right, bottom);
  }

  void _drawValueLabel(
    Canvas canvas,
    double value,
    double x,
    double y,
    String unit,
    Color color,
  ) {
    final text =
        value >= 1000.0
            ? '${(value / 1000.0).toStringAsFixed(1)}k'
            : value.toStringAsFixed(0);

    final tp = _text(text, fontSize: 7, weight: FontWeight.w800, color: color);

    tp.layout();

    double labelX = x - tp.width / 2.0;

    if (labelX < 48.0) {
      labelX = 48.0;
    }

    if (labelX + tp.width > canvasSizeWidth(canvas)) {
      labelX = canvasSizeWidth(canvas) - tp.width - 4.0;
    }

    tp.paint(canvas, Offset(labelX, y - tp.height - 5.0));
  }

  double canvasSizeWidth(Canvas canvas) {
    return canvas.getSaveCount() > 0 ? 100000.0 : 100000.0;
  }
}

/* ========================================================================== */
/* COMPOSITION PAINTER                                                        */
/* ========================================================================== */

class _CompositionPainter extends _ChartPainter {
  _CompositionPainter(this.points);

  final List<_CompositionPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      _empty(canvas, size);
      return;
    }

    const left = 42.0;
    const top = 8.0;
    const bottomPadding = 30.0;
    const rightPadding = 8.0;

    final right = size.width - rightPadding;
    final bottom = size.height - bottomPadding;

    _grid(canvas, left, right, top, bottom);

    final totals = points.map(
      (point) =>
          point.base +
          point.benefits +
          point.overtime +
          point.bonus +
          point.mission,
    );

    final maxValue = _niceMax(_maxDouble(totals));

    const colors = [
      Color(0xFF3475C4),
      Color(0xFF19A56F),
      Color(0xFFE38B22),
      Color(0xFFD95454),
      Color(0xFF7651B8),
    ];

    final width = right - left;

    final spacing =
        points.length <= 2 ? width / 3.0 : width / points.length.toDouble();

    final barWidth =
        points.length <= 2
            ? 60.0.clamp(25.0, width / 4.0).toDouble()
            : (spacing * 0.5).clamp(22.0, 55.0).toDouble();

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      final x =
          points.length == 1
              ? left + width / 2.0
              : points.length == 2
              ? left + width * (i + 1).toDouble() / 3.0
              : left + width * i.toDouble() / (points.length - 1).toDouble();

      final values = [
        point.base,
        point.benefits,
        point.overtime,
        point.bonus,
        point.mission,
      ];

      double accumulated = 0.0;

      for (int j = 0; j < values.length; j++) {
        final value = values[j];

        if (value <= 0.0) continue;

        final height = value / maxValue * (bottom - top);

        final rect = Rect.fromLTWH(
          x - barWidth / 2.0,
          bottom - accumulated / maxValue * (bottom - top) - height,
          barWidth,
          height,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()..color = colors[j],
        );

        accumulated += value;
      }
    }

    _yLabels(canvas, maxValue, left, top, bottom, 'میلیارد');

    _labels(canvas, points.map((e) => e.label).toList(), left, right, bottom);
  }
}

/* ========================================================================== */
/* OVERTIME PAINTER                                                           */
/* ========================================================================== */

class _OvertimePainter extends _ChartPainter {
  _OvertimePainter(this.points);

  final List<_TrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      _empty(canvas, size);
      return;
    }

    const left = 42.0;
    const top = 8.0;
    const bottomPadding = 30.0;
    const rightPadding = 8.0;

    final right = size.width - rightPadding;
    final bottom = size.height - bottomPadding;

    _grid(canvas, left, right, top, bottom);

    final maxOvertime = _niceMax(_maxDouble(points.map((e) => e.value)));

    final barPaint = Paint()..color = const Color(0xFF7651B8);

    final linePaint =
        Paint()
          ..color = const Color(0xFF19A56F)
          ..strokeWidth = 2.3
          ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = const Color(0xFF19A56F);

    final width = right - left;

    final spacing =
        points.length <= 2 ? width / 3.0 : width / points.length.toDouble();

    final barWidth =
        points.length <= 2
            ? 55.0.clamp(25.0, width / 4.0).toDouble()
            : (spacing * 0.48).clamp(20.0, 52.0).toDouble();

    final path = Path();

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      final x =
          points.length == 1
              ? left + width / 2.0
              : points.length == 2
              ? left + width * (i + 1).toDouble() / 3.0
              : left + width * i.toDouble() / (points.length - 1).toDouble();

      final barHeight = point.value / maxOvertime * (bottom - top);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x - barWidth / 2.0,
            bottom - barHeight,
            barWidth,
            barHeight,
          ),
          const Radius.circular(5),
        ),
        barPaint,
      );

      final percentage = point.secondaryValue.clamp(0.0, 100.0).toDouble();

      final y = bottom - percentage / 100.0 * (bottom - top);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      final x =
          points.length == 1
              ? left + width / 2.0
              : points.length == 2
              ? left + width * (i + 1).toDouble() / 3.0
              : left + width * i.toDouble() / (points.length - 1).toDouble();

      final percentage = point.secondaryValue.clamp(0.0, 100.0).toDouble();

      final y = bottom - percentage / 100.0 * (bottom - top);

      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);

      final tp = _text(
        '${percentage.toStringAsFixed(1)}%',
        fontSize: 7,
        weight: FontWeight.w800,
        color: const Color(0xFF19A56F),
      );

      tp.layout();

      tp.paint(canvas, Offset(x - tp.width / 2.0, y - tp.height - 5.0));
    }

    _yLabels(canvas, maxOvertime, left, top, bottom, 'میلیون');

    _labels(canvas, points.map((e) => e.label).toList(), left, right, bottom);
  }
}

/* ========================================================================== */
/* INSURANCE PAINTER                                                          */
/* ========================================================================== */

class _InsurancePainter extends _ChartPainter {
  _InsurancePainter(this.points);

  final List<_TrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      _empty(canvas, size);
      return;
    }

    const left = 48.0;
    const top = 8.0;
    const bottomPadding = 30.0;
    const rightPadding = 8.0;

    final right = size.width - rightPadding;
    final bottom = size.height - bottomPadding;

    _grid(canvas, left, right, top, bottom);

    final maxValue = _niceMax(_maxDouble(points.map((e) => e.secondaryValue)));

    final bluePaint =
        Paint()
          ..color = const Color(0xFF3475C4)
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke;

    final orangePaint =
        Paint()
          ..color = const Color(0xFFE38B22)
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke;

    final blueDot = Paint()..color = const Color(0xFF3475C4);

    final orangeDot = Paint()..color = const Color(0xFFE38B22);

    final width = right - left;

    final bluePath = Path();
    final orangePath = Path();

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      final x =
          points.length == 1
              ? left + width / 2.0
              : points.length == 2
              ? left + width * (i + 1).toDouble() / 3.0
              : left + width * i.toDouble() / (points.length - 1).toDouble();

      final blueY = bottom - point.value / maxValue * (bottom - top);

      final orangeY = bottom - point.secondaryValue / maxValue * (bottom - top);

      if (i == 0) {
        bluePath.moveTo(x, blueY);
        orangePath.moveTo(x, orangeY);
      } else {
        bluePath.lineTo(x, blueY);
        orangePath.lineTo(x, orangeY);
      }
    }

    canvas.drawPath(bluePath, bluePaint);

    canvas.drawPath(orangePath, orangePaint);

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      final x =
          points.length == 1
              ? left + width / 2.0
              : points.length == 2
              ? left + width * (i + 1).toDouble() / 3.0
              : left + width * i.toDouble() / (points.length - 1).toDouble();

      final blueY = bottom - point.value / maxValue * (bottom - top);

      final orangeY = bottom - point.secondaryValue / maxValue * (bottom - top);

      canvas.drawCircle(Offset(x, blueY), 3.5, blueDot);

      canvas.drawCircle(Offset(x, orangeY), 3.5, orangeDot);
    }

    _yLabels(canvas, maxValue, left, top, bottom, 'میلیون');

    _labels(canvas, points.map((e) => e.label).toList(), left, right, bottom);
  }
}

/* ========================================================================== */
/* HORIZONTAL PAINTER                                                         */
/* ========================================================================== */

class _HorizontalPainter extends _ChartPainter {
  _HorizontalPainter(this.points);

  final List<_HorizontalPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      _empty(canvas, size);
      return;
    }

    const left = 105.0;
    const rightPadding = 10.0;
    const top = 8.0;
    const bottom = 8.0;

    final width = size.width - left - rightPadding;

    final maxValue = _niceMax(_maxDouble(points.map((e) => e.value)));

    final rowHeight = (size.height - top - bottom) / points.length.toDouble();

    final paint = Paint()..color = const Color(0xFF116149);

    for (int i = 0; i < points.length; i++) {
      final item = points[i];

      final y = top + rowHeight * i.toDouble() + rowHeight * 0.22;

      final barHeight = (rowHeight * 0.52).clamp(18.0, 34.0).toDouble();

      final barWidth = item.value / maxValue * width;

      final label = _text(
        item.label,
        fontSize: 8,
        weight: FontWeight.w700,
        color: const Color(0xFF4C5552),
      );

      label.layout(maxWidth: left - 12);

      label.paint(
        canvas,
        Offset(left - label.width - 8, y + (barHeight - label.height) / 2.0),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, y, barWidth, barHeight),
          const Radius.circular(6),
        ),
        paint,
      );

      final valueText = _formatChartNumber(item.value);

      final valuePainter = _text(
        valueText,
        fontSize: 7,
        weight: FontWeight.w800,
        color: const Color(0xFF116149),
      );

      valuePainter.layout();

      double valueX = left + barWidth + 6.0;

      if (valueX + valuePainter.width > size.width) {
        valueX = left + barWidth - valuePainter.width - 6.0;
      }

      valuePainter.paint(
        canvas,
        Offset(valueX, y + (barHeight - valuePainter.height) / 2.0),
      );
    }
  }

  String _formatChartNumber(double value) {
    if (value >= 1000.0) {
      return '${(value / 1000.0).toStringAsFixed(1)}k';
    }

    if (value >= 100.0) {
      return value.toStringAsFixed(0);
    }

    if (value >= 10.0) {
      return value.toStringAsFixed(1);
    }

    return value.toStringAsFixed(1);
  }
}

/* ========================================================================== */
/* HELPERS                                                                    */
/* ========================================================================== */

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.round();
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is double) {
    return value;
  }

  if (value is int) {
    return value.toDouble();
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}
