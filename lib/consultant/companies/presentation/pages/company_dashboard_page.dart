import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';


class CompanyOverviewPage extends ConsumerWidget {
  const CompanyOverviewPage({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companyOverviewProvider(companyId));

    return CompanyScaffold(
      companyId: companyId,
      currentRoute: '/consultant/companies/$companyId',
      title: 'نمای کلی شرکت',
      body: state.when(
        loading: () => const _LoadingView(),
        error: (error, stackTrace) {
          return _ErrorView(
            error: error,
            onRetry: () {
              ref.invalidate(companyOverviewProvider(companyId));
            },
          );
        },
        data: (data) {
          return _CompanyOverviewBody(data: data);
        },
      ),
    );
  }
}

/* ============================================================
   PROVIDER
   ============================================================ */

final companyOverviewProvider =
    FutureProvider.family<CompanyOverviewData, String>((ref, companyId) async {
      return CompanyOverviewRepository().load(companyId);
    });

/* ============================================================
   REPOSITORY
   ============================================================ */

class CompanyOverviewRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<CompanyOverviewData> load(String companyId) async {
    final results = await Future.wait([
      _loadCompany(companyId),
      _safeRows(
        () => _supabase.from('employees').select().eq('company_id', companyId),
      ),
      _safeRows(
        () => _supabase
            .from('income_records')
            .select()
            .eq('company_id', companyId),
      ),
      _safeRows(
        () => _supabase.from('expenses').select().eq('company_id', companyId),
      ),
      _safeRows(
        () => _supabase
            .from('payroll_records')
            .select()
            .eq('company_id', companyId),
      ),
      _safeRows(
        () => _supabase
            .from('bank_accounts')
            .select()
            .eq('company_id', companyId),
      ),
      _safeRows(
        () => _supabase.from('cash_boxes').select().eq('company_id', companyId),
      ),
    ]);

    final company = results[0] as Map<String, dynamic>;

    final employees = results[1] as List<Map<String, dynamic>>;

    final incomes = results[2] as List<Map<String, dynamic>>;

    final expenses = results[3] as List<Map<String, dynamic>>;

    final payrolls = results[4] as List<Map<String, dynamic>>;

    final banks = results[5] as List<Map<String, dynamic>>;

    final cashBoxes = results[6] as List<Map<String, dynamic>>;

    final now = DateTime.now();

    final currentMonthStart = DateTime(now.year, now.month, 1);

    final nextMonthStart = DateTime(now.year, now.month + 1, 1);

    /* -----------------------------
       درآمد ماه جاری
       ----------------------------- */

    final currentMonthIncomes =
        incomes.where((row) {
          final date = _readDate(row, const [
            'income_date',
            'date',
            'created_at',
          ]);

          if (date == null) {
            return false;
          }

          return !date.isBefore(currentMonthStart) &&
              date.isBefore(nextMonthStart);
        }).toList();

    /* -----------------------------
       هزینه ماه جاری
       ----------------------------- */

    final currentMonthExpenses =
        expenses.where((row) {
          final date = _readDate(row, const [
            'expense_date',
            'date',
            'created_at',
          ]);

          if (date == null) {
            return false;
          }

          return !date.isBefore(currentMonthStart) &&
              date.isBefore(nextMonthStart);
        }).toList();

    /* -----------------------------
       حقوق ماه جاری
       ----------------------------- */

    final currentMonthPayroll =
        payrolls.where((row) {
          final date = _readDate(row, const ['created_at', 'date']);

          if (date != null) {
            return !date.isBefore(currentMonthStart) &&
                date.isBefore(nextMonthStart);
          }

          final year = _readInt(row, const ['period_year']);

          final month = _readInt(row, const ['period_month']);

          return year == now.year && month == now.month;
        }).toList();

    final monthlyIncome = _sumAmount(currentMonthIncomes, const [
      'amount',
      'total_amount',
      'income_amount',
    ]);

    final monthlyExpense = _sumAmount(currentMonthExpenses, const [
      'amount',
      'total_amount',
      'expense_amount',
    ]);

    final monthlyPayroll = _sumAmount(currentMonthPayroll, const [
      'gross_salary',
      'net_salary',
    ]);

    /* -----------------------------
       بانک
       ----------------------------- */

    final bankBalance = _sumAmount(banks, const [
      'balance',
      'current_balance',
      'available_balance',
      'account_balance',
    ]);

    /* -----------------------------
       صندوق
       ----------------------------- */

