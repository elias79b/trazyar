import 'package:flutter/material.dart';

import '../../data/users_repository.dart';

class UserEditDialog extends StatefulWidget {
  const UserEditDialog({
    super.key,
    required this.user,
  });

  final OwnerUser user;

  @override
  State<UserEditDialog> createState() =>
      _UserEditDialogState();
}

class _UserEditDialogState
    extends State<UserEditDialog> {
  late final TextEditingController
  _fullNameController;

  late String _selectedRole;
  late bool _isActive;

  final UsersRepository _repository =
  UsersRepository();

  List<CompanyOption> _companies = [];
  Set<String> _selectedCompanyIds = {};

  bool _loadingCompanies = false;
  bool _saving = false;

  String? _errorMessage;

  final List<_RoleOption> _roles = const [
    _RoleOption(
      'owner',
      'مدیر کل سیستم',
    ),
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

    _fullNameController =
        TextEditingController(
          text: widget.user.fullName,
        );

    _selectedRole =
        widget.user.role;

    _isActive =
        widget.user.isActive;

    if (_selectedRole == 'consultant') {
      _loadCompanies();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOAD COMPANIES
  // ==========================================================

  Future<void> _loadCompanies() async {
    setState(() {
      _loadingCompanies = true;
      _errorMessage = null;
    });

    try {
      final results =
      await Future.wait([
        _repository.fetchCompanies(),
        _repository.fetchConsultantCompanyIds(
          widget.user.id,
        ),
      ]);

      final companies =
      results[0] as List<CompanyOption>;

      final selectedIds =
      results[1] as List<String>;

      if (!mounted) {
        return;
      }

      setState(() {
        _companies = companies;
        _selectedCompanyIds =
            selectedIds.toSet();
        _loadingCompanies = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingCompanies = false;
        _errorMessage =
        'خطا در دریافت شرکت‌ها: $error';
      });
    }
  }

  // ==========================================================
  // ROLE CHANGE
  // ==========================================================

  void _changeRole(String? value) {
    if (value == null) {
      return;
    }

    setState(() {
      _selectedRole = value;
      _errorMessage = null;
    });

    if (value == 'consultant' &&
        _companies.isEmpty) {
      _loadCompanies();
    }
  }

  // ==========================================================
  // COMPANY SELECTION
  // ==========================================================

  void _toggleCompany(
      String companyId,
      bool selected,
      ) {
    setState(() {
      if (selected) {
        _selectedCompanyIds.add(
          companyId,
        );
      } else {
        _selectedCompanyIds.remove(
          companyId,
        );
      }
    });
  }

  // ==========================================================
  // SAVE
  // ==========================================================

  Future<void> _save() async {
    final fullName =
    _fullNameController.text.trim();

    if (fullName.isEmpty) {
      setState(() {
        _errorMessage =
        'نام و نام خانوادگی را وارد کنید.';
      });

      return;
    }

    if (_selectedRole == 'consultant' &&
        _selectedCompanyIds.isEmpty) {
      setState(() {
        _errorMessage =
        'برای مشاور حداقل یک شرکت انتخاب کنید.';
      });

      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await _repository.updateUser(
        id: widget.user.id,
        input: OwnerUserUpdateInput(
          fullName: fullName,
          role: _selectedRole,
          isActive: _isActive,
          companyIds:
          _selectedCompanyIds.toList(),
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _errorMessage =
        'ذخیره تغییرات انجام نشد:\n$error';
      });
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final width =
        MediaQuery.sizeOf(context).width;

    final dialogWidth =
    width >= 900
        ? 680.0
        : width - 24;

    return Dialog(
      insetPadding:
      const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints:
        BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight:
          MediaQuery.sizeOf(context)
              .height *
              .90,
        ),
        child: Padding(
          padding:
          const EdgeInsets.all(24),
          child: Directionality(
            textDirection:
            TextDirection.rtl,
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ویرایش کاربر',
                        style:
                        Theme.of(
                          context,
                        )
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
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
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  widget.user.email,
                  style:
                  Theme.of(
                    context,
                  )
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                    color: Colors
                        .grey
                        .shade700,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // ==================================================
                // SCROLL CONTENT
                // ==================================================

                Flexible(
                  child:
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,
                      children: [
                        // ==========================================
                        // NAME
                        // ==========================================

                        TextFormField(
                          controller:
                          _fullNameController,
                          enabled:
                          !_saving,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'نام و نام خانوادگی',
                            border:
                            OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        // ==========================================
                        // ROLE
                        // ==========================================

                        DropdownButtonFormField<
                            String>(
                          value:
                          _selectedRole,
                          items:
                          _roles
                              .map(
                                (
                                e,
                                ) =>
                                DropdownMenuItem(
                                  value:
                                  e.code,
                                  child:
                                  Text(
                                    e.title,
                                  ),
                                ),
                          )
                              .toList(),
                          onChanged:
                          _saving
                              ? null
                              : _changeRole,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'نقش',
                            border:
                            OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        // ==========================================
                        // ACTIVE
                        // ==========================================

                        SwitchListTile(
                          value:
                          _isActive,
                          onChanged:
                          _saving
                              ? null
                              : (
                              value,
                              ) {
                            setState(
                                  () =>
                              _isActive =
                                  value,
                            );
                          },
                          title:
                          const Text(
                            'فعال باشد',
                          ),
                        ),

                        // ==========================================
                        // CONSULTANT COMPANIES
                        // ==========================================

                        if (_selectedRole ==
                            'consultant') ...[
                          const SizedBox(
                            height: 12,
                          ),

                          _buildCompaniesSection(),
                        ],

                        // ==========================================
                        // ERROR
                        // ==========================================

                        if (_errorMessage !=
                            null) ...[
                          const SizedBox(
                            height: 16,
                          ),
                          _buildError(),
                        ],

                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                // ==================================================
                // ACTIONS
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child:
                      OutlinedButton(
                        onPressed:
                        _saving
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
                      child:
                      FilledButton(
                        onPressed:
                        _saving
                            ? null
                            : _save,
                        child: _saving
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth:
                            2,
                            color:
                            Colors.white,
                          ),
                        )
                            : const Text(
                          'ذخیره تغییرات',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // COMPANIES SECTION
  // ==========================================================

  Widget _buildCompaniesSection() {
    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color:
        Colors.grey.shade50,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border:
        Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.business_outlined,
              ),
              const SizedBox(
                width: 8,
              ),
              const Expanded(
                child: Text(
                  'شرکت‌های تحت پوشش',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
              if (!_loadingCompanies)
                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    Theme.of(
                      context,
                    )
                        .colorScheme
                        .primary
                        .withOpacity(
                      .10,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    '${_selectedCompanyIds.length} شرکت',
                    style:
                    TextStyle(
                      fontSize: 12,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      Theme.of(
                        context,
                      )
                          .colorScheme
                          .primary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'شرکت‌هایی را که این مشاور اجازه فعالیت روی آن‌ها را دارد انتخاب کنید.',
            style: TextStyle(
              fontSize: 12,
              color:
              Colors.grey.shade600,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          if (_loadingCompanies)
            const Padding(
              padding:
              EdgeInsets.all(24),
              child: Center(
                child:
                CircularProgressIndicator(),
              ),
            )
          else if (_companies.isEmpty)
            Container(
              padding:
              const EdgeInsets.all(
                16,
              ),
              decoration:
              BoxDecoration(
                color:
                Colors.white,
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
              ),
              child: const Text(
                'هیچ شرکت فعالی برای انتخاب وجود ندارد.',
                textAlign:
                TextAlign.center,
              ),
            )
          else
            ..._companies.map(
                  (company) {
                final selected =
                _selectedCompanyIds
                    .contains(
                  company.id,
                );

                return Container(
                  margin:
                  const EdgeInsets.only(
                    bottom: 8,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.white,
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                    border:
                    Border.all(
                      color: selected
                          ? Theme.of(
                        context,
                      )
                          .colorScheme
                          .primary
                          : Colors
                          .grey
                          .shade200,
                    ),
                  ),
                  child:
                  CheckboxListTile(
                    value: selected,
                    onChanged:
                    _saving
                        ? null
                        : (
                        value,
                        ) {
                      _toggleCompany(
                        company.id,
                        value ??
                            false,
                      );
                    },
                    controlAffinity:
                    ListTileControlAffinity
                        .leading,
                    title: Text(
                      company.name,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                    subtitle:
                    Text(
                      selected
                          ? 'دسترسی فعال'
                          : 'دسترسی ندارد',
                      style:
                      TextStyle(
                        fontSize: 11,
                        color: selected
                            ? Colors.green
                            : Colors
                            .grey,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR
  // ==========================================================

  Widget _buildError() {
    return Container(
      padding:
      const EdgeInsets.all(14),
      decoration:
      BoxDecoration(
        color:
        Colors.red.shade50,
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        border:
        Border.all(
          color:
          Colors.red.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            color:
            Colors.red.shade700,
            size: 20,
          ),
          const SizedBox(
            width: 8,
          ),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color:
                Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
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