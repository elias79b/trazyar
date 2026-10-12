import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyAdminScaffold extends StatelessWidget {
  final Widget child;

  const CompanyAdminScaffold({
    super.key,
    required this.child,
  });

  static const Color primaryGreen = Color(0xFF167A4A);
  static const Color lightGreen = Color(0xFFEAF7F0);
  static const Color background = Color(0xFFF6F8F7);
  static const Color border = Color(0xFFE2E8E5);
  static const Color textDark = Color(0xFF17221D);
  static const Color textMuted = Color(0xFF718078);

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'خروج از حساب',
          ),
          content: const Text(
            'آیا مطمئن هستید که می‌خواهید از حساب کاربری خود خارج شوید؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'انصراف',
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(
                Icons.logout_rounded,
              ),
              label: const Text(
                'خروج',
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    // ------------------------------------------------------------
    // نمایش Loading
    // ------------------------------------------------------------

    if (!context.mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'در حال خروج از حساب...',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // ----------------------------------------------------------
      // خروج واقعی از Supabase Auth
      // ----------------------------------------------------------

      await Supabase.instance.client.auth.signOut();

      if (!context.mounted) {
        return;
      }

      // ----------------------------------------------------------
      // بستن Loading
      // ----------------------------------------------------------

      Navigator.of(context).pop();

      // ----------------------------------------------------------
      // انتقال به صفحه ورود
      // ----------------------------------------------------------

      context.go('/login');
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      // ----------------------------------------------------------
      // بستن Loading
      // ----------------------------------------------------------

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خروج از حساب انجام نشد: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        endDrawer: _buildMobileDrawer(context),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktop =
                constraints.maxWidth >= 1000;

            if (isDesktop) {
              return Row(
                textDirection: TextDirection.ltr,
                children: [
                  Expanded(
                    child: child,
                  ),
                  SizedBox(
                    width: 300,
                    child: _buildSidebar(context),
                  ),
                ],
              );
            }

            return child;
          },
        ),
      ),
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar(
      BuildContext context,
      ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(
            color: border,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            const Divider(
              height: 1,
              color: border,
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                children: [
                  // ========================================================
                  // مدیریت شرکت
                  // ========================================================

                  _sectionTitle(
                    'مدیریت شرکت',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    title: 'داشبورد مدیرعامل',
                    route: '/company-admin',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.business_rounded,
                    title: 'اطلاعات شرکت',
                    route: '/company-admin/company',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.people_alt_rounded,
                    title: 'کاربران شرکت',
                    route: '/company-admin/users',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.security_rounded,
                    title: 'نقش‌ها و دسترسی‌ها',
                    route: '/company-admin/permissions',
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // ========================================================
                  // امور مالی
                  // ========================================================

                  _sectionTitle(
                    'امور مالی',
                  ),

                  // --------------------------------------------------------
                  // نقد و بانک
                  // --------------------------------------------------------

                  _moduleItem(
                    context,
                    icon: Icons.account_balance_rounded,
                    title: 'نقد و بانک',
                    route: '/company-admin/banking',
                    children: [
                      _subMenuItem(
                        context,
                        icon: Icons.dashboard_outlined,
                        title: 'نمای کلی',
                        route: '/company-admin/banking',
                      ),
                      _subMenuItem(
                        context,
                        icon: Icons.account_balance_outlined,
                        title: 'حساب‌های بانکی',
                        route:
                        '/company-admin/banking/accounts',
                      ),
                      _subMenuItem(
                        context,
                        icon:
                        Icons.account_balance_wallet_outlined,
                        title: 'صندوق‌ها',
                        route:
                        '/company-admin/banking/cash-boxes',
                      ),
                      _subMenuItem(
                        context,
                        icon: Icons.payments_outlined,
                        title: 'تنخواه',
                        route:
                        '/company-admin/banking/petty-cash',
                      ),
                      _subMenuItem(
                        context,
                        icon: Icons.credit_score_outlined,
                        title: 'وام‌ها',
                        route:
                        '/company-admin/banking/loans',
                      ),
                      _subMenuItem(
                        context,
                        icon:
                        Icons.call_received_outlined,
                        title: 'چک‌های دریافتی',
                        route:
                        '/company-admin/banking/received-checks',
                      ),
                      _subMenuItem(
                        context,
                        icon: Icons.call_made_outlined,
                        title: 'چک‌های پرداختی',
                        route:
                        '/company-admin/banking/paid-checks',
                      ),
                      _subMenuItem(
                        context,
                        icon:
                        Icons.calendar_month_outlined,
                        title: 'دوره‌های مالی',
                        route:
                        '/company-admin/banking/fiscal-periods',
                      ),
                      _subMenuItem(
                        context,
                        icon: Icons.bar_chart_outlined,
                        title: 'گزارش‌ها',
                        route:
                        '/company-admin/banking/reports',
                      ),
                    ],
                  ),

                  // --------------------------------------------------------
                  // حقوق و دستمزد
                  // --------------------------------------------------------

                  _moduleItem(
                    context,
                    icon: Icons.groups_rounded,
                    title: 'حقوق و دستمزد',
                    route: '/company-admin/payroll',
                    children: [
                      _subMenuItem(
                        context,
                        icon: Icons.dashboard_outlined,
                        title: 'نمای کلی',
                        route:
                        '/company-admin/payroll',
                      ),
                      _subMenuItem(
                        context,
                        icon: Icons.badge_outlined,
                        title: 'کارکنان',
                        route:
                        '/company-admin/payroll/employees',
                      ),
                      _subMenuItem(
                        context,
                        icon: Icons.description_outlined,
                        title: 'قراردادها',
                        route:
                        '/company-admin/payroll/contracts',
                      ),
                      _subMenuItem(
                        context,
                        icon:
                        Icons.calendar_month_outlined,
                        title: 'دوره‌های حقوق',
                        route:
                        '/company-admin/payroll/periods',
                      ),
                      _subMenuItem(
                        context,
                        icon:
                        Icons.account_tree_outlined,
                        title: 'مراکز هزینه',
                        route:
                        '/company-admin/payroll/cost-centers',
                      ),
                    ],
                  ),

                  // --------------------------------------------------------
                  // درآمد
                  // --------------------------------------------------------

                  _moduleItem(
                    context,
                    icon: Icons.trending_up_rounded,
                    title: 'درآمد',
                    route: '/company-admin/income',
                    children: [
                      _subMenuItem(
                        context,
                        icon: Icons.dashboard_outlined,
                        title: 'نمای کلی',
                        route:
                        '/company-admin/income',
                      ),
                      _subMenuItem(
                        context,
                        icon:
                        Icons.calendar_month_outlined,
                        title: 'دوره‌های درآمد',
                        route:
                        '/company-admin/income/periods',
                      ),
                      _subMenuItem(
                        context,
                        icon: Icons.category_outlined,
                        title: 'دسته‌بندی‌ها',
                        route:
                        '/company-admin/income/categories',
                      ),
                      _subMenuItem(
                        context,
                        icon: Icons.fact_check_outlined,
                        title: 'شناسایی درآمد',
                        route:
                        '/company-admin/income/recognitions',
                      ),
                      _subMenuItem(
                        context,
                        icon: Icons.receipt_long_outlined,
                        title: 'مطالبات',
                        route:
                        '/company-admin/income/receivables',
                      ),
                      _subMenuItem(
                        context,
                        icon: Icons.bar_chart_outlined,
                        title: 'گزارش‌ها',
                        route:
                        '/company-admin/income/reports',
                      ),
                    ],
                  ),

                  // --------------------------------------------------------
                  // هزینه
                  // --------------------------------------------------------

                  _moduleItem(
                    context,
                    icon: Icons.trending_down_rounded,
                    title: 'هزینه',
                    route: '/company-admin/expense',
                    children: [

                      _subMenuItem(
                        context,
                        icon: Icons.dashboard_outlined,
                        title: 'نمای کلی',
                        route: '/company-admin/expense',
                      ),

                      _subMenuItem(
                        context,
                        icon:
                        Icons.calendar_month_outlined,
                        title: 'دوره‌های هزینه',
                        route:
                        '/company-admin/expense/periods',
                      ),
                      _subMenuItem(
                        context,
                        icon: Icons.category_outlined,
                        title: 'دسته‌بندی‌ها',
                        route:
                        '/company-admin/expenses/categories',
                      ),
                      _subMenuItem(
                        context,
                        icon: Icons.fact_check_outlined,
                        title: 'شناسایی هزینه',
                        route:
                        '/company-admin/expenses/recognition',
                      ),
                      _subMenuItem(
                        context,
                        icon: Icons.receipt_long_outlined,
                        title: 'بدهی‌ها',
                        route:
                        '/company-admin/expenses/payables',
                      ),
                      _subMenuItem(
                        context,
                        icon: Icons.bar_chart_outlined,
                        title: 'گزارش‌ها',
                        route:
                        '/company-admin/expenses/reports',
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // ========================================================
                  // گزارش‌ها
                  // ========================================================

                  _sectionTitle(
                    'گزارش‌ها',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.bar_chart_rounded,
                    title: 'گزارش‌های مالی',
                    route: '/company-admin/reports',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.analytics_rounded,
                    title: 'گزارش مدیریتی',
                    route:
                    '/company-admin/management-reports',
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // ========================================================
                  // تنظیمات
                  // ========================================================

                  _sectionTitle(
                    'تنظیمات',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.settings_rounded,
                    title: 'تنظیمات شرکت',
                    route: '/company-admin/settings',
                  ),
                ],
              ),
            ),

            // ============================================================
            // FOOTER / LOGOUT
            // ============================================================

            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
      BuildContext context,
      ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        22,
        18,
        18,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: primaryGreen,
              size: 27,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'ترازیار',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                SizedBox(
                  height: 4,
                ),
                Text(
                  'پنل مدیرعامل',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter(
      BuildContext context,
      ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: border,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
          BorderRadius.circular(14),
          onTap: () {
            _logout(context);
          },
          child: Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFF3F5F4),
                    borderRadius:
                    BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color:
                    Color(0xFF66736C),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                const Expanded(
                  child: Text(
                    'خروج از حساب',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                      FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_left_rounded,
                  size: 20,
                  color: textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE DRAWER
  // ============================================================

  Widget _buildMobileDrawer(
      BuildContext context,
      ) {
    return Drawer(
      width: 310,
      child: _buildSidebar(context),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
      String title,
      ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        10,
        4,
        10,
        8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textMuted,
        ),
      ),
    );
  }

  // ============================================================
  // NORMAL MENU ITEM
  // ============================================================

  Widget _menuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String route,
      }) {
    final String currentLocation =
        GoRouterState.of(context).uri.path;

    final bool selected =
        currentLocation == route ||
            (route != '/company-admin' &&
                currentLocation
                    .startsWith('$route/'));

    return Padding(
      padding:
      const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? lightGreen
            : Colors.transparent,
        borderRadius:
        BorderRadius.circular(12),
        child: InkWell(
          borderRadius:
          BorderRadius.circular(12),
          onTap: () {
            if (currentLocation != route) {
              context.go(route);
            }

            final ScaffoldState? scaffold =
            Scaffold.maybeOf(context);

            if (scaffold?.isDrawerOpen ==
                true) {
              Navigator.of(context).pop();
            }
          },
          child: Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: selected
                      ? primaryGreen
                      : textMuted,
                ),
                const SizedBox(
                  width: 11,
                ),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: selected
                          ? primaryGreen
                          : textDark,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 5,
                    height: 22,
                    decoration:
                    BoxDecoration(
                      color: primaryGreen,
                      borderRadius:
                      BorderRadius.circular(
                        10,
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

  // ============================================================
  // MODULE
  // ============================================================

  Widget _moduleItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String route,
        required List<Widget> children,
      }) {
    final String currentLocation =
        GoRouterState.of(context).uri.path;

    final bool active =
        currentLocation == route ||
            currentLocation
                .startsWith('$route/');

    return Padding(
      padding:
      const EdgeInsets.only(bottom: 4),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor:
          Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: active,
          tilePadding:
          const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          childrenPadding:
          const EdgeInsets.only(
            right: 18,
            left: 4,
            bottom: 4,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
          collapsedShape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
          backgroundColor: active
              ? lightGreen
              : Colors.transparent,
          collapsedBackgroundColor:
          Colors.transparent,
          iconColor: primaryGreen,
          collapsedIconColor: textMuted,
          leading: Icon(
            icon,
            size: 21,
            color: active
                ? primaryGreen
                : textMuted,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active
                  ? FontWeight.w800
                  : FontWeight.w600,
              color: active
                  ? primaryGreen
                  : textDark,
            ),
          ),
          onExpansionChanged: (_) {},
          children: children,
        ),
      ),
    );
  }

  // ============================================================
  // SUB MENU ITEM
  // ============================================================

  Widget _subMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String route,
      }) {
    final String currentLocation =
        GoRouterState.of(context).uri.path;

    final bool selected =
        currentLocation == route ||
            currentLocation
                .startsWith('$route/');

    return Padding(
      padding:
      const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected
            ? lightGreen
            : Colors.transparent,
        borderRadius:
        BorderRadius.circular(10),
        child: InkWell(
          borderRadius:
          BorderRadius.circular(10),
          onTap: () {
            if (currentLocation != route) {
              context.go(route);
            }

            final ScaffoldState? scaffold =
            Scaffold.maybeOf(context);

            if (scaffold?.isDrawerOpen ==
                true) {
              Navigator.of(context).pop();
            }
          },
          child: Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? primaryGreen
                      : textMuted,
                ),
                const SizedBox(
                  width: 9,
                ),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: selected
                          ? primaryGreen
                          : textDark,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 4,
                    height: 18,
                    decoration:
                    BoxDecoration(
                      color: primaryGreen,
                      borderRadius:
                      BorderRadius.circular(
                        10,
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