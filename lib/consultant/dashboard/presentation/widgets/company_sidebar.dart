import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/company_provider.dart';

class CompanySidebar extends ConsumerStatefulWidget {
  const CompanySidebar({
    super.key,
    required this.companyId,
    required this.currentRoute,
  });

  final String companyId;
  final String currentRoute;

  @override
  ConsumerState<CompanySidebar> createState() => _CompanySidebarState();
}

class _CompanySidebarState extends ConsumerState<CompanySidebar> {
  bool _bankingExpanded = false;
  bool _payrollExpanded = false;
  bool _incomeExpanded = false;
  bool _expenseExpanded = false;

  bool _incomeActionLoading = false;
  bool _expenseActionLoading = false;

  String get _companyBase => '/consultant/companies/${widget.companyId}';

  String get _bankingBase => '$_companyBase/banking';
  String get _payrollBase => '$_companyBase/payroll';
  String get _incomeBase => '$_companyBase/income';
  String get _expenseBase => '$_companyBase/expenses';

  String get _incomePeriodsRoute => '$_incomeBase/periods';
  String get _expensePeriodsRoute => '$_expenseBase/periods';
  String get _expenseReportsRoute => '$_expenseBase/reports';

  @override
  void initState() {
    super.initState();

    _bankingExpanded = _isBankingRoute();
    _payrollExpanded = _isPayrollRoute();
    _incomeExpanded = _isIncomeRoute();
    _expenseExpanded = _isExpenseRoute();
  }

