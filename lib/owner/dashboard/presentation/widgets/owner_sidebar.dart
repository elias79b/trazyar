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
      width: 220,
      decoration: const BoxDecoration(
        color: Color(0xff183153),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 150,
          ),
          const Text(
            'ترازیار',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Material(
        color: selected ? Colors.white12 : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _go(context, route),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
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