import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  // BANKING
  // ==========================================================

  bool _isBankingRoute() {
    final base = '/consultant/companies/${widget.companyId}/banking';

    return widget.currentRoute == base ||
        widget.currentRoute.startsWith('$base/');
  }

  bool _isBankingSubRoute(String route) {
    return widget.currentRoute == route;
  }

  // ==========================================================
  // PAYROLL
  // ==========================================================

  bool _isPayrollRoute() {
    final base = '/consultant/companies/${widget.companyId}/payroll';

    return widget.currentRoute == base ||
        widget.currentRoute.startsWith('$base/');
  }

  bool _isPayrollSubRoute(String route) {
    return widget.currentRoute == route;
  }

  // ==========================================================
  // INCOME
  // ==========================================================

  bool _isIncomeRoute() {
    final base = '/consultant/companies/${widget.companyId}/income';

    return widget.currentRoute == base ||
        widget.currentRoute.startsWith('$base/');
  }

  bool _isIncomeSubRoute(String route) {
    return widget.currentRoute == route;
  }

  // ==========================================================
  // EXPENSE
  // ==========================================================

  bool _isExpenseRoute() {
    final base = '/consultant/companies/${widget.companyId}/expenses';

    return widget.currentRoute == base ||
        widget.currentRoute.startsWith('$base/');
  }

  bool _isExpenseSubRoute(String route) {
    return widget.currentRoute == route;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyProvider(widget.companyId));

    final bankingSelected = _isBankingRoute();
    final payrollSelected = _isPayrollRoute();
    final incomeSelected = _isIncomeRoute();
    final expenseSelected = _isExpenseRoute();

    return Container(
      width: 250,
      color: const Color(0xFF163A2B),
      child: Column(
        children: [
          const SizedBox(height: 30),

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

          const SizedBox(height: 15),

          const Text(
            'شرکت انتخاب شده',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),

          const SizedBox(height: 5),

          companyAsync.when(
            loading: () {
              return const Text(
                'درحال بارگذاری...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
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
                padding: const EdgeInsets.symmetric(horizontal: 14),
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

          const SizedBox(height: 28),

          // ==================================================
          // MENU
          // ==================================================
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ==================================================
                  // OVERVIEW
                  // ==================================================
                  _Item(
                    icon: Icons.dashboard_rounded,
                    title: 'نمای کلی',
                    route: '/consultant/companies/${widget.companyId}',
                    currentRoute: widget.currentRoute,
                    onTap: _go,
                  ),

                  // ==================================================
                  // BANKING PARENT
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
                      route:
                          '/consultant/companies/${widget.companyId}/banking',
                      selected: _isBankingSubRoute(
                        '/consultant/companies/${widget.companyId}/banking',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/banking',
                        );
                      },
                    ),
                    _SubItem(
                      icon: Icons.account_balance_rounded,
                      title: 'حساب‌های بانکی',
                      route:
                          '/consultant/companies/${widget.companyId}/banking/accounts',
                      selected: _isBankingSubRoute(
                        '/consultant/companies/${widget.companyId}/banking/accounts',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/banking/accounts',
                        );
                      },
                    ),
                    _SubItem(
                      icon: Icons.point_of_sale_rounded,
                      title: 'صندوق‌ها',
                      route:
                          '/consultant/companies/${widget.companyId}/banking/cash-boxes',
                      selected: _isBankingSubRoute(
                        '/consultant/companies/${widget.companyId}/banking/cash-boxes',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/banking/cash-boxes',
                        );
                      },
                    ),
                    _SubItem(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'تنخواه',
                      route:
                          '/consultant/companies/${widget.companyId}/banking/petty-cash',
                      selected: _isBankingSubRoute(
                        '/consultant/companies/${widget.companyId}/banking/petty-cash',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/banking/petty-cash',
                        );
                      },
                    ),
                    _SubItem(
                      icon: Icons.request_quote_rounded,
                      title: 'تسهیلات بانکی',
                      route:
                          '/consultant/companies/${widget.companyId}/banking/loans',
                      selected: _isBankingSubRoute(
                        '/consultant/companies/${widget.companyId}/banking/loans',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/banking/loans',
                        );
                      },
                    ),
                    _SubItem(
                      icon: Icons.call_received_rounded,
                      title: 'چک‌های دریافتی',
                      route:
                          '/consultant/companies/${widget.companyId}/banking/received-checks',
                      selected: _isBankingSubRoute(
                        '/consultant/companies/${widget.companyId}/banking/received-checks',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/banking/received-checks',
                        );
                      },
                    ),
                    _SubItem(
                      icon: Icons.call_made_rounded,
                      title: 'چک‌های پرداختی',
                      route:
                          '/consultant/companies/${widget.companyId}/banking/paid-checks',
                      selected: _isBankingSubRoute(
                        '/consultant/companies/${widget.companyId}/banking/paid-checks',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/banking/paid-checks',
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 4),

                  // ==================================================
                  // PAYROLL PARENT
                  // ==================================================
                  _ParentItem(
                    icon: Icons.payments_rounded,
                    title: 'حقوق و دستمزد',
                    selected: payrollSelected,
                    expanded: _payrollExpanded,
                    onTap: () {
                      setState(() {
                        _payrollExpanded = !_payrollExpanded;
                      });
                    },
                  ),

                  if (_payrollExpanded) ...[
                    _SubItem(
                      icon: Icons.dashboard_customize_rounded,
                      title: 'داشبورد حقوق و دستمزد',
                      route:
                          '/consultant/companies/${widget.companyId}/payroll',
                      selected: _isPayrollSubRoute(
                        '/consultant/companies/${widget.companyId}/payroll',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/payroll',
                        );
                      },
                    ),
                    _SubItem(
                      icon: Icons.people_alt_rounded,
                      title: 'پرسنل',
                      route:
                          '/consultant/companies/${widget.companyId}/payroll/employees',
                      selected: _isPayrollSubRoute(
                        '/consultant/companies/${widget.companyId}/payroll/employees',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/payroll/employees',
                        );
                      },
                    ),
                    _SubItem(
                      icon: Icons.account_tree_rounded,
                      title: 'مراکز هزینه',
                      route:
                          '/consultant/companies/${widget.companyId}/payroll/cost-centers',
                      selected: _isPayrollSubRoute(
                        '/consultant/companies/${widget.companyId}/payroll/cost-centers',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/payroll/cost-centers',
                        );
                      },
                    ),
                    _SubItem(
                      icon: Icons.description_rounded,
                      title: 'قراردادها',
                      route:
                          '/consultant/companies/${widget.companyId}/payroll/contracts',
                      selected: _isPayrollSubRoute(
                        '/consultant/companies/${widget.companyId}/payroll/contracts',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/payroll/contracts',
                        );
                      },
                    ),
                    _SubItem(
                      icon: Icons.calendar_month_rounded,
                      title: 'دوره‌های حقوق',
                      route:
                          '/consultant/companies/${widget.companyId}/payroll/periods',
                      selected: _isPayrollSubRoute(
                        '/consultant/companies/${widget.companyId}/payroll/periods',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/payroll/periods',
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 4),

                  // ==================================================
                  // INCOME PARENT
                  // ==================================================
                  _ParentItem(
                    icon: Icons.trending_up_rounded,
                    title: 'درآمد',
                    selected: incomeSelected,
                    expanded: _incomeExpanded,
                    onTap: () {
                      setState(() {
                        _incomeExpanded = !_incomeExpanded;
                      });
                    },
                  ),

                  if (_incomeExpanded) ...[
                    _SubItem(
                      icon: Icons.dashboard_customize_rounded,
                      title: 'داشبورد درآمد',
                      route: '/consultant/companies/${widget.companyId}/income',
                      selected: _isIncomeSubRoute(
                        '/consultant/companies/${widget.companyId}/income',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/income',
                        );
                      },
                    ),
                    _SubItem(
                      icon: Icons.trending_up_rounded,
                      title: 'درآمدها',
                      route:
                          '/consultant/companies/${widget.companyId}/income/records',
                      selected: _isIncomeSubRoute(
                        '/consultant/companies/${widget.companyId}/income/records',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/income/records',
                        );
                      },
                    ),
                    _SubItem(
                      icon: Icons.category_rounded,
                      title: 'دسته‌بندی درآمد',
                      route:
                          '/consultant/companies/${widget.companyId}/income/categories',
                      selected: _isIncomeSubRoute(
                        '/consultant/companies/${widget.companyId}/income/categories',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/income/categories',
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 4),

                  // ==================================================
                  // EXPENSE PARENT
                  // ==================================================
                  _ParentItem(
                    icon: Icons.payments_outlined,
                    title: 'هزینه‌ها',
                    selected: expenseSelected,
                    expanded: _expenseExpanded,
                    onTap: () {
                      setState(() {
                        _expenseExpanded = !_expenseExpanded;
                      });
                    },
                  ),

                  if (_expenseExpanded) ...[
                    _SubItem(
                      icon: Icons.dashboard_customize_rounded,
                      title: 'داشبورد هزینه‌ها',
                      route:
                          '/consultant/companies/${widget.companyId}/expenses',
                      selected: _isExpenseSubRoute(
                        '/consultant/companies/${widget.companyId}/expenses',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/expenses',
                        );
                      },
                    ),
                    _SubItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'ثبت و مدیریت هزینه‌ها',
                      route:
                          '/consultant/companies/${widget.companyId}/expenses/records',
                      selected: _isExpenseSubRoute(
                        '/consultant/companies/${widget.companyId}/expenses/records',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/expenses/records',
                        );
                      },
                    ),
                    _SubItem(
                      icon: Icons.category_outlined,
                      title: 'دسته‌بندی هزینه‌ها',
                      route:
                          '/consultant/companies/${widget.companyId}/expenses/categories',
                      selected: _isExpenseSubRoute(
                        '/consultant/companies/${widget.companyId}/expenses/categories',
                      ),
                      onTap: () {
                        _go(
                          context,
                          '/consultant/companies/${widget.companyId}/expenses/categories',
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 4),

                  // ==================================================
                  // ANALYTICS
                  // ==================================================
                  _Item(
                    icon: Icons.analytics_rounded,
                    title: 'تحلیل مالی',
                    route:
                        '/consultant/companies/${widget.companyId}/financial-analysis',
                    currentRoute: widget.currentRoute,
                    onTap: _go,
                  ),

                  // ==================================================
                  // REPORTS
                  // ==================================================
                  // _Item(
                  //   icon: Icons.description_rounded,
                  //   title: 'گزارش‌ها',
                  //   route: '/consultant/companies/${widget.companyId}/reports',
                  //   currentRoute: widget.currentRoute,
                  //   onTap: _go,
                  // ),

                  // ==================================================
                  // ACTIONS
                  // ==================================================
                  // _Item(
                  //   icon: Icons.task_alt_rounded,
                  //   title: 'اقدامات',
                  //   route: '/consultant/companies/${widget.companyId}/actions',
                  //   currentRoute: widget.currentRoute,
                  //   onTap: _go,
                  // ),

                  // ==================================================
                  // DOCUMENTS
                  // ==================================================
                  // _Item(
                  //   icon: Icons.folder_open_rounded,
                  //   title: 'اسناد و مدارک',
                  //   route:
                  //       '/consultant/companies/${widget.companyId}/documents',
                  //   currentRoute: widget.currentRoute,
                  //   onTap: _go,
                  // ),

                  // ==================================================
                  // NOTES
                  // ==================================================
                  _Item(
                    icon: Icons.note_alt_rounded,
                    title: 'یادداشت‌های مشاور',
                    route: '/consultant/companies/${widget.companyId}/notes',
                    currentRoute: widget.currentRoute,
                    onTap: _go,
                  ),
                ],
              ),
            ),
          ),

          // ==================================================
          // BACK
          // ==================================================
          _Item(
            icon: Icons.arrow_back_rounded,
            title: 'بازگشت به شرکت‌ها',
            route: '/consultant/companies',
            currentRoute: widget.currentRoute,
            onTap: _go,
          ),

          const SizedBox(height: 20),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Material(
        color: selected ? Colors.white.withOpacity(.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 21),
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
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70,
                  size: 21,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Material(
        color: selected ? Colors.white.withOpacity(.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            onTap(context, route);
          },
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 21),
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
  });

  final IconData icon;
  final String title;
  final String route;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 20, top: 2, bottom: 2),
      child: Material(
        color: selected ? Colors.white.withOpacity(.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : Colors.white60,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
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
