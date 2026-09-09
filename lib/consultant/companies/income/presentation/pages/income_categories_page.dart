import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

import '../../application/income_categories_provider.dart';
import '../widgets/income_category_dialog.dart';

class IncomeCategoriesPage extends ConsumerWidget {
  final String companyId;

  const IncomeCategoriesPage({super.key, required this.companyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(incomeCategoriesProvider(companyId));

    return CompanyScaffold(
      companyId: companyId,
      currentRoute: '/consultant/companies/$companyId/income/categories',
      title: 'دسته‌بندی درآمد',
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 50, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('خطا در دریافت دسته‌بندی‌ها'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      ref.invalidate(incomeCategoriesProvider(companyId));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('تلاش مجدد'),
                  ),
                ],
              ),
            ),
        data: (categories) {
          return _CategoriesContent(
            companyId: companyId,
            categories: categories,
          );
        },
      ),
    );
  }
}

class _CategoriesContent extends ConsumerWidget {
  final String companyId;
  final List<Map<String, dynamic>> categories;

  const _CategoriesContent({required this.companyId, required this.categories});

  Future<void> _openDialog(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? category,
  }) async {
    await showDialog(
      context: context,
      builder:
          (_) => IncomeCategoryDialog(companyId: companyId, category: category),
    );

    ref.invalidate(incomeCategoriesProvider(companyId));
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف دسته‌بندی'),
          content: Text(
            'آیا از حذف دسته‌بندی «$name» مطمئن هستید؟\n\n'
            'درآمدهای قبلی حذف نمی‌شوند و دسته‌بندی آن‌ها خالی خواهد شد.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref.read(incomeCategoryServiceProvider).deleteCategory(id);

      ref.invalidate(incomeCategoriesProvider(companyId));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('دسته‌بندی با موفقیت حذف شد')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در حذف دسته‌بندی: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ==================================================
          // HEADER
          // ==================================================
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دسته‌بندی درآمد',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'مدیریت دسته‌بندی‌های مستقل درآمد',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('دسته جدید'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Expanded(
            child:
                categories.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 70,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'هنوز دسته‌بندی درآمدی ثبت نشده است',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _openDialog(context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('ایجاد دسته‌بندی'),
                          ),
                        ],
                      ),
                    )
                    : ListView.separated(
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final category = categories[index];

                        final id = category['id'] as String;

                        final name = category['name']?.toString() ?? '-';

                        final code = category['code']?.toString();

                        final description = category['description']?.toString();

                        final isActive = category['is_active'] as bool? ?? true;

                        return Card(
                          elevation: 0,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFE8F5E9),
                              child: Icon(
                                Icons.category_outlined,
                                color:
                                    isActive
                                        ? const Color(0xFF0F5132)
                                        : Colors.grey,
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (code != null && code.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('کد: $code'),
                                  ),
                                if (description != null &&
                                    description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(description),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    isActive ? 'فعال' : 'غیرفعال',
                                    style: TextStyle(
                                      color:
                                          isActive
                                              ? Colors.green.shade700
                                              : Colors.grey.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openDialog(context, ref, category: category);
                                }

                                if (value == 'delete') {
                                  _delete(context, ref, id, name);
                                }
                              },
                              itemBuilder:
                                  (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined),
                                          SizedBox(width: 8),
                                          Text('ویرایش'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text('حذف'),
                                        ],
                                      ),
                                    ),
                                  ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
