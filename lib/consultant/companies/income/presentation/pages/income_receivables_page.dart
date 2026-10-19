import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tarazyar/consultant/companies/income/application/income_dashboard_provider.dart';
import 'package:tarazyar/consultant/companies/income/data/income_fiscal_provider.dart';
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

  Future<void> _showReceivableDialog({
    Map<String, dynamic>? existing,
    required double recognizedTotal,
    required double currentReceivablesTotal,
  }) async {
    final period =
        ref.read(incomeFiscalPeriodProvider(widget.periodId)).valueOrNull;

    if (period?['status']?.toString() == 'closed') {
      _message('این دوره بسته شده و امکان ثبت دریافتنی وجود ندارد.');
      return;
    }

    final titleController = TextEditingController(
      text: existing?['title']?.toString() ?? '',
    );

    final amountController = TextEditingController(
      text:
          existing == null ? '' : _formatAmount(_toDouble(existing['amount'])),
    );

    final receivedController = TextEditingController(
      text:
          existing == null
              ? ''
              : _formatAmount(_toDouble(existing['received_documents_amount'])),
    );

    final descriptionController = TextEditingController(
      text: existing?['description']?.toString() ?? '',
    );

    try {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final existingAmount =
                  existing == null ? 0.0 : _toDouble(existing['amount']);

              final currentWithoutExisting =
                  currentReceivablesTotal - existingAmount;

              final enteredAmount = _toDouble(amountController.text);

              final projectedTotal = currentWithoutExisting + enteredAmount;

              final exceedsRecognized =
                  recognizedTotal > 0 && projectedTotal > recognizedTotal;

              return Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  title: Text(
                    existing == null
                        ? 'ثبت حساب دریافتنی'
                        : 'ویرایش حساب دریافتنی',
                  ),
                  content: SizedBox(
                    width: 520,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (recognizedTotal > 0)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: .07),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'درآمد شناسایی‌شده این ماه',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _money(recognizedTotal),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          TextField(
                            controller: titleController,
                            textDirection: TextDirection.rtl,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'عنوان دریافتنی',
                              hintText: 'مثلاً مطالبات فروش فروردین',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9۰-۹٠-٩,٬.]'),
                              ),
                            ],
                            onChanged: (_) {
                              setDialogState(() {});
                            },
                            decoration: const InputDecoration(
                              labelText: 'مبلغ دریافتنی',
                              suffixText: 'ریال',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          if (exceedsRecognized) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'مجموع دریافتنی‌ها از درآمد شناسایی‌شده این ماه بیشتر می‌شود.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextField(
                            controller: receivedController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9۰-۹٠-٩,٬.]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'مبلغ اسناد دریافت‌شده',
                              suffixText: 'ریال',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: descriptionController,
                            textDirection: TextDirection.rtl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'توضیحات',
                              hintText: 'اختیاری',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('انصراف'),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        final title = titleController.text.trim();
                        final amount = _toDouble(amountController.text);
                        final received = _toDouble(receivedController.text);

                        if (title.isEmpty) {
                          _message('عنوان دریافتنی را وارد کنید.');
                          return;
                        }

                        if (amount <= 0) {
                          _message('مبلغ دریافتنی باید بیشتر از صفر باشد.');
                          return;
                        }

                        if (received < 0) {
                          _message(
                            'مبلغ اسناد دریافت‌شده نمی‌تواند منفی باشد.',
                          );
                          return;
                        }

                        if (received > amount) {
                          _message(
                            'مبلغ اسناد دریافت‌شده نمی‌تواند بیشتر از مبلغ دریافتنی باشد.',
                          );
                          return;
                        }

                        Navigator.of(dialogContext).pop(true);
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('ذخیره'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      if (result != true) return;

      final title = titleController.text.trim();
      final amount = _toDouble(amountController.text);
      final received = _toDouble(receivedController.text);
      final description = descriptionController.text.trim();

      if (title.isEmpty || amount <= 0 || received < 0) {
        return;
      }

      if (received > amount) {
        _message(
          'مبلغ اسناد دریافت‌شده نمی‌تواند بیشتر از مبلغ دریافتنی باشد.',
        );
        return;
      }

      final existingAmount =
          existing == null ? 0.0 : _toDouble(existing['amount']);

      final projectedTotal = currentReceivablesTotal - existingAmount + amount;

      if (recognizedTotal > 0 && projectedTotal > recognizedTotal) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text('مغایرت با درآمد شناسایی‌شده'),
                content: Text(
                  'مجموع دریافتنی‌ها پس از این ثبت برابر با '
                  '${_money(projectedTotal)} می‌شود، در حالی که درآمد '
                  'شناسایی‌شده این ماه ${_money(recognizedTotal)} است.\n\n'
                  'آیا می‌خواهید با این مبلغ ادامه دهید؟',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('انصراف'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('ادامه'),
                  ),
                ],
              ),
            );
          },
        );

        if (proceed != true) return;
      }

      setState(() => _saving = true);

      try {
        if (existing == null) {
          await IncomeReceivablesService.saveReceivable(
            companyId: widget.companyId,
            fiscalPeriodId: widget.periodId,
            title: title,
            amount: amount,
            receivedDocumentsAmount: received,
            description: description.isEmpty ? null : description,
          );
        } else {
          await IncomeReceivablesService.updateReceivable(
            id: existing['id'].toString(),
            title: title,
            amount: amount,
            receivedDocumentsAmount: received,
            description: description.isEmpty ? null : description,
          );
        }

        ref.invalidate(incomeReceivablesProvider(widget.periodId));
        ref.invalidate(incomeReceivablesSummaryProvider(widget.periodId));
        ref.invalidate(incomeDashboardProvider(widget.companyId));

        if (mounted) {
          _message(
            existing == null
                ? 'حساب دریافتنی ثبت شد.'
                : 'حساب دریافتنی ویرایش شد.',
          );
        }
      } catch (e) {
        if (mounted) {
          _message(_friendlyError(e));
        }
      } finally {
        if (mounted) {
          setState(() => _saving = false);
        }
      }
    } finally {
      titleController.dispose();
      amountController.dispose();
      receivedController.dispose();
      descriptionController.dispose();
    }
  }

  Future<void> _deleteReceivable(Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف دریافتنی'),
            content: Text(
              'آیا از حذف «${row['title']?.toString() ?? ''}» مطمئن هستید؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() => _saving = true);

      await IncomeReceivablesService.deleteReceivable(row['id'].toString());

      ref.invalidate(incomeReceivablesProvider(widget.periodId));
      ref.invalidate(incomeReceivablesSummaryProvider(widget.periodId));
      ref.invalidate(incomeDashboardProvider(widget.companyId));

      if (mounted) {
        _message('دریافتنی حذف شد.');
      }
    } catch (e) {
      if (mounted) {
        _message(_friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodAsync = ref.watch(incomeFiscalPeriodProvider(widget.periodId));

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
                  ref.invalidate(incomeFiscalPeriodProvider(widget.periodId));
                },
              ),
          data: (period) {
            if (period == null) {
              return const _ErrorView(message: 'دوره درآمد پیدا نشد.');
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

    final remainingRecognized = recognizedTotal - receivablesTotal;

    final width = MediaQuery.sizeOf(context).width;

    final horizontalPadding =
        width >= 1200
            ? 32.0
            : width >= 700
            ? 24.0
            : 16.0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(incomeFiscalPeriodProvider(widget.periodId));
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
          if (!isClosed)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed:
                    _saving
                        ? null
                        : () => _showReceivableDialog(
                          recognizedTotal: recognizedTotal,
                          currentReceivablesTotal: receivablesTotal,
                        ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('ثبت دریافتنی جدید'),
              ),
            ),
          if (!isClosed) const SizedBox(height: 18),
          if (receivables.isEmpty)
            _EmptyReceivables(
              isClosed: isClosed,
              onAdd:
                  isClosed
                      ? null
                      : () => _showReceivableDialog(
                        recognizedTotal: recognizedTotal,
                        currentReceivablesTotal: receivablesTotal,
                      ),
            )
          else
            _ReceivablesList(
              rows: receivables,
              isClosed: isClosed,
              saving: _saving,
              onEdit:
                  (row) => _showReceivableDialog(
                    existing: row,
                    recognizedTotal: recognizedTotal,
                    currentReceivablesTotal: receivablesTotal,
                  ),
              onDelete: _deleteReceivable,
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
  final bool isClosed;
  final bool saving;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const _ReceivablesList({
    required this.rows,
    required this.isClosed,
    required this.saving,
    required this.onEdit,
    required this.onDelete,
  });

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(double value) {
    final text =
        value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString();

    return '${text.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)},')} ریال';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children:
                rows
                    .map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReceivableCard(
                          row: row,
                          isClosed: isClosed,
                          saving: saving,
                          onEdit: () => onEdit(row),
                          onDelete: () => onDelete(row),
                        ),
                      ),
                    )
                    .toList(),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: .12),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 30,
              columns: const [
                DataColumn(label: Text('عنوان')),
                DataColumn(label: Text('مبلغ')),
                DataColumn(label: Text('اسناد دریافت‌شده')),
                DataColumn(label: Text('مانده')),
                DataColumn(label: Text('توضیحات')),
                DataColumn(label: Text('عملیات')),
              ],
              rows:
                  rows.map((row) {
                    final amount = _toDouble(row['amount']);
                    final received = _toDouble(
                      row['received_documents_amount'],
                    );

                    final remaining = (amount - received).clamp(
                      0,
                      double.infinity,
                    );

                    return DataRow(
                      cells: [
                        DataCell(Text(row['title']?.toString() ?? '')),
                        DataCell(Text(_money(amount))),
                        DataCell(Text(_money(received))),
                        DataCell(Text(_money(remaining.toDouble()))),
                        DataCell(
                          SizedBox(
                            width: 220,
                            child: Text(
                              row['description']?.toString() ?? '-',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'ویرایش',
                                onPressed:
                                    isClosed || saving
                                        ? null
                                        : () => onEdit(row),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                              IconButton(
                                tooltip: 'حذف',
                                onPressed:
                                    isClosed || saving
                                        ? null
                                        : () => onDelete(row),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _ReceivableCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final bool isClosed;
  final bool saving;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReceivableCard({
    required this.row,
    required this.isClosed,
    required this.saving,
    required this.onEdit,
    required this.onDelete,
  });

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _money(double value) {
    final text =
        value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString();

    return '${text.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)},')} ریال';
  }

  @override
  Widget build(BuildContext context) {
    final amount = _toDouble(row['amount']);
    final received = _toDouble(row['received_documents_amount']);

    final remaining = (amount - received).clamp(0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
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
            children: [
              Expanded(
                child: Text(
                  row['title']?.toString() ?? '',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!isClosed)
                PopupMenuButton<String>(
                  enabled: !saving,
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder:
                      (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                        PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
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
            value: _money(remaining.toDouble()),
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
        ],
      ),
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
  final bool isClosed;
  final VoidCallback? onAdd;

  const _EmptyReceivables({required this.isClosed, required this.onAdd});

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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (!isClosed && onAdd != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('ثبت دریافتنی'),
            ),
          ],
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