  @override
  void didUpdateWidget(covariant CompanySidebar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.companyId != oldWidget.companyId ||
        widget.currentRoute != oldWidget.currentRoute) {
      if (_isBankingRoute()) {
        _bankingExpanded = true;
      }

      if (_isPayrollRoute()) {
        _payrollExpanded = true;
      }

      if (_isIncomeRoute()) {
        _incomeExpanded = true;
      }

      if (_isExpenseRoute()) {
        _expenseExpanded = true;
      }
    }
  }

  // ==========================================================
  // NAVIGATION
  // ==========================================================

  void _go(BuildContext context, String route) {
    if (widget.currentRoute == route) {
      return;
    }

    context.go(route);
  }

  // ==========================================================
  // INCOME DIRECT ACTION
  // ==========================================================

  Future<void> _openIncomeRecognition(BuildContext context) async {
    if (_incomeActionLoading) {
      return;
    }

    setState(() {
      _incomeActionLoading = true;
    });

    try {
      final client = Supabase.instance.client;

      final yearResponse = await client
          .from('income_fiscal_years')
          .select('id, year, status')
          .eq('company_id', widget.companyId)
          .order('year', ascending: false)
          .limit(1)
          .maybeSingle();

      if (yearResponse == null) {
        if (!mounted) return;

        _showMessage(context, 'هنوز سال مالی درآمد ایجاد نشده است.');
        return;
      }

      final yearId = yearResponse['id']?.toString();

      if (yearId == null || yearId.isEmpty) {
        if (!mounted) return;

        _showMessage(context, 'سال مالی درآمد معتبر نیست.');
        return;
      }

      final periodResponse = await client
          .from('income_fiscal_periods')
          .select('id, fiscal_year_id, year, month, title, status')
          .eq('company_id', widget.companyId)
          .eq('fiscal_year_id', yearId)
          .eq('status', 'open')
          .order('month', ascending: true)
          .limit(1)
          .maybeSingle();

      if (periodResponse == null) {
        if (!mounted) return;

        _showMessage(
          context,
          'در این سال مالی هیچ دوره بازی برای ثبت درآمد وجود ندارد.',
        );
        return;
      }

      final periodId = periodResponse['id']?.toString();

      if (periodId == null || periodId.isEmpty) {
        if (!mounted) return;

        _showMessage(context, 'دوره درآمد معتبر نیست.');
        return;
      }

      if (!mounted) return;

      context.go('$_incomeBase/recognition/$periodId');
    } catch (error) {
      if (!mounted) return;

      _showMessage(context, 'خطا در بازکردن ثبت درآمد: $error');
    } finally {
      if (mounted) {
        setState(() {
          _incomeActionLoading = false;
        });
      }
    }
  }

  Future<void> _openIncomeReceivables(BuildContext context) async {
    if (_incomeActionLoading) {
      return;
    }

    setState(() {
      _incomeActionLoading = true;
    });

    try {
      final client = Supabase.instance.client;

      final yearResponse = await client
          .from('income_fiscal_years')
          .select('id, year, status')
          .eq('company_id', widget.companyId)
          .order('year', ascending: false)
          .limit(1)
          .maybeSingle();

      if (yearResponse == null) {
        if (!mounted) return;

        _showMessage(context, 'هنوز سال مالی درآمد ایجاد نشده است.');
        return;
      }

      final yearId = yearResponse['id']?.toString();

      if (yearId == null || yearId.isEmpty) {
        if (!mounted) return;

        _showMessage(context, 'سال مالی درآمد معتبر نیست.');
        return;
      }

      final periodResponse = await client
          .from('income_fiscal_periods')
          .select('id, fiscal_year_id, year, month, title, status')
          .eq('company_id', widget.companyId)
          .eq('fiscal_year_id', yearId)
          .eq('status', 'open')
          .order('month', ascending: true)
          .limit(1)
          .maybeSingle();

      if (periodResponse == null) {
        if (!mounted) return;

        _showMessage(
          context,
          'در این سال مالی هیچ دوره بازی برای ثبت دریافتنی وجود ندارد.',
        );
        return;
      }

      final periodId = periodResponse['id']?.toString();

      if (periodId == null || periodId.isEmpty) {
        if (!mounted) return;

        _showMessage(context, 'دوره درآمد معتبر نیست.');
        return;
      }

      if (!mounted) return;

      context.go('$_incomeBase/receivables/$periodId');
    } catch (error) {
      if (!mounted) return;

      _showMessage(context, 'خطا در بازکردن حساب‌های دریافتنی: $error');
    } finally {
      if (mounted) {
        setState(() {
          _incomeActionLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // EXPENSE DIRECT ACTION
  // ==========================================================

  Future<void> _openExpenseRecognition(BuildContext context) async {
    if (_expenseActionLoading) {
      return;
    }

    setState(() {
      _expenseActionLoading = true;
    });

    try {
      final client = Supabase.instance.client;

      final yearResponse = await client
          .from('expense_fiscal_years')
          .select('id, year, status')
          .eq('company_id', widget.companyId)
          .order('year', ascending: false)
          .limit(1)
          .maybeSingle();

      if (yearResponse == null) {
        if (!mounted) return;

        _showMessage(context, 'هنوز سال مالی هزینه ایجاد نشده است.');
        return;
      }

      final yearId = yearResponse['id']?.toString();

      if (yearId == null || yearId.isEmpty) {
        if (!mounted) return;

        _showMessage(context, 'سال مالی هزینه معتبر نیست.');
        return;
      }

      if (yearResponse['status']?.toString() == 'closed') {
        if (!mounted) return;

        _showMessage(
          context,
          'سال مالی هزینه بسته است و دوره بازی برای ثبت هزینه وجود ندارد.',
        );
        return;
      }

      final periodResponse = await client
          .from('expense_fiscal_periods')
          .select('id, fiscal_year_id, year, month, title, status')
          .eq('company_id', widget.companyId)
          .eq('fiscal_year_id', yearId)
          .eq('status', 'open')
          .order('month', ascending: true)
          .limit(1)
          .maybeSingle();

      if (periodResponse == null) {
        if (!mounted) return;

        _showMessage(
          context,
          'در این سال مالی هیچ دوره بازی برای ثبت هزینه وجود ندارد.',
        );
        return;
      }

      final periodId = periodResponse['id']?.toString();

      if (periodId == null || periodId.isEmpty) {
        if (!mounted) return;

        _showMessage(context, 'دوره هزینه معتبر نیست.');
        return;
      }

      if (!mounted) return;

      context.go('$_expenseBase/recognition/$periodId');
    } catch (error) {
      if (!mounted) return;

      _showMessage(context, 'خطا در بازکردن ثبت هزینه: $error');
    } finally {
      if (mounted) {
        setState(() {
          _expenseActionLoading = false;
        });
      }
    }
  }

  Future<void> _openExpenseReport(BuildContext context) async {
    if (_expenseActionLoading) {
      return;
    }

    setState(() {
      _expenseActionLoading = true;
    });

    try {
      final client = Supabase.instance.client;

      final periodResponse = await client
          .from('expense_fiscal_periods')
          .select('id, year, month, title, status')
          .eq('company_id', widget.companyId)
          .order('year', ascending: false)
          .order('month', ascending: false)
          .limit(1)
          .maybeSingle();

      if (periodResponse == null) {
        if (!mounted) return;

        _showMessage(
          context,
          'هنوز دوره مالی هزینه‌ای ثبت نشده است؛ ابتدا از بخش دوره‌های مالی هزینه، دوره ایجاد کنید.',
        );
        return;
      }

      final periodId = periodResponse['id']?.toString();

      if (periodId == null || periodId.isEmpty) {
        if (!mounted) return;

        _showMessage(context, 'شناسه دوره مالی هزینه معتبر نیست.');
        return;
      }

      if (!mounted) return;

      context.go('$_expenseReportsRoute/$periodId');
    } catch (error) {
      if (!mounted) return;

      _showMessage(context, 'خطا در بازکردن گزارش ماهانه هزینه: $error');
    } finally {
      if (mounted) {
        setState(() {
          _expenseActionLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textDirection: TextDirection.rtl,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================================
  // ROUTE HELPERS
  // ==========================================================

  bool _isBankingRoute() {
    return widget.currentRoute == _bankingBase ||
        widget.currentRoute.startsWith('$_bankingBase/');
  }

  bool _isBankingSubRoute(String route) {
    return widget.currentRoute == route;
  }

  bool _isPayrollRoute() {
    return widget.currentRoute == _payrollBase ||
        widget.currentRoute.startsWith('$_payrollBase/');
  }

  bool _isPayrollSubRoute(String route) {
    return widget.currentRoute == route;
  }

  bool _isIncomeRoute() {
    return widget.currentRoute == _incomeBase ||
        widget.currentRoute.startsWith('$_incomeBase/');
  }

  bool _isIncomeSubRoute(String route) {
    return widget.currentRoute == route;
  }

  bool _isIncomeRecognitionRoute() {
    return widget.currentRoute.startsWith(
      '$_incomeBase/recognition/',
    );
  }

  bool _isIncomeReceivablesRoute() {
    return widget.currentRoute.startsWith(
      '$_incomeBase/receivables/',
    );
  }

  bool _isExpenseRoute() {
    return widget.currentRoute == _expenseBase ||
        widget.currentRoute.startsWith('$_expenseBase/');
  }

  bool _isExpenseSubRoute(String route) {
    return widget.currentRoute == route;
  }

  bool _isExpenseRecognitionRoute() {
    return widget.currentRoute.startsWith(
      '$_expenseBase/recognition/',
    );
  }

  bool _isExpenseReportRoute() {
    return widget.currentRoute.startsWith(
      '$_expenseBase/reports/',
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(
      companyProvider(widget.companyId),
    );

    final bankingSelected = _isBankingRoute();
    final payrollSelected = _isPayrollRoute();
    final incomeSelected = _isIncomeRoute();
    final expenseSelected = _isExpenseRoute();

    return Container(
      width: 250,
      color: const Color(0xFF163A2B),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),

            // ==================================================
            // COMPANY ICON
            // ==================================================

            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.business_rounded,
                color: Color(0xFF1B4332),
                size: 38,
              ),
            ),

            const SizedBox(height: 13),

            const Text(
              'شرکت انتخاب شده',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 5),

            companyAsync.when(
              loading: () {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    'درحال بارگذاری...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              },
              error: (error, stackTrace) {
                return const Text(
                  'شرکت',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                );
              },
              data: (company) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                  ),
                  child: Text(
                    company.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // ==================================================
            // MENU
            // ==================================================

            Expanded(
              child: Scrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      // ==================================================
                      // OVERVIEW
                      // ==================================================

                      _Item(
                        icon: Icons.dashboard_rounded,
                        title: 'نمای کلی',
                        route: _companyBase,
                        currentRoute: widget.currentRoute,
                        onTap: _go,
                      ),

                      // ==================================================
                      // BANKING
                      // ==================================================

                      _ParentItem(
                        icon: Icons.account_balance_rounded,
                        title: 'بانک و نقد',
                        selected: bankingSelected,
                        expanded: _bankingExpanded,
                        onTap: () {
                          setState(() {
                            _bankingExpanded = !_bankingExpanded;
                          });
                        },
                      ),

                      if (_bankingExpanded) ...[
                        _SubItem(
                          icon: Icons.dashboard_customize_rounded,
                          title: 'داشبورد بانک و نقد',
                          route: _bankingBase,
                          selected: _isBankingSubRoute(
                            _bankingBase,
                          ),
                          onTap: () {
                            _go(context, _bankingBase);
                          },
                        ),
                        _SubItem(
                          icon: Icons.account_balance_rounded,
                          title: 'حساب‌های بانکی',
                          route: '$_bankingBase/accounts',
                          selected: _isBankingSubRoute(
                            '$_bankingBase/accounts',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_bankingBase/accounts',
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.point_of_sale_rounded,
                          title: 'صندوق‌ها',
                          route: '$_bankingBase/cash-boxes',
                          selected: _isBankingSubRoute(
                            '$_bankingBase/cash-boxes',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_bankingBase/cash-boxes',
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.account_balance_wallet_rounded,
                          title: 'تنخواه',
                          route: '$_bankingBase/petty-cash',
                          selected: _isBankingSubRoute(
                            '$_bankingBase/petty-cash',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_bankingBase/petty-cash',
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.calendar_month_rounded,
                          title: 'دوره‌های مالی',
                          route: '$_bankingBase/fiscal-periods',
                          selected: _isBankingSubRoute(
                            '$_bankingBase/fiscal-periods',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_bankingBase/fiscal-periods',
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.request_quote_rounded,
                          title: 'تسهیلات بانکی',
                          route: '$_bankingBase/loans',
                          selected: _isBankingSubRoute(
                            '$_bankingBase/loans',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_bankingBase/loans',
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.call_received_rounded,
                          title: 'چک‌های دریافتی',
                          route:
                          '$_bankingBase/received-checks',
                          selected: _isBankingSubRoute(
                            '$_bankingBase/received-checks',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_bankingBase/received-checks',
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.call_made_rounded,
                          title: 'چک‌های پرداختی',
                          route:
                          '$_bankingBase/paid-checks',
                          selected: _isBankingSubRoute(
                            '$_bankingBase/paid-checks',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_bankingBase/paid-checks',
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.assessment_outlined,
                          title: 'گزارش‌های بانکی',
                          route: '$_bankingBase/reports',
                          selected: _isBankingSubRoute(
                            '$_bankingBase/reports',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_bankingBase/reports',
                            );
                          },
                        ),
                        _SubItem(
                          icon:
                          Icons.notifications_active_outlined,
                          title: 'هشدارهای مدیریتی',
                          route: '$_bankingBase/alerts',
                          selected: _isBankingSubRoute(
                            '$_bankingBase/alerts',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_bankingBase/alerts',
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 5),

                      // ==================================================
                      // PAYROLL
                      // ==================================================

                      _ParentItem(
                        icon: Icons.payments_rounded,
                        title: 'حقوق و دستمزد',
                        selected: payrollSelected,
                        expanded: _payrollExpanded,
                        onTap: () {
                          setState(() {
                            _payrollExpanded =
                            !_payrollExpanded;
                          });
                        },
                      ),

                      if (_payrollExpanded) ...[
                        _SubItem(
                          icon:
                          Icons.dashboard_customize_rounded,
                          title: 'داشبورد حقوق و دستمزد',
                          route: _payrollBase,
                          selected: _isPayrollSubRoute(
                            _payrollBase,
                          ),
                          onTap: () {
                            _go(context, _payrollBase);
                          },
                        ),
                        _SubItem(
                          icon: Icons.people_alt_rounded,
                          title: 'پرسنل',
                          route: '$_payrollBase/employees',
                          selected: _isPayrollSubRoute(
                            '$_payrollBase/employees',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_payrollBase/employees',
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.account_tree_rounded,
                          title: 'مراکز هزینه',
                          route:
                          '$_payrollBase/cost-centers',
                          selected: _isPayrollSubRoute(
                            '$_payrollBase/cost-centers',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_payrollBase/cost-centers',
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.description_rounded,
                          title: 'قراردادها',
                          route: '$_payrollBase/contracts',
                          selected: _isPayrollSubRoute(
                            '$_payrollBase/contracts',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_payrollBase/contracts',
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.calendar_month_rounded,
                          title: 'دوره‌های حقوق',
                          route: '$_payrollBase/periods',
                          selected: _isPayrollSubRoute(
                            '$_payrollBase/periods',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_payrollBase/periods',
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 5),

                      // ==================================================
                      // INCOME
                      // ==================================================

                      _ParentItem(
                        icon: Icons.trending_up_rounded,
                        title: 'درآمد',
                        selected: incomeSelected,
                        expanded: _incomeExpanded,
                        onTap: () {
                          setState(() {
                            _incomeExpanded =
                            !_incomeExpanded;
                          });
                        },
                      ),

                      if (_incomeExpanded) ...[
                        _SubItem(
                          icon:
                          Icons.dashboard_customize_rounded,
                          title: 'داشبورد درآمد',
                          route: _incomeBase,
                          selected: _isIncomeSubRoute(
                            _incomeBase,
                          ),
                          onTap: () {
                            _go(context, _incomeBase);
                          },
                        ),
                        _SubItem(
                          icon: Icons.calendar_month_rounded,
                          title: 'دوره‌های درآمد',
                          route: _incomePeriodsRoute,
                          selected: _isIncomeSubRoute(
                            _incomePeriodsRoute,
                          ),
                          onTap: () {
                            _go(
                              context,
                              _incomePeriodsRoute,
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.fact_check_rounded,
                          title: 'ثبت درآمد ماهانه',
                          route:
                          '$_incomeBase/recognition',
                          selected:
                          _isIncomeRecognitionRoute(),
                          loading: _incomeActionLoading,
                          onTap: () {
                            _openIncomeRecognition(
                              context,
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.receipt_long_rounded,
                          title: 'حساب‌های دریافتنی',
                          route:
                          '$_incomeBase/receivables',
                          selected:
                          _isIncomeReceivablesRoute(),
                          loading: _incomeActionLoading,
                          onTap: () {
                            _openIncomeReceivables(
                              context,
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.category_rounded,
                          title: 'دسته‌بندی درآمد',
                          route:
                          '$_incomeBase/categories',
                          selected: _isIncomeSubRoute(
                            '$_incomeBase/categories',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_incomeBase/categories',
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.assessment_outlined,
                          title: 'گزارش ماهانه درآمد',
                          route: '$_incomeBase/reports',
                          selected: _isIncomeSubRoute(
                            '$_incomeBase/reports',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_incomeBase/reports',
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 5),

                      // ==================================================
                      // EXPENSES
                      // ==================================================

                      _ParentItem(
                        icon: Icons.payments_outlined,
                        title: 'هزینه‌ها',
                        selected: expenseSelected,
                        expanded: _expenseExpanded,
                        onTap: () {
                          setState(() {
                            _expenseExpanded =
                            !_expenseExpanded;
                          });
                        },
                      ),

                      if (_expenseExpanded) ...[
                        _SubItem(
                          icon:
                          Icons.dashboard_customize_rounded,
                          title: 'داشبورد هزینه‌ها',
                          route: _expenseBase,
                          selected: _isExpenseSubRoute(
                            _expenseBase,
                          ),
                          onTap: () {
                            _go(context, _expenseBase);
                          },
                        ),
                        _SubItem(
                          icon: Icons.calendar_month_rounded,
                          title: 'دوره‌های مالی هزینه',
                          route: _expensePeriodsRoute,
                          selected: _isExpenseSubRoute(
                            _expensePeriodsRoute,
                          ),
                          onTap: () {
                            _go(
                              context,
                              _expensePeriodsRoute,
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.fact_check_rounded,
                          title: 'ثبت هزینه ماهانه',
                          route:
                          '$_expenseBase/recognition',
                          selected:
                          _isExpenseRecognitionRoute(),
                          loading: _expenseActionLoading,
                          onTap: () {
                            _openExpenseRecognition(
                              context,
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.category_outlined,
                          title: 'دسته‌بندی هزینه‌ها',
                          route:
                          '$_expenseBase/categories',
                          selected: _isExpenseSubRoute(
                            '$_expenseBase/categories',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_expenseBase/categories',
                            );
                          },
                        ),
                        _SubItem(
                          icon:
                          Icons.receipt_long_outlined,
                          title: 'رکوردهای هزینه',
                          route:
                          '$_expenseBase/records',
                          selected: _isExpenseSubRoute(
                            '$_expenseBase/records',
                          ),
                          onTap: () {
                            _go(
                              context,
                              '$_expenseBase/records',
                            );
                          },
                        ),
                        _SubItem(
                          icon: Icons.assessment_outlined,
                          title: 'گزارش ماهانه هزینه',
                          route: _expenseReportsRoute,
                          selected: _isExpenseReportRoute(),
                          loading: _expenseActionLoading,
                          onTap: () {
                            _openExpenseReport(context);
                          },
                        ),
                      ],

                      const SizedBox(height: 5),

                      // ==================================================
                      // FINANCIAL ANALYSIS
                      // ==================================================

                      _Item(
                        icon: Icons.analytics_rounded,
                        title: 'تحلیل مالی',
                        route:
                        '$_companyBase/financial-analysis',
                        currentRoute: widget.currentRoute,
                        onTap: _go,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ==================================================
            // BACK TO COMPANIES
            // ==================================================

            const Divider(
              height: 1,
              color: Colors.white12,
            ),

            const SizedBox(height: 8),

            _Item(
              icon: Icons.arrow_back_rounded,
              title: 'بازگشت به شرکت‌ها',
              route: '/consultant/companies',
              currentRoute: widget.currentRoute,
              onTap: _go,
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PARENT ITEM
// ============================================================

class _ParentItem extends StatelessWidget {
  const _ParentItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Material(
        color: selected
            ? Colors.white.withOpacity(.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 21,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? .5 : 0,
                  duration:
                  const Duration(milliseconds: 180),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                    size: 21,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MAIN ITEM
// ============================================================

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.title,
    required this.route,
    required this.currentRoute,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String route;
  final String currentRoute;
  final Function(BuildContext, String) onTap;

  @override
  Widget build(BuildContext context) {
    final selected = currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
      child: Material(
        color: selected
            ? Colors.white.withOpacity(.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            onTap(context, route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 13,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 21,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SUB ITEM
// ============================================================

class _SubItem extends StatelessWidget {
  const _SubItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.selected,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String route;
  final bool selected;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 24,
        right: 20,
        top: 2,
        bottom: 2,
      ),
      child: Material(
        color: selected
            ? Colors.white.withOpacity(.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: loading ? null : onTap,
          child: AnimatedContainer(
            duration:
            const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: selected
                  ? Border.all(
                color:
                Colors.white.withOpacity(.06),
              )
                  : null,
            ),
            child: Row(
              children: [
                if (loading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  )
                else
                  Icon(
                    icon,
                    color: selected
                        ? Colors.white
                        : Colors.white60,
                    size: 18,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.white70,
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}