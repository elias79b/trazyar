import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tarazyar/consultant/companies/income/application/expense_payables_provider.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

const _months = ['فروردین','اردیبهشت','خرداد','تیر','مرداد','شهریور','مهر','آبان','آذر','دی','بهمن','اسفند'];

class PayableConsultantPeriodsPage extends ConsumerWidget {
  final String companyId;
  final String yearId;
  const PayableConsultantPeriodsPage({super.key, required this.companyId, required this.yearId});

  String _status(String? s) => switch (s) {
    'open' => 'باز',
    'submitted_to_company_admin' => 'در انتظار تأیید مدیرعامل',
    'submitted_to_consultant' => 'در انتظار بررسی مشاور',
    'approved' => 'تأییدشده',
    'closed' => 'بسته',
    _ => s ?? 'نامشخص',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periods = ref.watch(payableFiscalPeriodsProvider(yearId));
    return CompanyScaffold(
      companyId: companyId,
      currentRoute: '/consultant/companies/$companyId/expenses/payables/years/$yearId',
      title: 'ماه‌های سال مالی',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: periods.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('دریافت دوره‌ها ناموفق بود: $e')),
          data: (rows) {
            final byMonth = {for (final r in rows) (r['month'] as num).toInt(): r};
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(payableFiscalPeriodsProvider(yearId)),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final row = byMonth[month];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 9),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('$month')),
                      title: Text(_months[index]),
                      subtitle: Text(row == null ? 'دوره ایجاد نشده' : _status(row['status']?.toString())),
                      trailing: const Icon(Icons.chevron_left),
                      enabled: row != null,
                      onTap: row == null ? null : () => context.push('/consultant/companies/$companyId/expenses/payables/periods/${row['id']}'),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
