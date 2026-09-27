import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountantSidebar extends StatefulWidget {
  final String currentRoute;

  const AccountantSidebar({super.key, required this.currentRoute});

  @override
  State<AccountantSidebar> createState() => _AccountantSidebarState();
}

class _AccountantSidebarState extends State<AccountantSidebar> {
  bool _bankingExpanded = false;
  bool _payrollExpanded = false;
  bool _incomeExpanded = false;
  bool _expenseExpanded = false;

  @override
  void initState() {
    super.initState();
    _syncExpandedSections();
  }

  @override
  void didUpdateWidget(covariant AccountantSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentRoute != widget.currentRoute) {
      _syncExpandedSections();
    }
  }

  void _syncExpandedSections() {
    final route = widget.currentRoute;

    _bankingExpanded = route.startsWith('/accountant/banking');

    _payrollExpanded = route.startsWith('/accountant/payroll');

    _incomeExpanded = route.startsWith('/accountant/income');

    _expenseExpanded = route.startsWith('/accountant/expenses');
  }

  void _go(String route) {
    context.go(route);
  }

  bool _isActive(String route) {
    return widget.currentRoute == route;
  }

  bool _isSectionActive(String prefix) {
    return widget.currentRoute.startsWith(prefix);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 12,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                children: [
                  _buildSectionTitle('اصلی'),

                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    title: 'داشبورد',
                    route: '/accountant',
                  ),

                  const SizedBox(height: 8),

                  _buildSectionTitle('عملیات مالی'),

                  _buildExpandableSection(
                    context,
                    icon: Icons.account_balance_outlined,
                    title: 'نقد و بانک',
                    expanded: _bankingExpanded,
                    active: _isSectionActive('/accountant/banking'),
                    onExpansionChanged: (value) {
                      setState(() {
                        _bankingExpanded = value;
                      });
                    },
                    children: [
                      _buildChildItem(
                        context,
                        title: 'داشبورد بانک و نقد',
                        route: '/accountant/banking',
                      ),
                      _buildChildItem(
                        context,
                        title: 'حساب‌های بانکی',
                        route: '/accountant/banking/accounts',
                      ),
                      _buildChildItem(
                        context,
                        title: 'صندوق‌ها',
                        route: '/accountant/banking/cash-boxes',
                      ),
                      _buildChildItem(
                        context,
                        title: 'تنخواه',
                        route: '/accountant/banking/petty-cash',
                      ),
                      _buildChildItem(
                        context,
                        title: 'تسهیلات بانکی',
                        route: '/accountant/banking/loans',
                      ),
                      _buildChildItem(
                        context,
                        title: 'چک‌های دریافتی',
                        route: '/accountant/banking/received-checks',
                      ),
                      _buildChildItem(
                        context,
                        title: 'چک‌های پرداختی',
                        route: '/accountant/banking/paid-checks',
                      ),
                      _buildChildItem(
                        context,
                        title: 'دوره‌های مالی',
                        route: '/accountant/banking/fiscal-periods',
                      ),
                      _buildChildItem(
                        context,
                        title: 'گزارش‌های بانکی',
                        route: '/accountant/banking/reports',
                      ),
                    ],
                  ),

                  _buildExpandableSection(
                    context,
                    icon: Icons.groups_outlined,
                    title: 'حقوق و دستمزد',
                    expanded: _payrollExpanded,
                    active: _isSectionActive('/accountant/payroll'),
                    onExpansionChanged: (value) {
                      setState(() {
                        _payrollExpanded = value;
                      });
                    },
                    children: [
                      _buildChildItem(
                        context,
                        title: 'داشبورد حقوق',
                        route: '/accountant/payroll',
                      ),
                      _buildChildItem(
                        context,
                        title: 'کارکنان',
                        route: '/accountant/payroll/employees',
                      ),
                      _buildChildItem(
                        context,
                        title: 'قراردادها',
                        route: '/accountant/payroll/contracts',
                      ),
                      _buildChildItem(
                        context,
                        title: 'دوره‌های حقوق',
                        route: '/accountant/payroll/periods',
                      ),
                      _buildChildItem(
                        context,
                        title: 'مراکز هزینه',
                        route: '/accountant/payroll/cost-centers',
                      ),
                    ],
                  ),

                  _buildExpandableSection(
                    context,
                    icon: Icons.trending_up_outlined,
                    title: 'درآمد',
                    expanded: _incomeExpanded,
                    active: _isSectionActive('/accountant/income'),
                    onExpansionChanged: (value) {
                      setState(() {
                        _incomeExpanded = value;
                      });
                    },
                    children: [
                      _buildChildItem(
                        context,
                        title: 'داشبورد درآمد',
                        route: '/accountant/income',
                      ),
                      _buildChildItem(
                        context,
                        title: 'دوره‌های مالی',
                        route: '/accountant/income/periods',
                      ),
                      _buildChildItem(
                        context,
                        title: 'دسته‌بندی‌ها',
                        route: '/accountant/income/categories',
                      ),
                      _buildChildItem(
                        context,
                        title: 'ثبت درآمد',
                        route: '/accountant/income/recognition',
                      ),
                      _buildChildItem(
                        context,
                        title: 'مطالبات',
                        route: '/accountant/income/receivables',
                      ),
                      _buildChildItem(
                        context,
                        title: 'گزارش درآمد',
                        route: '/accountant/income/reports',
                      ),
                    ],
                  ),

                  _buildExpandableSection(
                    context,
                    icon: Icons.trending_down_outlined,
                    title: 'هزینه',
                    expanded: _expenseExpanded,
                    active: _isSectionActive('/accountant/expenses'),
                    onExpansionChanged: (value) {
                      setState(() {
                        _expenseExpanded = value;
                      });
                    },
                    children: [
                      _buildChildItem(
                        context,
                        title: 'داشبورد هزینه',
                        route: '/accountant/expenses',
                      ),
                      _buildChildItem(
                        context,
                        title: 'دوره‌های مالی',
                        route: '/accountant/expenses/periods',
                      ),
                      _buildChildItem(
                        context,
                        title: 'دسته‌بندی‌ها',
                        route: '/accountant/expenses/categories',
                      ),
                      _buildChildItem(
                        context,
                        title: 'ثبت هزینه',
                        route: '/accountant/expenses/recognition',
                      ),
                      _buildChildItem(
                        context,
                        title: 'گزارش هزینه',
                        route: '/accountant/expenses/reports',
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _buildSectionTitle('سیستم'),

                  _buildMenuItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'حساب کاربری',
                    route: '/accountant/settings',
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: theme.colorScheme.primary.withOpacity(.10),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: theme.colorScheme.primary,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ترازیار',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'پنل حسابدار',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final active = _isActive(route);
    final theme = Theme.of(context);

    return Material(
      color:
          active
              ? theme.colorScheme.primary.withOpacity(.10)
              : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _go(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 21,
                color:
                    active ? theme.colorScheme.primary : Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color:
                        active
                            ? theme.colorScheme.primary
                            : Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool expanded,
    required bool active,
    required ValueChanged<bool> onExpansionChanged,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey<String>('accountant-$title'),
        initiallyExpanded: expanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 13),
        childrenPadding: const EdgeInsets.only(right: 18, left: 4, bottom: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor:
            active
                ? theme.colorScheme.primary.withOpacity(.05)
                : Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        leading: Icon(
          icon,
          size: 21,
          color: active ? theme.colorScheme.primary : Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? theme.colorScheme.primary : Colors.grey.shade800,
          ),
        ),
        iconColor: theme.colorScheme.primary,
        collapsedIconColor: Colors.grey.shade600,
        children: children,
      ),
    );
  }

  Widget _buildChildItem(
    BuildContext context, {
    required String title,
    required String route,
  }) {
    final active = _isActive(route);
    final theme = Theme.of(context);

    return Material(
      color:
          active
              ? theme.colorScheme.primary.withOpacity(.08)
              : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _go(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      active ? theme.colorScheme.primary : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    color:
                        active
                            ? theme.colorScheme.primary
                            : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await Supabase.instance.client.auth.signOut();

            if (!context.mounted) {
              return;
            }

            context.go('/login');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.logout_outlined,
                  size: 21,
                  color: Colors.red.shade600,
                ),
                const SizedBox(width: 12),
                Text(
                  'خروج از حساب',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade600,
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
