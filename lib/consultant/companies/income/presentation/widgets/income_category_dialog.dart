import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/income_categories_provider.dart';

class IncomeCategoryDialog extends ConsumerStatefulWidget {
  final String companyId;
  final Map<String, dynamic>? category;

  const IncomeCategoryDialog({
    super.key,
    required this.companyId,
    this.category,
  });

  bool get isEdit => category != null;

  @override
  ConsumerState<IncomeCategoryDialog> createState() =>
      _IncomeCategoryDialogState();
}

class _IncomeCategoryDialogState extends ConsumerState<IncomeCategoryDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descriptionController;

  bool _isActive = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    final category = widget.category;

    _nameController = TextEditingController(
      text: category?['name'] as String? ?? '',
    );

    _codeController = TextEditingController(
      text: category?['code'] as String? ?? '',
    );

    _descriptionController = TextEditingController(
      text: category?['description'] as String? ?? '',
    );

    _isActive = category?['is_active'] as bool? ?? true;
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
      title: Text(
        widget.isEdit ? 'ویرایش دسته‌بندی درآمد' : 'دسته‌بندی درآمد جدید',
      ),
      content: SizedBox(
        width: 480,
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
                    labelText: 'نام دسته‌بندی *',
                    hintText: 'مثلاً فروش کالا',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'نام دسته‌بندی الزامی است';
                    }

                    if (value.trim().length < 2) {
                      return 'نام دسته‌بندی خیلی کوتاه است';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'کد دسته‌بندی',
                    hintText: 'مثلاً INC-001',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    hintText: 'توضیحات اختیاری',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('دسته‌بندی فعال باشد'),
                  subtitle: const Text(
                    'دسته‌بندی‌های غیرفعال در ثبت درآمد قابل انتخاب نیستند.',
                  ),
                  value: _isActive,
                  onChanged:
                      _loading
                          ? null
                          : (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child:
              _loading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : Text(widget.isEdit ? 'ذخیره تغییرات' : 'ایجاد'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final service = ref.read(incomeCategoryServiceProvider);

      final name = _nameController.text.trim();

      final code =
          _codeController.text.trim().isEmpty
              ? null
              : _codeController.text.trim();

      final description =
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim();

      if (widget.isEdit) {
        await service.updateCategory(
          id: widget.category!['id'] as String,
          name: name,
          code: code,
          description: description,
          isActive: _isActive,
        );
      } else {
        await service.createCategory(
          companyId: widget.companyId,
          name: name,
          code: code,
          description: description,
        );
      }

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'دسته‌بندی با موفقیت ویرایش شد'
                : 'دسته‌بندی با موفقیت ایجاد شد',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
