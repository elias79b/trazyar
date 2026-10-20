import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/companies/income/application/income_access_provider.dart';
import 'package:tarazyar/consultant/companies/income/application/income_categories_provider.dart';
import 'package:tarazyar/consultant/companies/income/application/income_dashboard_provider.dart';
import 'package:tarazyar/consultant/companies/income/data/income_fiscal_provider.dart';
import 'package:tarazyar/consultant/companies/income/data/income_recognition_provider.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class IncomeRecognitionPage extends ConsumerStatefulWidget {
  final String companyId;
  final String periodId;

  const IncomeRecognitionPage({
    super.key,
    required this.companyId,
    required this.periodId,
  });

  @override
  ConsumerState<IncomeRecognitionPage> createState() =>
      _IncomeRecognitionPageState();
}

class _IncomeRecognitionPageState extends ConsumerState<IncomeRecognitionPage> {
  final Map<String, TextEditingController> _amountControllers = {};
  final Map<String, TextEditingController> _descriptionControllers = {};

  bool _hydrated = false;
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

  void _syncControllers(List<Map<String, dynamic>> categories) {
    for (final category in categories) {
      final id = category['id']?.toString();

      if (id == null || id.isEmpty) {
        continue;
      }

      _amountControllers.putIfAbsent(id, () => TextEditingController());

      _descriptionControllers.putIfAbsent(id, () => TextEditingController());
    }
  }

  void _hydrateExisting(
    List<Map<String, dynamic>> categories,
    List<Map<String, dynamic>> recognitions,
  ) {
    if (_hydrated) {
      return;
    }

    _syncControllers(categories);

    for (final row in recognitions) {
      final categoryId = row['category_id']?.toString();

      if (categoryId == null || categoryId.isEmpty) {
        continue;
      }

      final amountController = _amountControllers[categoryId];

      final descriptionController = _descriptionControllers[categoryId];

      if (amountController != null) {
        final amount = _toDouble(row['amount']);

        amountController.text = amount == 0 ? '' : _formatAmount(amount);
      }

      if (descriptionController != null) {
        descriptionController.text = row['description']?.toString() ?? '';
      }
    }

    _hydrated = true;
  }

  double _categoryAmount(String categoryId) {
    return _parseAmount(_amountControllers[categoryId]?.text);
  }

  double get _total {
    double total = 0;

    for (final controller in _amountControllers.values) {
      total += _parseAmount(controller.text);
    }

    return total;
  }

  double _totalByType(List<Map<String, dynamic>> categories, String type) {
    double total = 0;

    for (final category in categories) {
      if (category['category_type']?.toString() != type) {
        continue;
      }

      final id = category['id']?.toString();

      if (id == null || id.isEmpty) {
        continue;
      }

      total += _categoryAmount(id);
    }

    return total;
  }

