import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tarazyar/accountant/dashboard/application/accountant_dashboard_provider.dart';
import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';
import 'package:tarazyar/accountant/income/application/accountant_income_categories_provider.dart';

class AccountantIncomeCategoriesPage extends ConsumerStatefulWidget {
  final String companyId;

  const AccountantIncomeCategoriesPage({super.key, required this.companyId});

  @override
  ConsumerState<AccountantIncomeCategoriesPage> createState() =>
      _AccountantIncomeCategoriesPageState();
}

class _AccountantIncomeCategoriesPageState
    extends ConsumerState<AccountantIncomeCategoriesPage> {
  bool _loadingDefaults = false;

  Future<void> _refresh() async {
    ref.invalidate(accountantIncomeCategoriesProvider(widget.companyId));

    await ref.read(accountantIncomeCategoriesProvider(widget.companyId).future);
  }

  Future<void> _ensureDefaults() async {
    if (_loadingDefaults) {
      return;
    }

    setState(() {
      _loadingDefaults = true;
    });

    try {
      await AccountantIncomeCategoriesService.ensureDefaultCategories(
        widget.companyId,
      );

      ref.invalidate(accountantIncomeCategoriesProvider(widget.companyId));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سرفصل‌های پیش‌فرض بررسی و به‌روزرسانی شدند.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showError(e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingDefaults = false;
        });
      }
    }
  }

  Future<void> _addCategory() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _IncomeCategoryDialog(),
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      await AccountantIncomeCategoriesService.createCategory(
        companyId: widget.companyId,
        name: result['name'] as String,
        code: result['code'] as String?,
        description: result['description'] as String?,
        categoryType: result['category_type'] as String,
      );

      if (!mounted) {
        return;
      }

      ref.invalidate(accountantIncomeCategoriesProvider(widget.companyId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سرفصل با موفقیت ایجاد شد.')),
      );
    } catch (e) {
      if (mounted) {
        _showError(e);
      }
    }
  }

  Future<void> _editCategory(Map<String, dynamic> category) async {
    if (category['is_system'] == true) {
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _IncomeCategoryDialog(category: category),
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      await AccountantIncomeCategoriesService.updateCategory(
        id: category['id'].toString(),
        name: result['name'] as String,
        code: result['code'] as String?,
        description: result['description'] as String?,
        categoryType: result['category_type'] as String,
      );

      if (!mounted) {
        return;
      }

      ref.invalidate(accountantIncomeCategoriesProvider(widget.companyId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سرفصل با موفقیت ویرایش شد.')),
      );
    } catch (e) {
      if (mounted) {
        _showError(e);
      }
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    if (category['is_system'] == true) {
      return;
    }

    final name = category['name']?.toString() ?? 'این سرفصل';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('غیرفعال کردن سرفصل'),
            content: Text('آیا از غیرفعال کردن «$name» مطمئن هستید؟'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text('غیرفعال کردن'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    try {
      await AccountantIncomeCategoriesService.deleteCategory(
        category['id'].toString(),
      );

      if (!mounted) {
        return;
      }

      ref.invalidate(accountantIncomeCategoriesProvider(widget.companyId));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('سرفصل غیرفعال شد.')));
    } catch (e) {
      if (mounted) {
        _showError(e);
      }
    }
  }

  void _showError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncCategories = ref.watch(
      accountantIncomeCategoriesProvider(widget.companyId),
    );

    return AccountantScaffold(
      currentRoute: '/accountant/income/categories',
      title: 'سرفصل‌های درآمد',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: asyncCategories.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (error, stack) =>
                  _ErrorView(message: error.toString(), onRetry: _refresh),
          data: (categories) {
            final operational =
                categories
                    .where((item) => item['category_type'] == 'operational')
                    .toList();

            final nonOperational =
                categories
                    .where((item) => item['category_type'] == 'non_operational')
                    .toList();

            final systemCount =
                categories.where((item) => item['is_system'] == true).length;

            final customCount =
                categories.where((item) => item['is_system'] != true).length;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 700;

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(isMobile ? 16 : 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PageHeader(
                          isMobile: isMobile,
                          onAdd: _addCategory,
                          onEnsureDefaults: _ensureDefaults,
                          loadingDefaults: _loadingDefaults,
                        ),
                        const SizedBox(height: 24),
                        _SummaryRow(
                          total: categories.length,
                          system: systemCount,
                          custom: customCount,
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 28),
                        _CategorySection(
                          title: 'درآمدهای عملیاتی',
                          subtitle: 'درآمدهای مرتبط با فعالیت اصلی شرکت',
                          icon: Icons.trending_up_rounded,
                          categories: operational,
                          emptyText: 'هنوز سرفصل عملیاتی ثبت نشده است.',
                          onEdit: _editCategory,
                          onDelete: _deleteCategory,
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 24),
                        _CategorySection(
                          title: 'درآمدهای غیرعملیاتی',
                          subtitle: 'درآمدهایی خارج از فعالیت اصلی شرکت',
                          icon: Icons.account_balance_rounded,
                          categories: nonOperational,
                          emptyText: 'هنوز سرفصل غیرعملیاتی ثبت نشده است.',
                          onEdit: _editCategory,
                          onDelete: _deleteCategory,
                          isMobile: isMobile,
                        ),
                      ],
                    ),
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

class _IncomeCategoryDialog extends StatefulWidget {
  final Map<String, dynamic>? category;

  const _IncomeCategoryDialog({this.category});

  @override
  State<_IncomeCategoryDialog> createState() => _IncomeCategoryDialogState();
}

class _IncomeCategoryDialogState extends State<_IncomeCategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;

  final _formKey = GlobalKey<FormState>();

  late String _categoryType;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final category = widget.category;

    _nameController = TextEditingController(
      text: category?['name']?.toString() ?? '',
    );

    _codeController = TextEditingController(
      text: category?['code']?.toString() ?? '',
    );

    _descriptionController = TextEditingController(
      text: category?['description']?.toString() ?? '',
    );

    _categoryType = category?['category_type']?.toString() ?? 'operational';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _close() {
    if (_saving) {
      return;
    }

    Navigator.of(context).pop();
  }

  void _submit() {
    if (_saving) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'code':
          _codeController.text.trim().isEmpty
              ? null
              : _codeController.text.trim(),
      'description':
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
      'category_type': _categoryType,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isEdit = widget.category != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(isEdit ? 'ویرایش سرفصل درآمد' : 'افزودن سرفصل درآمد'),
        content: SizedBox(
          width: 520,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'نام سرفصل',
                      hintText: 'مثلاً فروش کالا',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'نام سرفصل الزامی است.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'کد سرفصل',
                      hintText: 'اختیاری',
                      prefixIcon: Icon(Icons.tag_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _categoryType,
                    decoration: const InputDecoration(
                      labelText: 'نوع سرفصل',
                      prefixIcon: Icon(Icons.account_tree_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'operational',
                        child: Text('درآمد عملیاتی'),
                      ),
                      DropdownMenuItem(
                        value: 'non_operational',
                        child: Text('درآمد غیرعملیاتی'),
                      ),
                    ],
                    onChanged:
                        _saving
                            ? null
                            : (value) {
                              if (value == null) {
                                return;
                              }

                              setState(() {
                                _categoryType = value;
                              });
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
                  if (widget.category?['is_system'] == true) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_outline_rounded),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('سرفصل سیستمی قابل ویرایش نیست.'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: _close, child: const Text('انصراف')),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: const Icon(Icons.save_outlined),
            label: Text(isEdit ? 'ذخیره' : 'ایجاد'),
          ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onAdd;
  final VoidCallback onEnsureDefaults;
  final bool loadingDefaults;

  const _PageHeader({
    required this.isMobile,
    required this.onAdd,
    required this.onEnsureDefaults,
    required this.loadingDefaults,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: loadingDefaults ? null : onEnsureDefaults,
          icon:
              loadingDefaults
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Icon(Icons.sync_rounded),
          label: const Text('بررسی سرفصل‌های پیش‌فرض'),
        ),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('افزودن سرفصل'),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: .035),
          ),
        ],
      ),
      child:
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HeaderTitle(),
                  const SizedBox(height: 18),
                  actions,
                ],
              )
              : Row(children: [const Expanded(child: _HeaderTitle()), actions]),
    );
  }
}

