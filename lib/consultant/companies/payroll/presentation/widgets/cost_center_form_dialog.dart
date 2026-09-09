import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/cost_center_provider.dart';
import '../../data/cost_center_model.dart';

class CostCenterFormDialog extends ConsumerStatefulWidget {
  const CostCenterFormDialog({
    super.key,
    required this.companyId,
    this.costCenter,
  });

  final String companyId;
  final CostCenterModel? costCenter;

  bool get isEdit => costCenter != null;

  @override
  ConsumerState<CostCenterFormDialog> createState() =>
      _CostCenterFormDialogState();
}

class _CostCenterFormDialogState extends ConsumerState<CostCenterFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;

  late final TextEditingController _codeController;

  late final TextEditingController _descriptionController;

  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final item = widget.costCenter;

    _nameController = TextEditingController(text: item?.name ?? '');

    _codeController = TextEditingController(text: item?.code ?? '');

    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );

    _isActive = item?.isActive ?? true;
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
        widget.isEdit ? 'ویرایش مرکز هزینه' : 'ایجاد مرکز هزینه',
        style: const TextStyle(fontWeight: FontWeight.w900),
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
                  decoration: const InputDecoration(
                    labelText: 'نام مرکز هزینه *',
                    hintText: 'مثلاً اداری، فروش، تولید',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'نام مرکز هزینه را وارد کنید.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'کد مرکز هزینه',
                    hintText: 'مثلاً CC-001',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 8),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('مرکز هزینه فعال باشد'),
                  value: _isActive,
                  onChanged: (value) {
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
          onPressed:
              _saving
                  ? null
                  : () {
                    Navigator.of(context).pop();
                  },
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child:
              _saving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : Text(widget.isEdit ? 'ذخیره تغییرات' : 'ایجاد مرکز هزینه'),
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
      final repository = ref.read(costCenterRepositoryProvider);

      if (widget.isEdit) {
        await repository.updateCostCenter(
          id: widget.costCenter!.id,
          name: _nameController.text,
          code: _codeController.text,
          description: _descriptionController.text,
          isActive: _isActive,
        );
      } else {
        await repository.createCostCenter(
          companyId: widget.companyId,
          name: _nameController.text,
          code: _codeController.text,
          description: _descriptionController.text,
          isActive: _isActive,
        );
      }

      ref.invalidate(costCentersProvider(widget.companyId));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(error.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
}