    final cashBalance = _sumAmount(cashBoxes, const [
      'balance',
      'current_balance',
      'cash_balance',
    ]);

    final totalLiquidity = bankBalance + cashBalance;

    /* -----------------------------
       سود واقعی
       ----------------------------- */

    final monthlyProfit = monthlyIncome - monthlyExpense;

    final monthlyProfitMargin =
        monthlyIncome > 0
            ? ((monthlyProfit / monthlyIncome) * 100).toDouble()
            : 0.0;

    /* -----------------------------
       نمودار
       ----------------------------- */

    final monthlySeries = _buildMonthlySeries(
      incomes: incomes,
      expenses: expenses,
    );

    /* -----------------------------
       آخرین درآمدها
       ----------------------------- */

    final recentIncomes = _recentRows(incomes, const [
      'income_date',
      'date',
      'created_at',
    ]);

    /* -----------------------------
       آخرین هزینه‌ها
       ----------------------------- */

    final recentExpenses = _recentRows(expenses, const [
      'expense_date',
      'date',
      'created_at',
    ]);

    /* -----------------------------
       هشدارها
       ----------------------------- */

    final alerts = _buildAlerts(
      employeeCount: employees.length,
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      monthlyPayroll: monthlyPayroll,
      totalLiquidity: totalLiquidity,
    );

