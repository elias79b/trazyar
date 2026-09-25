import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';
import 'package:tarazyar/consultant/companies/expenses/application/expense_fiscal_provider.dart';
import 'package:tarazyar/consultant/companies/expenses/application/expense_recognition_provider.dart';
import 'package:tarazyar/consultant/companies/expenses/application/expense_categories_provider.dart';
import 'package:tarazyar/consultant/companies/expenses/data/expense_category_model.dart';

const Color _projectColor = Color(0xFF163A2B);
const Color _projectColorSoft = Color(0xFFEAF2EE);

const List<String> _jalaliMonths = [
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

class ExpenseRecognitionPage extends ConsumerStatefulWidget {
  final String companyId;
  final String periodId;

  const ExpenseRecognitionPage({
    super.key,
    required this.companyId,
    required this.periodId,
  });

  @override
  ConsumerState<ExpenseRecognitionPage> createState() =>
      _ExpenseRecognitionPageState();
}

class _ExpenseRecognitionPageState
    extends ConsumerState<ExpenseRecognitionPage> {
  final Map<String, TextEditingController> _amountControllers = {};
  final Map<String, TextEditingController> _descriptionControllers = {};

  bool _saving = false;

  @override
  void dispose() {
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }

    for (final controller in _descriptionControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final periodAsync = ref.watch(expenseFiscalPeriodProvider(widget.periodId));

    final recognitionsAsync = ref.watch(
      expenseRecognitionsProvider(widget.periodId),
    );

    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute:
          '/consultant/companies/${widget.companyId}/expenses/recognition/${widget.periodId}',
      title: 'ثبت هزینه ماهانه',
      body: periodAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => _ErrorView(
              message: _errorMessage(error),
              onRetry: () {
                ref.invalidate(expenseFiscalPeriodProvider(widget.periodId));
              },
            ),
        data: (period) {
          if (period == null) {
            return const _NotFoundView();
          }

          final isClosed = period['status']?.toString() == 'closed';

          return recognitionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, stack) => _ErrorView(
                  message: _errorMessage(error),
                  onRetry: () {
                    ref.invalidate(
                      expenseRecognitionsProvider(widget.periodId),
                    );
                  },
                ),
            data: (recognitions) {
              return _ExpenseRecognitionContent(
                companyId: widget.companyId,
                periodId: widget.periodId,
                period: period,
                recognitions: recognitions,
                isClosed: isClosed,
                amountControllers: _amountControllers,
                descriptionControllers: _descriptionControllers,
                saving: _saving,
                onSave: isClosed ? null : _saveAll,
                onRefresh: _refresh,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _saveAll() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final period = await ref.read(
        expenseFiscalPeriodProvider(widget.periodId).future,
      );

      if (period == null) {
        throw Exception('دوره مالی پیدا نشد.');
      }

      if (period['status']?.toString() == 'closed') {
        throw Exception('این دوره مالی بسته است و امکان ثبت هزینه وجود ندارد.');
      }

      final categories = await ref.read(
        activeExpenseCategoriesProvider(widget.companyId).future,
      );

      for (final category in categories) {
        final categoryId = category.id;

        final amountController = _amountControllers[categoryId];
        final descriptionController = _descriptionControllers[categoryId];

        if (amountController == null) {
          continue;
        }

        final amount = _parseAmount(amountController.text);

        await ExpenseRecognitionService.saveRecognition(
          companyId: widget.companyId,
          fiscalPeriodId: widget.periodId,
          categoryId: categoryId,
          amount: amount,
          description: descriptionController?.text.trim(),
        );
      }

      ref.invalidate(expenseRecognitionsProvider(widget.periodId));

      ref.invalidate(expenseRecognitionSummaryProvider(widget.periodId));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هزینه‌های ماه با موفقیت ثبت شد.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(expenseFiscalPeriodProvider(widget.periodId));

    ref.invalidate(expenseRecognitionsProvider(widget.periodId));

    ref.invalidate(expenseRecognitionSummaryProvider(widget.periodId));

    await ref.read(expenseRecognitionsProvider(widget.periodId).future);
  }

  double _parseAmount(String value) {
    var normalized = value.trim();

    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const english = '0123456789';

    for (var i = 0; i < 10; i++) {
      normalized = normalized.replaceAll(persian[i], english[i]);

      normalized = normalized.replaceAll(arabic[i], english[i]);
    }

    normalized = normalized
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('،', '')
        .replaceAll(' ', '');

    if (normalized.isEmpty) {
      return 0;
    }

    final parsed = double.tryParse(normalized);

    if (parsed == null) {
      throw Exception('یکی از مبالغ واردشده معتبر نیست.');
    }

    if (parsed < 0) {
      throw Exception('مبلغ هزینه نمی‌تواند منفی باشد.');
    }

    return parsed;
  }

  String _errorMessage(Object error) {
    if (error is PostgrestException) {
      return error.message;
    }

    return error.toString().replaceFirst('Exception: ', '');
  }
}

class _ExpenseRecognitionContent extends ConsumerWidget {
  final String companyId;
  final String periodId;
  final Map<String, dynamic> period;
  final List<Map<String, dynamic>> recognitions;
  final bool isClosed;

  final Map<String, TextEditingController> amountControllers;
  final Map<String, TextEditingController> descriptionControllers;

  final bool saving;
  final VoidCallback? onSave;
  final Future<void> Function() onRefresh;

  const _ExpenseRecognitionContent({
    required this.companyId,
    required this.periodId,
    required this.period,
    required this.recognitions,
    required this.isClosed,
    required this.amountControllers,
    required this.descriptionControllers,
    required this.saving,
    required this.onSave,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(
      activeExpenseCategoriesProvider(companyId),
    );

    final summaryAsync = ref.watch(expenseRecognitionSummaryProvider(periodId));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(isMobile ? 14 : 24),
              children: [
                _Header(
                  period: period,
                  isClosed: isClosed,
                  saving: saving,
                  onSave: onSave,
                  onBack: () => context.pop(),
                ),
                const SizedBox(height: 18),
                summaryAsync.when(
                  loading: () => const _SummaryLoading(),
                  error:
                      (error, stack) =>
                          _SummaryError(message: error.toString()),
                  data: (summary) => _SummaryCards(summary: summary),
                ),
                const SizedBox(height: 18),
                categoriesAsync.when(
                  loading:
                      () => const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  error:
                      (error, stack) => _ErrorView(
                        message: error.toString(),
                        onRetry: () {
                          ref.invalidate(
                            activeExpenseCategoriesProvider(companyId),
                          );
                        },
                      ),
                  data: (categories) {
                    if (categories.isEmpty) {
                      return const _NoCategories();
                    }

                    return _CategorySection(
                      categories: categories,
                      recognitions: recognitions,
                      isClosed: isClosed,
                      amountControllers: amountControllers,
                      descriptionControllers: descriptionControllers,
                    );
                  },
                ),
                const SizedBox(height: 24),
                if (!isClosed) _BottomSaveBar(saving: saving, onSave: onSave),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Map<String, dynamic> period;
  final bool isClosed;
  final bool saving;
  final VoidCallback? onSave;
  final VoidCallback onBack;

  const _Header({
    required this.period,
    required this.isClosed,
    required this.saving,
    required this.onSave,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final month = (period['month'] as num?)?.toInt() ?? 0;

    final year = period['year']?.toString() ?? '-';

    final monthTitle =
        month >= 1 && month <= 12
            ? _jalaliMonths[month - 1]
            : period['title']?.toString() ?? 'دوره مالی';

    final title = period['title']?.toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          final titleWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ثبت هزینه ماهانه',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _projectColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title?.isNotEmpty == true ? title! : '$monthTitle $year',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isClosed ? Colors.grey.shade100 : _projectColorSoft,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  isClosed ? 'دوره بسته است' : 'دوره باز است',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isClosed ? Colors.grey.shade700 : _projectColor,
                  ),
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('بازگشت'),
              ),
              if (!isClosed)
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _projectColor),
                  onPressed: saving ? null : onSave,
                  icon:
                      saving
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'در حال ذخیره...' : 'ذخیره هزینه‌ها'),
                ),
            ],
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [titleWidget, const SizedBox(height: 16), actions],
            );
          }

          return Row(
            children: [
              Expanded(child: titleWidget),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final ExpenseRecognitionSummary summary;

  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        title: 'کل هزینه ماه',
        value: _money(summary.total),
        icon: Icons.account_balance_wallet_outlined,
      ),
      _MetricCard(
        title: 'هزینه عملیاتی',
        value: _money(summary.operational),
        icon: Icons.trending_up,
      ),
      _MetricCard(
        title: 'هزینه غیرعملیاتی',
        value: _money(summary.nonOperational),
        icon: Icons.category_outlined,
      ),
      _MetricCard(
        title: 'دسته‌های ثبت‌شده',
        value: summary.categoryCount.toString(),
        icon: Icons.list_alt_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _projectColorSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _projectColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _projectColor,
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

class _CategorySection extends StatelessWidget {
  final List<ExpenseCategoryModel> categories;
  final List<Map<String, dynamic>> recognitions;
  final bool isClosed;

  final Map<String, TextEditingController> amountControllers;
  final Map<String, TextEditingController> descriptionControllers;

  const _CategorySection({
    required this.categories,
    required this.recognitions,
    required this.isClosed,
    required this.amountControllers,
    required this.descriptionControllers,
  });

  @override
  Widget build(BuildContext context) {
    final operational =
        categories
            .where((category) => category.expenseType == 'operational')
            .toList();

    final nonOperational =
        categories
            .where((category) => category.expenseType == 'non_operational')
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (operational.isNotEmpty)
          _CategoryGroup(
            title: 'هزینه‌های عملیاتی',
            subtitle: 'هزینه‌های مرتبط با فعالیت اصلی شرکت',
            icon: Icons.business_center_outlined,
            categories: operational,
            recognitions: recognitions,
            isClosed: isClosed,
            amountControllers: amountControllers,
            descriptionControllers: descriptionControllers,
          ),
        if (operational.isNotEmpty && nonOperational.isNotEmpty)
          const SizedBox(height: 18),
        if (nonOperational.isNotEmpty)
          _CategoryGroup(
            title: 'هزینه‌های غیرعملیاتی',
            subtitle: 'هزینه‌هایی خارج از فعالیت اصلی شرکت',
            icon: Icons.category_outlined,
            categories: nonOperational,
            recognitions: recognitions,
            isClosed: isClosed,
            amountControllers: amountControllers,
            descriptionControllers: descriptionControllers,
          ),
      ],
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<ExpenseCategoryModel> categories;
  final List<Map<String, dynamic>> recognitions;
  final bool isClosed;

  final Map<String, TextEditingController> amountControllers;
  final Map<String, TextEditingController> descriptionControllers;

  const _CategoryGroup({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.categories,
    required this.recognitions,
    required this.isClosed,
    required this.amountControllers,
    required this.descriptionControllers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _projectColorSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _projectColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _projectColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...categories.map((category) {
            final recognition = _findRecognition(category.id);

            final amountController = _controllerFor(category, recognition);

            final descriptionController = _descriptionControllerFor(
              category,
              recognition,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategoryRow(
                category: category,
                isClosed: isClosed,
                amountController: amountController,
                descriptionController: descriptionController,
              ),
            );
          }),
        ],
      ),
    );
  }

  Map<String, dynamic>? _findRecognition(String categoryId) {
    for (final row in recognitions) {
      if (row['category_id']?.toString() == categoryId) {
        return row;
      }
    }

    return null;
  }

  TextEditingController _controllerFor(
    ExpenseCategoryModel category,
    Map<String, dynamic>? recognition,
  ) {
    final id = category.id;

    final existing = amountControllers[id];

    if (existing != null) {
      return existing;
    }

    final controller = TextEditingController(
      text: _formatInitialAmount(recognition?['amount']),
    );

    amountControllers[id] = controller;

    return controller;
  }

  TextEditingController _descriptionControllerFor(
    ExpenseCategoryModel category,
    Map<String, dynamic>? recognition,
  ) {
    final id = category.id;

    final existing = descriptionControllers[id];

    if (existing != null) {
      return existing;
    }

    final controller = TextEditingController(
      text: recognition?['description']?.toString() ?? '',
    );

    descriptionControllers[id] = controller;

    return controller;
  }

  String _formatInitialAmount(dynamic value) {
    if (value == null) return '';

    if (value is num) {
      if (value == 0) return '';

      return _formatNumber(value.toDouble());
    }

    final parsed = double.tryParse(value.toString());

    if (parsed == null || parsed == 0) {
      return '';
    }

    return _formatNumber(parsed);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class _CategoryRow extends StatelessWidget {
  final ExpenseCategoryModel category;
  final bool isClosed;
  final TextEditingController amountController;
  final TextEditingController descriptionController;

  const _CategoryRow({
    required this.category,
    required this.isClosed,
    required this.amountController,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    final categoryName = category.name;
    final code = category.code;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child:
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CategoryTitle(name: categoryName, code: code),
                  const SizedBox(height: 12),
                  _AmountField(
                    controller: amountController,
                    enabled: !isClosed,
                  ),
                  const SizedBox(height: 10),
                  _DescriptionField(
                    controller: descriptionController,
                    enabled: !isClosed,
                  ),
                ],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 230,
                    child: _CategoryTitle(name: categoryName, code: code),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AmountField(
                      controller: amountController,
                      enabled: !isClosed,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DescriptionField(
                      controller: descriptionController,
                      enabled: !isClosed,
                    ),
                  ),
                ],
              ),
    );
  }
}

