import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:tarazyar/consultant/companies/shared/presentation/widgets/persian_date_field.dart';

import '../../application/employee_provider.dart';
import '../../data/employee_model.dart';

class EmployeeFormDialog extends ConsumerStatefulWidget {
  const EmployeeFormDialog({super.key, required this.companyId, this.employee});

  final String companyId;
  final EmployeeModel? employee;

  bool get isEdit => employee != null;

  @override
  ConsumerState<EmployeeFormDialog> createState() => _EmployeeFormDialogState();
}

class _EmployeeFormDialogState extends ConsumerState<EmployeeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _personnelCodeController;

  late final TextEditingController _firstNameController;

  late final TextEditingController _lastNameController;

  late final TextEditingController _nationalIdController;

  late final TextEditingController _mobileController;

  late final TextEditingController _jobTitleController;

  late final TextEditingController _departmentController;

  late final TextEditingController _hireDateController;

  late final TextEditingController _terminationDateController;

  late String _employmentType;
  late String _status;

  DateTime? _hireDate;
  DateTime? _terminationDate;

  bool _saving = false;

  static const employmentTypes = [
    'full_time',
    'part_time',
    'contract',
    'temporary',
    'intern',
  ];

  static const statuses = ['active', 'inactive', 'terminated', 'suspended'];

  @override
  void initState() {
    super.initState();

    final employee = widget.employee;

    _personnelCodeController = TextEditingController(
      text: employee?.personnelCode ?? '',
    );

    _firstNameController = TextEditingController(
      text: employee?.firstName ?? '',
    );

    _lastNameController = TextEditingController(text: employee?.lastName ?? '');

    _nationalIdController = TextEditingController(
      text: employee?.nationalId ?? '',
    );

    _mobileController = TextEditingController(text: employee?.mobile ?? '');

    _jobTitleController = TextEditingController(text: employee?.jobTitle ?? '');

    _departmentController = TextEditingController(
      text: employee?.department ?? '',
    );

    _hireDate = employee?.hireDate;

    _terminationDate = employee?.terminationDate;

    _hireDateController = TextEditingController();

    _terminationDateController = TextEditingController();

    _employmentType = employee?.employmentType ?? employmentTypes.first;

    _status = employee?.status ?? 'active';

    if (_hireDate != null) {
      _hireDateController.text = _formatDate(_hireDate!);
    }

    if (_terminationDate != null) {
      _terminationDateController.text = _formatDate(_terminationDate!);
    }
  }

  String _formatDate(DateTime date) {
    final jalali = Jalali.fromDateTime(date);

    return '${_fa(jalali.year.toString())}/'
        '${_fa(jalali.month.toString().padLeft(2, '0'))}/'
        '${_fa(jalali.day.toString().padLeft(2, '0'))}';
  }

  String _fa(String value) {
    const en = '0123456789';
    const fa = '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (var i = 0; i < en.length; i++) {
      result = result.replaceAll(en[i], fa[i]);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isEdit ? 'ویرایش پرسنل' : 'ثبت پرسنل',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),

      content: SizedBox(
        width: 650,

        child: SingleChildScrollView(
          child: Form(
            key: _formKey,

            child: Column(
              children: [
                _textField(
                  controller: _personnelCodeController,
                  label: 'کد پرسنلی',
                ),

                _textField(controller: _firstNameController, label: 'نام'),

                _textField(
                  controller: _lastNameController,
                  label: 'نام خانوادگی',
                ),

                _textField(
                  controller: _nationalIdController,
                  label: 'کد ملی',
                  requiredField: false,
                  maxLength: 10,
                ),

                _textField(
                  controller: _mobileController,
                  label: 'شماره موبایل',
                  requiredField: false,
                ),

                _textField(
                  controller: _jobTitleController,
                  label: 'سمت',
                  requiredField: false,
                ),

                _textField(
                  controller: _departmentController,
                  label: 'دپارتمان',
                  requiredField: false,
                ),

                _employmentTypeField(),

                PersianDateField(
                  controller: _hireDateController,
                  label: 'تاریخ استخدام',
                  initialDate: _hireDate,
                  requiredField: false,
                  onDateSelected: (date) {
                    _hireDate = date;
                  },
                ),

                PersianDateField(
                  controller: _terminationDateController,
                  label: 'تاریخ پایان همکاری',
                  initialDate: _terminationDate,
                  requiredField: false,
                  onDateSelected: (date) {
                    _terminationDate = date;
                  },
                ),

                _statusField(),
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

        FilledButton.icon(
          onPressed: _saving ? null : _save,

          icon:
              _saving
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.save_rounded),

          label: Text(widget.isEdit ? 'ذخیره تغییرات' : 'ثبت پرسنل'),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    bool requiredField = true,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          counterText: maxLength == null ? null : '',
        ),
        validator: (value) {
          if (!requiredField) {
            return null;
          }

          if (value == null || value.trim().isEmpty) {
            return 'این فیلد الزامی است.';
          }

          return null;
        },
      ),
    );
  }

  Widget _employmentTypeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _employmentType,
        decoration: const InputDecoration(
          labelText: 'نوع استخدام',
          border: OutlineInputBorder(),
        ),
        items:
            employmentTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Text(_employmentTypeTitle(type)),
              );
            }).toList(),
        onChanged: (value) {
          if (value == null) {
            return;
          }

          setState(() {
            _employmentType = value;
          });
        },
      ),
    );
  }

  Widget _statusField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _status,
        decoration: const InputDecoration(
          labelText: 'وضعیت پرسنل',
          border: OutlineInputBorder(),
        ),
        items:
            statuses.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(_statusTitle(status)),
              );
            }).toList(),
        onChanged: (value) {
          if (value == null) {
            return;
          }

          setState(() {
            _status = value;
          });
        },
      ),
    );
  }

  String _employmentTypeTitle(String value) {
    switch (value) {
      case 'full_time':
        return 'تمام‌وقت';

      case 'part_time':
        return 'پاره‌وقت';

      case 'contract':
        return 'قراردادی';

      case 'temporary':
        return 'موقت';

      case 'intern':
        return 'کارآموز';

      default:
        return value;
    }
  }

  String _statusTitle(String value) {
    switch (value) {
      case 'active':
        return 'فعال';

      case 'inactive':
        return 'غیرفعال';

      case 'terminated':
        return 'خاتمه همکاری';

      case 'suspended':
        return 'معلق';

      default:
        return value;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_nationalIdController.text.trim().isNotEmpty &&
        _nationalIdController.text.trim().length != 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('کد ملی باید ۱۰ رقم باشد.')));

      return;
    }

    if (_hireDate != null &&
        _terminationDate != null &&
        _terminationDate!.isBefore(_hireDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تاریخ پایان همکاری نمی‌تواند قبل از تاریخ استخدام باشد.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final repository = ref.read(employeeRepositoryProvider);

      if (widget.isEdit) {
        await repository.updateEmployee(
          id: widget.employee!.id,
          personnelCode: _personnelCodeController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          nationalId: _nationalIdController.text.trim(),
          mobile: _mobileController.text.trim(),
          jobTitle: _jobTitleController.text.trim(),
          department: _departmentController.text.trim(),
          employmentType: _employmentType,
          hireDate: _hireDate,
          terminationDate: _terminationDate,
          status: _status,
        );
      } else {
        await repository.createEmployee(
          companyId: widget.companyId,
          personnelCode: _personnelCodeController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          nationalId: _nationalIdController.text.trim(),
          mobile: _mobileController.text.trim(),
          jobTitle: _jobTitleController.text.trim(),
          department: _departmentController.text.trim(),
          employmentType: _employmentType,
          hireDate: _hireDate,
          terminationDate: _terminationDate,
          status: _status,
        );
      }

      ref.invalidate(employeesProvider(widget.companyId));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'پرسنل با موفقیت ویرایش شد.'
                : 'پرسنل با موفقیت ثبت شد.',
          ),
        ),
      );
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

  @override
  void dispose() {
    _personnelCodeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nationalIdController.dispose();
    _mobileController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
    _hireDateController.dispose();
    _terminationDateController.dispose();

    super.dispose();
  }
}
