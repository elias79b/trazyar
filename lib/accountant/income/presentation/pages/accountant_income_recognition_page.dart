import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';
import 'package:tarazyar/accountant/income/application/accountant_income_recognition_provider.dart';

class AccountantIncomeRecognitionPage extends ConsumerWidget {
  final String periodId;

  const AccountantIncomeRecognitionPage({super.key, required this.periodId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountantIncomeRecognitionProvider(periodId));

    return AccountantScaffold(
      currentRoute: '/accountant/income/recognition',
      title: 'ثبت درآمد',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stack) => _ErrorView(
                message: error.toString(),
                onRetry: () {
                  ref.invalidate(accountantIncomeRecognitionProvider(periodId));
                },
              ),
          data: (data) => _RecognitionContent(data: data, periodId: periodId),
        ),
      ),
    );
  }
}

class _RecognitionContent extends ConsumerWidget {
  final AccountantIncomeRecognitionData data;
  final String periodId;

  const _RecognitionContent({required this.data, required this.periodId});

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    AccountantIncomeCategory category,
  ) async {
    final existing = data.recognitionForCategory(category.id);

    final result = await showDialog<_IncomeResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _IncomeDialog(category: category, existing: existing),
    );

    if (result == null) return;

    try {
      await AccountantIncomeRecognitionRepository.saveRecognition(
        periodId: data.period.id,
        companyId: data.period.companyId,
        categoryId: category.id,
        amount: result.amount,
        description: result.description,
      );

      ref.invalidate(accountantIncomeRecognitionProvider(periodId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('درآمد با موفقیت ذخیره شد.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _error(context, e);
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AccountantIncomeRecognition recognition,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('حذف ثبت درآمد'),
              content: const Text('آیا از حذف این ثبت درآمد مطمئن هستید؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('حذف'),
                ),
              ],
            ),
          ),
    );

    if (confirmed != true) return;

    try {
      await AccountantIncomeRecognitionRepository.deleteRecognition(
        periodId: data.period.id,
        recognitionId: recognition.id,
      );

      ref.invalidate(accountantIncomeRecognitionProvider(periodId));

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ثبت درآمد حذف شد.')));
      }
    } catch (e) {
      if (context.mounted) {
        _error(context, e);
      }
    }
  }

  Future<void> _submitToCompanyAdmin(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (!data.period.isOpen) return;

    if (data.recognitions.isEmpty) {
      _error(
        context,
        Exception('قبل از ارسال، حداقل یک سرفصل درآمد باید ثبت شود.'),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('ارسال برای مدیرعامل'),
              content: const Text(
                'پس از ارسال، دوره برای حسابدار قفل می‌شود و امکان ویرایش درآمدها وجود نخواهد داشت.\n\nآیا ادامه می‌دهید؟',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('انصراف'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('ارسال'),
                ),
              ],
            ),
          ),
    );

    if (confirmed != true) return;

    try {
      await AccountantIncomeRecognitionRepository.submitToCompanyAdmin(
        periodId: data.period.id,
      );

      ref.invalidate(accountantIncomeRecognitionProvider(periodId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('دوره برای مدیرعامل ارسال شد.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _error(context, e);
      }
    }
  }

  void _error(BuildContext context, Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operational = data.categories.where((e) => e.isOperational).toList();

    final nonOperational =
        data.categories.where((e) => !e.isOperational).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(accountantIncomeRecognitionProvider(periodId));

        await ref.read(accountantIncomeRecognitionProvider(periodId).future);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 800;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(mobile ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  data: data,
                  mobile: mobile,
                  onSubmit: () => _submitToCompanyAdmin(context, ref),
                ),
                const SizedBox(height: 20),
                _Summary(data: data, mobile: mobile),
                const SizedBox(height: 28),
                _Section(
                  title: 'درآمدهای عملیاتی',
                  subtitle: 'درآمدهای مرتبط با فعالیت اصلی شرکت',
                  icon: Icons.trending_up_rounded,
                  categories: operational,
                  data: data,
                  mobile: mobile,
                  onSave: (category) => _save(context, ref, category),
                  onDelete: (recognition) => _delete(context, ref, recognition),
                ),
                const SizedBox(height: 24),
                _Section(
                  title: 'درآمدهای غیرعملیاتی',
                  subtitle: 'درآمدهای خارج از فعالیت اصلی شرکت',
                  icon: Icons.account_balance_rounded,
                  categories: nonOperational,
                  data: data,
                  mobile: mobile,
                  onSave: (category) => _save(context, ref, category),
                  onDelete: (recognition) => _delete(context, ref, recognition),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AccountantIncomeRecognitionData data;
  final bool mobile;
  final VoidCallback onSubmit;

  const _Header({
    required this.data,
    required this.mobile,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ثبت درآمد دوره',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${data.period.title} • سال ${data.period.year}',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );

    final action =
        data.period.isOpen
            ? FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.send_rounded),
              label: const Text('ارسال برای مدیرعامل'),
            )
            : _StatusChip(
              title: data.period.statusTitle,
              status: data.period.status,
            );

    return Container(
      padding: EdgeInsets.all(mobile ? 18 : 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: .55)),
      ),
      child:
          mobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [title, const SizedBox(height: 18), action],
              )
              : Row(children: [Expanded(child: title), action]),
    );
  }
}

