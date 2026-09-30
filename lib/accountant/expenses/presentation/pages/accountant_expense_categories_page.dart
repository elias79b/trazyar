import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/accountant/expenses/application/accountant_expense_categories_provider.dart';
import 'package:tarazyar/accountant/expenses/presentation/widgets/accountant_expense_category_dialog.dart';

class AccountantExpenseCategoriesPage extends ConsumerStatefulWidget {
  const AccountantExpenseCategoriesPage({super.key, required this.companyId});

  final String companyId;

  @override
  ConsumerState<AccountantExpenseCategoriesPage> createState() =>
      _AccountantExpenseCategoriesPageState();
}

class _AccountantExpenseCategoriesPageState
    extends ConsumerState<AccountantExpenseCategoriesPage> {
  String _search = '';
  String _typeFilter = 'all';
  bool _activeOnly = false;

  AccountantExpenseCategoriesRepository get _repository {
    return AccountantExpenseCategoriesRepository(Supabase.instance.client);
  }

  Future<void> _refresh() async {
    ref.invalidate(accountantExpenseCategoriesProvider(widget.companyId));

    await ref.read(
      accountantExpenseCategoriesProvider(widget.companyId).future,
    );
  }

  Future<void> _createCategory() async {
    final result = await showDialog<AccountantExpenseCategoryDialogResult>(
      context: context,
      builder: (context) {
        return const AccountantExpenseCategoryDialog();
      },
    );

    if (result == null || !mounted) {
      return;
    }

    try {
      await _repository.createCategory(
        companyId: widget.companyId,
        name: result.name,
        code: result.code,
        description: result.description,
        expenseType: result.expenseType,
      );

      ref.invalidate(accountantExpenseCategoriesProvider(widget.companyId));

      if (!mounted) {
        return;
      }

      _showSuccess('سرفصل هزینه با موفقیت ایجاد شد.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error);
    }
  }

  Future<void> _editCategory(AccountantExpenseCategory category) async {
    final result = await showDialog<AccountantExpenseCategoryDialogResult>(
      context: context,
      builder: (context) {
        return AccountantExpenseCategoryDialog(category: category);
      },
    );

    if (result == null || !mounted) {
      return;
    }

    try {
      await _repository.updateCategory(
        categoryId: category.id,
        companyId: widget.companyId,
        name: result.name,
        code: result.code,
        description: result.description,
        expenseType: result.expenseType,
        isActive: result.isActive,
      );

      ref.invalidate(accountantExpenseCategoriesProvider(widget.companyId));

      if (!mounted) {
        return;
      }

      _showSuccess('تغییرات سرفصل ذخیره شد.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error);
    }
  }

  Future<void> _toggleActive(AccountantExpenseCategory category) async {
    try {
      await _repository.setActive(
        categoryId: category.id,
        companyId: widget.companyId,
        isActive: !category.isActive,
      );

      ref.invalidate(accountantExpenseCategoriesProvider(widget.companyId));

      if (!mounted) {
        return;
      }

      _showSuccess(category.isActive ? 'سرفصل غیرفعال شد.' : 'سرفصل فعال شد.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error);
    }
  }

  Future<void> _deleteCategory(AccountantExpenseCategory category) async {
    if (category.isSystem) {
      _showError('سرفصل سیستمی قابل حذف نیست.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف سرفصل'),
            content: Text('آیا از حذف سرفصل «${category.name}» مطمئن هستید؟'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('انصراف'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _repository.deleteCategory(
        categoryId: category.id,
        companyId: widget.companyId,
      );

      ref.invalidate(accountantExpenseCategoriesProvider(widget.companyId));

      if (!mounted) {
        return;
      }

      _showSuccess('سرفصل با موفقیت حذف شد.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(error);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message, textDirection: TextDirection.rtl)),
      );
  }

  void _showError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(message, textDirection: TextDirection.rtl),
        ),
      );
  }

  List<AccountantExpenseCategory> _filteredCategories(
    List<AccountantExpenseCategory> categories,
  ) {
    final query = _search.trim().toLowerCase();

    return categories.where((category) {
      if (_activeOnly && !category.isActive) {
        return false;
      }

      if (_typeFilter != 'all' && category.expenseType != _typeFilter) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final name = category.name.toLowerCase();
      final code = (category.code ?? '').toLowerCase();
      final description = (category.description ?? '').toLowerCase();

      return name.contains(query) ||
          code.contains(query) ||
          description.contains(query);
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _search = '';
      _typeFilter = 'all';
      _activeOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      accountantExpenseCategoriesProvider(widget.companyId),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: state.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return _ErrorView(error: error, onRetry: _refresh);
        },
        data: (data) {
          final categories = _filteredCategories(data.categories);

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;

              return RefreshIndicator(
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      sliver: SliverToBoxAdapter(
                        child: _buildHeader(context, data, isMobile),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _buildFilters(context, isMobile),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 16 : 24,
                        20,
                        isMobile ? 16 : 24,
                        32,
                      ),
                      sliver:
                          categories.isEmpty
                              ? SliverToBoxAdapter(
                                child: _EmptyView(
                                  hasFilters:
                                      _search.isNotEmpty ||
                                      _typeFilter != 'all' ||
                                      _activeOnly,
                                  onClearFilters: _clearFilters,
                                ),
                              )
                              : SliverGrid(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final category = categories[index];

                                  return _CategoryCard(
                                    category: category,
                                    onEdit: () => _editCategory(category),
                                    onDelete: () => _deleteCategory(category),
                                    onToggleActive:
                                        () => _toggleActive(category),
                                  );
                                }, childCount: categories.length),
                                gridDelegate:
                                    SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: isMobile ? 500 : 420,
                                      mainAxisExtent: isMobile ? 230 : 220,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                              ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AccountantExpenseCategoriesData data,
    bool isMobile,
  ) {
    final operational = data.operationalCategories.length;

    final nonOperational = data.nonOperationalCategories.length;

    final active = data.activeCategories.length;

    final summary = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryChip(
          icon: Icons.list_alt_outlined,
          label: 'کل: ${data.categories.length}',
        ),
        _SummaryChip(icon: Icons.check_circle_outline, label: 'فعال: $active'),
        _SummaryChip(
          icon: Icons.business_center_outlined,
          label: 'عملیاتی: $operational',
        ),
        _SummaryChip(
          icon: Icons.account_balance_outlined,
          label: 'غیرعملیاتی: $nonOperational',
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'سرفصل‌های هزینه',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton.filled(
                onPressed: _createCategory,
                tooltip: 'افزودن سرفصل',
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('مدیریت سرفصل‌های هزینه عملیاتی و غیرعملیاتی شرکت'),
          const SizedBox(height: 16),
          summary,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سرفصل‌های هزینه',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('مدیریت سرفصل‌های هزینه عملیاتی و غیرعملیاتی شرکت'),
              const SizedBox(height: 16),
              summary,
            ],
          ),
        ),
        const SizedBox(width: 24),
        FilledButton.icon(
          onPressed: _createCategory,
          icon: const Icon(Icons.add),
          label: const Text('افزودن سرفصل'),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, bool isMobile) {
    final searchField = TextField(
      onChanged: (value) {
        setState(() {
          _search = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'جستجوی نام، کد یا توضیحات...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon:
            _search.isEmpty
                ? null
                : IconButton(
                  onPressed: () {
                    setState(() {
                      _search = '';
                    });
                  },
                  icon: const Icon(Icons.clear),
                ),
        border: const OutlineInputBorder(),
      ),
    );

    final typeDropdown = DropdownButtonFormField<String>(
      value: _typeFilter,
      decoration: const InputDecoration(
        labelText: 'نوع هزینه',
        prefixIcon: Icon(Icons.filter_alt_outlined),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('همه')),
        DropdownMenuItem(value: 'operational', child: Text('عملیاتی')),
        DropdownMenuItem(value: 'non_operational', child: Text('غیرعملیاتی')),
      ],
      onChanged: (value) {
        setState(() {
          _typeFilter = value ?? 'all';
        });
      },
    );

    final activeSwitch = SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: const Text('فقط سرفصل‌های فعال'),
      value: _activeOnly,
      onChanged: (value) {
        setState(() {
          _activeOnly = value;
        });
      },
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 12),
          typeDropdown,
          activeSwitch,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: searchField),
        const SizedBox(width: 12),
        SizedBox(width: 240, child: typeDropdown),
        const SizedBox(width: 12),
        SizedBox(width: 220, child: activeSwitch),
      ],
    );
  }
}

// ============================================================
// CATEGORY CARD
// ============================================================

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final AccountantExpenseCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final typeColor =
        category.isOperational
            ? theme.colorScheme.primary
            : theme.colorScheme.tertiary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    category.isOperational
                        ? Icons.business_center_outlined
                        : Icons.account_balance_outlined,
                    color: typeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (category.code != null &&
                          category.code!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          category.code!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'عملیات',
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'toggle':
                        onToggleActive();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    return [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('ویرایش'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            category.isActive
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          title: Text(
                            category.isActive ? 'غیرفعال کردن' : 'فعال کردن',
                          ),
                        ),
                      ),
                      if (!category.isSystem)
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.delete_outline),
                            title: Text('حذف'),
                          ),
                        ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CategoryBadge(
                  text: category.expenseTypeTitle,
                  color: typeColor,
                ),
                _CategoryBadge(
                  text: category.isActive ? 'فعال' : 'غیرفعال',
                  color:
                      category.isActive
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                ),
                if (category.isSystem)
                  _CategoryBadge(text: 'سیستمی', color: Colors.indigo.shade700),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                category.description?.trim().isNotEmpty == true
                    ? category.description!
                    : 'بدون توضیحات',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BADGE
// ============================================================

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// SUMMARY CHIP
// ============================================================

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ============================================================
// EMPTY
// ============================================================

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasFilters, required this.onClearFilters});

  final bool hasFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasFilters
                ? Icons.search_off_outlined
                : Icons.account_tree_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'سرفلی مطابق فیلترها پیدا نشد.'
                : 'هنوز سرفصل هزینه‌ای وجود ندارد.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onClearFilters,
              child: const Text('حذف فیلترها'),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error.toString().replaceFirst('Exception: ', '');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'خطا در دریافت سرفصل‌های هزینه',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}
