import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

/// مدیریت دسته‌بندی هزینه‌ها بر اساس شمای موجود expense_categories.
class CompanyAdminExpenseCategoriesPage extends StatefulWidget {
  const CompanyAdminExpenseCategoriesPage({super.key});

  @override
  State<CompanyAdminExpenseCategoriesPage> createState() =>
      _CompanyAdminExpenseCategoriesPageState();
}

class _CompanyAdminExpenseCategoriesPageState
    extends State<CompanyAdminExpenseCategoriesPage> {
  final SupabaseClient _db = Supabase.instance.client;

  static const Color _green = Color(0xFF176B4D);
  static const Color _background = Color(0xFFF4F8F5);
  static const Color _border = Color(0xFFD9E4DD);
  static const Color _text = Color(0xFF202B25);
  static const Color _muted = Color(0xFF718078);

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _companyId;
  String _typeFilter = 'all';
  String _statusFilter = 'all';
  String _search = '';
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final user = _db.auth.currentUser;
      if (user == null) throw Exception('ابتدا وارد حساب کاربری شوید.');

      final membership = await _db
          .from('company_users')
          .select('company_id')
          .eq('user_id', user.id)
          .eq('role', 'company_admin')
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (membership == null || membership['company_id'] == null) {
        throw Exception('شرکت فعال برای این حساب مدیرعامل پیدا نشد.');
      }

      final companyId = membership['company_id'].toString();
      final response = await _db
          .from('expense_categories')
          .select(
            'id, company_id, name, code, description, expense_type, is_active, created_by, created_at, updated_at, is_system',
          )
          .eq('company_id', companyId)
          .order('name');

      if (!mounted) return;
      setState(() {
        _companyId = companyId;
        _categories = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
        _loading = false;
      });
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('permission denied') ||
        message.contains('row-level security') ||
        message.contains('RLS')) {
      return 'دسترسی به دسته‌بندی‌های هزینه مجاز نیست؛ سیاست‌های RLS در Supabase را بررسی کنید.';
    }
    return message.replaceFirst('Exception: ', '');
  }

  List<Map<String, dynamic>> get _visibleCategories {
    final query = _search.trim().toLowerCase();
    return _categories.where((row) {
      final type = row['expense_type']?.toString() ?? 'operational';
      final active = row['is_active'] == true;
      final name = (row['name'] ?? '').toString().toLowerCase();
      final code = (row['code'] ?? '').toString().toLowerCase();
      final description = (row['description'] ?? '').toString().toLowerCase();

      if (_typeFilter != 'all' && type != _typeFilter) return false;
      if (_statusFilter == 'active' && !active) return false;
      if (_statusFilter == 'inactive' && active) return false;
      if (query.isNotEmpty &&
          !name.contains(query) &&
          !code.contains(query) &&
          !description.contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  int get _activeCount => _categories.where((c) => c['is_active'] == true).length;
  int get _inactiveCount =>
      _categories.where((c) => c['is_active'] != true).length;

  String _typeLabel(String? type) {
    switch (type) {
      case 'operational':
        return 'عملیاتی';
      case 'non_operational':
        return 'غیرعملیاتی';
      default:
        return type ?? 'نامشخص';
    }
  }

  Future<void> _openEditor({Map<String, dynamic>? category}) async {
    if (_saving) return;
    final isEditing = category != null;
    if (isEditing && category['is_system'] == true) {
      _showSnack('دسته‌بندی سیستمی از این بخش قابل ویرایش نیست.', error: true);
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: (category?['name'] ?? '').toString(),
    );
    final codeController = TextEditingController(
      text: (category?['code'] ?? '').toString(),
    );
    final descriptionController = TextEditingController(
      text: (category?['description'] ?? '').toString(),
    );
    String expenseType =
        (category?['expense_type'] ?? 'operational').toString();
    bool isActive = category?['is_active'] == true;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'ویرایش دسته‌بندی هزینه' : 'دسته‌بندی جدید'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'نام دسته‌بندی *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'نام دسته‌بندی را وارد کنید.';
                        }
                        final duplicate = _categories.any((row) =>
                            row['id']?.toString() != category?['id']?.toString() &&
                            (row['name'] ?? '')
                                .toString()
                                .trim()
                                .toLowerCase() ==
                            value.trim().toLowerCase() &&
                            (row['expense_type'] ?? 'operational') == expenseType);
                        if (duplicate) {
                          return 'دسته‌بندی با این نام و نوع از قبل وجود دارد.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: codeController,
                      maxLength: 40,
                      decoration: const InputDecoration(
                        labelText: 'کد (اختیاری)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: expenseType,
                      decoration: const InputDecoration(
                        labelText: 'نوع هزینه',
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
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => expenseType = value);
                          formKey.currentState?.validate();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'توضیحات (اختیاری)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('دسته‌بندی فعال باشد'),
                      value: isActive,
                      onChanged: (value) =>
                          setDialogState(() => isActive = value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(dialogContext).pop({
                  'name': nameController.text.trim(),
                  'code': codeController.text.trim().isEmpty
                      ? null
                      : codeController.text.trim(),
                  'description': descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  'expense_type': expenseType,
                  'is_active': isActive,
                });
              },
              child: Text(isEditing ? 'ذخیره تغییرات' : 'ایجاد دسته‌بندی'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    codeController.dispose();
    descriptionController.dispose();

    if (result == null || _companyId == null) return;
    setState(() => _saving = true);
    try {
      final userId = _db.auth.currentUser?.id;
      final payload = <String, dynamic>{
        ...result,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isEditing) {
        await _db
            .from('expense_categories')
            .update(payload)
            .eq('id', category['id'])
            .eq('company_id', _companyId!);
      } else {
        payload
          ..['company_id'] = _companyId
          ..['created_by'] = userId
          ..['is_system'] = false;
        await _db.from('expense_categories').insert(payload);
      }

      await _load();
      if (mounted) {
        _showSnack(isEditing
            ? 'دسته‌بندی با موفقیت ویرایش شد.'
            : 'دسته‌بندی با موفقیت ایجاد شد.');
      }
    } catch (e) {
      if (mounted) _showSnack(_friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> category) async {
    if (_saving) return;
    if (category['is_system'] == true) {
      _showSnack('وضعیت دسته‌بندی سیستمی از این بخش قابل تغییر نیست.', error: true);
      return;
    }
    final currentlyActive = category['is_active'] == true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(currentlyActive
            ? 'غیرفعال‌کردن دسته‌بندی'
            : 'فعال‌کردن دسته‌بندی'),
        content: Text(currentlyActive
            ? 'دسته‌بندی «${category['name']}» غیرفعال شود؟ سوابق ثبت‌شده حذف نخواهند شد.'
            : 'دسته‌بندی «${category['name']}» دوباره فعال شود؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('تأیید'),
          ),
        ],
      ),
    );
    if (confirmed != true || _companyId == null) return;

    setState(() => _saving = true);
    try {
      await _db
          .from('expense_categories')
          .update({
            'is_active': !currentlyActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', category['id'])
          .eq('company_id', _companyId!);
      await _load();
      if (mounted) {
        _showSnack(currentlyActive
            ? 'دسته‌بندی غیرفعال شد.'
            : 'دسته‌بندی فعال شد.');
      }
    } catch (e) {
      if (mounted) _showSnack(_friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : _green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompanyAdminScaffold(
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
              children: [
                _header(),
                const SizedBox(height: 20),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(
                      child: CircularProgressIndicator(color: _green),
                    ),
                  )
                else if (_error != null)
                  _errorCard()
                else ...[
                  _summary(),
                  const SizedBox(height: 18),
                  _toolbar(),
                  const SizedBox(height: 14),
                  if (_visibleCategories.isEmpty)
                    _emptyState()
                  else
                    ..._visibleCategories.map(_categoryCard),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'هزینه / دسته‌بندی‌ها',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'مدیریت دسته‌بندی هزینه‌ها',
                    style: TextStyle(
                      color: _text,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'دسته‌بندی‌های عملیاتی و غیرعملیاتی شرکت را مدیریت کنید.',
                    style: TextStyle(color: _muted, fontSize: 13, height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (!compact)
              FilledButton.icon(
                onPressed: _loading || _saving ? null : () => _openEditor(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('دسته‌بندی جدید'),
              )
            else
              IconButton(
                tooltip: 'دسته‌بندی جدید',
                onPressed: _saving ? null : () => _openEditor(),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
          ],
        );
      },
    );
  }

  Widget _summary() {
    final operational = _categories
        .where((c) => c['expense_type'] == 'operational')
        .length;
    final nonOperational = _categories
        .where((c) => c['expense_type'] == 'non_operational')
        .length;
    final items = [
      _Metric('کل دسته‌بندی‌ها', '${_categories.length}', Icons.category_outlined),
      _Metric('فعال', '$_activeCount', Icons.check_circle_outline_rounded),
      _Metric('غیرفعال', '$_inactiveCount', Icons.pause_circle_outline_rounded),
      _Metric('عملیاتی / غیرعملیاتی', '$operational / $nonOperational',
          Icons.account_tree_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1100
            ? 4
            : constraints.maxWidth > 650
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 4.0 : columns == 2 ? 2.5 : 2.0,
          children: items.map((item) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F4EB),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(item.icon, color: _green),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.label, style: const TextStyle(color: _muted, fontSize: 12)),
                  const SizedBox(height: 7),
                  Text(item.value, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              )),
            ]),
          )).toList(),
        );
      },
    );
  }

  Widget _toolbar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'جست‌وجوی نام، کد یا توضیحات...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _search.isEmpty
                ? null
                : IconButton(
                    tooltip: 'پاک‌کردن جست‌وجو',
                    onPressed: () => setState(() => _search = ''),
                    icon: const Icon(Icons.close_rounded),
                  ),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filterChip('all', 'همه انواع', _typeFilter, (v) => setState(() => _typeFilter = v)),
            _filterChip('operational', 'عملیاتی', _typeFilter, (v) => setState(() => _typeFilter = v)),
            _filterChip('non_operational', 'غیرعملیاتی', _typeFilter, (v) => setState(() => _typeFilter = v)),
            const SizedBox(width: 10),
            _filterChip('all', 'همه وضعیت‌ها', _statusFilter, (v) => setState(() => _statusFilter = v), status: true),
            _filterChip('active', 'فعال', _statusFilter, (v) => setState(() => _statusFilter = v), status: true),
            _filterChip('inactive', 'غیرفعال', _statusFilter, (v) => setState(() => _statusFilter = v), status: true),
          ],
        ),
      ]),
    );
  }

  Widget _filterChip(
    String value,
    String label,
    String current,
    ValueChanged<String> onSelected, {
    bool status = false,
  }) {
    final selected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: const Color(0xFFDDF1E5),
      side: BorderSide(color: selected ? _green : _border),
      labelStyle: TextStyle(
        color: selected ? _green : _text,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
      ),
    );
  }

  Widget _categoryCard(Map<String, dynamic> category) {
    final active = category['is_active'] == true;
    final isSystem = category['is_system'] == true;
    final type = category['expense_type']?.toString();
    final name = (category['name'] ?? 'بدون نام').toString();
    final code = (category['code'] ?? '').toString().trim();
    final description = (category['description'] ?? '').toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F4EB),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              type == 'non_operational'
                  ? Icons.account_balance_outlined
                  : Icons.receipt_long_outlined,
              color: _green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(name, style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w800)),
                _pill(_typeLabel(type), const Color(0xFFEAF4EE), _green),
                _pill(active ? 'فعال' : 'غیرفعال',
                    active ? const Color(0xFFE4F4EB) : const Color(0xFFF0F1F0),
                    active ? _green : _muted),
                if (isSystem) _pill('سیستمی', const Color(0xFFFFF3D9), const Color(0xFF946200)),
              ]),
              if (code.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('کد: $code', style: const TextStyle(color: _muted, fontSize: 12)),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(color: _muted, height: 1.6)),
              ],
            ],
          )),
          PopupMenuButton<String>(
            tooltip: 'عملیات',
            enabled: !isSystem && !_saving,
            onSelected: (value) {
              if (value == 'edit') _openEditor(category: category);
              if (value == 'toggle') _toggleActive(category);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_outlined),
                  title: Text('ویرایش'),
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(active ? Icons.pause_circle_outline : Icons.check_circle_outline),
                  title: Text(active ? 'غیرفعال‌کردن' : 'فعال‌کردن'),
                ),
              ),
            ],
          ),
        ]),
        if (isSystem) ...[
          const SizedBox(height: 10),
          const Text(
            'این دسته‌بندی سیستمی است و از این صفحه قابل ویرایش یا غیرفعال‌سازی نیست.',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ]),
    );
  }

  Widget _pill(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18)),
      child: Text(label, style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }


  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: [
        const Icon(Icons.category_outlined, size: 48, color: _green),
        const SizedBox(height: 12),
        Text(
          _categories.isEmpty
              ? 'هنوز دسته‌بندی هزینه‌ای ثبت نشده است.'
              : 'دسته‌بندی مطابق فیلترهای انتخاب‌شده پیدا نشد.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'برای تفکیک هزینه‌ها، دسته‌بندی عملیاتی یا غیرعملیاتی ایجاد کنید.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, height: 1.6),
        ),
        const SizedBox(height: 16),
        if (_categories.isEmpty)
          FilledButton.icon(
            onPressed: _saving ? null : () => _openEditor(),
            icon: const Icon(Icons.add),
            label: const Text('ایجاد دسته‌بندی'),
          ),
      ]),
    );
  }

  Widget _errorCard() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.red.shade200),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('بارگذاری دسته‌بندی‌ها ناموفق بود',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(_error ?? 'خطای نامشخص', style: const TextStyle(height: 1.6)),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('تلاش دوباره'),
        ),
      ],
    ),
  );
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}