  Future<void> _save({
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> existing,
    bool continueToReceivables = false,
  }) async {
    if (_saving) {
      return;
    }

    final access = ref.read(incomeAccessProvider(widget.companyId)).valueOrNull;

    if (access == null || !access.canEnterRecognition) {
      _showMessage('شما مجوز ثبت یا ویرایش درآمد را ندارید.', isError: true);
      return;
    }

    final period =
        ref.read(incomeFiscalPeriodProvider(widget.periodId)).valueOrNull;

    if (period == null) {
      _showMessage('اطلاعات دوره درآمد در دسترس نیست.', isError: true);
      return;
    }

    if (period['status']?.toString() == 'closed') {
      _showMessage(
        'این دوره بسته شده و امکان ویرایش درآمد وجود ندارد.',
        isError: true,
      );
      return;
    }

    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      _showMessage('کاربر وارد سیستم نشده است.', isError: true);
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final existingByCategory = <String, Map<String, dynamic>>{};

      for (final row in existing) {
        final categoryId = row['category_id']?.toString();

        if (categoryId != null && categoryId.isNotEmpty) {
          existingByCategory[categoryId] = row;
        }
      }

      int savedCount = 0;
      int deletedCount = 0;

      for (final category in categories) {
        final categoryId = category['id']?.toString();

        if (categoryId == null || categoryId.isEmpty) {
          continue;
        }

        final amount = _categoryAmount(categoryId);

        final description =
            _descriptionControllers[categoryId]?.text.trim() ?? '';

        final old = existingByCategory[categoryId];

        if (amount == 0 && description.isEmpty) {
          if (old != null && old['id'] != null) {
            await IncomeRecognitionService.deleteRecognition(
              old['id'].toString(),
            );

            deletedCount++;
          }

          continue;
        }

        await IncomeRecognitionService.saveRecognition(
          companyId: widget.companyId,
          fiscalPeriodId: widget.periodId,
          categoryId: categoryId,
          amount: amount,
          description: description.isEmpty ? null : description,
        );

        savedCount++;
      }

      ref.invalidate(incomeRecognitionsProvider(widget.periodId));

      ref.invalidate(incomeRecognitionSummaryProvider(widget.periodId));

      ref.invalidate(incomeDashboardProvider(widget.companyId));

      if (!mounted) {
        return;
      }

      _showMessage(
        'درآمد ماهانه با موفقیت ثبت شد.'
        ' ثبت: $savedCount'
        '${deletedCount > 0 ? ' • حذف: $deletedCount' : ''}',
      );

      if (continueToReceivables) {
        await Future<void>.delayed(const Duration(milliseconds: 250));

        if (!mounted) {
          return;
        }

        context.push(
          '/consultant/companies/${widget.companyId}/income/receivables',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('==================================================');
      debugPrint('INCOME RECOGNITION SAVE ERROR');
      debugPrint('companyId: ${widget.companyId}');
      debugPrint('periodId: ${widget.periodId}');
      debugPrint('userId: ${Supabase.instance.client.auth.currentUser?.id}');
      debugPrint('error: $error');
      debugPrint('stackTrace: $stackTrace');
      debugPrint('==================================================');

      if (!mounted) {
        return;
      }

      _showMessage(_extractRealError(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _extractRealError(Object error) {
    if (error is PostgrestException) {
      return _formatPostgrestError(error);
    }

    final text = error.toString().trim();

    if (text.isEmpty) {
      return 'خطای نامشخص در ثبت درآمد.';
    }

    return text.replaceFirst('Exception: ', '');
  }

  String _formatPostgrestError(PostgrestException error) {
    final buffer = StringBuffer();

    buffer.write('خطای دیتابیس درآمد');

    if (error.code != null && error.code!.isNotEmpty) {
      buffer.write('\nکد: ${error.code}');
    }

    if (error.message.isNotEmpty) {
      buffer.write('\nپیام: ${error.message}');
    }

    if (error.details != null && error.details.toString().isNotEmpty) {
      buffer.write('\nجزئیات: ${error.details}');
    }

    if (error.hint != null && error.hint!.isNotEmpty) {
      buffer.write('\nراهنما: ${error.hint}');
    }

    return buffer.toString();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError ? Colors.red.shade800 : null,
          duration: Duration(seconds: isError ? 8 : 3),
          behavior: SnackBarBehavior.floating,
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: SelectableText(
              message,
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(incomeAccessProvider(widget.companyId));

    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute:
          '/consultant/companies/${widget.companyId}/income/recognition/${widget.periodId}',
      title: 'ثبت درآمد ماهانه',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: accessAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stack) => _AccessDeniedView(
                companyId: widget.companyId,
                message: 'دسترسی‌های درآمد قابل بررسی نیست.',
              ),
          data: (access) {
            if (!access.canEnterRecognition) {
              return _AccessDeniedView(
                companyId: widget.companyId,
                message: 'شما مجوز ثبت یا ویرایش درآمد را ندارید.',
              );
            }

            return _buildRecognitionContent();
          },
        ),
      ),
    );
  }

  Widget _buildRecognitionContent() {
    final periodAsync = ref.watch(incomeFiscalPeriodProvider(widget.periodId));

    final categoriesAsync = ref.watch(
      incomeCategoriesProvider(widget.companyId),
    );

    final recognitionsAsync = ref.watch(
      incomeRecognitionsProvider(widget.periodId),
    );

    return periodAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => _ErrorView(
            message: 'اطلاعات دوره درآمد دریافت نشد.',
            onRetry: () {
              ref.invalidate(incomeFiscalPeriodProvider(widget.periodId));
            },
          ),
      data: (period) {
        if (period == null) {
          return const _ErrorView(message: 'دوره درآمد پیدا نشد.');
        }

        return categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stack) => _ErrorView(
                message: 'دسته‌بندی‌های درآمد دریافت نشد.',
                onRetry: () {
                  ref.invalidate(incomeCategoriesProvider(widget.companyId));
                },
              ),
          data: (categories) {
            return recognitionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stack) => _ErrorView(
                    message: 'اطلاعات درآمد این دوره دریافت نشد.',
                    onRetry: () {
                      ref.invalidate(
                        incomeRecognitionsProvider(widget.periodId),
                      );
                    },
                  ),
              data: (recognitions) {
                _syncControllers(categories);
                _hydrateExisting(categories, recognitions);

                return _buildContent(
                  context,
                  period: period,
                  categories: categories,
                  recognitions: recognitions,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required Map<String, dynamic> period,
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> recognitions,
  }) {
    final isClosed = period['status']?.toString() == 'closed';

    final operational = _totalByType(categories, 'operational');

    final nonOperational = _totalByType(categories, 'non_operational');

    final width = MediaQuery.sizeOf(context).width;

    final horizontalPadding =
        width >= 1200
            ? 32.0
            : width >= 700
            ? 24.0
            : 16.0;

    final operationalCategories =
        categories
            .where((item) => item['category_type']?.toString() == 'operational')
            .toList();

    final nonOperationalCategories =
        categories
            .where(
              (item) => item['category_type']?.toString() == 'non_operational',
            )
            .toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(incomeFiscalPeriodProvider(widget.periodId));

        ref.invalidate(incomeCategoriesProvider(widget.companyId));

        ref.invalidate(incomeRecognitionsProvider(widget.periodId));
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
          _buildHeader(context, period: period, isClosed: isClosed),
          const SizedBox(height: 18),
          _buildSummary(
            total: _total,
            operational: operational,
            nonOperational: nonOperational,
          ),
          const SizedBox(height: 24),
          if (isClosed) const _ClosedPeriodBanner(),
          if (isClosed) const SizedBox(height: 18),
          _buildSection(
            context,
            title: 'درآمدهای عملیاتی',
            subtitle: 'مبالغ درآمد ماهانه را به تفکیک دسته‌بندی ثبت کنید.',
            icon: Icons.trending_up_rounded,
            categories: operationalCategories,
            enabled: !isClosed && !_saving,
          ),
          const SizedBox(height: 20),
          _buildSection(
            context,
            title: 'درآمدهای غیرعملیاتی',
            subtitle: 'درآمدهای بانکی، فروش دارایی و سایر درآمدهای غیرعملیاتی.',
            icon: Icons.account_balance_wallet_rounded,
            categories: nonOperationalCategories,
            enabled: !isClosed && !_saving,
          ),
          const SizedBox(height: 24),
          _buildBottomActions(
            context,
            categories: categories,
            recognitions: recognitions,
            isClosed: isClosed,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required Map<String, dynamic> period,
    required bool isClosed,
  }) {
    final periodTitle = period['title']?.toString() ?? 'دوره درآمد';

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
              Icons.receipt_long_rounded,
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
                  'ثبت درآمد ماهانه',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  periodTitle,
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

  Widget _buildSummary({
    required double total,
    required double operational,
    required double nonOperational,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;

        final cards = [
          _SummaryItem(
            title: 'کل درآمد',
            value: _money(total),
            icon: Icons.payments_rounded,
          ),
          _SummaryItem(
            title: 'درآمد عملیاتی',
            value: _money(operational),
            icon: Icons.trending_up_rounded,
          ),
          _SummaryItem(
            title: 'درآمد غیرعملیاتی',
            value: _money(nonOperational),
            icon: Icons.account_balance_wallet_rounded,
          ),
        ];

        if (isCompact) {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1) const SizedBox(width: 14),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Map<String, dynamic>> categories,
    required bool enabled,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: .12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (categories.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('دسته‌بندی فعالی وجود ندارد.'),
              )
            else
              ...categories.map((category) {
                final id = category['id'].toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CategoryIncomeRow(
                    category: category,
                    amountController: _amountControllers[id]!,
                    descriptionController: _descriptionControllers[id]!,
                    enabled: enabled,
                    onChanged: () {
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context, {
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> recognitions,
    required bool isClosed,
  }) {
    if (isClosed) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () {
            context.push(
              '/consultant/companies/${widget.companyId}/income/receivables',
            );
          },
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('مشاهده حساب‌های دریافتنی'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;

        final continueButton = FilledButton.icon(
          onPressed:
              _saving
                  ? null
                  : () => _save(
                    categories: categories,
                    existing: recognitions,
                    continueToReceivables: true,
                  ),
          icon:
              _saving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.arrow_back_rounded),
          label: Text(
            _saving ? 'در حال ثبت...' : 'ذخیره و ادامه به حساب‌های دریافتنی',
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              continueButton,
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed:
                    _saving
                        ? null
                        : () => _save(
                          categories: categories,
                          existing: recognitions,
                        ),
                icon: const Icon(Icons.save_rounded),
                label: const Text('ذخیره فقط'),
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton.icon(
              onPressed:
                  _saving
                      ? null
                      : () =>
                          _save(categories: categories, existing: recognitions),
              icon: const Icon(Icons.save_rounded),
              label: const Text('ذخیره فقط'),
            ),
            const SizedBox(width: 12),
            continueButton,
          ],
        );
      },
    );
  }

  static double _parseAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 0;
    }

    final normalized = value
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
        .replaceAll('٩', '9');

    return double.tryParse(normalized) ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  static String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match.group(1)},',
      );
    }

    return value.toString();
  }

  static String _money(double value) {
    return '${_formatAmount(value)} ریال';
  }
}

class _CategoryIncomeRow extends StatelessWidget {
  final Map<String, dynamic> category;
  final TextEditingController amountController;
  final TextEditingController descriptionController;
  final bool enabled;
  final VoidCallback onChanged;

  const _CategoryIncomeRow({
    required this.category,
    required this.amountController,
    required this.descriptionController,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final name = category['name']?.toString() ?? '';

    final code = category['code']?.toString() ?? '';

    final isSystem = category['is_system'] == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          final title = Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (isSystem)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'سیستمی',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          );

          final codeWidget =
              code.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'کد: $code',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );

          final amount = TextFormField(
            controller: amountController,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹٠-٩,٬.]')),
            ],
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            onChanged: (_) => onChanged(),
            decoration: const InputDecoration(
              labelText: 'مبلغ درآمد',
              hintText: 'مثلاً 1,500,000,000',
              suffixText: 'ریال',
              border: OutlineInputBorder(),
            ),
          );