class _Summary extends StatelessWidget {
  final AccountantIncomeRecognitionData data;
  final bool mobile;

  const _Summary({required this.data, required this.mobile});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CardData('درآمد کل', _money(data.totalIncome), Icons.payments_outlined),
      _CardData(
        'درآمد عملیاتی',
        _money(data.operationalTotal),
        Icons.trending_up_rounded,
      ),
      _CardData(
        'درآمد غیرعملیاتی',
        _money(data.nonOperationalTotal),
        Icons.account_balance_rounded,
      ),
    ];

    if (mobile) {
      return Column(
        children:
            cards
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SummaryCard(data: e),
                  ),
                )
                .toList(),
      );
    }

    return Row(
      children:
          cards
              .map(
                (e) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _SummaryCard(data: e),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _CardData {
  final String title;
  final String value;
  final IconData icon;

  const _CardData(this.title, this.value, this.icon);
}

class _SummaryCard extends StatelessWidget {
  final _CardData data;

  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  '${data.value} ریال',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
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

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<AccountantIncomeCategory> categories;
  final AccountantIncomeRecognitionData data;
  final bool mobile;
  final Future<void> Function(AccountantIncomeCategory) onSave;
  final Future<void> Function(AccountantIncomeRecognition) onDelete;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.categories,
    required this.data,
    required this.mobile,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (categories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('سرفصلی ثبت نشده است.', textAlign: TextAlign.center),
            )
          else
            ...categories.map((category) {
              final recognition = data.recognitionForCategory(category.id);

              return _RecognitionTile(
                category: category,
                recognition: recognition,
                editable: data.period.canAccountantEdit,
                mobile: mobile,
                onSave: () => onSave(category),
                onDelete:
                    recognition == null ? null : () => onDelete(recognition),
              );
            }),
        ],
      ),
    );
  }
}

class _RecognitionTile extends StatelessWidget {
  final AccountantIncomeCategory category;
  final AccountantIncomeRecognition? recognition;
  final bool editable;
  final bool mobile;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  const _RecognitionTile({
    required this.category,
    required this.recognition,
    required this.editable,
    required this.mobile,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final info = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            category.isSystem
                ? Icons.lock_outline_rounded
                : Icons.category_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                recognition == null
                    ? 'هنوز مبلغی ثبت نشده است'
                    : '${_money(recognition!.amount)} ریال',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: recognition == null ? null : theme.colorScheme.primary,
                  fontWeight: recognition == null ? null : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 6,
      children: [
        FilledButton.icon(
          onPressed: editable ? onSave : null,
          icon: Icon(
            recognition == null ? Icons.add_rounded : Icons.edit_outlined,
          ),
          label: Text(recognition == null ? 'ثبت درآمد' : 'ویرایش'),
        ),
        if (recognition != null)
          IconButton(
            onPressed: editable ? onDelete : null,
            tooltip: 'حذف',
            icon: const Icon(Icons.delete_outline_rounded),
          ),
      ],
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 5, 12, 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .32),
        borderRadius: BorderRadius.circular(15),
      ),
      child:
          mobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [info, const SizedBox(height: 12), actions],
              )
              : Row(children: [Expanded(child: info), actions]),
    );
  }
}

class _IncomeDialog extends StatefulWidget {
  final AccountantIncomeCategory category;
  final AccountantIncomeRecognition? existing;

  const _IncomeDialog({required this.category, required this.existing});

  @override
  State<_IncomeDialog> createState() => _IncomeDialogState();
}

class _IncomeDialogState extends State<_IncomeDialog> {
  late final TextEditingController _amountController;

  late final TextEditingController _descriptionController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _amountController = TextEditingController(
      text:
          widget.existing == null
              ? ''
              : widget.existing!.amount.round().toString(),
    );

    _descriptionController = TextEditingController(
      text: widget.existing?.description ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(
      _amountController.text.replaceAll(',', '').trim(),
    );

    if (amount == null) return;

    Navigator.of(context).pop(
      _IncomeResult(
        amount: amount,
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(widget.existing == null ? 'ثبت درآمد' : 'ویرایش درآمد'),
        content: SizedBox(
          width: 500,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    widget.category.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'مبلغ درآمد',
                    suffixText: 'ریال',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    final text = value?.replaceAll(',', '').trim();

                    if (text == null || text.isEmpty) {
                      return 'مبلغ الزامی است.';
                    }

                    final amount = double.tryParse(text);

                    if (amount == null || amount < 0) {
                      return 'مبلغ معتبر نیست.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    hintText: 'اختیاری',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.save_outlined),
            label: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }
}

class _IncomeResult {
  final double amount;
  final String? description;

  const _IncomeResult({required this.amount, required this.description});
}

class _StatusChip extends StatelessWidget {
  final String title;
  final String status;

  const _StatusChip({required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color =
        status == 'open'
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == 'open'
                ? Icons.lock_open_rounded
                : Icons.lock_outline_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 54,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 14),
            Text(
              'خطا در دریافت اطلاعات درآمد',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

String _money(double value) {
  final text = value.round().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(text[i]);
  }

  return buffer.toString();
}
