import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tarazyar/consultant/companies/income/application/expense_payables_provider.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class PayableConsultantYearsPage extends ConsumerWidget {
  final String companyId;
  const PayableConsultantYearsPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final years = ref.watch(payableFiscalYearsProvider(companyId));
    return CompanyScaffold(
      companyId: companyId,
      currentRoute: '/consultant/companies/$companyId/expenses/payables',
      title: 'حساب‌های پرداختنی',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: years.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('دریافت سال‌های مالی ناموفق بود: $e')),
          data: (items) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(payableFiscalYearsProvider(companyId)),
            child: items.isEmpty
                ? ListView(children: const [SizedBox(height: 120), Center(child: Text('هنوز سال مالی پرداختنی ثبت نشده است.'))])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final y = items[i];
                      final year = y['year']?.toString() ?? '';
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.calendar_month)),
                          title: Text(y['title']?.toString().trim().isNotEmpty == true ? y['title'].toString() : 'سال مالی $year'),
                          subtitle: Text(y['status'] == 'closed' ? 'بسته' : 'فعال'),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () => context.push('/consultant/companies/$companyId/expenses/payables/years/${y['id']}'),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