          final description = TextFormField(
            controller: descriptionController,
            enabled: enabled,
            maxLines: compact ? 2 : 1,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(
              labelText: 'توضیحات',
              hintText: 'اختیاری',
              border: OutlineInputBorder(),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                codeWidget,
                const SizedBox(height: 12),
                amount,
                const SizedBox(height: 10),
                description,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [title, codeWidget],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(flex: 3, child: amount),
              const SizedBox(width: 14),
              Expanded(flex: 4, child: description),
            ],
          );
        },
      ),
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
      padding: const EdgeInsets.all(18),
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
          const SizedBox(width: 12),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

class _ClosedPeriodBanner extends StatelessWidget {
  const _ClosedPeriodBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: .18),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'این دوره بسته است. اطلاعات درآمد فقط به صورت مشاهده‌ای نمایش داده می‌شود.',
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

class _AccessDeniedView extends StatelessWidget {
  final String companyId;
  final String message;

  const _AccessDeniedView({required this.companyId, required this.message});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: color.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.outline.withValues(alpha: .15)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.error.withValues(alpha: .10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 36,
                  color: color.error,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'دسترسی محدود است',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: () {
                  context.go('/consultant/companies/$companyId/income/periods');
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('بازگشت به دوره‌های درآمد'),
              ),
            ],
          ),
        ),
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
