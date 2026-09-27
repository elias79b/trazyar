import 'package:flutter/material.dart';

import 'accountant_sidebar.dart';

class AccountantScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 900;

              if (isMobile) {
                return _buildMobileLayout(context);
              }

              return _buildDesktopLayout(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildContent(context)),

        AccountantSidebar(currentRoute: currentRoute),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Builder(
      builder: (scaffoldContext) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          drawer: Drawer(child: AccountantSidebar(currentRoute: currentRoute)),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFFF7F8FA),
            surfaceTintColor: Colors.transparent,
            title: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            leading: Builder(
              builder: (context) {
                return IconButton(
                  tooltip: 'منو',
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
          ),
          body: _buildContent(context),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [_buildDesktopHeader(context), Expanded(child: body)],
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'حسابدار',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
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
