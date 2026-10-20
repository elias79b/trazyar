
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tarazyar/consultant/companies/income/application/income_dashboard_provider.dart';
import 'package:tarazyar/consultant/companies/income/data/income_receivable_fiscal_provider.dart';
import 'package:tarazyar/consultant/companies/income/data/income_recognition_provider.dart';
import 'package:tarazyar/consultant/companies/income/data/income_receivables_provider.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class IncomeReceivablesPage extends ConsumerStatefulWidget {
  final String companyId;
  final String periodId;

  const IncomeReceivablesPage({
    super.key,
    required this.companyId,
    required this.periodId,
  });

  @override
  ConsumerState<IncomeReceivablesPage> createState() =>
      _IncomeReceivablesPageState();
}

class _IncomeReceivablesPageState extends ConsumerState<IncomeReceivablesPage> {
  bool _saving = false;

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value
          .toString()
          .replaceAll(',', '')
          .replaceAll('٬', '')
          .replaceAll(' ', '')
          .replaceAll('۰', '0')
          .replaceAll('۱', '1')
          .replaceAll('۲', '2')
          .replaceAll('۳', '3')
          .replaceAll('۴', '4')
          .replaceAll('۵', '5')
          .replaceAll('۶', '6')
          .replaceAll('۷', '7')
          .replaceAll('۸', '8')
          .replaceAll('۹', '9')
          .replaceAll('٠', '0')
          .replaceAll('١', '1')
          .replaceAll('٢', '2')
          .replaceAll('٣', '3')
          .replaceAll('٤', '4')
          .replaceAll('٥', '5')
          .replaceAll('٦', '6')
          .replaceAll('٧', '7')
          .replaceAll('٨', '8')
          .replaceAll('٩', '9'),
    ) ??
        0;
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (match) => '${match.group(1)},',
      );
    }

    return value.toString();
  }

  String _money(double value) {
    return '${_formatAmount(value)} ریال';
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(text),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _friendlyError(Object error) {
    final text = error.toString();

    if (text.contains('permission denied')) {
      return 'دسترسی لازم برای ثبت حساب دریافتنی را ندارید.';
    }

    if (text.contains('JWT')) {
      return 'نشست کاربری منقضی شده است. دوباره وارد شوید.';
    }

    return 'عملیات انجام نشد. دوباره تلاش کنید.';
  }

  Future<void> _approveReceivable(Map<String, dynamic> row) async {
    if (row['status']?.toString() != 'submitted_to_consultant') {
      _message('این حساب در انتظار بررسی مشاور نیست.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأیید حساب دریافتنی'),
          content: Text(
            'آیا حساب «${row['title']?.toString() ?? ''}» را تأیید می‌کنید؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('انصراف'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('تأیید'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await IncomeReceivablesService.approveByConsultant(
        receivableId: row['id'].toString(),
      );

      ref.invalidate(incomeReceivablesProvider(widget.periodId));
      ref.invalidate(incomeReceivablesSummaryProvider(widget.periodId));
      ref.invalidate(incomeDashboardProvider(widget.companyId));

      _message('حساب دریافتنی تأیید شد.');
    } catch (error) {
      _message(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _returnReceivable(Map<String, dynamic> row) async {
    if (row['status']?.toString() != 'submitted_to_consultant') {
      _message('این حساب در انتظار بررسی مشاور نیست.');
      return;
    }

    final noteController = TextEditingController();
    try {
      final note = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('برگشت حساب دریافتنی'),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'علت برگشت حساب «${row['title']?.toString() ?? ''}» را وارد کنید.',
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteController,
                    autofocus: true,
                    maxLines: 3,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'علت برگشت',
                      hintText: 'توضیح دهید چه چیزی باید اصلاح شود',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('انصراف'),
              ),
              FilledButton.icon(
                onPressed: () {
                  final value = noteController.text.trim();
                  if (value.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('علت برگشت را وارد کنید.')),
                    );
                    return;
                  }
                  Navigator.of(dialogContext).pop(value);
                },
                icon: const Icon(Icons.undo_rounded),
                label: const Text('برگشت به اصلاح'),
              ),
            ],
          ),
        ),
      );

      if (note == null || note.trim().isEmpty || !mounted) return;

      setState(() => _saving = true);
      try {
        await IncomeReceivablesService.returnByConsultant(
          receivableId: row['id'].toString(),
          note: note.trim(),
        );

        ref.invalidate(incomeReceivablesProvider(widget.periodId));
        ref.invalidate(incomeReceivablesSummaryProvider(widget.periodId));
        ref.invalidate(incomeDashboardProvider(widget.companyId));

        _message('حساب برای اصلاح برگشت داده شد.');
      } catch (error) {
        _message(_friendlyError(error));
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    } finally {
      noteController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodAsync = ref.watch(incomeReceivableFiscalPeriodProvider(widget.periodId));

    final receivablesAsync = ref.watch(
      incomeReceivablesProvider(widget.periodId),
    );

    final summaryAsync = ref.watch(
      incomeReceivablesSummaryProvider(widget.periodId),
    );

    final recognitionSummaryAsync = ref.watch(
      incomeRecognitionSummaryProvider(widget.periodId),
    );

    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute:
      '/consultant/companies/${widget.companyId}/income/receivables/${widget.periodId}',
      title: 'حساب‌های دریافتنی',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: periodAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (_, __) => _ErrorView(
            message: 'اطلاعات دوره دریافت نشد.',
            onRetry: () {
              ref.invalidate(incomeReceivableFiscalPeriodProvider(widget.periodId));
            },
          ),
          data: (period) {
            if (period == null) {
              // آدرس‌های قدیمی ممکن است شناسه income_fiscal_periods را
              // بفرستند؛ اما صفحه جدید به دوره‌های اختصاصی دریافتنی متصل است.
              // در این حالت کاربر را به فهرست سال‌های مالی دریافتنی هدایت می‌کنیم.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.go(
                    '/consultant/companies/${widget.companyId}/income/receivables',
                  );
                }
              });
              return const Center(child: CircularProgressIndicator());
            }

            return receivablesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (_, __) => _ErrorView(
                message: 'اطلاعات دریافتنی‌ها دریافت نشد.',
                onRetry: () {
                  ref.invalidate(
                    incomeReceivablesProvider(widget.periodId),
                  );
                },
              ),
              data: (receivables) {
                return summaryAsync.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (_, __) => _ErrorView(
                    message: 'خلاصه دریافتنی‌ها دریافت نشد.',
                    onRetry: () {
                      ref.invalidate(
                        incomeReceivablesSummaryProvider(widget.periodId),
                      );
                    },
                  ),
                  data: (summary) {
                    return recognitionSummaryAsync.when(
                      loading:
                          () =>
                      const Center(child: CircularProgressIndicator()),
                      error:
                          (_, __) => _ErrorView(
                        message: 'خلاصه درآمد شناسایی‌شده دریافت نشد.',
                        onRetry: () {
                          ref.invalidate(
                            incomeRecognitionSummaryProvider(
                              widget.periodId,
                            ),
                          );
                        },
                      ),
                      data: (recognitionSummary) {
                        return _buildContent(
                          period: period,
                          receivables: receivables,
                          summary: summary,
                          recognizedTotal: recognitionSummary.total,
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent({
    required Map<String, dynamic> period,
    required List<Map<String, dynamic>> receivables,
    required IncomeReceivablesSummary summary,
    required double recognizedTotal,
  }) {
    final isClosed = period['status']?.toString() == 'closed';

    // استفاده از فیلدهای موجود در IncomeReceivablesSummary
    final receivablesTotal = summary.total;
    final receivedDocuments = summary.receivedDocuments;
    final remainingReceivable = summary.remaining;

    final width = MediaQuery.sizeOf(context).width;

    final horizontalPadding =
    width >= 1200
        ? 32.0
        : width >= 700
        ? 24.0
        : 16.0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(incomeReceivableFiscalPeriodProvider(widget.periodId));
        ref.invalidate(incomeReceivablesProvider(widget.periodId));
        ref.invalidate(incomeReceivablesSummaryProvider(widget.periodId));
        ref.invalidate(incomeRecognitionSummaryProvider(widget.periodId));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          20,
          horizontalPadding,
          32,
        ),
        children: [
          _Header(period: period, isClosed: isClosed),
          const SizedBox(height: 18),
          _SummarySection(
            recognizedTotal: recognizedTotal,
            receivablesTotal: receivablesTotal,
            receivedDocuments: receivedDocuments,
            remainingReceivable: remainingReceivable,
          ),
          const SizedBox(height: 18),
          _FlowBanner(
            recognizedTotal: recognizedTotal,
            receivablesTotal: receivablesTotal,
          ),
          const SizedBox(height: 22),
          if (receivables.isEmpty)
            const _EmptyReceivables()
          else
            _ReceivablesList(
              rows: receivables,
              saving: _saving,
              onApprove: _approveReceivable,
              onReturn: _returnReceivable,
            ),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: () {
              context.push(
                '/consultant/companies/${widget.companyId}/income/recognition/${widget.periodId}',
              );
            },
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('بازگشت به ثبت درآمد ماهانه'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Map<String, dynamic> period;
  final bool isClosed;

  const _Header({required this.period, required this.isClosed});

  @override
  Widget build(BuildContext context) {
    final title = period['title']?.toString() ?? 'دوره درآمد';
    final year = period['year']?.toString() ?? '';
    final month = period['month']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: .12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حساب‌های دریافتنی',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (year.isNotEmpty || month.isNotEmpty)
                  Text(
                    'سال $year • ماه $month',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusChip(closed: isClosed),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final double recognizedTotal;
  final double receivablesTotal;
  final double receivedDocuments;
  final double remainingReceivable;

  const _SummarySection({
    required this.recognizedTotal,
    required this.receivablesTotal,
    required this.receivedDocuments,
    required this.remainingReceivable,
  });

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (match) => '${match.group(1)},',
      );
    }

    return value.toString();
  }

  String _money(double value) {
    return '${_format(value)} ریال';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;

        final items = [
          _SummaryItem(
            title: 'درآمد شناسایی‌شده',
            value: _money(recognizedTotal),
            icon: Icons.receipt_long_rounded,
          ),
          _SummaryItem(
            title: 'کل دریافتنی',
            value: _money(receivablesTotal),
            icon: Icons.request_quote_rounded,
          ),
          _SummaryItem(
            title: 'اسناد دریافت‌شده',
            value: _money(receivedDocuments),
            icon: Icons.task_alt_rounded,
          ),
          _SummaryItem(
            title: 'باقی‌مانده دریافتنی',
            value: _money(remainingReceivable),
            icon: Icons.pending_actions_rounded,
          ),
        ];

        if (compact) {
          return Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i != items.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              Expanded(child: items[i]),
              if (i != items.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}

class _FlowBanner extends StatelessWidget {
  final double recognizedTotal;
  final double receivablesTotal;

  const _FlowBanner({
    required this.recognizedTotal,
    required this.receivablesTotal,
  });

  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (match) => '${match.group(1)},',
      );
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final difference = recognizedTotal - receivablesTotal;
    final hasDifference = difference > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: .10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasDifference
                ? Icons.info_outline_rounded
                : Icons.check_circle_outline_rounded,
            color:
            hasDifference
                ? Theme.of(context).colorScheme.primary
                : Colors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              recognizedTotal <= 0
                  ? 'ابتدا درآمد این ماه را در بخش ثبت درآمد ماهانه شناسایی کنید، سپس دریافتنی‌های آن را ثبت کنید.'
                  : hasDifference
                  ? 'از درآمد شناسایی‌شده، ${_format(difference)} ریال هنوز در دریافتنی‌ها ثبت نشده است.'
                  : 'مجموع دریافتنی‌ها با درآمد شناسایی‌شده این ماه پوشش داده شده است.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivablesList extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final bool saving;
  final Future<void> Function(Map<String, dynamic>) onApprove;
  final Future<void> Function(Map<String, dynamic>) onReturn;

  const _ReceivablesList({
    required this.rows,
    required this.saving,
    required this.onApprove,
    required this.onReturn,
  });

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return '${text.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)},')} ریال';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'باز';
      case 'submitted_to_company_admin':
        return 'ارسال‌شده به مدیر شرکت';
      case 'submitted_to_consultant':
        return 'در انتظار بررسی مشاور';
      case 'approved':
        return 'تأییدشده';
      case 'closed':
        return 'بسته';
      default:
        return status.isEmpty ? 'نامشخص' : status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: rows.map((row) {
        final amount = _toDouble(row['amount']);
        final received = _toDouble(row['received_documents_amount']);
        final remaining = (amount - received).clamp(0.0, double.infinity);
        final status = row['status']?.toString() ?? '';
        final canReview = status == 'submitted_to_consultant';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: .12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      row['title']?.toString() ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (canReview
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline)
                            .withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        _statusLabel(status),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoLine(title: 'مبلغ دریافتنی', value: _money(amount)),
              const SizedBox(height: 8),
              _InfoLine(title: 'اسناد دریافت‌شده', value: _money(received)),
              const SizedBox(height: 8),
              _InfoLine(
                title: 'مانده',
                value: _money(remaining),
                bold: true,
              ),
              if ((row['description']?.toString() ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  row['description'].toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (canReview) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: saving ? null : () => onApprove(row),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('تأیید حساب'),
                    ),
                    OutlinedButton.icon(
                      onPressed: saving ? null : () => onReturn(row),
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('برگشت برای اصلاح'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String title;
  final String value;
  final bool bold;

  const _InfoLine({
    required this.title,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: .12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReceivables extends StatelessWidget {
  const _EmptyReceivables();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: .12),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.request_quote_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'هنوز حساب دریافتنی برای این ماه ثبت نشده است.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool closed;

  const _StatusChip({required this.closed});

  @override
  Widget build(BuildContext context) {
    final color =
    closed
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            closed ? Icons.lock_rounded : Icons.lock_open_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            closed ? 'بسته' : 'باز',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

