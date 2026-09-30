import 'package:flutter/material.dart';

import 'package:tarazyar/accountant/expenses/application/accountant_expense_categories_provider.dart';

class AccountantExpenseCategoryDialog extends StatefulWidget {
  const AccountantExpenseCategoryDialog({super.key, this.category});

  final AccountantExpenseCategory? category;

  bool get isEditing => category != null;

  @override
  State<AccountantExpenseCategoryDialog> createState() =>
      _AccountantExpenseCategoryDialogState();
}

class _AccountantExpenseCategoryDialogState
    extends State<AccountantExpenseCategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;

  String _expenseType = 'operational';
  bool _isActive = true;

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

  void _submit() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showError('نام سرفصل هزینه را وارد کنید.');
      return;
    }

    if (_expenseType != 'operational' && _expenseType != 'non_operational') {
      _showError('نوع هزینه را انتخاب کنید.');
      return;
    }

    Navigator.of(context).pop(
      AccountantExpenseCategoryDialogResult(
        name: name,
        code: _nullableText(_codeController.text),
        description: _nullableText(_descriptionController.text),
        expenseType: _expenseType,
        isActive: _isActive,
      ),
    );
  }

  String? _nullableText(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textDirection: TextDirection.rtl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = widget.category;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              widget.isEditing ? Icons.edit_outlined : Icons.add_circle_outline,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.isEditing ? 'ویرایش سرفصل هزینه' : 'افزودن سرفصل هزینه',
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (category?.isSystem == true) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.55,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'این سرفصل سیستمی است و حذف نمی‌شود.',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'نام سرفصل',
                    hintText: 'مثلاً هزینه تعمیر و نگهداری',
                    prefixIcon: Icon(Icons.account_tree_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _codeController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'کد سرفصل',
                    hintText: 'مثلاً OP-MAINTENANCE',
                    prefixIcon: Icon(Icons.tag_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _expenseType,
                  decoration: const InputDecoration(
                    labelText: 'نوع هزینه',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'operational',
                      child: Text('هزینه عملیاتی'),
                    ),
                    DropdownMenuItem(
                      value: 'non_operational',
                      child: Text('هزینه غیرعملیاتی'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _expenseType = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    hintText: 'توضیحات اختیاری درباره سرفصل',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.description_outlined),
                    ),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),

                if (widget.isEditing) ...[
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('سرفصل فعال باشد'),
                    subtitle: const Text(
                      'سرفصل غیرفعال در ثبت هزینه جدید '
                      'قابل انتخاب نخواهد بود.',
                    ),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('انصراف'),
          ),
          FilledButton.icon(
            onPressed: _submit,
            icon: Icon(widget.isEditing ? Icons.save_outlined : Icons.add),
            label: Text(widget.isEditing ? 'ذخیره تغییرات' : 'ایجاد سرفصل'),
          ),
        ],
      ),
    );
  }
}

class AccountantExpenseCategoryDialogResult {
  const AccountantExpenseCategoryDialogResult({
    required this.name,
    required this.code,
    required this.description,
    required this.expenseType,
    required this.isActive,
  });

  final String name;
  final String? code;
  final String? description;
  final String expenseType;
  final bool isActive;
}
