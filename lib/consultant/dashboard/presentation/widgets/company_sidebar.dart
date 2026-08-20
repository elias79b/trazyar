import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/company_provider.dart';

class CompanySidebar extends ConsumerWidget {
  const CompanySidebar({
    super.key,

    required this.companyId,

    required this.currentRoute,
  });

  final String companyId;

  final String currentRoute;

  void _go(BuildContext context, String route) {
    if (currentRoute == route) return;

    context.go(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyAsync = ref.watch(companyProvider(companyId));

    return Container(
      width: 250,

      color: const Color(0xFF163A2B),

      child: Column(
        children: [
          const SizedBox(height: 30),

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

            error: (_, __) {
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
              return Text(
                company.name,

                style: const TextStyle(
                  color: Colors.white,

                  fontSize: 18,

                  fontWeight: FontWeight.w900,
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          _Item(
            icon: Icons.dashboard_rounded,

            title: 'نمای کلی',

            route: '/consultant/companies/$companyId',

            currentRoute: currentRoute,

            onTap: _go,
          ),

          _Item(
            icon: Icons.account_balance,

            title: 'بانک و نقد',

            route: '/consultant/companies/$companyId/banking',

            currentRoute: currentRoute,

            onTap: _go,
          ),

          _Item(
            icon: Icons.analytics_rounded,

            title: 'تحلیل مالی',

            route: '/consultant/companies/$companyId/analytics',

            currentRoute: currentRoute,

            onTap: _go,
          ),

          _Item(
            icon: Icons.description_rounded,

            title: 'گزارش‌ها',

            route: '/consultant/companies/$companyId/reports',

            currentRoute: currentRoute,

            onTap: _go,
          ),

          _Item(
            icon: Icons.task_alt_rounded,

            title: 'اقدامات',

            route: '/consultant/companies/$companyId/actions',

            currentRoute: currentRoute,

            onTap: _go,
          ),
          _Item(
            icon: Icons.folder_open_rounded,

            title: 'اسناد و مدارک',

            route: '/consultant/companies/$companyId/documents',

            currentRoute: currentRoute,

            onTap: _go,
          ),

          _Item(
            icon: Icons.note_alt_rounded,

            title: 'یادداشت‌های مشاور',

            route: '/consultant/companies/$companyId/notes',

            currentRoute: currentRoute,

            onTap: _go,
          ),

          const Spacer(),

          _Item(
            icon: Icons.arrow_back_rounded,

            title: 'بازگشت به شرکت‌ها',

            route: '/consultant/companies',

            currentRoute: currentRoute,

            onTap: _go,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

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

                Text(
                  title,

                  style: const TextStyle(
                    color: Colors.white,

                    fontSize: 13,

                    fontWeight: FontWeight.w700,
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
