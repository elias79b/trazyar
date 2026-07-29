import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OwnerSidebar extends StatelessWidget {
  const OwnerSidebar({
    super.key,
    required this.currentRoute,
  });

  final String currentRoute;

  void _go(BuildContext context, String route) {
    if (currentRoute == route) return;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Color(0xff183153),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Image.asset(
            'assets/images/logo.png',
            height: 70,
          ),
          const SizedBox(height: 20),
          const Text(
            'ترازیار',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),

          _item(
            context,
            icon: Icons.dashboard,
            title: 'داشبورد',
            route: '/owner',
            selected: currentRoute == '/owner',
          ),
          _item(
            context,
            icon: Icons.business,
            title: 'شرکت ها',
            route: '/owner/companies',
            selected: currentRoute == '/owner/companies',
          ),
          _item(
            context,
            icon: Icons.people,
            title: 'کاربران',
            route: '/owner/users',
            selected: currentRoute == '/owner/users',
          ),
          _item(
            context,
            icon: Icons.inventory,
            title: 'محصولات',
            route: '/owner/products',
            selected: currentRoute == '/owner/products',
          ),
          _item(
            context,
            icon: Icons.receipt_long,
            title: 'فاکتورها',
            route: '/owner/invoices',
            selected: currentRoute == '/owner/invoices',
          ),
          _item(
            context,
            icon: Icons.account_balance_wallet,
            title: 'حسابداری',
            route: '/owner/accounting',
            selected: currentRoute == '/owner/accounting',
          ),
          _item(
            context,
            icon: Icons.bar_chart,
            title: 'گزارشات',
            route: '/owner/reports',
            selected: currentRoute == '/owner/reports',
          ),
          _item(
            context,
            icon: Icons.settings,
            title: 'تنظیمات',
            route: '/owner/settings',
            selected: currentRoute == '/owner/settings',
          ),

          const Spacer(),
          const Divider(color: Colors.white24),
          _item(
            context,
            icon: Icons.logout,
            title: 'خروج',
            route: '/login',
            selected: false,
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }

  Widget _item(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String route,
        required bool selected,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      child: Material(
        color: selected ? Colors.white12 : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _go(context, route),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                ),
                const SizedBox(width: 15),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
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
}