    return CompanyOverviewData(
      company: company,
      employeeCount: employees.length,
      monthlyIncome: monthlyIncome,
      monthlyExpense: monthlyExpense,
      monthlyPayroll: monthlyPayroll,
      monthlyProfit: monthlyProfit,
      monthlyProfitMargin: monthlyProfitMargin,
      bankBalance: bankBalance,
      cashBalance: cashBalance,
      totalLiquidity: totalLiquidity,
      monthlySeries: monthlySeries,
      recentIncomes: recentIncomes,
      recentExpenses: recentExpenses,
      alerts: alerts,
    );
  }

  Future<Map<String, dynamic>> _loadCompany(String companyId) async {
    final result =
        await _supabase
            .from('companies')
            .select()
            .eq('id', companyId)
            .maybeSingle();

    if (result == null) {
      throw Exception('اطلاعات شرکت پیدا نشد.');
    }

    return Map<String, dynamic>.from(result);
  }

  Future<List<Map<String, dynamic>>> _safeRows(
    Future<dynamic> Function() query,
  ) async {
    try {
      final result = await query();

      if (result is! List) {
        return <Map<String, dynamic>>[];
      }

      return result
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  List<MonthlyFinancialPoint> _buildMonthlySeries({
    required List<Map<String, dynamic>> incomes,
    required List<Map<String, dynamic>> expenses,
  }) {
    final now = DateTime.now();

    final points = <MonthlyFinancialPoint>[];

    for (int index = 5; index >= 0; index--) {
      final monthDate = DateTime(now.year, now.month - index, 1);

      final nextMonth = DateTime(monthDate.year, monthDate.month + 1, 1);

      final incomeRows =
          incomes.where((row) {
            final date = _readDate(row, const [
              'income_date',
              'date',
              'created_at',
            ]);

            return date != null &&
                !date.isBefore(monthDate) &&
                date.isBefore(nextMonth);
          }).toList();

      final expenseRows =
          expenses.where((row) {
            final date = _readDate(row, const [
              'expense_date',
              'date',
              'created_at',
            ]);

            return date != null &&
                !date.isBefore(monthDate) &&
                date.isBefore(nextMonth);
          }).toList();

      final income = _sumAmount(incomeRows, const [
        'amount',
        'total_amount',
        'income_amount',
      ]);

      final expense = _sumAmount(expenseRows, const [
        'amount',
        'total_amount',
        'expense_amount',
      ]);

      final profit = income - expense;

      final jalali = Jalali.fromDateTime(monthDate);

      points.add(
        MonthlyFinancialPoint(
          year: jalali.year,
          month: jalali.month,
          label: _monthName(jalali.month),
          income: income.toDouble(),
          expense: expense.toDouble(),
          profit: profit.toDouble(),
        ),
      );
    }

    return points;
  }

  List<Map<String, dynamic>> _recentRows(
    List<Map<String, dynamic>> rows,
    List<String> dateKeys,
  ) {
    final result = List<Map<String, dynamic>>.from(rows);

    result.sort((a, b) {
      final aDate = _readDate(a, dateKeys);

      final bDate = _readDate(b, dateKeys);

      if (aDate == null && bDate == null) {
        return 0;
      }

      if (aDate == null) {
        return 1;
      }

      if (bDate == null) {
        return -1;
      }

      return bDate.compareTo(aDate);
    });

    return result.take(5).toList();
  }

  List<CompanyAlert> _buildAlerts({
    required int employeeCount,
    required double monthlyIncome,
    required double monthlyExpense,
    required double monthlyPayroll,
    required double totalLiquidity,
  }) {
    final alerts = <CompanyAlert>[];

    if (monthlyExpense > monthlyIncome && monthlyExpense > 0) {
      alerts.add(
        const CompanyAlert(
          title: 'هزینه‌ها بیشتر از درآمد ماه جاری است',
          description:
              'بر اساس اطلاعات ثبت‌شده، هزینه‌های ماه جاری از درآمد بیشتر است.',
          icon: Icons.warning_amber_rounded,
          type: CompanyAlertType.warning,
        ),
      );
    }

    if (monthlyPayroll > 0 && totalLiquidity < monthlyPayroll) {
      alerts.add(
        const CompanyAlert(
          title: 'نقدینگی کمتر از حقوق ماه جاری است',
          description:
              'موجودی فعلی بانک و صندوق کمتر از مبلغ حقوق ثبت‌شده است.',
          icon: Icons.account_balance_wallet_outlined,
          type: CompanyAlertType.danger,
        ),
      );
    }

    if (employeeCount == 0) {
      alerts.add(
        const CompanyAlert(
          title: 'پرسنلی ثبت نشده است',
          description: 'برای این شرکت هنوز پرسنلی در سیستم ثبت نشده است.',
          icon: Icons.people_outline_rounded,
          type: CompanyAlertType.info,
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        const CompanyAlert(
          title: 'وضعیت شرکت مناسب است',
          description: 'در حال حاضر هشدار مهمی برای پیگیری وجود ندارد.',
          icon: Icons.check_circle_outline_rounded,
          type: CompanyAlertType.success,
        ),
      );
    }

    return alerts;
  }
}

/* ============================================================
   MODELS
   ============================================================ */

class CompanyOverviewData {
  const CompanyOverviewData({
    required this.company,
    required this.employeeCount,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlyPayroll,
    required this.monthlyProfit,
    required this.monthlyProfitMargin,
    required this.bankBalance,
    required this.cashBalance,
    required this.totalLiquidity,
    required this.monthlySeries,
    required this.recentIncomes,
    required this.recentExpenses,
    required this.alerts,
  });

  final Map<String, dynamic> company;

  final int employeeCount;

  final double monthlyIncome;

  final double monthlyExpense;

  final double monthlyPayroll;

  final double monthlyProfit;

  final double monthlyProfitMargin;

  final double bankBalance;

  final double cashBalance;

  final double totalLiquidity;

  final List<MonthlyFinancialPoint> monthlySeries;

  final List<Map<String, dynamic>> recentIncomes;

  final List<Map<String, dynamic>> recentExpenses;

  final List<CompanyAlert> alerts;

  String get companyName {
    final value = company['name'] ?? company['company_name'];

    if (value == null || value.toString().trim().isEmpty) {
      return 'شرکت انتخاب‌شده';
    }

    return value.toString();
  }

  String get companyCode {
    final value =
        company['code'] ?? company['company_code'] ?? company['national_id'];

    return value?.toString() ?? '---';
  }
}

class MonthlyFinancialPoint {
  const MonthlyFinancialPoint({
    required this.year,
    required this.month,
    required this.label,
    required this.income,
    required this.expense,
    required this.profit,
  });

  final int year;
  final int month;
  final String label;

  final double income;
  final double expense;
  final double profit;
}

enum CompanyAlertType { success, warning, danger, info }

class CompanyAlert {
  const CompanyAlert({
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
  });

  final String title;
  final String description;
  final IconData icon;
  final CompanyAlertType type;
}

/* ============================================================
   COLORS
   ============================================================ */

class _Colors {
  static const background = Color(0xFFF5F8F7);

  static const card = Colors.white;

  static const primary = Color(0xFF176B50);

  static const primaryDark = Color(0xFF0F513D);

  static const income = Color(0xFF1683E8);

  static const expense = Color(0xFFE67E00);

  static const profit = Color(0xFF159A67);

  static const payroll = Color(0xFF7652B8);

  static const danger = Color(0xFFDC2626);

  static const warning = Color(0xFFF59E0B);

  static const text = Color(0xFF17202A);

  static const muted = Color(0xFF718096);

  static const border = Color(0xFFE1E8E5);

  static const grid = Color(0xFFE9EFEC);
}

/* ============================================================
   MAIN BODY
   ============================================================ */

class _CompanyOverviewBody extends StatelessWidget {
  const _CompanyOverviewBody({required this.data});

  final CompanyOverviewData data;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _Colors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: _horizontalPadding(constraints.maxWidth),
              vertical: 18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CompanyHeader(data: data),

                const SizedBox(height: 14),

                _KpiGrid(data: data),

                const SizedBox(height: 14),

                _FinancialChartCard(data: data),

                const SizedBox(height: 14),

                _OperationalSection(data: data),

                const SizedBox(height: 14),

                _BottomSection(data: data),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  double _horizontalPadding(double width) {
    if (width >= 1500) {
      return 28;
    }

    if (width >= 1000) {
      return 20;
    }

    if (width >= 600) {
      return 14;
    }

    return 10;
  }
}

/* ============================================================
   HEADER
   ============================================================ */

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({required this.data});

  final CompanyOverviewData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [_Colors.primaryDark, _Colors.primary],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CompanyIdentity(data: data),
                const SizedBox(height: 12),
                _LiquidityBadge(amount: data.totalLiquidity),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _CompanyIdentity(data: data)),
              const SizedBox(width: 12),
              _LiquidityBadge(amount: data.totalLiquidity),
            ],
          );
        },
      ),
    );
  }
}