class _CategoryTitle extends StatelessWidget {
  final String name;
  final String? code;

  const _CategoryTitle({required this.name, required this.code});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _projectColor,
          ),
        ),
        if (code != null && code!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'کد: $code',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
      ],
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _AmountField({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: 'مبلغ هزینه ماه',
        hintText: 'مثلاً ۵۰۰۰۰۰۰۰۰',
        suffixText: 'ریال',
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const _DescriptionField({required this.controller, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: 1,
      decoration: InputDecoration(
        labelText: 'توضیحات',
        hintText: 'توضیحات اختیاری',
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}

class _BottomSaveBar extends StatelessWidget {
  final bool saving;
  final VoidCallback? onSave;

  const _BottomSaveBar({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: _projectColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'مبالغ این صفحه به‌صورت مجموع ماهانه برای هر دسته‌بندی ثبت می‌شوند.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _projectColor),
            onPressed: saving ? null : onSave,
            icon:
                saving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.save_outlined),
            label: Text(saving ? 'در حال ذخیره...' : 'ذخیره هزینه‌ها'),
          ),
        ],
      ),
    );
  }
}

class _SummaryLoading extends StatelessWidget {
  const _SummaryLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const CircularProgressIndicator(),
    );
  }
}

class _SummaryError extends StatelessWidget {
  final String message;

  const _SummaryError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade700)),
    );
  }
}

class _NoCategories extends StatelessWidget {
  const _NoCategories();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(child: Text('هیچ دسته‌بندی هزینه‌ای فعال نیست.')),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Text('دوره مالی موردنظر پیدا نشد.'),
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
    return Center(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _projectColor),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _money(double value) {
  return _formatWithSeparator(value.round().toString());
}

String _formatWithSeparator(String value) {
  final buffer = StringBuffer();

  final negative = value.startsWith('-');

  final digits = negative ? value.substring(1) : value;

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(digits[i]);
  }

  return negative ? '-${buffer.toString()}' : buffer.toString();
}
