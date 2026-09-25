import 'package:flutter/material.dart';

class IncomeCategoryDialog extends StatefulWidget {
  final Map<String, dynamic>? category;

  const IncomeCategoryDialog({
    super.key,
    this.category,
  });

  static Future<Map<String, dynamic>?> show(
      BuildContext context, {
        Map<String, dynamic>? category,
      }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => IncomeCategoryDialog(
        category: category,
      ),
    );
  }

  @override
  State<IncomeCategoryDialog> createState() =>
      _IncomeCategoryDialogState();
}

class _IncomeCategoryDialogState
    extends State<IncomeCategoryDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;

  String _categoryType = 'operational';

  bool get isEditing => widget.category != null;

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

    _categoryType =
        category?['category_type']?.toString() ?? 'operational';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'code': _codeController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category_type': _categoryType,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isEditing
                    ? Icons.edit_outlined
                    : Icons.add_chart_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isEditing
                  ? 'ویرایش سرفصل درآمد'
                  : 'افزودن سرفصل درآمد',
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  autofocus: !isEditing,
                  decoration: const InputDecoration(
                    labelText: 'نام سرفصل',
                    hintText: 'مثلاً درآمد اجاره',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'نام سرفصل را وارد کنید.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _categoryType,
                  decoration: const InputDecoration(
                    labelText: 'نوع درآمد',
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
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _categoryType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'کد سرفصل',
                    hintText: 'اختیاری',
                    prefixIcon: Icon(Icons.tag_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    hintText: 'توضیحات تکمیلی سرفصل',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check),
            label: Text(
              isEditing ? 'ذخیره تغییرات' : 'افزودن سرفصل',
            ),
          ),
        ],
      ),
    );
  }
}