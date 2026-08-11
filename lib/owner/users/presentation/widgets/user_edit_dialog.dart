import 'package:flutter/material.dart';
import '../../data/users_repository.dart';

class UserEditDialog extends StatefulWidget {
  const UserEditDialog({
    super.key,
    required this.user,
  });

  final OwnerUser user;

  @override
  State<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  late final TextEditingController _fullNameController;
  late String _selectedRole;
  late bool _isActive;

  final List<_RoleOption> _roles = const [
    _RoleOption('owner', 'مدیر کل سیستم'),
    _RoleOption('consultant', 'مشاور'),
    _RoleOption('company_admin', 'مدیر شرکت'),
    _RoleOption('accountant', 'حسابدار'),
    _RoleOption('hr', 'منابع انسانی'),
    _RoleOption('observer', 'ناظر'),
  ];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _selectedRole = widget.user.role;
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final dialogWidth = width >= 900 ? 640.0 : width - 24;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ویرایش کاربر',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.user.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'نام و نام خانوادگی',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  items: _roles
                      .map(
                        (e) => DropdownMenuItem(
                      value: e.code,
                      child: Text(e.title),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'نقش',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  title: const Text('فعال باشد'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('انصراف'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        child: const Text('ذخیره'),
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

  void _save() {
    final fullName = _fullNameController.text.trim();
    Navigator.pop(
      context,
      OwnerUserUpdateInput(
        fullName: fullName.isEmpty ? widget.user.displayName : fullName,
        role: _selectedRole,
        isActive: _isActive,
      ),
    );
  }
}

class _RoleOption {
  const _RoleOption(this.code, this.title);

  final String code;
  final String title;
}