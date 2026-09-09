import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/expense_categories_provider.dart';
import '../../application/expense_provider.dart';
import '../../data/expense_category_model.dart';

class ExpenseCategoryDialog extends ConsumerStatefulWidget {
  const ExpenseCategoryDialog({
    super.key,
    required this.companyId,
    this.category,
  });

  final String companyId;
  final ExpenseCategoryModel? category;

  @override
  ConsumerState<ExpenseCategoryDialog> createState() =>
      _ExpenseCategoryDialogState();
}

class _ExpenseCategoryDialogState extends ConsumerState<ExpenseCategoryDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;

  late String _expenseType;
  late bool _isActive;

  bool _saving = false;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();

    final category = widget.category;

    _nameController = TextEditingController(text: category?.name ?? '');

    _codeController = TextEditingController(text: category?.code ?? '');

    _descriptionController = TextEditingController(
      text: category?.description ?? '',
    );

    _expenseType = category?.expenseType ?? 'operational';

    _isActive = category?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'ویرایش دسته‌بندی هزینه' : 'دسته‌بندی هزینه جدید'),
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
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'نام دسته‌بندی *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'نام دسته‌بندی را وارد کنید.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'کد',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _expenseType,
                  decoration: const InputDecoration(
                    labelText: 'نوع هزینه *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'operational',
                      child: Text('عملیاتی'),
                    ),
                    DropdownMenuItem(
                      value: 'non_operational',
                      child: Text('غیرعملیاتی'),
                    ),
                  ],
                  onChanged:
                      _saving
                          ? null
                          : (value) {
                            if (value == null) return;

                            setState(() {
                              _expenseType = value;
                            });
                          },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_saving,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged:
                      _saving
                          ? null
                          : (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                  title: const Text('فعال'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child:
              _saving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(_isEdit ? 'ذخیره' : 'ثبت'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final repository = ref.read(expenseRepositoryProvider);

      if (_isEdit) {
        await repository.updateCategory(
          categoryId: widget.category!.id,
          name: _nameController.text,
          code: _codeController.text,
          description: _descriptionController.text,
          expenseType: _expenseType,
          isActive: _isActive,
        );
      } else {
        await repository.createCategory(
          companyId: widget.companyId,
          name: _nameController.text,
          code: _codeController.text,
          description: _descriptionController.text,
          expenseType: _expenseType,
        );
      }

      ref.invalidate(expenseCategoriesProvider(widget.companyId));

      ref.invalidate(activeExpenseCategoriesProvider(widget.companyId));

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'دسته‌بندی با موفقیت ویرایش شد.'
                : 'دسته‌بندی با موفقیت ثبت شد.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}
