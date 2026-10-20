import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/consultant/companies/income/application/expense_payables_provider.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class PayableConsultantPeriodDetailPage extends ConsumerStatefulWidget {
  final String companyId;
  final String periodId;
  const PayableConsultantPeriodDetailPage({super.key, required this.companyId, required this.periodId});

  @override
  ConsumerState<PayableConsultantPeriodDetailPage> createState() => _PayableConsultantPeriodDetailPageState();
}

class _PayableConsultantPeriodDetailPageState extends ConsumerState<PayableConsultantPeriodDetailPage> {
  bool _busy = false;
  static const _months = ['فروردین','اردیبهشت','خرداد','تیر','مرداد','شهریور','مهر','آبان','آذر','دی','بهمن','اسفند'];

  String _status(String? s) => switch (s) {
    'open' => 'باز',
    'submitted_to_company_admin' => 'در انتظار تأیید مدیرعامل',
    'submitted_to_consultant' => 'در انتظار بررسی مشاور',
    'approved' => 'تأییدشده',
    'closed' => 'بسته',
    _ => s ?? 'نامشخص',
  };

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _approve() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('تأیید دوره پرداختنی'),
        content: const Text('آیا اطلاعات این دوره را تأیید می‌کنید؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تأیید دوره')),
        ],
      ),
    ));
    if (ok != true || !mounted) return;
    await _runAction('approve_by_consultant');
  }

  Future<void> _return() async {
    final controller = TextEditingController();
    try {
      final note = await showDialog<String>(context: context, barrierDismissible: false, builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('برگشت به حسابدار'),
          content: TextField(controller: controller, autofocus: true, maxLines: 3, decoration: const InputDecoration(labelText: 'علت برگشت', border: OutlineInputBorder())),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            FilledButton(onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx, controller.text.trim());
            }, child: const Text('برگشت برای اصلاح')),
          ],
        ),
      ));
      if (note == null || note.trim().isEmpty || !mounted) return;
      await _runAction('return_by_consultant', note: note.trim());
    } finally {
      controller.dispose();
    }
  }

  Future<void> _runAction(String action, {String? note}) async {
    setState(() => _busy = true);
    try {
      await PayableFiscalWorkflowService.process(periodId: widget.periodId, action: action, note: note);
      ref.invalidate(payableFiscalPeriodProvider(widget.periodId));
      final currentPeriod = ref.read(payableFiscalPeriodProvider(widget.periodId)).value;
      final yearId = currentPeriod?['fiscal_year_id']?.toString();
      if (yearId != null && yearId.isNotEmpty) {
        ref.invalidate(payableFiscalPeriodsProvider(yearId));
      }
      ref.invalidate(payablesForPeriodProvider(widget.periodId));
      _toast(action == 'approve_by_consultant' ? 'دوره تأیید شد.' : 'دوره برای اصلاح به حسابدار برگشت داده شد.');
    } catch (e) {
      _toast('عملیات انجام نشد: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodAsync = ref.watch(payableFiscalPeriodProvider(widget.periodId));
    final payablesAsync = ref.watch(payablesForPeriodProvider(widget.periodId));
    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute: '/consultant/companies/${widget.companyId}/expenses/payables/periods/${widget.periodId}',
      title: 'جزئیات حساب‌های پرداختنی',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: periodAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('دریافت دوره ناموفق بود: $e')),
          data: (period) {
            if (period == null) return const Center(child: Text('دوره پیدا نشد.'));
            final monthNumber = (period['month'] as num?)?.toInt() ?? 1;
            final status = period['status']?.toString();
            final canReview = status == 'submitted_to_consultant';
            return payablesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('دریافت جزئیات پرداختنی‌ها ناموفق بود: $e')),
              data: (rows) {
                final total = rows.fold<double>(0, (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? double.tryParse('${row['amount']}') ?? 0));
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(payableFiscalPeriodProvider(widget.periodId));
                    ref.invalidate(payablesForPeriodProvider(widget.periodId));
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${_months[(monthNumber - 1).clamp(0, 11).toInt()]} ${period['year']}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('وضعیت: ${_status(status)}'),
                        const SizedBox(height: 6),
                        Text('تعداد اسناد: ${rows.length}'),
                        Text('جمع مبلغ: ${total.toStringAsFixed(0)} ریال'),
                      ]))),
                      const SizedBox(height: 8),
                      if (rows.isEmpty)
                        const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('برای این دوره حساب پرداختنی ثبت نشده است.'))))
                      else
                        ...rows.map((row) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(row['title']?.toString() ?? '', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('طلبکار: ${row['creditor_name'] ?? '—'}'),
                            Text('مبلغ: ${row['amount'] ?? 0} ریال'),
                            if ((row['due_date']?.toString() ?? '').isNotEmpty) Text('سررسید: ${row['due_date']}'),
                            if ((row['reference_number']?.toString() ?? '').isNotEmpty) Text('شماره مرجع: ${row['reference_number']}'),
                            if ((row['description']?.toString() ?? '').trim().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(row['description'].toString())),
                            Text('وضعیت پرداخت: ${row['status'] == 'paid' ? 'پرداخت‌شده' : row['status'] == 'cancelled' ? 'لغوشده' : 'پرداخت‌نشده'}'),
                          ])),
                        )),
                      if (canReview) ...[
                        const SizedBox(height: 12),
                        FilledButton.icon(onPressed: _busy ? null : _approve, icon: const Icon(Icons.check_circle_outline), label: const Text('تأیید دوره')),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(onPressed: _busy ? null : _return, icon: const Icon(Icons.undo), label: const Text('برگشت به حسابدار')),
                      ],
                      if (_busy) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
