import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/expense_categories_provider.dart';
import '../../application/expense_provider.dart';
import '../../data/expense_category_model.dart';
import '../widgets/expense_category_dialog.dart';

class ExpenseCategoriesPage extends ConsumerWidget {
  const ExpenseCategoriesPage({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider(companyId));

    return CompanyScaffold(
      companyId: companyId,
      currentRoute: '/consultant/companies/$companyId/expenses/categories',
      title: 'دسته‌بندی هزینه‌ها',
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => _ErrorView(
              message: error.toString(),
              onRetry: () {
                ref.invalidate(expenseCategoriesProvider(companyId));
              },
            ),
        data: (categories) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(expenseCategoriesProvider(companyId));

              await ref.read(expenseCategoriesProvider(companyId).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header(
                  count: categories.length,
                  onAdd: () => _openDialog(context, ref),
                ),
                const SizedBox(height: 16),
                if (categories.isEmpty)
                  const _EmptyView()
                else
                  ..._buildSections(context, ref, categories),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSections(
    BuildContext context,
    WidgetRef ref,
    List<ExpenseCategoryModel> categories,
  ) {
    final operational =
        categories.where((item) => item.expenseType == 'operational').toList();

    final nonOperational =
        categories
            .where((item) => item.expenseType == 'non_operational')
            .toList();

    return [
      _Section(
        title: 'هزینه‌های عملیاتی',
        icon: Icons.business_center_outlined,
        categories: operational,
        onEdit: (category) => _openDialog(context, ref, category: category),
        onDelete: (category) => _deleteCategory(context, ref, category),
      ),
      const SizedBox(height: 16),
      _Section(
        title: 'هزینه‌های غیرعملیاتی',
        icon: Icons.account_balance_outlined,
        categories: nonOperational,
        onEdit: (category) => _openDialog(context, ref, category: category),
        onDelete: (category) => _deleteCategory(context, ref, category),
      ),
    ];
  }

  Future<void> _openDialog(
    BuildContext context,
    WidgetRef ref, {
    ExpenseCategoryModel? category,
  }) async {
    await showDialog<void>(
      context: context,
      builder:
          (_) =>
              ExpenseCategoryDialog(companyId: companyId, category: category),
    );

    ref.invalidate(expenseCategoriesProvider(companyId));

    ref.invalidate(activeExpenseCategoriesProvider(companyId));
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    ExpenseCategoryModel category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف دسته‌بندی'),
          content: Text('آیا از حذف «${category.name}» مطمئن هستید؟'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final repository = ref.read(expenseRepositoryProvider);

      await repository.deleteCategory(category.id);

      ref.invalidate(expenseCategoriesProvider(companyId));

      ref.invalidate(activeExpenseCategoriesProvider(companyId));

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('دسته‌بندی حذف شد.')));
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حذف دسته‌بندی انجام نشد: $error')),
      );
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onAdd});

  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'دسته‌بندی هزینه‌ها',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('$count دسته‌بندی'),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('دسته‌بندی جدید'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final IconData icon;
  final List<ExpenseCategoryModel> categories;
  final ValueChanged<ExpenseCategoryModel> onEdit;
  final ValueChanged<ExpenseCategoryModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text('${categories.length}'),
              ],
            ),
            const Divider(height: 24),
            if (categories.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('دسته‌بندی‌ای در این بخش وجود ندارد.'),
              )
            else
              ...categories.map(
                (category) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Icon(category.isActive ? Icons.check : Icons.block),
                  ),
                  title: Text(category.name),
                  subtitle: Text(
                    [
                      if (category.code != null &&
                          category.code!.trim().isNotEmpty)
                        'کد: ${category.code}',
                      category.isActive ? 'فعال' : 'غیرفعال',
                    ].join(' • '),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit(category);
                      } else if (value == 'delete') {
                        onDelete(category);
                      }
                    },
                    itemBuilder:
                        (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                          PopupMenuItem(value: 'delete', child: Text('حذف')),
                        ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('هیچ دسته‌بندی‌ای ثبت نشده است.')),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            const Text(
              'خطا در دریافت دسته‌بندی‌ها',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('تلاش مجدد')),
          ],
        ),
      ),
    );
  }
}
