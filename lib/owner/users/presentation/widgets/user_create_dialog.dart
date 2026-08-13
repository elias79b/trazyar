import 'package:flutter/material.dart';

import '../../data/users_repository.dart';

class UserCreateDialog extends StatefulWidget {
  const UserCreateDialog({
    super.key,
    required this.companies,
    this.initialRole = 'consultant',
  });

  final List<CompanyOption> companies;
  final String initialRole;

  @override
  State<UserCreateDialog> createState() =>
      _UserCreateDialogState();
}

class _UserCreateDialogState
    extends State<UserCreateDialog> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController =
  TextEditingController();

  final _emailController =
  TextEditingController();

  final _phoneController =
  TextEditingController();

  late String _selectedRole;

  final Set<String> _selectedCompanyIds = {};

  bool _isLoading = false;

  final List<_RoleOption> _roles = const [
    _RoleOption(
      'consultant',
      'مشاور',
    ),
    _RoleOption(
      'company_admin',
      'مدیر شرکت',
    ),
    _RoleOption(
      'accountant',
      'حسابدار',
    ),
    _RoleOption(
      'hr',
      'منابع انسانی',
    ),
    _RoleOption(
      'observer',
      'ناظر',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _selectedRole =
        widget.initialRole;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();

    super.dispose();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final width =
        MediaQuery.sizeOf(context).width;

    final dialogWidth =
    width >= 900
        ? 700.0
        : width - 24;

    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: Dialog(
        insetPadding:
        const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints:
          BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight:
            MediaQuery.sizeOf(
              context,
            ).height *
                .9,
          ),
          child:
          SingleChildScrollView(
            padding:
            const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment
                    .stretch,
                children: [
                  _buildHeader(
                    context,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  TextFormField(
                    controller:
                    _fullNameController,
                    textInputAction:
                    TextInputAction.next,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'نام و نام خانوادگی',
                      hintText:
                      'مثلاً علی رضایی',
                      prefixIcon:
                      Icon(
                        Icons
                            .person_outline,
                      ),
                      border:
                      OutlineInputBorder(),
                    ),
                    validator:
                        (value) {
                      if (value ==
                          null ||
                          value
                              .trim()
                              .isEmpty) {
                        return 'نام و نام خانوادگی را وارد کنید';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  TextFormField(
                    controller:
                    _emailController,
                    keyboardType:
                    TextInputType
                        .emailAddress,
                    textDirection:
                    TextDirection.ltr,
                    textInputAction:
                    TextInputAction.next,
                    decoration:
                    const InputDecoration(
                      labelText: 'ایمیل',
                      hintText:
                      'example@email.com',
                      prefixIcon:
                      Icon(
                        Icons
                            .email_outlined,
                      ),
                      border:
                      OutlineInputBorder(),
                    ),
                    validator:
                        (value) {
                      final email =
                          value
                              ?.trim() ??
                              '';

                      if (email.isEmpty) {
                        return 'ایمیل را وارد کنید';
                      }

                      final valid =
                      RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(
                        email,
                      );

                      if (!valid) {
                        return 'ایمیل معتبر وارد کنید';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  TextFormField(
                    controller:
                    _phoneController,
                    keyboardType:
                    TextInputType.phone,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'شماره موبایل',
                      hintText:
                      'اختیاری',
                      prefixIcon:
                      Icon(
                        Icons
                            .phone_outlined,
                      ),
                      border:
                      OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  DropdownButtonFormField<
                      String>(
                    value:
                    _selectedRole,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'نقش کاربر',
                      prefixIcon:
                      Icon(
                        Icons
                            .badge_outlined,
                      ),
                      border:
                      OutlineInputBorder(),
                    ),
                    items:
                    _roles.map(
                          (
                          role,
                          ) {
                        return DropdownMenuItem<
                            String>(
                          value:
                          role.code,
                          child:
                          Text(
                            role.title,
                          ),
                        );
                      },
                    ).toList(),
                    onChanged:
                    _isLoading
                        ? null
                        : (
                        value,
                        ) {
                      if (value ==
                          null) {
                        return;
                      }

                      setState(
                            () {
                          _selectedRole =
                              value;

                          if (value !=
                              'consultant') {
                            _selectedCompanyIds
                                .clear();
                          }
                        },
                      );
                    },
                  ),

                  if (_selectedRole ==
                      'consultant') ...[
                    const SizedBox(
                      height: 24,
                    ),

                    const Text(
                      'شرکت‌های تحت پوشش مشاور',
                      style:
                      TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight
                            .w800,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    const Text(
                      'شرکت‌هایی را انتخاب کنید که این مشاور مجاز به مشاهده و مدیریت آن‌هاست.',
                      style:
                      TextStyle(
                        color:
                        Colors.grey,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _buildCompanies(),

                    if (_selectedCompanyIds
                        .isEmpty)
                      const Padding(
                        padding:
                        EdgeInsets.only(
                          top: 8,
                        ),
                        child:
                        Text(
                          'حداقل یک شرکت را انتخاب کنید.',
                          style:
                          TextStyle(
                            color:
                            Colors.orange,
                            fontSize:
                            12,
                          ),
                        ),
                      ),
                  ],

                  const SizedBox(
                    height: 28,
                  ),

                  _buildActions(
                    context,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      ) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration:
          BoxDecoration(
            color: const Color(
              0xFF1B4332,
            ).withValues(
              alpha: .10,
            ),
            borderRadius:
            BorderRadius.circular(
              14,
            ),
          ),
          child:
          const Icon(
            Icons
                .person_add_alt_1_outlined,
            color:
            Color(0xFF1B4332),
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        const Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Text(
                'افزودن کاربر',
                style:
                TextStyle(
                  fontSize: 21,
                  fontWeight:
                  FontWeight
                      .w800,
                ),
              ),
              SizedBox(
                height: 4,
              ),
              Text(
                'ایجاد دسترسی برای مشاور یا سایر کاربران',
                style:
                TextStyle(
                  color:
                  Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed:
          _isLoading
              ? null
              : () =>
              Navigator.pop(
                context,
              ),
          icon:
          const Icon(
            Icons.close,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanies() {
    if (widget.companies.isEmpty) {
      return Container(
        padding:
        const EdgeInsets.all(
          20,
        ),
        decoration:
        BoxDecoration(
          border: Border.all(
            color:
            Colors.grey.shade300,
          ),
          borderRadius:
          BorderRadius.circular(
            14,
          ),
        ),
        child:
        const Center(
          child: Text(
            'هیچ شرکتی برای تخصیص وجود ندارد.',
            style:
            TextStyle(
              color:
              Colors.grey,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration:
      BoxDecoration(
        border: Border.all(
          color:
          Colors.grey.shade300,
        ),
        borderRadius:
        BorderRadius.circular(
          14,
        ),
      ),
      child: Column(
        children:
        widget.companies
            .map(
              (
              company,
              ) {
            final selected =
            _selectedCompanyIds
                .contains(
              company.id,
            );

            return CheckboxListTile(
              value:
              selected,
              dense: true,
              controlAffinity:
              ListTileControlAffinity
                  .leading,
              title: Text(
                company.name,
                style:
                const TextStyle(
                  fontWeight:
                  FontWeight
                      .w600,
                ),
              ),
              subtitle:
              Text(
                company.id,
                maxLines: 1,
                overflow:
                TextOverflow
                    .ellipsis,
              ),
              onChanged:
              _isLoading
                  ? null
                  : (
                  value,
                  ) {
                setState(
                      () {
                    if (value ==
                        true) {
                      _selectedCompanyIds
                          .add(
                        company.id,
                      );
                    } else {
                      _selectedCompanyIds
                          .remove(
                        company.id,
                      );
                    }
                  },
                );
              },
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildActions(
      BuildContext context,
      ) {
    return Row(
      children: [
        Expanded(
          child:
          OutlinedButton(
            onPressed:
            _isLoading
                ? null
                : () =>
                Navigator.pop(
                  context,
                ),
            child:
            const Text(
              'انصراف',
            ),
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        Expanded(
          flex: 2,
          child:
          FilledButton.icon(
            onPressed:
            _isLoading
                ? null
                : _submit,
            icon: _isLoading
                ? const SizedBox(
              width: 18,
              height: 18,
              child:
              CircularProgressIndicator(
                strokeWidth:
                2,
                color:
                Colors.white,
              ),
            )
                : const Icon(
              Icons
                  .send_outlined,
            ),
            label: Text(
              _isLoading
                  ? 'در حال ثبت...'
                  : 'ایجاد و ارسال دعوت‌نامه',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (_selectedRole ==
        'consultant' &&
        _selectedCompanyIds
            .isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'حداقل یک شرکت برای مشاور انتخاب کنید.',
          ),
        ),
      );

      return;
    }

    setState(
          () {
        _isLoading = true;
      },
    );

    try {
      final result =
      await UsersRepository()
          .createUserInvitation(
        fullName:
        _fullNameController
            .text
            .trim(),
        email:
        _emailController
            .text
            .trim(),
        phone:
        _phoneController
            .text
            .trim()
            .isEmpty
            ? null
            : _phoneController
            .text
            .trim(),
        role:
        _selectedRole,
        companyIds:
        _selectedCompanyIds
            .toList(),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        result,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(
            () {
          _isLoading = false;
        },
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'خطا در ایجاد کاربر: $e',
          ),
        ),
      );
    }
  }
}

class _RoleOption {
  const _RoleOption(
      this.code,
      this.title,
      );

  final String code;
  final String title;
}