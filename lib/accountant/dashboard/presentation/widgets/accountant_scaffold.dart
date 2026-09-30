// import 'package:flutter/material.dart';
//
// import 'accountant_sidebar.dart';
//
// class AccountantScaffold extends StatelessWidget {
//   final String currentRoute;
//   final String title;
//   final Widget body;
//
//   const AccountantScaffold({
//     super.key,
//     required this.currentRoute,
//     required this.title,
//     required this.body,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         backgroundColor: const Color(0xFFF7F8FA),
//         body: SafeArea(
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               final isMobile = constraints.maxWidth < 900;
//
//               if (isMobile) {
//                 return _buildMobileLayout(context);
//               }
//
//               return _buildDesktopLayout(context);
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDesktopLayout(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(child: _buildContent(context)),
//
//         AccountantSidebar(currentRoute: currentRoute),
//       ],
//     );
//   }
//
//   Widget _buildMobileLayout(BuildContext context) {
//     return Builder(
//       builder: (scaffoldContext) {
//         return Scaffold(
//           backgroundColor: const Color(0xFFF7F8FA),
//           drawer: Drawer(child: AccountantSidebar(currentRoute: currentRoute)),
//           appBar: AppBar(
//             elevation: 0,
//             backgroundColor: const Color(0xFFF7F8FA),
//             surfaceTintColor: Colors.transparent,
//             title: Text(
//               title,
//               style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
//             ),
//             leading: Builder(
//               builder: (context) {
//                 return IconButton(
//                   tooltip: 'منو',
//                   icon: const Icon(Icons.menu),
//                   onPressed: () {
//                     Scaffold.of(context).openDrawer();
//                   },
//                 );
//               },
//             ),
//           ),
//           body: _buildContent(context),
//         );
//       },
//     );
//   }
//
//   Widget _buildContent(BuildContext context) {
//     return Column(
//       children: [_buildDesktopHeader(context), Expanded(child: body)],
//     );
//   }
//
//   Widget _buildDesktopHeader(BuildContext context) {
//     final theme = Theme.of(context);
//
//     return Container(
//       height: 76,
//       padding: const EdgeInsets.symmetric(horizontal: 28),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   'پنل حسابدار',
//                   style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
//             decoration: BoxDecoration(
//               color: theme.colorScheme.primary.withOpacity(.07),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.account_balance_wallet_outlined,
//                   size: 18,
//                   color: theme.colorScheme.primary,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   'حسابدار',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w700,
//                     color: theme.colorScheme.primary,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountantScaffold extends StatefulWidget {
  final String currentRoute;
  final String title;
  final Widget body;

  const AccountantScaffold({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.body,
  });

  @override
  State<AccountantScaffold> createState() =>
      _AccountantScaffoldState();
}