class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'سرفصل‌های درآمد',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'مدیریت سرفصل‌های سیستمی و اختصاصی درآمد شرکت',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int total;
  final int system;
  final int custom;
  final bool isMobile;

  const _SummaryRow({
    required this.total,
    required this.system,
    required this.custom,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryCardData(
        title: 'کل سرفصل‌ها',
        value: total.toString(),
        icon: Icons.account_tree_outlined,
      ),
      _SummaryCardData(
        title: 'سرفصل‌های سیستمی',
        value: system.toString(),
        icon: Icons.verified_outlined,
      ),
      _SummaryCardData(
        title: 'سرفصل‌های اختصاصی',
        value: custom.toString(),
        icon: Icons.tune_rounded,
      ),
    ];

    if (isMobile) {
      return Column(
        children:
            cards
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SummaryCard(data: item),
                  ),
                )
                .toList(),
      );
    }

    return Row(
      children:
          cards
              .map(
                (item) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _SummaryCard(data: item),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Map<String, dynamic>> categories;
  final String emptyText;
  final bool isMobile;

  final Future<void> Function(Map<String, dynamic>) onEdit;

  final Future<void> Function(Map<String, dynamic>) onDelete;

  const _CategorySection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.categories,
    required this.emptyText,
    required this.onEdit,
    required this.onDelete,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final systemCategories =
        categories.where((item) => item['is_system'] == true).toList();

    final customCategories =
        categories.where((item) => item['is_system'] != true).toList();

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
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: .55)),
          if (systemCategories.isNotEmpty) ...[
            const _SubHeader(
              title: 'سرفصل‌های پیش‌فرض سیستم',
              icon: Icons.verified_rounded,
            ),
            ...systemCategories.map(
              (category) => _CategoryTile(
                category: category,
                onEdit: null,
                onDelete: null,
                isMobile: isMobile,
              ),
            ),
          ],
          if (customCategories.isNotEmpty) ...[
            const _SubHeader(
              title: 'سرفصل‌های اختصاصی شرکت',
              icon: Icons.tune_rounded,
            ),
            ...customCategories.map(
              (category) => _CategoryTile(
                category: category,
                onEdit: () => onEdit(category),
                onDelete: () => onDelete(category),
                isMobile: isMobile,
              ),
            ),
          ],
          if (systemCategories.isEmpty && customCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                emptyText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SubHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: theme.colorScheme.primary),
          const SizedBox(width: 7),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isMobile;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isSystem = category['is_system'] == true;

    final name = category['name']?.toString() ?? '';

    final code = category['code']?.toString();

    final description = category['description']?.toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .32),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isSystem ? Icons.lock_outline_rounded : Icons.category_outlined,
              size: 19,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isSystem)
                      const _Badge(
                        text: 'سیستمی',
                        icon: Icons.verified_outlined,
                      ),
                  ],
                ),
                if (description != null && description.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (code != null && code.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _CodeBadge(code: code),
            ),
          if (!isSystem)
            PopupMenuButton<String>(
              tooltip: 'عملیات',
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit?.call();
                } else if (value == 'delete') {
                  onDelete?.call();
                }
              },
              itemBuilder:
                  (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('ویرایش'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline),
                        title: Text('غیرفعال کردن'),
                      ),
                    ),
                  ],
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Badge({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  final String code;

  const _CodeBadge({required this.code});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: theme.dividerColor.withValues(alpha: .6)),
      ),
      child: Text(
        code,
        style: theme.textTheme.labelSmall?.copyWith(
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
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
                'خطا در دریافت سرفصل‌های درآمد',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message.replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
      ),
    );
  }
}
