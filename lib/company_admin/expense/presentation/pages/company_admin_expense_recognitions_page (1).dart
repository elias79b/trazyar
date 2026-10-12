import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

/// ثبت و مدیریت شناسایی هزینه‌ها با استفاده از جداول موجود Supabase.
class CompanyAdminExpenseRecognitionsPage extends StatefulWidget {
  const CompanyAdminExpenseRecognitionsPage({super.key});

  @override
  State<CompanyAdminExpenseRecognitionsPage> createState() =>
      _CompanyAdminExpenseRecognitionsPageState();
}

class _CompanyAdminExpenseRecognitionsPageState
    extends State<CompanyAdminExpenseRecognitionsPage> {
  final SupabaseClient _db = Supabase.instance.client;
  final NumberFormat _money = NumberFormat('#,##0', 'en_US');

  static const Color _green = Color(0xFF176B4D);
  static const Color _background = Color(0xFFF4F8F5);
  static const Color _border = Color(0xFFD9E4DD);
  static const Color _text = Color(0xFF202B25);
  static const Color _muted = Color(0xFF718078);

  static const List<String> _months = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _companyId;
  String _search = '';
  String _typeFilter = 'all';
  String? _periodFilter;
  List<Map<String, dynamic>> _periods = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _recognitions = [];
  Map<String, String> _categoryNames = {};
  Map<String, Map<String, dynamic>> _periodById = {};

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

      final responses = await Future.wait([
        _db
            .from('expense_fiscal_periods')
            .select('id, fiscal_year_id, company_id, year, month, title, status')
            .eq('company_id', companyId)
            .order('year', ascending: false)
            .order('month', ascending: false),
        _db
            .from('expense_categories')
            .select('id, name, expense_type, is_active')
            .eq('company_id', companyId)
            .eq('is_active', true)
            .order('name'),
        _db
            .from('expense_recognitions')
            .select('id, company_id, fiscal_period_id, category_id, amount, description, created_by, created_at, updated_at')
            .eq('company_id', companyId)
            .order('created_at', ascending: false),
      ]);

      final periods = List<Map<String, dynamic>>.from(responses[0] as List);
      final categories = List<Map<String, dynamic>>.from(responses[1] as List);
      final recognitions = List<Map<String, dynamic>>.from(responses[2] as List);
      final categoryNames = <String, String>{};
      for (final row in categories) {
        categoryNames[row['id'].toString()] = (row['name'] ?? 'بدون نام').toString();
      }
      // Include names of inactive categories already used in existing records.
      final usedCategoryIds = recognitions
          .map((row) => row['category_id']?.toString())
          .whereType<String>()
          .toSet();
      final missingCategoryIds = usedCategoryIds
          .where((id) => !categoryNames.containsKey(id))
          .toList();
      if (missingCategoryIds.isNotEmpty) {
        final oldCategories = await _db
            .from('expense_categories')
            .select('id, name')
            .eq('company_id', companyId)
            .inFilter('id', missingCategoryIds);
        for (final row in oldCategories) {
          categoryNames[row['id'].toString()] =
              (row['name'] ?? 'دسته‌بندی').toString();
        }
      }

      final periodById = <String, Map<String, dynamic>>{};
      for (final row in periods) {
        periodById[row['id'].toString()] = row;
      }

      if (!mounted) return;
      setState(() {
        _companyId = companyId;
        _periods = periods;
        _categories = categories;
        _recognitions = recognitions;
        _categoryNames = categoryNames;
        _periodById = periodById;
        if (_periodFilter != null &&
            !periods.any((p) => p['id'].toString() == _periodFilter)) {
          _periodFilter = null;
        }
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
      return 'دسترسی به شناسایی هزینه‌ها مجاز نیست؛ سیاست‌های RLS در Supabase را بررسی کنید.';
    }
    return message.replaceFirst('Exception: ', '');
  }

  String _periodLabel(Map<String, dynamic> period) {
    final month = ((period['month'] as num?)?.toInt() ?? 1).clamp(1, 12);
    return '${_months[month - 1]} ${period['year']}';
  }

  String _periodStatusLabel(String? status) {
    switch (status) {
      case 'open':
        return 'باز';
      case 'submitted_to_company_admin':
        return 'در انتظار بررسی مدیرعامل';
      case 'submitted_to_consultant':
        return 'نزد مشاور';
      case 'approved':
        return 'تأییدشده';
      case 'closed':
        return 'بسته';
      default:
        return status ?? 'نامشخص';
    }
  }

  List<Map<String, dynamic>> get _visibleRecognitions {
    final query = _search.trim().toLowerCase();
    return _recognitions.where((row) {
      if (_periodFilter != null &&
          row['fiscal_period_id']?.toString() != _periodFilter) {
        return false;
      }
      final categoryId = row['category_id']?.toString();
      final category = _categoryNames[categoryId] ?? '';
      final period = _periodById[row['fiscal_period_id']?.toString()];
      final periodLabel = period == null ? '' : _periodLabel(period);
      if (_typeFilter != 'all') {
        String? type;
        for (final categoryRow in _categories) {
          if (categoryRow['id']?.toString() == categoryId) {
            type = categoryRow['expense_type']?.toString();
            break;
          }
        }
        if (type != _typeFilter) return false;
      }
      final description = (row['description'] ?? '').toString().toLowerCase();
      if (query.isNotEmpty &&
          !category.toLowerCase().contains(query) &&
          !description.contains(query) &&
          !periodLabel.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  double _amount(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  double get _visibleTotal => _visibleRecognitions.fold<double>(
        0,
        (sum, row) => sum + _amount(row['amount']),
      );

  bool _periodCanEdit(Map<String, dynamic>? period) =>
      period != null && period['status'] == 'open';

  Future<void> _openEditor({Map<String, dynamic>? recognition}) async {
    if (_saving || _companyId == null) return;
    final isEditing = recognition != null;
    final existingPeriodId = recognition?['fiscal_period_id']?.toString();
    final editablePeriods = _periods.where(_periodCanEdit).toList();

    String? selectedPeriodId = existingPeriodId;
    if (selectedPeriodId == null || !_periodCanEdit(_periodById[selectedPeriodId])) {
      selectedPeriodId = editablePeriods.isEmpty
          ? null
          : editablePeriods.first['id'].toString();
    }

    final existingCategoryId = recognition?['category_id']?.toString();
    final availableCategories = _categories.toList();
    if (existingCategoryId != null &&
        !availableCategories.any((c) => c['id'].toString() == existingCategoryId)) {
      final old = await _db
          .from('expense_categories')
          .select('id, name, expense_type, is_active')
          .eq('company_id', _companyId!)
          .eq('id', existingCategoryId)
          .maybeSingle();
      if (old != null) availableCategories.add(Map<String, dynamic>.from(old));
    }
    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: recognition == null ? '' : _amount(recognition['amount']).toStringAsFixed(0),
    );
    final descriptionController = TextEditingController(
      text: (recognition?['description'] ?? '').toString(),
    );
    String? selectedCategoryId = existingCategoryId;
    if (selectedCategoryId == null ||
        !availableCategories.any((c) => c['id'].toString() == selectedCategoryId)) {
      selectedCategoryId = availableCategories.isEmpty
          ? null
          : availableCategories.first['id'].toString();
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'ویرایش شناسایی هزینه' : 'ثبت شناسایی هزینه'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedPeriodId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'دوره مالی *',
                        border: OutlineInputBorder(),
                      ),
                      items: editablePeriods.map((period) {
                        return DropdownMenuItem(
                          value: period['id'].toString(),
                          child: Text(_periodLabel(period)),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedPeriodId = value),
                      validator: (value) =>
                          value == null ? 'یک دوره باز انتخاب کنید.' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'دسته‌بندی هزینه *',
                        border: OutlineInputBorder(),
                      ),
                      items: availableCategories.map((category) {
                        final type = category['expense_type'] == 'non_operational'
                            ? 'غیرعملیاتی'
                            : 'عملیاتی';
                        final inactive = category['is_active'] == true ? '' : ' (غیرفعال)';
                        return DropdownMenuItem(
                          value: category['id'].toString(),
                          child: Text('${category['name']} • $type$inactive',
                              overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedCategoryId = value),
                      validator: (value) =>
                          value == null ? 'یک دسته‌بندی انتخاب کنید.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'مبلغ (ریال) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (value) {
                        final amount = double.tryParse(
                          (value ?? '').replaceAll(',', '').trim(),
                        );
                        if (amount == null || amount <= 0) {
                          return 'مبلغ معتبر و بزرگ‌تر از صفر وارد کنید.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'شرح هزینه (اختیاری)',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (editablePeriods.isEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'برای ثبت شناسایی، ابتدا یک دوره با وضعیت «باز» ایجاد کنید.',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
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
              onPressed: editablePeriods.isEmpty
                  ? null
                  : () {
                      if (formKey.currentState?.validate() != true) return;
                      Navigator.of(dialogContext).pop({
                        'fiscal_period_id': selectedPeriodId,
                        'category_id': selectedCategoryId,
                        'amount': double.parse(
                          amountController.text.replaceAll(',', '').trim(),
                        ),
                        'description': descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      });
                    },
              child: Text(isEditing ? 'ذخیره تغییرات' : 'ثبت هزینه'),
            ),
          ],
        ),
      ),
    );

    // showDialog may complete before the reverse transition has fully removed
    // the dialog subtree. Keep its controllers alive until that transition
    // finishes so TextFormField cannot access a disposed controller.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    amountController.dispose();
    descriptionController.dispose();

    if (!mounted || result == null || _companyId == null) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now().toIso8601String();
      final payload = <String, dynamic>{
        'company_id': _companyId,
        'fiscal_period_id': result['fiscal_period_id'],
        'category_id': result['category_id'],
        'amount': result['amount'],
        'description': result['description'],
        'updated_at': now,
      };
      if (isEditing) {
        await _db
            .from('expense_recognitions')
            .update(payload)
            .eq('id', recognition['id'])
            .eq('company_id', _companyId!);
      } else {
        payload['created_by'] = _db.auth.currentUser!.id;
        await _db.from('expense_recognitions').insert(payload);
      }
      await _load();
      if (mounted) {
        _showSnack(isEditing
            ? 'شناسایی هزینه ویرایش شد.'
            : 'شناسایی هزینه ثبت شد.');
      }
    } catch (e) {
      if (mounted) _showSnack(_friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteRecognition(Map<String, dynamic> row) async {
    if (_saving) return;
    final period = _periodById[row['fiscal_period_id']?.toString()];
    if (!_periodCanEdit(period)) {
      _showSnack('فقط شناسایی‌های دوره باز قابل حذف هستند.', error: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف شناسایی هزینه'),
        content: const Text(
          'این شناسایی هزینه حذف شود؟ این عملیات قابل بازگشت نیست.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || _companyId == null) return;

    setState(() => _saving = true);
    try {
      await _db
          .from('expense_recognitions')
          .delete()
          .eq('id', row['id'])
          .eq('company_id', _companyId!);
      await _load();
      if (mounted) _showSnack('شناسایی هزینه حذف شد.');
    } catch (e) {
      if (mounted) _showSnack(_friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red.shade700 : _green,
    ));
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
                    child: Center(child: CircularProgressIndicator(color: _green)),
                  )
                else if (_error != null)
                  _errorCard()
                else ...[
                  _summary(),
                  const SizedBox(height: 18),
                  _toolbar(),
                  const SizedBox(height: 14),
                  if (_visibleRecognitions.isEmpty)
                    _emptyState()
                  else
                    ..._visibleRecognitions.map(_recognitionCard),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 620;
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('هزینه / شناسایی هزینه‌ها',
                style: TextStyle(color: _muted, fontSize: 12)),
            SizedBox(height: 7),
            Text('ثبت و مدیریت شناسایی هزینه‌ها',
                style: TextStyle(color: _text, fontSize: 25, fontWeight: FontWeight.w800)),
            SizedBox(height: 5),
            Text(
              'هزینه‌ها را در دوره مالی باز ثبت کنید؛ دوره‌های ارسال‌شده یا بسته قابل ویرایش نیستند.',
              style: TextStyle(color: _muted, fontSize: 13, height: 1.7),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        if (!compact)
          FilledButton.icon(
            onPressed: _loading || _saving ? null : () => _openEditor(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('ثبت شناسایی هزینه'),
          )
        else
          IconButton(
            tooltip: 'ثبت شناسایی هزینه',
            onPressed: _loading || _saving ? null : () => _openEditor(),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
      ]);
    });
  }

  Widget _summary() {
    final total = _recognitions.fold<double>(
        0, (sum, row) => sum + _amount(row['amount']));
    final openPeriods = _periods.where(_periodCanEdit).length;
    final items = [
      _Metric('تعداد شناسایی‌ها', '${_recognitions.length}', Icons.receipt_long_outlined),
      _Metric('مجموع مبلغ ثبت‌شده', '${_money.format(total)} ریال', Icons.account_balance_wallet_outlined),
      _Metric('دوره‌های باز', '$openPeriods', Icons.lock_open_outlined),
      _Metric('نتایج فیلتر فعلی', '${_visibleRecognitions.length}', Icons.filter_alt_outlined),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 1100 ? 4 : constraints.maxWidth > 650 ? 2 : 1;
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: columns == 1 ? 4.0 : columns == 2 ? 2.5 : 2.0,
        children: items.map((item) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _border), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: const Color(0xFFE4F4EB), borderRadius: BorderRadius.circular(13)),
              child: Icon(item.icon, color: _green)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(item.label, style: const TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 7),
              Text(item.value, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w800)),
            ])),
          ]),
        )).toList(),
      );
    });
  }

  Widget _toolbar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _border), borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'جست‌وجوی شرح، دسته‌بندی یا دوره...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _search.isEmpty ? null : IconButton(
              onPressed: () => setState(() => _search = ''),
              icon: const Icon(Icons.close_rounded),
            ),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (value) => setState(() => _search = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          value: _periodFilter,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'فیلتر دوره مالی',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('همه دوره‌ها'),
            ),
            ..._periods.map((period) => DropdownMenuItem<String?>(
              value: period['id'].toString(),
              child: Text('${_periodLabel(period)} • ${_periodStatusLabel(period['status']?.toString())}'),
            )),
          ],
          onChanged: (value) => setState(() => _periodFilter = value),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            _filterChip('all', 'همه انواع'),
            _filterChip('operational', 'عملیاتی'),
            _filterChip('non_operational', 'غیرعملیاتی'),
          ]),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text('جمع نتایج فیلترشده: ${_money.format(_visibleTotal)} ریال',
              style: const TextStyle(color: _green, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _typeFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _typeFilter = value),
      selectedColor: const Color(0xFFDDF1E5),
      side: BorderSide(color: selected ? _green : _border),
      labelStyle: TextStyle(color: selected ? _green : _text,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400),
    );
  }

  Widget _recognitionCard(Map<String, dynamic> row) {
    final period = _periodById[row['fiscal_period_id']?.toString()];
    final categoryId = row['category_id']?.toString();
    final categoryName = _categoryNames[categoryId] ?? 'دسته‌بندی حذف‌شده';
    final canEdit = _periodCanEdit(period);
    final description = (row['description'] ?? '').toString().trim();
    final amount = _amount(row['amount']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _border), borderRadius: BorderRadius.circular(17)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 46, height: 46,
            decoration: BoxDecoration(color: const Color(0xFFE4F4EB), borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.receipt_long_outlined, color: _green)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(categoryName, style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(period == null ? 'دوره نامشخص' : _periodLabel(period),
                style: const TextStyle(color: _muted, fontSize: 12)),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(color: _muted, height: 1.6)),
            ],
          ])),
          const SizedBox(width: 8),
          Text('${_money.format(amount)} ریال',
              style: const TextStyle(color: _green, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text(
              'وضعیت دوره: ${period == null ? 'نامشخص' : _periodStatusLabel(period['status']?.toString())}',
              style: TextStyle(color: canEdit ? _green : _muted, fontSize: 12),
            ),
          ),
          if (canEdit)
            PopupMenuButton<String>(
              tooltip: 'عملیات',
              enabled: !_saving,
              onSelected: (value) {
                if (value == 'edit') _openEditor(recognition: row);
                if (value == 'delete') _deleteRecognition(row);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('ویرایش'),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline, color: Colors.red),
                    title: Text('حذف'),
                  ),
                ),
              ],
            )
          else
            const Tooltip(
              message: 'دوره باز نیست؛ این شناسایی قابل ویرایش یا حذف نیست.',
              child: Icon(Icons.lock_outline, color: _muted, size: 20),
            ),
        ]),
      ]),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _border), borderRadius: BorderRadius.circular(18)),
      child: Column(children: [
        const Icon(Icons.receipt_long_outlined, size: 48, color: _green),
        const SizedBox(height: 12),
        Text(
          _recognitions.isEmpty
              ? 'هنوز شناسایی هزینه‌ای ثبت نشده است.'
              : 'با فیلترهای انتخاب‌شده نتیجه‌ای پیدا نشد.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'برای ثبت هزینه، یک دوره مالی باز و یک دسته‌بندی فعال لازم است.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, height: 1.6),
        ),
        const SizedBox(height: 16),
        if (_recognitions.isEmpty)
          FilledButton.icon(
            onPressed: _saving ? null : () => _openEditor(),
            icon: const Icon(Icons.add),
            label: const Text('ثبت شناسایی هزینه'),
          ),
      ]),
    );
  }

  Widget _errorCard() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.red.shade200), borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('بارگذاری شناسایی‌های هزینه ناموفق بود',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(_error ?? 'خطای نامشخص', style: const TextStyle(height: 1.6)),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('تلاش دوباره')),
    ]),
  );
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}