class _AccountantScaffoldState
    extends State<AccountantScaffold> {
  bool bankingExpanded = false;
  bool payrollExpanded = false;
  bool incomeExpanded = false;
  bool expenseExpanded = false;

  @override
  void initState() {
    super.initState();

    bankingExpanded =
        widget.currentRoute.startsWith('/accountant/banking');

    payrollExpanded =
        widget.currentRoute.startsWith('/accountant/payroll');

    incomeExpanded =
        widget.currentRoute.startsWith('/accountant/income');

    expenseExpanded =
        widget.currentRoute.startsWith('/accountant/expenses');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return Scaffold(
              backgroundColor: const Color(0xfff7f9f8),
              appBar: AppBar(
                elevation: 0,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                title: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  Builder(
                    builder: (context) {
                      return IconButton(
                        onPressed: () {
                          Scaffold.of(context).openEndDrawer();
                        },
                        icon: const Icon(Icons.menu),
                      );
                    },
                  ),
                ],
              ),
              endDrawer: Drawer(
                width: 310,
                child: SafeArea(
                  child: _buildSidebar(context),
                ),
              ),
              body: widget.body,
            );
          }

          // ============================================================
          // DESKTOP
          // محتوا سمت چپ + سایدبار سمت راست
          // ============================================================

          return Scaffold(
            backgroundColor: const Color(0xfff7f9f8),
            body: Row(
              textDirection: TextDirection.ltr,
              children: [
                // ------------------------------------------------------
                // MAIN CONTENT - LEFT
                // ------------------------------------------------------

                Expanded(
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      children: [
                        _buildTopBar(context),
                        Expanded(
                          child: widget.body,
                        ),
                      ],
                    ),
                  ),
                ),

                // ------------------------------------------------------
                // SIDEBAR - RIGHT
                // ------------------------------------------------------

                SizedBox(
                  width: 307,
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: _buildSidebar(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xffe8ece9),
          ),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: const Color(0xffedf5f1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: Color(0xff17775c),
                ),
                const SizedBox(width: 8),
                const Text(
                  'حسابدار',
                  style: TextStyle(
                    color: Color(0xff17775c),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'پنل حسابدار',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xff89918d),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar(BuildContext context) {
    return Container(
      color: const Color(0xfff4faf6),
      child: Column(
        children: [
          _buildSidebarHeader(context),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionTitle('اصلی'),

                  const SizedBox(height: 8),

                  _menuItem(
                    context,
                    icon: Icons.dashboard_outlined,
                    title: 'داشبورد',
                    route: '/accountant',
                  ),

                  const SizedBox(height: 22),

                  _sectionTitle('عملیات مالی'),

                  const SizedBox(height: 8),

                  // ======================================================
                  // BANKING
                  // ======================================================

                  _expandableMenu(
                    context,
                    icon: Icons.account_balance_outlined,
                    title: 'نقد و بانک',
                    expanded: bankingExpanded,
                    onExpand: () {
                      setState(() {
                        bankingExpanded = !bankingExpanded;
                      });
                    },
                    children: [
                      _subMenuItem(
                        context,
                        title: 'داشبورد نقد و بانک',
                        route: '/accountant/banking',
                      ),
                      _subMenuItem(
                        context,
                        title: 'حساب‌های بانکی',
                        route: '/accountant/banking/accounts',
                      ),
                      _subMenuItem(
                        context,
                        title: 'صندوق‌ها',
                        route: '/accountant/banking/cash-boxes',
                      ),
                      _subMenuItem(
                        context,
                        title: 'تنخواه',
                        route: '/accountant/banking/petty-cash',
                      ),
                      _subMenuItem(
                        context,
                        title: 'تسهیلات بانکی',
                        route: '/accountant/banking/loans',
                      ),
                      _subMenuItem(
                        context,
                        title: 'چک‌های دریافتی',
                        route:
                        '/accountant/banking/received-checks',
                      ),
                      _subMenuItem(
                        context,
                        title: 'چک‌های پرداختی',
                        route:
                        '/accountant/banking/paid-checks',
                      ),
                      _subMenuItem(
                        context,
                        title: 'دوره‌های مالی',
                        route:
                        '/accountant/banking/fiscal-periods',
                      ),
                      _subMenuItem(
                        context,
                        title: 'گزارش‌های بانکی',
                        route: '/accountant/banking/reports',
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // ======================================================
                  // PAYROLL
                  // ======================================================

                  _expandableMenu(
                    context,
                    icon: Icons.groups_outlined,
                    title: 'حقوق و دستمزد',
                    expanded: payrollExpanded,
                    onExpand: () {
                      setState(() {
                        payrollExpanded = !payrollExpanded;
                      });
                    },
                    children: [
                      _subMenuItem(
                        context,
                        title: 'داشبورد حقوق',
                        route: '/accountant/payroll',
                      ),
                      _subMenuItem(
                        context,
                        title: 'کارکنان',
                        route: '/accountant/payroll/employees',
                      ),
                      _subMenuItem(
                        context,
                        title: 'قراردادها',
                        route: '/accountant/payroll/contracts',
                      ),
                      _subMenuItem(
                        context,
                        title: 'دوره‌های حقوق',
                        route: '/accountant/payroll/periods',
                      ),
                      _subMenuItem(
                        context,
                        title: 'مراکز هزینه',
                        route:
                        '/accountant/payroll/cost-centers',
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // ======================================================
                  // INCOME
                  // ======================================================

                  _expandableMenu(
                    context,
                    icon: Icons.trending_up_outlined,
                    title: 'درآمد',
                    expanded: incomeExpanded,
                    onExpand: () {
                      setState(() {
                        incomeExpanded = !incomeExpanded;
                      });
                    },
                    children: [
                      _subMenuItem(
                        context,
                        title: 'داشبورد درآمد',
                        route: '/accountant/income',
                      ),
                      _subMenuItem(
                        context,
                        title: 'دوره‌های مالی',
                        route: '/accountant/income/periods',
                      ),
                      _subMenuItem(
                        context,
                        title: 'دسته‌بندی‌ها',
                        route: '/accountant/income/categories',
                      ),
                      _subMenuItem(
                        context,
                        title: 'ثبت درآمد',
                        route: '/accountant/income/recognition',
                      ),
                      _subMenuItem(
                        context,
                        title: 'مطالبات',
                        route: '/accountant/income/receivables',
                      ),
                      _subMenuItem(
                        context,
                        title: 'گزارش درآمد',
                        route: '/accountant/income/reports',
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  // ======================================================
                  // EXPENSE
                  // ======================================================

                  _expandableMenu(
                    context,
                    icon: Icons.trending_down_outlined,
                    title: 'هزینه',
                    expanded: expenseExpanded,
                    onExpand: () {
                      setState(() {
                        expenseExpanded = !expenseExpanded;
                      });
                    },
                    children: [
                      _subMenuItem(
                        context,
                        title: 'داشبورد هزینه',
                        route: '/accountant/expenses',
                      ),
                      _subMenuItem(
                        context,
                        title: 'دوره‌های مالی',
                        route: '/accountant/expenses/periods',
                      ),
                      _subMenuItem(
                        context,
                        title: 'دسته‌بندی‌ها',
                        route:
                        '/accountant/expenses/categories',
                      ),
                      _subMenuItem(
                        context,
                        title: 'ثبت هزینه',
                        route:
                        '/accountant/expenses/recognition',
                      ),
                      _subMenuItem(
                        context,
                        title: 'حساب‌های پرداختنی',
                        route:
                        '/accountant/expenses/payables/periods',
                      ),
                      _subMenuItem(
                        context,
                        title: 'گزارش هزینه',
                        route:
                        '/accountant/expenses/reports',
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // ======================================================
                  // SYSTEM
                  // ======================================================

                  _sectionTitle('سیستم'),

                  const SizedBox(height: 8),

                  _menuItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'حساب کاربری',
                    route: '/accountant/profile',
                  ),
                ],
              ),
            ),
          ),

          _buildLogout(context),
        ],
      ),
    );
  }

  // ============================================================
  // SIDEBAR HEADER
  // ============================================================

  Widget _buildSidebarHeader(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xffdce7df),
          ),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xffdfeee6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Color(0xff17775c),
              size: 27,
            ),
          ),

          const SizedBox(width: 12),

          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ترازیار',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'پنل حسابدار',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xff89918d),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: Text(
        title,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xff89918d),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // NORMAL MENU
  // ============================================================

  Widget _menuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String route,
      }) {
    final active = _isActive(route);

    return Material(
      color: active
          ? const Color(0xffdcece3)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          context.go(route);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 12,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                icon,
                size: 21,
                color: active
                    ? const Color(0xff17775c)
                    : const Color(0xff626b67),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: active
                        ? const Color(0xff17775c)
                        : const Color(0xff454c49),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EXPANDABLE MENU
  // ============================================================

  Widget _expandableMenu(
      BuildContext context, {
        required IconData icon,
        required String title,
        required bool expanded,
        required VoidCallback onExpand,
        required List<Widget> children,
      }) {
    final active = _isCurrentSection(title);

    return Column(
      children: [
        Material(
          color: active
              ? const Color(0xffedf5f1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onExpand,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 12,
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(
                    icon,
                    size: 21,
                    color: active
                        ? const Color(0xff17775c)
                        : const Color(0xff626b67),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: active
                            ? const Color(0xff17775c)
                            : const Color(0xff454c49),
                      ),
                    ),
                  ),

                  AnimatedRotation(
                    turns: expanded ? .5 : 0,
                    duration: const Duration(
                      milliseconds: 180,
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: Color(0xff69716d),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(
              right: 17,
              top: 3,
              bottom: 5,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(
            milliseconds: 180,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUB MENU
  // ============================================================

  Widget _subMenuItem(
      BuildContext context, {
        required String title,
        required String route,
      }) {
    final active =
        widget.currentRoute == route;

    return Material(
      color: active
          ? const Color(0xffdcece3)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          context.go(route);
        },
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(
            bottom: 2,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? const Color(0xff17775c)
                      : const Color(0xffa8b1ac),
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: active
                        ? FontWeight.bold
                        : FontWeight.w500,
                    color: active
                        ? const Color(0xff17775c)
                        : const Color(0xff5e6763),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Widget _buildLogout(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xffdce7df),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await GoRouter.of(context).push('/login');
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 11,
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  Icons.logout,
                  color: Colors.redAccent,
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  'خروج از حساب',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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
  // ACTIVE ROUTE
  // ============================================================

  bool _isActive(String route) {
    if (route == '/accountant') {
      return widget.currentRoute == route;
    }

    return widget.currentRoute == route ||
        widget.currentRoute.startsWith('$route/');
  }

  // ============================================================
  // ACTIVE SECTION
  // ============================================================

  bool _isCurrentSection(String title) {
    switch (title) {
      case 'نقد و بانک':
        return widget.currentRoute
            .startsWith('/accountant/banking');

      case 'حقوق و دستمزد':
        return widget.currentRoute
            .startsWith('/accountant/payroll');

      case 'درآمد':
        return widget.currentRoute
            .startsWith('/accountant/income');

      case 'هزینه':
        return widget.currentRoute
            .startsWith('/accountant/expenses');

      default:
        return false;
    }
  }
}
