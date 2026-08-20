import 'package:flutter/material.dart';

import 'company_sidebar.dart';

class CompanyScaffold extends StatelessWidget {
  const CompanyScaffold({
    super.key,

    required this.companyId,

    required this.currentRoute,

    required this.title,

    required this.body,
  });

  final String companyId;

  final String currentRoute;

  final String title;

  final Widget body;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final desktop = width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),

      drawer:
          desktop
              ? null
              : Drawer(
                child: CompanySidebar(
                  companyId: companyId,

                  currentRoute: currentRoute,
                ),
              ),

      body: Row(
        children: [
          if (desktop)
            CompanySidebar(companyId: companyId, currentRoute: currentRoute),

          Expanded(
            child: Column(
              children: [
                _CompanyTopBar(title: title, showMenu: !desktop),

                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyTopBar extends StatelessWidget {
  const _CompanyTopBar({required this.title, required this.showMenu});

  final String title;

  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,

      padding: const EdgeInsets.symmetric(horizontal: 24),

      decoration: BoxDecoration(
        color: Colors.white,

        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),

      child: Row(
        children: [
          if (showMenu)
            Builder(
              builder: (context) {
                return IconButton(
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },

                  icon: const Icon(Icons.menu_rounded),
                );
              },
            ),

          Expanded(
            child: Text(
              title,

              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),

          Container(
            width: 42,

            height: 42,

            decoration: BoxDecoration(
              color: const Color(0xFF1B4332),

              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(Icons.business_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
