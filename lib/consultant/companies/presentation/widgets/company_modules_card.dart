import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CompanyModulesCard extends StatelessWidget {
  const CompanyModulesCard({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context) {
    final modules = [
      _ModuleItem(
        title: 'بانک و نقد',
        icon: Icons.account_balance_rounded,
        route: '/consultant/companies/$companyId/banking',
      ),

      _ModuleItem(
        title: 'حقوق و دستمزد',
        icon: Icons.people_alt_rounded,
        route: '/consultant/companies/$companyId/payroll',
      ),

      _ModuleItem(
        title: 'فروش',
        icon: Icons.shopping_cart_rounded,
        route: '/consultant/companies/$companyId/sales',
      ),

      _ModuleItem(
        title: 'خرید',
        icon: Icons.shopping_bag_rounded,
        route: '/consultant/companies/$companyId/purchases',
      ),

      _ModuleItem(
        title: 'انبار',
        icon: Icons.inventory_2_rounded,
        route: '/consultant/companies/$companyId/inventory',
      ),

      _ModuleItem(
        title: 'تحلیل مالی',
        icon: Icons.analytics_rounded,
        route: '/consultant/companies/$companyId/analytics',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'ماژول‌های شرکت',

            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              int count;

              if (constraints.maxWidth >= 1000) {
                count = 4;
              } else if (constraints.maxWidth >= 600) {
                count = 3;
              } else {
                count = 2;
              }

              return GridView.builder(
                shrinkWrap: true,

                physics: const NeverScrollableScrollPhysics(),

                itemCount: modules.length,

                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: count,

                  crossAxisSpacing: 14,

                  mainAxisSpacing: 14,

                  childAspectRatio: 1.7,
                ),

                itemBuilder: (context, index) {
                  final module = modules[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(18),

                    onTap: () {
                      context.go(module.route);
                    },

                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9F8),

                        borderRadius: BorderRadius.circular(18),
                      ),

                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [
                          Icon(
                            module.icon,

                            size: 32,

                            color: const Color(0xFF1B4332),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            module.title,

                            style: const TextStyle(
                              fontWeight: FontWeight.w800,

                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModuleItem {
  final String title;

  final IconData icon;

  final String route;

  const _ModuleItem({
    required this.title,

    required this.icon,

    required this.route,
  });
}
