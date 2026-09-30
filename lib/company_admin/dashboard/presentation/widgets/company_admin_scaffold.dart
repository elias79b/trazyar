import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompanyAdminScaffold extends StatelessWidget {
  final Widget child;

  const CompanyAdminScaffold({super.key, required this.child});

  static const Color primaryGreen = Color(0xFF167A4A);
  static const Color lightGreen = Color(0xFFEAF7F0);
  static const Color background = Color(0xFFF6F8F7);
  static const Color border = Color(0xFFE2E8E5);
  static const Color textDark = Color(0xFF17221D);
  static const Color textMuted = Color(0xFF718078);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        endDrawer: _buildMobileDrawer(context),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bool isDesktop = constraints.maxWidth >= 1000;

            if (isDesktop) {
              return Row(
                textDirection: TextDirection.ltr,
                children: [
                  Expanded(child: child),
                  SizedBox(width: 300, child: _buildSidebar(context)),
                ],
              );
            }

            return child;
          },
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                children: [
                  _sectionTitle('مدیریت شرکت'),

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

                  const SizedBox(height: 18),

                  _sectionTitle('امور مالی'),

                  _menuItem(
                    context,
                    icon: Icons.account_balance_rounded,
                    title: 'بانک و حساب‌ها',
                    route: '/company-admin/banking',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'صندوق‌ها',
                    route: '/company-admin/cash',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.receipt_long_rounded,
                    title: 'دریافتنی‌ها',
                    route: '/company-admin/receivables',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.payments_rounded,
                    title: 'پرداختنی‌ها',
                    route: '/company-admin/payables',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.trending_up_rounded,
                    title: 'درآمد',
                    route: '/company-admin/income',
                  ),

                  _menuItem(
                    context,
                    icon: Icons.trending_down_rounded,
                    title: 'هزینه',
                    route: '/company-admin/expenses',
                  ),

                  const SizedBox(height: 18),

                  _sectionTitle('گزارش‌ها'),

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
                    route: '/company-admin/management-reports',
                  ),

                  const SizedBox(height: 18),

                  _sectionTitle('تنظیمات'),

                  _menuItem(
                    context,
                    icon: Icons.settings_rounded,
                    title: 'تنظیمات شرکت',
                    route: '/company-admin/settings',
                  ),
                ],
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: primaryGreen,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ترازیار',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'پنل مدیرعامل',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: border)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('خروج از حساب در این بخش متصل خواهد شد.'),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F4),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: Color(0xFF66736C),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'خروج از حساب',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(width: 310, child: _buildSidebar(context));
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
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

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    final String currentLocation = GoRouterState.of(context).uri.path;

    final bool selected =
        currentLocation == route ||
        (route != '/company-admin' && currentLocation.startsWith('$route/'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? lightGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (currentLocation != route) {
              context.go(route);
            }

            final ScaffoldState? scaffold = Scaffold.maybeOf(context);

            if (scaffold?.isDrawerOpen == true) {
              Navigator.of(context).pop();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: selected ? primaryGreen : textMuted,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? primaryGreen : textDark,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 5,
                    height: 22,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(10),
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
