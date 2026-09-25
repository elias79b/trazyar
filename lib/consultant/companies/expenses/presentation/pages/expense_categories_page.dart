import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/consultant/companies/expenses/application/expense_categories_provider.dart';
import 'package:tarazyar/consultant/companies/expenses/data/expense_category_model.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class ExpenseCategoriesPage extends ConsumerStatefulWidget {
  final String companyId;

  const ExpenseCategoriesPage({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<ExpenseCategoriesPage> createState() =>
      _ExpenseCategoriesPageState();
}

class _ExpenseCategoriesPageState
    extends ConsumerState<ExpenseCategoriesPage> {
  bool _showInactive = false;

  String get _route =>
      '/consultant/companies/${widget.companyId}/expenses/categories';

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(
      expenseCategoriesProvider(widget.companyId),
    );

    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute: _route,
      title: 'دسته‌بندی هزینه‌ها',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                  expenseCategoriesProvider(widget.companyId),
                );

                await ref.read(
                  expenseCategoriesProvider(widget.companyId).future,
                );
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                children: [
                  _buildHeader(context, isMobile),
                  const SizedBox(height: 20),
                  categoriesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => _buildError(
                      context,
                      error,
                    ),
                    data: (categories) {
                      final visibleCategories = _showInactive
                          ? categories
                          : categories
                          .where(
                            (category) => category.isActive,
                      )
                          .toList();

                      return _buildContent(
                        context,
                        visibleCategories,
                        categories,
                        isMobile,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      bool isMobile,
      ) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outline
              .withOpacity(.12),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(.04),
          ),
        ],
      ),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderTitle(context),
          const SizedBox(height: 16),
          _buildInactiveSwitch(),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: _buildHeaderTitle(context),
          ),
          _buildInactiveSwitch(),
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
            Icons.category_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'دسته‌بندی هزینه‌ها',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'مدیریت دسته‌بندی‌های عملیاتی و غیرعملیاتی',
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

  Widget _buildInactiveSwitch() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: _showInactive,
          onChanged: (value) {
            setState(() {
              _showInactive = value;
            });
          },
        ),
        const SizedBox(width: 6),
        const Text('نمایش غیرفعال‌ها'),
      ],
    );
  }

  Widget _buildContent(
      BuildContext context,
      List<ExpenseCategoryModel> categories,
      List<ExpenseCategoryModel> allCategories,
      bool isMobile,
      ) {
    final operational = categories
        .where(
          (item) => item.expenseType != 'non_operational',
    )
        .toList();

    final nonOperational = categories
        .where(
          (item) => item.expenseType == 'non_operational',
    )
        .toList();

    return Column(
      children: [
        _buildSummary(
          context,
          allCategories,
          operational,
          nonOperational,
          isMobile,
        ),
        const SizedBox(height: 20),
        if (categories.isEmpty)
          _buildEmpty(context)
        else
          _buildCategoriesCard(
            context,
            operational,
            nonOperational,
            isMobile,
          ),
      ],
    );
  }

  Widget _buildSummary(
      BuildContext context,
      List<ExpenseCategoryModel> allCategories,
      List<ExpenseCategoryModel> operational,
      List<ExpenseCategoryModel> nonOperational,
      bool isMobile,
      ) {
    final activeCount =
        allCategories.where((item) => item.isActive).length;

    final inactiveCount =
        allCategories.where((item) => !item.isActive).length;

    final cards = [
      _SummaryData(
        title: 'کل دسته‌بندی‌ها',
        value: '${allCategories.length}',
        icon: Icons.category_outlined,
      ),
      _SummaryData(
        title: 'عملیاتی',
        value: '${operational.length}',
        icon: Icons.trending_up_rounded,
      ),
      _SummaryData(
        title: 'غیرعملیاتی',
        value: '${nonOperational.length}',
        icon: Icons.account_balance_outlined,
      ),
      _SummaryData(
        title: 'فعال',
        value: '$activeCount',
        icon: Icons.check_circle_outline,
      ),
      _SummaryData(
        title: 'غیرفعال',
        value: '$inactiveCount',
        icon: Icons.pause_circle_outline,
      ),
    ];

    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.65,
        ),
        itemBuilder: (context, index) {
          return _buildSummaryCard(
            context,
            cards[index],
          );
        },
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(
            child: _buildSummaryCard(
              context,
              cards[i],
            ),
          ),
          if (i != cards.length - 1)
            const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(
      BuildContext context,
      _SummaryData data,
      ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(.12),
        ),
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
            child: Icon(
              data.icon,
              size: 21,
              color: theme.colorScheme.primary,
            ),
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
                const SizedBox(height: 4),
                Text(
                  data.value,
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

  Widget _buildCategoriesCard(
      BuildContext context,
      List<ExpenseCategoryModel> operational,
      List<ExpenseCategoryModel> nonOperational,
      bool isMobile,
      ) {
    return Column(
      children: [
        _buildCategorySection(
          context,
          title: 'هزینه‌های عملیاتی',
          icon: Icons.trending_up_rounded,
          categories: operational,
          isMobile: isMobile,
        ),
        const SizedBox(height: 18),
        _buildCategorySection(
          context,
          title: 'هزینه‌های غیرعملیاتی',
          icon: Icons.account_balance_outlined,
          categories: nonOperational,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildCategorySection(
      BuildContext context, {
        required String title,
        required IconData icon,
        required List<ExpenseCategoryModel> categories,
        required bool isMobile,
      }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(.12),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              14,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${categories.length} مورد',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: theme.colorScheme.outline.withOpacity(.10),
          ),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                'دسته‌بندی‌ای در این بخش وجود ندارد.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else if (isMobile)
            _buildMobileList(
              context,
              categories,
            )
          else
            _buildDesktopTable(
              context,
              categories,
            ),
        ],
      ),
    );
  }

  Widget _buildMobileList(
      BuildContext context,
      List<ExpenseCategoryModel> categories,
      ) {
    return Column(
      children: [
        for (var i = 0; i < categories.length; i++) ...[
          _buildMobileCategoryTile(
            context,
            categories[i],
          ),
          if (i != categories.length - 1)
            Divider(
              height: 1,
              indent: 18,
              endIndent: 18,
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withOpacity(.08),
            ),
        ],
      ],
    );
  }

  Widget _buildMobileCategoryTile(
      BuildContext context,
      ExpenseCategoryModel category,
      ) {
    final theme = Theme.of(context);
    final code = category.code ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 7,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.label_outline_rounded,
          color: theme.colorScheme.primary,
          size: 21,
        ),
      ),
      title: Text(
        category.name,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          code.isEmpty
              ? _typeLabel(category.expenseType)
              : '$code • ${_typeLabel(category.expenseType)}',
        ),
      ),
      trailing: _statusChip(
        context,
        category.isActive,
      ),
    );
  }

  Widget _buildDesktopTable(
      BuildContext context,
      List<ExpenseCategoryModel> categories,
      ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 760,
        child: DataTable(
          headingRowHeight: 48,
          dataRowMinHeight: 62,
          dataRowMaxHeight: 72,
          columnSpacing: 28,
          horizontalMargin: 18,
          columns: const [
            DataColumn(
              label: Text('کد'),
            ),
            DataColumn(
              label: Text('نام دسته‌بندی'),
            ),
            DataColumn(
              label: Text('نوع'),
            ),
            DataColumn(
              label: Text('وضعیت'),
            ),
          ],
          rows: categories.map((category) {
            final code = category.code ?? '';

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    code.isEmpty ? '—' : code,
                  ),
                ),
                DataCell(
                  Text(
                    category.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _typeLabel(category.expenseType),
                  ),
                ),
                DataCell(
                  _statusChip(
                    context,
                    category.isActive,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 60,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(.12),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.category_outlined,
            size: 54,
            color: theme.colorScheme.primary.withOpacity(.55),
          ),
          const SizedBox(height: 16),
          Text(
            'دسته‌بندی‌ای وجود ندارد',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'در حال حاضر دسته‌بندی قابل نمایشی برای هزینه‌ها ثبت نشده است.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildError(
      BuildContext context,
      Object error,
      ) {
    final theme = Theme.of(context);

    return Container(
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
            'خطا در دریافت دسته‌بندی‌های هزینه',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
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
              ref.invalidate(
                expenseCategoriesProvider(widget.companyId),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('تلاش مجدد'),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
      BuildContext context,
      bool isActive,
      ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary.withOpacity(.09)
            : theme.colorScheme.outline.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'فعال' : 'غیرفعال',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isActive
              ? theme.colorScheme.primary
              : theme.textTheme.bodySmall?.color,
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    if (type == 'non_operational') {
      return 'غیرعملیاتی';
    }

    return 'عملیاتی';
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