class _CompanyIdentity extends StatelessWidget {
  const _CompanyIdentity({required this.data});

  final CompanyOverviewData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.business_rounded,
            color: _Colors.primaryDark,
            size: 25,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'نمای کلی شرکت',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.companyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'کد شرکت: ${_persianDigits(data.companyCode)}',
                style: const TextStyle(color: Colors.white70, fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiquidityBadge extends StatelessWidget {
  const _LiquidityBadge({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نقدینگی شرکت',
            style: TextStyle(color: Colors.white70, fontSize: 8),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${_formatAmount(amount)} ریال',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   KPI GRID
   ============================================================ */

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.data});

  final CompanyOverviewData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;

        if (width >= 1400) {
          columns = 6;
        } else if (width >= 1000) {
          columns = 3;
        } else if (width >= 600) {
          columns = 2;
        } else {
          columns = 1;
        }

        final cards = [
          _CompactKpiCard(
            title: 'موجودی بانک و نقد',
            value: '${_formatAmount(data.totalLiquidity)} ریال',
            subtitle: 'بانک + صندوق',
            icon: Icons.account_balance_rounded,
            color: _Colors.primary,
          ),
          _CompactKpiCard(
            title: 'درآمد ماه جاری',
            value: '${_formatAmount(data.monthlyIncome)} ریال',
            subtitle: 'ثبت‌شده در ماه جاری',
            icon: Icons.trending_up_rounded,
            color: _Colors.income,
          ),
          _CompactKpiCard(
            title: 'هزینه ماه جاری',
            value: '${_formatAmount(data.monthlyExpense)} ریال',
            subtitle: 'ثبت‌شده در ماه جاری',
            icon: Icons.receipt_long_rounded,
            color: _Colors.expense,
          ),
          _CompactKpiCard(
            title: 'سود / زیان ماه جاری',
            value: '${_formatAmount(data.monthlyProfit.abs())} ریال',
            subtitle: data.monthlyProfit >= 0 ? 'مازاد' : 'زیان',
            icon:
                data.monthlyProfit >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
            color: data.monthlyProfit >= 0 ? _Colors.profit : _Colors.danger,
          ),
          _CompactKpiCard(
            title: 'پرسنل فعال',
            value: '${_persianDigits(data.employeeCount.toString())} نفر',
            subtitle: 'پرسنل ثبت‌شده',
            icon: Icons.people_alt_rounded,
            color: _Colors.payroll,
          ),
          _CompactKpiCard(
            title: 'حقوق ماه جاری',
            value: '${_formatAmount(data.monthlyPayroll)} ریال',
            subtitle: 'مبلغ حقوق ثبت‌شده',
            icon: Icons.payments_rounded,
            color: _Colors.payroll,
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,

            // مهم:
            // به جای childAspectRatio
            // ارتفاع ثابت داریم.
            mainAxisExtent: columns == 1 ? 88 : 96,
          ),
          itemBuilder: (context, index) {
            return cards[index];
          },
        );
      },
    );
  }
}

class _CompactKpiCard extends StatelessWidget {
  const _CompactKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _Colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _Colors.muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      color: _Colors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _Colors.muted, fontSize: 7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   FINANCIAL CHART
   ============================================================ */

class _FinancialChartCard extends StatelessWidget {
  const _FinancialChartCard({required this.data});

