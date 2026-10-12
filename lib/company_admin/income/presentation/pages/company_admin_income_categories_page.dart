import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

class CompanyAdminIncomeCategoriesPage extends StatefulWidget {
  const CompanyAdminIncomeCategoriesPage({super.key});

  @override
  State<CompanyAdminIncomeCategoriesPage> createState() =>
      _CompanyAdminIncomeCategoriesPageState();
}

class _CompanyAdminIncomeCategoriesPageState
    extends State<CompanyAdminIncomeCategoriesPage> {
  static const Color _green = Color(0xFF168052);
  static const Color _background = Color(0xFFF5F8F6);
  static const Color _border = Color(0xFFE2EAE4);
  static const Color _text = Color(0xFF26332C);
  static const Color _muted = Color(0xFF77837B);

  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _companyId;
  String _typeFilter = 'all';
  String _activeFilter = 'all';
  String _search = '';
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(() {
      if (mounted) setState(() => _search = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _string(dynamic value) => value?.toString() ?? '';

  bool _bool(dynamic value) => value == true;

  void _message(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red.shade700 : _green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _loadCategories() async {
    if (mounted) setState(() => _loading = true);

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('ابتدا وارد حساب کاربری شوید.');

      final membership = await _supabase
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
      final rows = await _supabase
          .from('income_categories')
          .select(
            'id, company_id, name, code, description, is_active, is_system, category_type, created_at, updated_at',
          )
          .eq('company_id', companyId)
          .order('is_system', ascending: false)
          .order('name');

      if (!mounted) return;
      setState(() {
        _companyId = companyId;
        _categories = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('دریافت دسته‌بندی‌ها ناموفق بود: $error', error: true);
    }
  }

  List<Map<String, dynamic>> get _filteredCategories {
    return _categories.where((category) {
      final name = _string(category['name']).toLowerCase();
      final code = _string(category['code']).toLowerCase();
      final description = _string(category['description']).toLowerCase();
      final query = _search.toLowerCase();

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          code.contains(query) ||
          description.contains(query);

      final matchesType = _typeFilter == 'all' ||
          _string(category['category_type']) == _typeFilter;

      final isActive = _bool(category['is_active']);
      final matchesActive = _activeFilter == 'all' ||
          (_activeFilter == 'active' && isActive) ||
          (_activeFilter == 'inactive' && !isActive);

      return matchesSearch && matchesType && matchesActive;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _categories.where((c) => _bool(c['is_active'])).length;
    final operationalCount = _categories
        .where((c) => _string(c['category_type']) == 'operational')
        .length;
    final nonOperationalCount = _categories
        .where((c) => _string(c['category_type']) == 'non_operational')
        .length;

    return CompanyAdminScaffold(
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadCategories,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
              children: [
                _header(),
                const SizedBox(height: 22),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: CircularProgressIndicator(color: _green),
                    ),
                  )
                else ...[
                  _summaryCards(
                    total: _categories.length,
                    active: activeCount,
                    operational: operationalCount,
                    nonOperational: nonOperationalCount,
                  ),
                  const SizedBox(height: 22),
                  _managementPanel(),
                  const SizedBox(height: 15),
                  _filterPanel(),
                  const SizedBox(height: 14),
                  _categoryList(_filteredCategories),
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
        final compact = constraints.maxWidth < 650;
        final title = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'درآمد  /  دسته‌بندی‌ها',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
            SizedBox(height: 8),
            Text(
              'مدیریت دسته‌بندی‌های درآمد',
              style: TextStyle(
                fontSize: 25,
                height: 1.35,
                color: _text,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'دسته‌بندی‌های عملیاتی و غیرعملیاتی را تعریف و مدیریت کنید.',
              style: TextStyle(fontSize: 13, height: 1.7, color: _muted),
            ),
          ],
        );

        final addButton = FilledButton.icon(
          onPressed: _saving ? null : () => _showCategoryDialog(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('دسته‌بندی جدید'),
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerRight, child: addButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            addButton,
          ],
        );
      },
    );
  }

  Widget _summaryCards({
    required int total,
    required int active,
    required int operational,
    required int nonOperational,
  }) {
    final items = [
      _SummaryData(
        title: 'کل دسته‌بندی‌ها',
        value: '$total',
        caption: 'ثبت‌شده برای شرکت',
        icon: Icons.category_outlined,
        color: _green,
      ),
      _SummaryData(
        title: 'دسته‌بندی فعال',
        value: '$active',
        caption: 'قابل انتخاب هنگام ثبت درآمد',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF23845A),
      ),
      _SummaryData(
        title: 'درآمد عملیاتی',
        value: '$operational',
        caption: 'مرتبط با فعالیت اصلی',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF2878D0),
      ),
      _SummaryData(
        title: 'درآمد غیرعملیاتی',
        value: '$nonOperational',
        caption: 'سایر منابع درآمد',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF8955C7),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 1100 ? 4 : constraints.maxWidth >= 650 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 122,
          ),
          itemBuilder: (context, index) => _summaryCard(items[index]),
        );
      },
    );
  }

  Widget _summaryCard(_SummaryData item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: item.color.withOpacity(.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(item.icon, color: item.color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: TextStyle(
                    color: item.color,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  item.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _managementPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune_rounded, color: _green),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'قواعد مدیریت دسته‌بندی',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _text,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'برای جلوگیری از به‌هم‌ریختن سوابق مالی، دسته‌بندی حذف نمی‌شود؛ در صورت عدم استفاده، آن را غیرفعال کنید. دسته‌بندی‌های سیستمی محافظت می‌شوند.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.8,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'بارگذاری مجدد',
            onPressed: _loading ? null : _loadCategories,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _filterPanel() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'جست‌وجو بر اساس نام، کد یا توضیحات...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'پاک کردن جست‌وجو',
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: const Color(0xFFFAFCFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _border),
              ),
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'نوع:',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _filterChip('همه انواع', _typeFilter == 'all',
                  () => setState(() => _typeFilter = 'all')),
              _filterChip('عملیاتی', _typeFilter == 'operational',
                  () => setState(() => _typeFilter = 'operational')),
              _filterChip('غیرعملیاتی', _typeFilter == 'non_operational',
                  () => setState(() => _typeFilter = 'non_operational')),
              const SizedBox(width: 8),
              const Text(
                'وضعیت:',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _filterChip('همه', _activeFilter == 'all',
                  () => setState(() => _activeFilter = 'all')),
              _filterChip('فعال', _activeFilter == 'active',
                  () => setState(() => _activeFilter = 'active')),
              _filterChip('غیرفعال', _activeFilter == 'inactive',
                  () => setState(() => _activeFilter = 'inactive')),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${_filteredCategories.length} مورد از ${_categories.length} دسته‌بندی',
            style: const TextStyle(fontSize: 11, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: _green,
      backgroundColor: const Color(0xFFF7F9F7),
      side: BorderSide(color: selected ? _green : _border),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _text,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _categoryList(List<Map<String, dynamic>> categories) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF6EF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.category_outlined,
                size: 31,
                color: _green,
              ),
            ),
            const SizedBox(height: 13),
            Text(
              _categories.isEmpty
                  ? 'هنوز دسته‌بندی درآمدی ثبت نشده است'
                  : 'دسته‌بندی مطابق فیلترها پیدا نشد',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'دسته‌بندی‌های درآمد را تعریف کنید تا هنگام ثبت درآمد قابل انتخاب باشند.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.7,
                color: _muted,
              ),
            ),
            const SizedBox(height: 14),
            if (_categories.isEmpty)
              FilledButton.icon(
                onPressed: () => _showCategoryDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('ایجاد اولین دسته‌بندی'),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _searchController.clear();
                  _typeFilter = 'all';
                  _activeFilter = 'all';
                }),
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('پاک کردن فیلترها'),
              ),
          ],
        ),
      );
    }

    return Column(
      children: categories.map(_categoryCard).toList(),
    );
  }

  Widget _categoryCard(Map<String, dynamic> category) {
    final active = _bool(category['is_active']);
    final system = _bool(category['is_system']);
    final operational = _string(category['category_type']) == 'operational';
    final typeColor = operational
        ? const Color(0xFF2878D0)
        : const Color(0xFF8955C7);

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: active ? _border : const Color(0xFFE9E5DE)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 570;

          final icon = Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              operational
                  ? Icons.trending_up_rounded
                  : Icons.account_balance_wallet_outlined,
              color: typeColor,
              size: 23,
            ),
          );

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 7,
                runSpacing: 7,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _string(category['name']),
                    style: TextStyle(
                      color: active ? _text : _muted,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (system)
                    _badge('سیستمی', const Color(0xFF7651C9)),
                  _badge(
                    operational ? 'عملیاتی' : 'غیرعملیاتی',
                    typeColor,
                  ),
                  _badge(
                    active ? 'فعال' : 'غیرفعال',
                    active ? _green : const Color(0xFF858C87),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_string(category['code']).isNotEmpty)
                Text(
                  'کد: ${_string(category['code'])}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (_string(category['description']).isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _string(category['description']),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.7,
                  ),
                ),
              ],
              if (system) ...[
                const SizedBox(height: 6),
                const Text(
                  'این دسته‌بندی سیستمی است و ویرایش یا غیرفعال نمی‌شود.',
                  style: TextStyle(
                    color: Color(0xFF7651C9),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          );

          final actions = Wrap(
            spacing: 4,
            children: [
              IconButton(
                tooltip: system ? 'دسته‌بندی سیستمی' : 'ویرایش',
                onPressed: system
                    ? null
                    : () => _showCategoryDialog(category: category),
                icon: const Icon(Icons.edit_outlined),
                color: _green,
              ),
              IconButton(
                tooltip: system
                    ? 'دسته‌بندی سیستمی'
                    : active
                        ? 'غیرفعال کردن'
                        : 'فعال کردن',
                onPressed: system || _saving
                    ? null
                    : () => _toggleActive(category),
                icon: Icon(
                  active
                      ? Icons.toggle_on_rounded
                      : Icons.toggle_off_rounded,
                  size: 30,
                ),
                color: active ? _green : _muted,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(child: info),
                  ],
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerLeft, child: actions),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 13),
              Expanded(child: info),
              const SizedBox(width: 8),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _showCategoryDialog({
    Map<String, dynamic>? category,
  }) async {
    if (_companyId == null) {
      _message('ابتدا اطلاعات شرکت را بارگذاری کنید.', error: true);
      return;
    }

    final editing = category != null;
    final nameController = TextEditingController(
      text: _string(category?['name']),
    );
    final codeController = TextEditingController(
      text: _string(category?['code']),
    );
    final descriptionController = TextEditingController(
      text: _string(category?['description']),
    );
    final formKey = GlobalKey<FormState>();
    String type = _string(category?['category_type']).isEmpty
        ? 'operational'
        : _string(category?['category_type']);
    bool active = category == null ? true : _bool(category['is_active']);

    await showDialog<void>(
      context: context,
      barrierDismissible: !_saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(editing ? 'ویرایش دسته‌بندی' : 'دسته‌بندی جدید'),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          autofocus: true,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration('نام دسته‌بندی *'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'نام دسته‌بندی الزامی است';
                            }
                            if (value.trim().length > 100) {
                              return 'نام دسته‌بندی نباید بیشتر از ۱۰۰ نویسه باشد';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 13),
                        TextFormField(
                          controller: codeController,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration('کد دسته‌بندی (اختیاری)'),
                        ),
                        const SizedBox(height: 13),
                        DropdownButtonFormField<String>(
                          value: type,
                          decoration: _decoration('نوع درآمد *'),
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
                            if (value != null) setDialogState(() => type = value);
                          },
                        ),
                        const SizedBox(height: 13),
                        TextFormField(
                          controller: descriptionController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: _decoration('توضیحات (اختیاری)'),
                        ),
                        if (editing) ...[
                          const SizedBox(height: 10),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: active,
                            activeColor: _green,
                            title: const Text(
                              'دسته‌بندی فعال باشد',
                              style: TextStyle(fontSize: 13),
                            ),
                            subtitle: const Text(
                              'دسته‌بندی غیرفعال در ثبت درآمد جدید نمایش داده نمی‌شود.',
                              style: TextStyle(fontSize: 11, height: 1.6),
                            ),
                            onChanged: (value) =>
                                setDialogState(() => active = value),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('انصراف'),
                ),
                FilledButton.icon(
                  onPressed: _saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          await _saveCategory(
                            dialogContext: dialogContext,
                            existing: category,
                            name: nameController.text.trim(),
                            code: codeController.text.trim(),
                            description: descriptionController.text.trim(),
                            type: type,
                            active: active,
                          );
                        },
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(_saving ? 'در حال ذخیره...' : 'ذخیره'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    codeController.dispose();
    descriptionController.dispose();
  }

  Future<void> _saveCategory({
    required BuildContext dialogContext,
    required Map<String, dynamic>? existing,
    required String name,
    required String code,
    required String description,
    required String type,
    required bool active,
  }) async {
    if (_companyId == null) return;

    setState(() => _saving = true);

    try {
      final user = _supabase.auth.currentUser;
      final duplicate = _categories.any((item) {
        if (_string(item['id']) == _string(existing?['id'])) return false;
        return _string(item['name']).trim().toLowerCase() == name.toLowerCase();
      });

      if (duplicate) {
        throw Exception('دسته‌بندی دیگری با همین نام وجود دارد.');
      }

      final payload = <String, dynamic>{
        'name': name,
        'code': code.isEmpty ? null : code,
        'description': description.isEmpty ? null : description,
        'category_type': type,
        'is_active': active,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (existing == null) {
        payload.addAll({
          'company_id': _companyId,
          'created_by': user?.id,
          'is_system': false,
        });

        await _supabase.from('income_categories').insert(payload);
      } else {
        if (_bool(existing['is_system'])) {
          throw Exception('دسته‌بندی سیستمی قابل ویرایش نیست.');
        }

        await _supabase
            .from('income_categories')
            .update(payload)
            .eq('id', existing['id'])
            .eq('company_id', _companyId!);
      }

      if (!mounted) return;
      Navigator.pop(dialogContext);
      await _loadCategories();
      _message(existing == null
          ? 'دسته‌بندی جدید ایجاد شد.'
          : 'دسته‌بندی ویرایش شد.');
    } catch (error) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text('ذخیره دسته‌بندی ناموفق بود: $error'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> category) async {
    if (_companyId == null || _bool(category['is_system'])) return;

    final currentlyActive = _bool(category['is_active']);
    final nextActive = !currentlyActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(nextActive ? 'فعال کردن دسته‌بندی' : 'غیرفعال کردن دسته‌بندی'),
        content: Text(
          nextActive
              ? 'دسته‌بندی «${_string(category['name'])}» برای ثبت درآمدهای جدید قابل انتخاب خواهد بود.'
              : 'دسته‌بندی «${_string(category['name'])}» در ثبت درآمدهای جدید نمایش داده نمی‌شود. سوابق قبلی حذف نخواهند شد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: nextActive ? _green : const Color(0xFF8A5A18),
              foregroundColor: Colors.white,
            ),
            child: Text(nextActive ? 'فعال شود' : 'غیرفعال شود'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await _supabase
          .from('income_categories')
          .update({
            'is_active': nextActive,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', category['id'])
          .eq('company_id', _companyId!);

      await _loadCategories();
      _message(nextActive ? 'دسته‌بندی فعال شد.' : 'دسته‌بندی غیرفعال شد.');
    } catch (error) {
      _message('تغییر وضعیت دسته‌بندی ناموفق بود: $error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFFAFCFA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _green, width: 1.4),
      ),
    );
  }
}

class _SummaryData {
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });
}
