import 'package:flutter/material.dart';

class CreateCompanyInput {
  final String name;
  final String legalName;
  final String nationalId;
  final String economicCode;
  final String phone;
  final String email;
  final String website;
  final String address;
  final String city;
  final String province;
  final String postalCode;
  final bool isActive;

  const CreateCompanyInput({
    required this.name,
    this.legalName = '',
    this.nationalId = '',
    this.economicCode = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.address = '',
    this.city = '',
    this.province = '',
    this.postalCode = '',
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'legal_name': _nullable(legalName),
      'national_id': _nullable(nationalId),
      'economic_code': _nullable(economicCode),
      'phone': _nullable(phone),
      'email': _nullable(email),
      'website': _nullable(website),
      'address': _nullable(address),
      'city': _nullable(city),
      'province': _nullable(province),
      'postal_code': _nullable(postalCode),
      'is_active': isActive,
    };
  }

  static String? _nullable(String value) {
    final result = value.trim();

    if (result.isEmpty) {
      return null;
    }

    return result;
  }
}

class CompanyFormDialog extends StatefulWidget {
  const CompanyFormDialog({super.key});

  @override
  State<CompanyFormDialog> createState() => _CompanyFormDialogState();
}

class _CompanyFormDialogState extends State<CompanyFormDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _economicCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();

  bool _isActive = true;
  final bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _legalNameController.dispose();
    _nationalIdController.dispose();
    _economicCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final dialogWidth =
        width >= 1200
            ? 980.0
            : width >= 800
            ? 860.0
            : width - 24;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'ایجاد شرکت جدید',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed:
                              _isSubmitting
                                  ? null
                                  : () {
                                    Navigator.pop(context);
                                  },
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    const Text('اطلاعات شرکت را وارد کنید و ذخیره را بزنید.'),

                    const SizedBox(height: 20),

                    _buildField(
                      controller: _nameController,
                      label: 'نام شرکت',
                      hint: 'مثلاً شرکت آریا',
                      required: true,
                    ),

                    const SizedBox(height: 14),

                    _ResponsiveTwoColumns(
                      first: _buildField(
                        controller: _legalNameController,
                        label: 'نام رسمی',
                        hint: 'نام حقوقی شرکت',
                      ),
                      second: _buildField(
                        controller: _nationalIdController,
                        label: 'شناسه ملی',
                        hint: 'شناسه ملی شرکت',
                        keyboardType: TextInputType.number,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _ResponsiveTwoColumns(
                      first: _buildField(
                        controller: _economicCodeController,
                        label: 'کد اقتصادی',
                        hint: 'کد اقتصادی',
                        keyboardType: TextInputType.number,
                      ),
                      second: _buildField(
                        controller: _phoneController,
                        label: 'تلفن',
                        hint: '021...',
                        keyboardType: TextInputType.phone,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _ResponsiveTwoColumns(
                      first: _buildField(
                        controller: _emailController,
                        label: 'ایمیل',
                        hint: 'info@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      second: _buildField(
                        controller: _websiteController,
                        label: 'وب‌سایت',
                        hint: 'https://...',
                        keyboardType: TextInputType.url,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _ResponsiveTwoColumns(
                      first: _buildField(
                        controller: _provinceController,
                        label: 'استان',
                        hint: 'استان',
                      ),
                      second: _buildField(
                        controller: _cityController,
                        label: 'شهر',
                        hint: 'شهر',
                      ),
                    ),

                    const SizedBox(height: 14),

                    _buildField(
                      controller: _postalCodeController,
                      label: 'کد پستی',
                      hint: 'کد پستی',
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 14),

                    _buildField(
                      controller: _addressController,
                      label: 'آدرس',
                      hint: 'آدرس کامل شرکت',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 14),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isActive,
                      onChanged:
                          _isSubmitting
                              ? null
                              : (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                      title: const Text('شرکت فعال باشد'),
                      subtitle: Text(
                        _isActive
                            ? 'شرکت بلافاصله فعال خواهد بود'
                            : 'شرکت به صورت غیرفعال ثبت خواهد شد',
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _isSubmitting
                                    ? null
                                    : () {
                                      Navigator.pop(context);
                                    },
                            child: const Text('انصراف'),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child:
                                _isSubmitting
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text('ذخیره شرکت'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (required && text.isEmpty) {
          return '$label را وارد کنید';
        }

        if (label == 'ایمیل' &&
            text.isNotEmpty &&
            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
          return 'ایمیل معتبر نیست';
        }

        if (label == 'وب‌سایت' &&
            text.isNotEmpty &&
            !(text.startsWith('http://') || text.startsWith('https://'))) {
          return 'آدرس وب‌سایت معتبر نیست';
        }

        return null;
      },
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final input = CreateCompanyInput(
      name: _nameController.text.trim(),
      legalName: _legalNameController.text.trim(),
      nationalId: _nationalIdController.text.trim(),
      economicCode: _economicCodeController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      website: _websiteController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      province: _provinceController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      isActive: _isActive,
    );

    Navigator.pop(context, input);
  }
}

class _ResponsiveTwoColumns extends StatelessWidget {
  const _ResponsiveTwoColumns({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= 800) {
      return Row(
        children: [
          Expanded(child: first),
          const SizedBox(width: 14),
          Expanded(child: second),
        ],
      );
    }

    return Column(children: [first, const SizedBox(height: 14), second]);
  }
}
