import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

class ConsultantScaffold extends StatelessWidget {
  const ConsultantScaffold({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.body,
  });

  final String currentRoute;
  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      body: Row(
        children: [
          if (isDesktop)
            ConsultantSidebar(
              currentRoute: currentRoute,
            ),
          Expanded(
            child: Column(
              children: [
                _ConsultantTopBar(
                  title: title,
                  showMenu: !isDesktop,
                  onMenuPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
                Expanded(
                  child: body,
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
        child: ConsultantSidebar(
          currentRoute: currentRoute,
          insideDrawer: true,
        ),
      ),
    );
  }
}

class _ConsultantTopBar extends StatelessWidget {
  const _ConsultantTopBar({
    required this.title,
    required this.showMenu,
    required this.onMenuPressed,
  });

  final String title;
  final bool showMenu;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showMenu) ...[
            IconButton(
              onPressed: onMenuPressed,
              icon: const Icon(Icons.menu_rounded),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17211D),
              ),
            ),
          ),
          IconButton(
            tooltip: 'اعلان‌ها',
            onPressed: () {
              context.go('/consultant/notifications');
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class ConsultantSidebar extends StatelessWidget {
  const ConsultantSidebar({
    super.key,
    required this.currentRoute,
    this.insideDrawer = false,
  });

  final String currentRoute;
  final bool insideDrawer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      color: const Color(0xFF163A2B),
      child: SafeArea(
        child: Column(
          children: [
            _SidebarHeader(),

            const SizedBox(height: 18),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                child: Column(
                  children: [
                    _SidebarItem(
                      icon: Icons.dashboard_rounded,
                      title: 'داشبورد',
                      route: '/consultant',
                      currentRoute: currentRoute,
                    ),

                    _SidebarItem(
                      icon: Icons.business_rounded,
                      title: 'شرکت‌های من',
                      route: '/consultant/companies',
                      currentRoute: currentRoute,
                    ),

                    const _SidebarDivider(),

                    _SidebarItem(
                      icon: Icons.analytics_rounded,
                      title: 'تحلیل عملکرد',
                      route: '/consultant/analytics',
                      currentRoute: currentRoute,
                    ),

                    _SidebarItem(
                      icon: Icons.bar_chart_rounded,
                      title: 'گزارش‌ها',
                      route: '/consultant/reports',
                      currentRoute: currentRoute,
                    ),

                    _SidebarItem(
                      icon: Icons.account_tree_rounded,
                      title: 'گردش کار',
                      route: '/consultant/workflow',
                      currentRoute: currentRoute,
                    ),

                    const _SidebarDivider(),

                    _SidebarItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'اعلان‌ها',
                      route: '/consultant/notifications',
                      currentRoute: currentRoute,
                    ),

                    _SidebarItem(
                      icon: Icons.history_rounded,
                      title: 'تاریخچه فعالیت',
                      route: '/consultant/history',
                      currentRoute: currentRoute,
                    ),

                    _SidebarItem(
                      icon: Icons.settings_outlined,
                      title: 'تنظیمات',
                      route: '/consultant/settings',
                      currentRoute: currentRoute,
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                8,
                14,
                18,
              ),
              child: _LogoutButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        0,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 25,
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
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'پنل مشاور',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.currentRoute,
  });

  final IconData icon;
  final String title;
  final String route;
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final selected = currentRoute == route ||
        (route != '/consultant' &&
            currentRoute.startsWith('$route/'));

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected
            ? Colors.white.withOpacity(.13)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            context.go(route);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: selected
                      ? Colors.white
                      : Colors.white60,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.white70,
                      fontSize: 13,
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

class _SidebarDivider extends StatelessWidget {
  const _SidebarDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 8,
      ),
      child: Divider(
        color: Colors.white.withOpacity(.10),
        height: 1,
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Supabase.instance.client.auth.signOut();
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.white70,
                size: 20,
              ),
              SizedBox(width: 13),
              Text(
                'خروج از حساب',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}