  final CompanyOverviewData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 355,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: 'روند مالی شرکت',
            subtitle: 'مقایسه درآمد، هزینه و سود / زیان در ۶ ماه اخیر',
            icon: Icons.show_chart_rounded,
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegend(color: _Colors.income, title: 'درآمد'),
              SizedBox(width: 16),
              _ChartLegend(color: _Colors.expense, title: 'هزینه'),
              SizedBox(width: 16),
              _ChartLegend(color: _Colors.profit, title: 'سود / زیان'),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child:
                data.monthlySeries.isEmpty
                    ? const _NoDataView()
                    : _FinancialChart(points: data.monthlySeries),
          ),
        ],
      ),
    );
  }
}

class _FinancialChart extends StatelessWidget {
  const _FinancialChart({required this.points});

  final List<MonthlyFinancialPoint> points;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          painter: _FinancialChartPainter(points: points),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.title});

  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          title,
          style: const TextStyle(
            color: _Colors.muted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   FINANCIAL PAINTER
   ============================================================ */

class _FinancialChartPainter extends CustomPainter {
  _FinancialChartPainter({required this.points});

  final List<MonthlyFinancialPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    const leftPadding = 54.0;
    const rightPadding = 14.0;
    const topPadding = 12.0;
    const bottomPadding = 34.0;

    final chartWidth = math.max(1.0, size.width - leftPadding - rightPadding);

    final chartHeight = math.max(1.0, size.height - topPadding - bottomPadding);

    /*
     * تمام مقادیر واقعی:
     *
     * income
     * expense
     * profit
     *
     * بدون abs()
     */

    final values = <double>[
      for (final point in points) ...[
        point.income,
        point.expense,
        point.profit,
      ],
    ];

    double minValue = values.reduce(math.min);

    double maxValue = values.reduce(math.max);

    /*
     * اگر همه مقادیر صفر باشند.
     */

    if (minValue == 0 && maxValue == 0) {
      minValue = -1;
      maxValue = 1;
    } else {
      /*
       * Padding متناسب با مقدار واقعی.
       */
      final range = maxValue - minValue;

      final padding = math.max(range * .12, 1.0);

      minValue -= padding;
      maxValue += padding;
    }

    /*
     * اگر فقط مقادیر مثبت داشتیم،
     * صفر را هم داخل نمودار نگه می‌داریم.
     */
    if (minValue > 0) {
      minValue = 0;
    }

    /*
     * اگر فقط مقادیر منفی داشتیم،
     * صفر را هم داخل نمودار نگه می‌داریم.
     */
    if (maxValue < 0) {
      maxValue = 0;
    }

    final range = math.max(maxValue - minValue, 1.0);

    final gridPaint =
        Paint()
          ..color = _Colors.grid
          ..strokeWidth = 1;

    final zeroPaint =
        Paint()
          ..color = const Color(0xFFCBD5D1)
          ..strokeWidth = 1.4;

    final textPainter = TextPainter(textDirection: TextDirection.rtl);

    /*
     * GRID
     */

    for (int i = 0; i <= 4; i++) {
      final ratio = i / 4;

      final value = maxValue - range * ratio;

      final y = topPadding + chartHeight * ratio;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      textPainter.text = TextSpan(
        text: _formatCompact(value),
        style: const TextStyle(color: _Colors.muted, fontSize: 7.5),
      );

      textPainter.layout();

      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    /*
     * ZERO LINE
     */

    if (minValue <= 0 && maxValue >= 0) {
      final zeroRatio = maxValue / range;

      final zeroY = topPadding + chartHeight * zeroRatio;

      canvas.drawLine(
        Offset(leftPadding, zeroY),
        Offset(size.width - rightPadding, zeroY),
        zeroPaint,
      );
    }

    /*
     * X LABELS
     */

    for (int i = 0; i < points.length; i++) {
      final x =
          points.length == 1
              ? leftPadding + chartWidth / 2
              : leftPadding + chartWidth * (i / (points.length - 1));

      textPainter.text = TextSpan(
        text: points[i].label,
        style: const TextStyle(
          color: _Colors.muted,
          fontSize: 7.5,
          fontWeight: FontWeight.w600,
        ),
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - bottomPadding + 8),
      );
    }

    /*
     * SERIES
     */

    _drawSeries(
      canvas: canvas,
      values: points.map((item) => item.income).toList(),
      color: _Colors.income,
      leftPadding: leftPadding,
      topPadding: topPadding,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      minValue: minValue,
      range: range,
    );

    _drawSeries(
      canvas: canvas,
      values: points.map((item) => item.expense).toList(),
      color: _Colors.expense,
      leftPadding: leftPadding,
      topPadding: topPadding,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      minValue: minValue,
      range: range,
    );

    _drawSeries(
      canvas: canvas,
      values: points.map((item) => item.profit).toList(),
      color: _Colors.profit,
      leftPadding: leftPadding,
      topPadding: topPadding,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      minValue: minValue,
      range: range,
    );
  }

  void _drawSeries({
    required Canvas canvas,
    required List<double> values,
    required Color color,
    required double leftPadding,
    required double topPadding,
    required double chartWidth,
    required double chartHeight,
    required double minValue,
    required double range,
  }) {
    if (values.isEmpty) {
      return;
    }

    final path = Path();

    final linePaint =
        Paint()
          ..color = color
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final pointPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final x =
          values.length == 1
              ? leftPadding + chartWidth / 2
              : leftPadding + chartWidth * (i / (values.length - 1));

      final normalized = (values[i] - minValue) / range;

      /*
       * محدود کردن Y
       *
       * باعث می‌شود هیچ‌وقت
       * نقطه از محدوده نمودار
       * خارج نشود.
       */

      final safeNormalized = normalized.clamp(0.0, 1.0);

      final y = topPadding + chartHeight * (1 - safeNormalized);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    for (int i = 0; i < values.length; i++) {
      final x =
          values.length == 1
              ? leftPadding + chartWidth / 2
              : leftPadding + chartWidth * (i / (values.length - 1));

      final normalized = (values[i] - minValue) / range;

      final safeNormalized = normalized.clamp(0.0, 1.0);

      final y = topPadding + chartHeight * (1 - safeNormalized);

      canvas.drawCircle(Offset(x, y), 3.6, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FinancialChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

/* ============================================================
   OPERATIONAL
   ============================================================ */

class _OperationalSection extends StatelessWidget {
  const _OperationalSection({required this.data});

  final CompanyOverviewData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return Column(
            children: [
              _LiquidityCard(data: data),
              const SizedBox(height: 12),
              _OperationalStatusCard(data: data),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _LiquidityCard(data: data)),
            const SizedBox(width: 12),
            Expanded(child: _OperationalStatusCard(data: data)),
          ],
        );
      },
    );
  }
}

