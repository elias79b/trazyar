import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tarazyar/consultant/companies/income/data/income_receivable_fiscal_provider.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

const _monthNames = <String>[
  'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
  'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
];

class IncomeReceivableYearsPage extends ConsumerWidget {
  final String companyId;

  const IncomeReceivableYearsPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearsAsync = ref.watch(incomeReceivableFiscalYearsProvider(companyId));

    return CompanyScaffold(
      companyId: companyId,
      currentRoute: '/consultant/companies/$companyId/income/receivables',
      title: 'حساب‌های دریافتی',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: yearsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _StateMessage(
            icon: Icons.error_outline,
            title: 'دریافت سال‌های مالی انجام نشد',
            detail: 'اتصال و دسترسی جدول‌های اختصاصی حساب‌های دریافتی را بررسی کنید.\n$error',
            actionLabel: 'تلاش دوباره',
            onPressed: () => ref.invalidate(incomeReceivableFiscalYearsProvider(companyId)),
          ),
          data: (years) {
            if (years.isEmpty) {
              return const _StateMessage(
                icon: Icons.calendar_month_outlined,
                title: 'سال مالی‌ای برای حساب‌های دریافتی ثبت نشده است',
                detail: 'ابتدا سال مالی و ۱۲ دوره ماهانه آن را در ساختار حساب‌های دریافتی ایجاد کنید.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.refresh(incomeReceivableFiscalYearsProvider(companyId).future),
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: years.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final year = years[index];
                  return _FiscalYearCard(
                    companyId: companyId,
                    year: year,
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

class _FiscalYearCard extends ConsumerWidget {
  final String companyId;
  final Map<String, dynamic> year;

  const _FiscalYearCard({required this.companyId, required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearId = year['id'].toString();
    final periodsAsync = ref.watch(incomeReceivableFiscalPeriodsProvider(yearId));
    final yearNumber = year['year']?.toString() ?? '';
    final title = (year['title']?.toString().trim().isNotEmpty ?? false)
        ? year['title'].toString()
        : 'سال مالی $yearNumber';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, color: Color(0xFF176B50)),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold))),
              _StatusPill(label: year['status']?.toString() == 'closed' ? 'بسته' : 'باز'),
            ],
          ),
          const SizedBox(height: 18),
          periodsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _StateMessage(
              icon: Icons.error_outline,
              title: 'دوره‌های این سال دریافت نشد',
              detail: error.toString(),
              actionLabel: 'تلاش دوباره',
              onPressed: () => ref.invalidate(incomeReceivableFiscalPeriodsProvider(yearId)),
            ),
            data: (periods) {
              final byMonth = <int, Map<String, dynamic>>{};
              for (final period in periods) {
                final month = int.tryParse(period['month'].toString());
                if (month != null && month >= 1 && month <= 12) byMonth[month] = period;
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final count = constraints.maxWidth >= 1050 ? 4 : constraints.maxWidth >= 680 ? 3 : constraints.maxWidth >= 430 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 12,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: count,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 92,
                    ),
                    itemBuilder: (context, index) {
                      final month = index + 1;
                      final period = byMonth[month];
                      final exists = period != null;
                      final status = period?['status']?.toString() ?? '';
                      final statusText = !exists
                          ? 'دوره ایجاد نشده'
                          : status == 'closed'
                              ? 'بسته شده'
                              : status == 'approved'
                                  ? 'تأیید شده'
                                  : status == 'submitted_to_consultant'
                                      ? 'ارسال برای مشاور'
                                      : status == 'submitted_to_company_admin'
                                          ? 'ارسال برای مدیرعامل'
                                          : 'در انتظار ثبت';
                      return Material(
                        color: exists ? Colors.white : const Color(0xFFE7ECE8),
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13),
                          onTap: exists
                              ? () => context.go('/consultant/companies/$companyId/income/receivables/${period['id']}')
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: exists ? const Color(0xFFC7D6CC) : const Color(0xFFD9DFDA)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, size: 21, color: exists ? const Color(0xFF176B50) : Colors.grey),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(_monthNames[index], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                      const SizedBox(height: 5),
                                      Text(statusText, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: exists ? const Color(0xFF39745D) : Colors.grey.shade700)),
                                    ],
                                  ),
                                ),
                                Icon(exists ? Icons.chevron_left : Icons.lock_outline, size: 20, color: exists ? const Color(0xFF176B50) : Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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

class _StatusPill extends StatelessWidget {
  final String label;
  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: const Color(0xFFDDEBE2), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: const TextStyle(color: Color(0xFF176B50), fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onPressed;

  const _StateMessage({required this.icon, required this.title, this.detail, this.actionLabel, this.onPressed});

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: const Color(0xFF176B50)),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            if (detail != null) ...[
              const SizedBox(height: 9),
              Text(detail!, textAlign: TextAlign.center, style: const TextStyle(height: 1.7, color: Colors.black54)),
            ],
            if (actionLabel != null && onPressed != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onPressed, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    ),
  );
}
