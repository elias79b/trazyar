import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/companies/expenses/application/expense_fiscal_provider.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class ExpenseRecordsPage extends ConsumerStatefulWidget {
  final String companyId;

  const ExpenseRecordsPage({super.key, required this.companyId});

  @override
  ConsumerState<ExpenseRecordsPage> createState() => _ExpenseRecordsPageState();
}

class _ExpenseRecordsPageState extends ConsumerState<ExpenseRecordsPage> {
  String? _selectedYearId;
  String? _selectedPeriodId;
  bool _loading = false;

  String get _route =>
      '/consultant/companies/${widget.companyId}/expenses/records';

  @override
  Widget build(BuildContext context) {
    final yearsAsync = ref.watch(expenseFiscalYearsProvider(widget.companyId));

    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute: _route,
      title: 'رکوردهای هزینه',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 800;

            return ListView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              children: [
                _buildHeader(context, isMobile),
                const SizedBox(height: 20),
                yearsAsync.when(
                  loading:
                      () => const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  error: (error, stack) => _buildError(context, error),
                  data: (years) {
                    if (years.isEmpty) {
                      return _buildEmptyYears(context);
                    }

                    final selectedYear = _resolveSelectedYear(years);

                    return _buildYearContent(
                      context,
                      years,
                      selectedYear,
                      isMobile,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<String, dynamic> _resolveSelectedYear(List<Map<String, dynamic>> years) {
    if (_selectedYearId != null) {
      for (final year in years) {
        if (year['id']?.toString() == _selectedYearId) {
          return year;
        }
      }
    }

    final current = years.first;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_selectedYearId != current['id']?.toString()) {
        setState(() {
          _selectedYearId = current['id']?.toString();
          _selectedPeriodId = null;
        });
      }
    });

    return current;
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(.12)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(.04),
          ),
        ],
      ),
      child:
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderTitle(context),
                  const SizedBox(height: 16),
                  _buildRefreshButton(context),
                ],
              )
              : Row(
                children: [
                  Expanded(child: _buildHeaderTitle(context)),
                  _buildRefreshButton(context),
                ],
              ),
    );
  }

  Widget _buildHeaderTitle(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.receipt_long_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'رکوردهای هزینه',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'مشاهده جزئیات ثبت‌های هزینه بر اساس دوره مالی',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed:
          _loading
              ? null
              : () {
                setState(() {});
              },
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('بروزرسانی'),
    );
  }

  Widget _buildYearContent(
    BuildContext context,
    List<Map<String, dynamic>> years,
    Map<String, dynamic> selectedYear,
    bool isMobile,
  ) {
    final yearId = selectedYear['id']?.toString();

    if (yearId == null || yearId.isEmpty) {
      return _buildError(context, 'شناسه سال مالی نامعتبر است.');
    }

    final periodsAsync = ref.watch(expenseFiscalPeriodsProvider(yearId));

    return Column(
      children: [
        _buildYearSelector(context, years, selectedYear, isMobile),
        const SizedBox(height: 18),
        periodsAsync.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
          error: (error, stack) => _buildError(context, error),
          data: (periods) {
            if (periods.isEmpty) {
              return _buildEmptyPeriods(context);
            }

            final selectedPeriod = _resolveSelectedPeriod(periods);

            return _buildPeriodContent(
              context,
              periods,
              selectedPeriod,
              isMobile,
            );
          },
        ),
      ],
    );
  }

  Widget _buildYearSelector(
    BuildContext context,
    List<Map<String, dynamic>> years,
    Map<String, dynamic> selectedYear,
    bool isMobile,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(.12)),
      ),
      child:
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'سال مالی',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _yearDropdown(years, selectedYear),
                ],
              )
              : Row(
                children: [
                  const Icon(Icons.calendar_today_outlined),
                  const SizedBox(width: 10),
                  const Text(
                    'سال مالی:',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 280,
                    child: _yearDropdown(years, selectedYear),
                  ),
                  const Spacer(),
                  _statusChip(
                    context,
                    selectedYear['status']?.toString() ?? 'open',
                  ),
                ],
              ),
    );
  }

  Widget _yearDropdown(
    List<Map<String, dynamic>> years,
    Map<String, dynamic> selectedYear,
  ) {
    final selectedId = selectedYear['id']?.toString();

    return DropdownButtonFormField<String>(
      value: selectedId,
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'سال مالی',
      ),
      items:
          years
              .map((year) {
                final id = year['id']?.toString();

                if (id == null) {
                  return null;
                }

                final title = year['title']?.toString().trim();
                final number = year['year']?.toString() ?? '';

                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(
                    title == null || title.isEmpty
                        ? number
                        : '$number - $title',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              })
              .whereType<DropdownMenuItem<String>>()
              .toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedYearId = value;
          _selectedPeriodId = null;
        });
      },
    );
  }

  Map<String, dynamic> _resolveSelectedPeriod(
    List<Map<String, dynamic>> periods,
  ) {
    if (_selectedPeriodId != null) {
      for (final period in periods) {
        if (period['id']?.toString() == _selectedPeriodId) {
          return period;
        }
      }
    }

    final openPeriods = periods.where(
      (period) => period['status']?.toString() != 'closed',
    );

    final selected = openPeriods.isNotEmpty ? openPeriods.first : periods.first;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_selectedPeriodId != selected['id']?.toString()) {
        setState(() {
          _selectedPeriodId = selected['id']?.toString();
        });
      }
    });

    return selected;
  }

  Widget _buildPeriodContent(
    BuildContext context,
    List<Map<String, dynamic>> periods,
    Map<String, dynamic> selectedPeriod,
    bool isMobile,
  ) {
    final periodId = selectedPeriod['id']?.toString();

    if (periodId == null || periodId.isEmpty) {
      return _buildError(context, 'شناسه دوره مالی نامعتبر است.');
    }

    return Column(
      children: [
        _buildPeriodSelector(context, periods, selectedPeriod, isMobile),
        const SizedBox(height: 18),
        _buildRecordSection(context, periodId, selectedPeriod, isMobile),
      ],
    );
  }

  Widget _buildPeriodSelector(
    BuildContext context,
    List<Map<String, dynamic>> periods,
    Map<String, dynamic> selectedPeriod,
    bool isMobile,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(.12)),
      ),
      child:
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'دوره مالی',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _periodDropdown(periods, selectedPeriod),
                ],
              )
              : Row(
                children: [
                  const Icon(Icons.calendar_view_month_outlined),
                  const SizedBox(width: 10),
                  const Text(
                    'دوره مالی:',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 300,
                    child: _periodDropdown(periods, selectedPeriod),
                  ),
                  const Spacer(),
                  _statusChip(
                    context,
                    selectedPeriod['status']?.toString() ?? 'open',
                  ),
                ],
              ),
    );
  }

  Widget _periodDropdown(
    List<Map<String, dynamic>> periods,
    Map<String, dynamic> selectedPeriod,
  ) {
    final selectedId = selectedPeriod['id']?.toString();

    return DropdownButtonFormField<String>(
      value: selectedId,
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'دوره مالی',
      ),
      items:
          periods
              .map((period) {
                final id = period['id']?.toString();

                if (id == null) {
                  return null;
                }

                final month = period['month']?.toString() ?? '';
                final year = period['year']?.toString() ?? '';
                final title = period['title']?.toString().trim();

                final label =
                    title == null || title.isEmpty ? '$month - $year' : title;

                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(label, overflow: TextOverflow.ellipsis),
                );
              })
              .whereType<DropdownMenuItem<String>>()
              .toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedPeriodId = value;
        });
      },
    );
  }

  Widget _buildRecordSection(
    BuildContext context,
    String periodId,
    Map<String, dynamic> period,
    bool isMobile,
  ) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadRecords(periodId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _buildError(context, snapshot.error!);
        }

        final records = snapshot.data ?? [];

        return Column(
          children: [
            _buildSummary(context, records, isMobile),
            const SizedBox(height: 18),
            if (records.isEmpty)
              _buildEmptyRecords(context)
            else
              _buildRecordsCard(context, records, isMobile),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadRecords(String periodId) async {
    final client = Supabase.instance.client;

    final response = await client
        .from('expense_recognitions')
        .select('''
          id,
          company_id,
          fiscal_period_id,
          category_id,
          amount,
          description,
          created_by,
          created_at,
          updated_at,
          expense_categories (
            id,
            name,
            code,
            expense_type,
            is_active
          )
        ''')
        .eq('fiscal_period_id', periodId)
        .order('amount', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Widget _buildSummary(
    BuildContext context,
    List<Map<String, dynamic>> records,
    bool isMobile,
  ) {
    double total = 0;
    double operational = 0;
    double nonOperational = 0;

    for (final record in records) {
      final amount = _toDouble(record['amount']);
      final category = record['expense_categories'];

      total += amount;

      if (category is Map &&
          category['expense_type']?.toString() == 'non_operational') {
        nonOperational += amount;
      } else {
        operational += amount;
      }
    }

    final cards = [
      _SummaryData(
        title: 'کل هزینه',
        value: _formatMoney(total),
        icon: Icons.payments_outlined,
      ),
      _SummaryData(
        title: 'عملیاتی',
        value: _formatMoney(operational),
        icon: Icons.trending_up_rounded,
      ),
      _SummaryData(
        title: 'غیرعملیاتی',
        value: _formatMoney(nonOperational),
        icon: Icons.account_balance_outlined,
      ),
      _SummaryData(
        title: 'تعداد ثبت‌ها',
        value: '${records.length}',
        icon: Icons.receipt_long_outlined,
      ),
    ];

    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
        ),
        itemBuilder: (context, index) {
          return _buildSummaryCard(context, cards[index]);
        },
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: _buildSummaryCard(context, cards[i])),
          if (i != cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, _SummaryData data) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, size: 21, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 5),
                Text(
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
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

  Widget _buildRecordsCard(
    BuildContext context,
    List<Map<String, dynamic>> records,
    bool isMobile,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(.12)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 9),
                Text(
                  'جزئیات هزینه‌ها',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text('${records.length} ثبت', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline.withOpacity(.10)),
          if (isMobile)
            _buildMobileRecords(context, records)
          else
            _buildDesktopRecords(context, records),
        ],
      ),
    );
  }

  Widget _buildMobileRecords(
    BuildContext context,
    List<Map<String, dynamic>> records,
  ) {
    return Column(
      children: [
        for (var i = 0; i < records.length; i++) ...[
          _buildMobileRecord(context, records[i]),
          if (i != records.length - 1)
            Divider(
              height: 1,
              indent: 18,
              endIndent: 18,
              color: Theme.of(context).colorScheme.outline.withOpacity(.08),
            ),
        ],
      ],
    );
  }

  Widget _buildMobileRecord(BuildContext context, Map<String, dynamic> record) {
    final category = record['expense_categories'];

    final categoryName =
        category is Map
            ? category['name']?.toString() ?? 'بدون دسته‌بندی'
            : 'بدون دسته‌بندی';

    final code = category is Map ? category['code']?.toString() ?? '' : '';

    final amount = _toDouble(record['amount']);

    final description = record['description']?.toString().trim();

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.receipt_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        categoryName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          [
            if (code.isNotEmpty) code,
            if (description != null && description.isNotEmpty) description,
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Text(
        _formatMoney(amount),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildDesktopRecords(
    BuildContext context,
    List<Map<String, dynamic>> records,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 950,
        child: DataTable(
          headingRowHeight: 50,
          dataRowMinHeight: 64,
          dataRowMaxHeight: 78,
          columnSpacing: 28,
          horizontalMargin: 18,
          columns: const [
            DataColumn(label: Text('دسته‌بندی')),
            DataColumn(label: Text('کد')),
            DataColumn(label: Text('نوع')),
            DataColumn(label: Text('مبلغ')),
            DataColumn(label: Text('شرح')),
          ],
          rows:
              records.map((record) {
                final category = record['expense_categories'];

                final categoryName =
                    category is Map
                        ? category['name']?.toString() ?? 'بدون دسته‌بندی'
                        : 'بدون دسته‌بندی';

                final code =
                    category is Map ? category['code']?.toString() ?? '' : '';

                final type =
                    category is Map
                        ? category['expense_type']?.toString()
                        : null;

                final description = record['description']?.toString().trim();

                final amount = _toDouble(record['amount']);

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        categoryName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DataCell(Text(code.isEmpty ? '—' : code)),
                    DataCell(_typeChip(context, type)),
                    DataCell(
                      Text(
                        _formatMoney(amount),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 260,
                        child: Text(
                          description == null || description.isEmpty
                              ? '—'
                              : description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _typeChip(BuildContext context, String? type) {
    final isNonOperational = type == 'non_operational';

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isNonOperational ? 'غیرعملیاتی' : 'عملیاتی',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final isClosed = status == 'closed';
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            isClosed
                ? theme.colorScheme.error.withOpacity(.08)
                : theme.colorScheme.primary.withOpacity(.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isClosed ? 'بسته' : 'باز',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isClosed ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildEmptyYears(BuildContext context) {
    return _emptyCard(
      context,
      icon: Icons.calendar_today_outlined,
      title: 'سال مالی‌ای وجود ندارد',
      message: 'ابتدا از بخش دوره‌های مالی هزینه، یک سال مالی ایجاد کنید.',
    );
  }

  Widget _buildEmptyPeriods(BuildContext context) {
    return _emptyCard(
      context,
      icon: Icons.calendar_view_month_outlined,
      title: 'دوره مالی‌ای وجود ندارد',
      message: 'برای سال مالی انتخاب‌شده دوره‌ای ایجاد نشده است.',
    );
  }

  Widget _buildEmptyRecords(BuildContext context) {
    return _emptyCard(
      context,
      icon: Icons.receipt_long_outlined,
      title: 'ثبت هزینه‌ای وجود ندارد',
      message: 'برای این دوره هنوز هزینه‌ای ثبت نشده است.',
    );
  }

  Widget _emptyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 55),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(.12)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 52,
            color: theme.colorScheme.primary.withOpacity(.55),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 42,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          const Text(
            'خطا در دریافت اطلاعات',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
            label: const Text('تلاش مجدد'),
          ),
        ],
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '')) ?? 0;
  }

  String _formatMoney(double value) {
    final rounded = value.round();
    final text = rounded.toString();

    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(text[i]);
    }

    return '${buffer.toString()} ریال';
  }
}

class _SummaryData {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.icon,
  });
}