class _LiquidityCard extends StatelessWidget {
  const _LiquidityCard({required this.data});

  final CompanyOverviewData data;

  @override
  Widget build(BuildContext context) {
    final total = data.totalLiquidity;

    final bankShare =
        total > 0 ? (data.bankBalance / total).clamp(0.0, 1.0) : 0.0;

    final cashShare =
        total > 0 ? (data.cashBalance / total).clamp(0.0, 1.0) : 0.0;

    return _SimpleCard(
      title: 'وضعیت نقدینگی',
      subtitle: 'توزیع موجودی بین بانک و صندوق',
      icon: Icons.account_balance_wallet_rounded,
      child: Column(
        children: [
          _BalanceRow(
            title: 'حساب‌های بانکی',
            amount: data.bankBalance,
            share: bankShare.toDouble(),
            color: _Colors.primary,
            icon: Icons.account_balance_rounded,
          ),
          const SizedBox(height: 14),
          _BalanceRow(
            title: 'صندوق‌ها',
            amount: data.cashBalance,
            share: cashShare.toDouble(),
            color: _Colors.income,
            icon: Icons.point_of_sale_rounded,
          ),
        ],
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({
    required this.title,
    required this.amount,
    required this.share,
    required this.color,
    required this.icon,
  });

  final String title;
  final double amount;
  final double share;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(.09),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _Colors.text,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${_formatAmount(amount)} ریال',
                style: const TextStyle(
                  color: _Colors.text,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: share.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFEFF3F1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _OperationalStatusCard extends StatelessWidget {
  const _OperationalStatusCard({required this.data});

  final CompanyOverviewData data;

  @override
  Widget build(BuildContext context) {
    return _SimpleCard(
      title: 'وضعیت عملیاتی شرکت',
      subtitle: 'خلاصه وضعیت بخش‌های اصلی',
      icon: Icons.dashboard_customize_rounded,
      child: Column(
        children: [
          _StatusRow(
            title: 'بانک و نقد',
            value: '${_formatAmount(data.totalLiquidity)} ریال',
            active: data.totalLiquidity > 0,
            color: _Colors.primary,
          ),
          const Divider(height: 17),
          _StatusRow(
            title: 'درآمد ماه جاری',
            value: '${_formatAmount(data.monthlyIncome)} ریال',
            active: data.monthlyIncome > 0,
            color: _Colors.income,
          ),
          const Divider(height: 17),
          _StatusRow(
            title: 'هزینه ماه جاری',
            value: '${_formatAmount(data.monthlyExpense)} ریال',
            active: data.monthlyExpense > 0,
            color: _Colors.expense,
          ),
          const Divider(height: 17),
          _StatusRow(
            title: 'پرسنل',
            value: '${_persianDigits(data.employeeCount.toString())} نفر',
            active: data.employeeCount > 0,
            color: _Colors.payroll,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.title,
    required this.value,
    required this.active,
    required this.color,
  });

  final String title;
  final String value;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? color : _Colors.border,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _Colors.text,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: _Colors.text,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   BOTTOM
   ============================================================ */

class _BottomSection extends StatelessWidget {
  const _BottomSection({required this.data});

  final CompanyOverviewData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1000) {
          return Column(
            children: [
              _RecentCard(
                title: 'آخرین درآمدها',
                subtitle: 'آخرین درآمدهای ثبت‌شده',
                icon: Icons.trending_up_rounded,
                color: _Colors.income,
                rows: data.recentIncomes,
                income: true,
              ),
              const SizedBox(height: 12),
              _RecentCard(
                title: 'آخرین هزینه‌ها',
                subtitle: 'آخرین هزینه‌های ثبت‌شده',
                icon: Icons.receipt_long_rounded,
                color: _Colors.expense,
                rows: data.recentExpenses,
                income: false,
              ),
              const SizedBox(height: 12),
              _AlertsCard(alerts: data.alerts),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: _RecentCard(
                title: 'آخرین درآمدها',
                subtitle: 'آخرین درآمدهای ثبت‌شده',
                icon: Icons.trending_up_rounded,
                color: _Colors.income,
                rows: data.recentIncomes,
                income: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: _RecentCard(
                title: 'آخرین هزینه‌ها',
                subtitle: 'آخرین هزینه‌های ثبت‌شده',
                icon: Icons.receipt_long_rounded,
                color: _Colors.expense,
                rows: data.recentExpenses,
                income: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: _AlertsCard(alerts: data.alerts)),
          ],
        );
      },
    );
  }
}

/* ============================================================
   RECENT
   ============================================================ */

class _RecentCard extends StatelessWidget {
  const _RecentCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.rows,
    required this.income,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> rows;
  final bool income;

  @override
  Widget build(BuildContext context) {
    return _SimpleCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      child:
          rows.isEmpty
              ? const _NoDataView()
              : Column(
                children: List.generate(rows.length, (index) {
                  final row = rows[index];

                  final titleValue = _readString(row, const [
                    'title',
                    'name',
                    'description',
                  ], fallback: income ? 'درآمد ثبت‌شده' : 'هزینه ثبت‌شده');

                  final amount = _readAmount(row, const [
                    'amount',
                    'total_amount',
                    'income_amount',
                    'expense_amount',
                  ]);

                  final date = _readDate(
                    row,
                    income
                        ? const ['income_date', 'date', 'created_at']
                        : const ['expense_date', 'date', 'created_at'],
                  );

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == rows.length - 1 ? 0 : 8,
                    ),
                    child: _TransactionRow(
                      title: titleValue,
                      amount: amount,
                      date: date,
                      color: color,
                    ),
                  );
                }),
              ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.title,
    required this.amount,
    required this.date,
    required this.color,
  });

  final String title;
  final double amount;
  final DateTime? date;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: color.withOpacity(.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.receipt_rounded, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _Colors.text,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date == null ? 'بدون تاریخ' : _formatJalaliDate(date!),
                  style: const TextStyle(color: _Colors.muted, fontSize: 7),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${_formatAmount(amount)} ریال',
                style: const TextStyle(
                  color: _Colors.text,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   ALERTS
   ============================================================ */

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.alerts});

  final List<CompanyAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return _SimpleCard(
      title: 'هشدارهای مدیریتی',
      subtitle: 'موارد مهم قابل پیگیری',
      icon: Icons.notifications_active_rounded,
      child: Column(
        children:
            alerts.map((alert) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _AlertItem(alert: alert),
              );
            }).toList(),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  const _AlertItem({required this.alert});

  final CompanyAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = _alertColor(alert.type);

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withOpacity(.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(alert.icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    color: _Colors.text,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.description,
                  style: const TextStyle(
                    color: _Colors.muted,
                    fontSize: 7,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _alertColor(CompanyAlertType type) {
    switch (type) {
      case CompanyAlertType.success:
        return _Colors.profit;

      case CompanyAlertType.warning:
        return _Colors.warning;

      case CompanyAlertType.danger:
        return _Colors.danger;

      case CompanyAlertType.info:
        return _Colors.income;
    }
  }
}

/* ============================================================
   COMMON CARD
   ============================================================ */

class _SimpleCard extends StatelessWidget {
  const _SimpleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 230),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _Colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(title: title, subtitle: subtitle, icon: icon),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _Colors.primary.withOpacity(.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: _Colors.primary, size: 17),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _Colors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _Colors.muted, fontSize: 7.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ============================================================
   NO DATA
   ============================================================ */

class _NoDataView extends StatelessWidget {
  const _NoDataView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _Colors.primary.withOpacity(.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.insert_chart_outlined_rounded,
              color: _Colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'داده‌ای برای نمایش وجود ندارد',
            style: TextStyle(
              color: _Colors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   LOADING
   ============================================================ */

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: _Colors.primary,
        strokeWidth: 2.5,
      ),
    );
  }
}

/* ============================================================
   ERROR
   ============================================================ */

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: _Colors.danger,
              size: 40,
            ),
            const SizedBox(height: 10),
            const Text(
              'خطا در دریافت اطلاعات شرکت',
              style: TextStyle(
                color: _Colors.text,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _Colors.muted, fontSize: 8),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: _Colors.primary),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   HELPERS
   ============================================================ */

double _sumAmount(List<Map<String, dynamic>> rows, List<String> keys) {
  double total = 0.0;

  for (final row in rows) {
    total += _readAmount(row, keys);
  }

  return total;
}

double _readAmount(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    if (!row.containsKey(key)) {
      continue;
    }

    final value = row[key];

    if (value == null) {
      continue;
    }

    if (value is num) {
      return value.toDouble();
    }

    final parsed = double.tryParse(value.toString().replaceAll(',', ''));

    if (parsed != null) {
      return parsed;
    }
  }

  return 0.0;
}

int? _readInt(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final value = row[key];

    if (value == null) {
      continue;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    final parsed = int.tryParse(value.toString());

    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

String _readString(
  Map<String, dynamic> row,
  List<String> keys, {
  required String fallback,
}) {
  for (final key in keys) {
    final value = row[key];

    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }

  return fallback;
}

DateTime? _readDate(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final value = row[key];

    if (value == null) {
      continue;
    }

    if (value is DateTime) {
      return value;
    }

    final parsed = DateTime.tryParse(value.toString());

    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

/* ============================================================
   FORMAT
   ============================================================ */

String _formatAmount(num amount) {
  final rounded = amount.round();

  final negative = rounded < 0;

  final raw = rounded.abs().toString();

  final buffer = StringBuffer();

  for (int i = 0; i < raw.length; i++) {
    buffer.write(raw[i]);

    final remaining = raw.length - i - 1;

    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
  }

  final value = negative ? '-${buffer.toString()}' : buffer.toString();

  return _persianDigits(value);
}

String _formatCompact(double value) {
  final absolute = value.abs();

  if (absolute >= 1000000000) {
    return _persianDigits('${(value / 1000000000).toStringAsFixed(1)}B');
  }

  if (absolute >= 1000000) {
    return _persianDigits('${(value / 1000000).toStringAsFixed(1)}M');
  }

  if (absolute >= 1000) {
    return _persianDigits('${(value / 1000).toStringAsFixed(1)}K');
  }

  return _persianDigits(value.round().toString());
}

String _formatJalaliDate(DateTime date) {
  final jalali = Jalali.fromDateTime(date);

  return '${_persianDigits(jalali.year.toString())}/${_persianDigits(jalali.month.toString().padLeft(2, '0'))}/${_persianDigits(jalali.day.toString().padLeft(2, '0'))}';
}

String _monthName(int month) {
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

  if (month < 1 || month > 12) {
    return '';
  }

  return months[month - 1];
}

String _persianDigits(String value) {
  const english = '0123456789';

  const persian = '۰۱۲۳۴۵۶۷۸۹';

  return value.split('').map((char) {
    final index = english.indexOf(char);

    if (index == -1) {
      return char;
    }

    return persian[index];
  }).join();
}
