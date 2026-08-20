import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/consultant_companies_provider.dart';

import '../widgets/company_search_box.dart';
import '../widgets/consultant_company_card.dart';

import '../widgets/consultant_scaffold.dart';

class ConsultantCompaniesPage extends ConsumerStatefulWidget {
  const ConsultantCompaniesPage({super.key});

  @override
  ConsumerState<ConsultantCompaniesPage> createState() =>
      _ConsultantCompaniesPageState();
}

class _ConsultantCompaniesPageState
    extends ConsumerState<ConsultantCompaniesPage> {
  final TextEditingController _searchController = TextEditingController();

  String _search = '';

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(consultantCompaniesProvider);

    return ConsultantScaffold(
      currentRoute: '/consultant/companies',

      title: 'شرکت‌های من',

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'شرکت‌های تحت مدیریت',

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),

            const SizedBox(height: 6),

            Text(
              'مشاهده وضعیت و ورود به داشبورد هر شرکت',

              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),

            const SizedBox(height: 24),

            CompanySearchBox(
              controller: _searchController,

              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
            ),

            const SizedBox(height: 24),

            companiesAsync.when(
              loading: () {
                return const Center(child: CircularProgressIndicator());
              },

              error: (error, stackTrace) {
                return Center(
                  child: Text(error.toString(), textAlign: TextAlign.center),
                );
              },

              data: (companies) {
                final filtered =
                    companies.where((company) {
                      return company.name.contains(_search);
                    }).toList();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int count;

                    if (constraints.maxWidth >= 1200) {
                      count = 3;
                    } else if (constraints.maxWidth >= 700) {
                      count = 2;
                    } else {
                      count = 1;
                    }

                    return GridView.builder(
                      shrinkWrap: true,

                      physics: const NeverScrollableScrollPhysics(),

                      itemCount: filtered.length,

                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: count,

                        crossAxisSpacing: 18,

                        mainAxisSpacing: 18,

                        mainAxisExtent: 230,
                      ),

                      itemBuilder: (context, index) {
                        final company = filtered[index];

                        return ConsultantCompanyCard(
                          name: company.name,

                          industry: company.city ?? '---',

                          status: company.isActive ? 'فعال' : 'غیرفعال',

                          lastActivity: '---',

                          onTap: () {
                            context.go('/consultant/companies/${company.id}');
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }
}
