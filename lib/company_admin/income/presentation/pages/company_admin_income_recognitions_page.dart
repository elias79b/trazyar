import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

class CompanyAdminIncomeRecognitionsPage extends StatefulWidget {
  const CompanyAdminIncomeRecognitionsPage({super.key});

  @override
  State<CompanyAdminIncomeRecognitionsPage> createState() =>
      _CompanyAdminIncomeRecognitionsPageState();
}

class _CompanyAdminIncomeRecognitionsPageState
    extends State<CompanyAdminIncomeRecognitionsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _companyId;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _periods = [];
  List<Map<String, dynamic>> _recognitions = [];
  String _search = '';
  String? _periodFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      if (mounted) setState(() => _search = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _jalaliToday() {
    final j = Jalali.now();
    return '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
  }

  String _formatMoney(dynamic value) {
    final number = num.tryParse(value?.toString() ?? '') ?? 0;
    return NumberFormat('#,##0.##', 'en_US').format(number);
  }

  String _periodLabel(Map<String, dynamic> period) {
    final fiscalYear = period['income_fiscal_years'];
    final fiscalYearMap = fiscalYear is Map ? fiscalYear : <String, dynamic>{};
    final fiscalYearTitle = (fiscalYearMap['title'] ?? '').toString().trim();
    final fiscalYearNumber = fiscalYearMap['year'] ?? period['year'] ?? '';
    final monthTitle = (period['title'] ?? '').toString().trim();
    final month = period['month'];
    final monthLabel = monthTitle.isNotEmpty ? monthTitle : 'ماه $month';
    final yearLabel = fiscalYearTitle.isNotEmpty
        ? '$fiscalYearTitle ($fiscalYearNumber)'
        : 'سال مالی $fiscalYearNumber';
    return '$yearLabel — $monthLabel';
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'open':
        return 'باز';
      case 'submitted_to_company_admin':
        return 'ارسال‌شده برای مدیر شرکت';
      case 'submitted_to_consultant':
        return 'ارسال‌شده برای مشاور';
      case 'approved':
        return 'تأیید نهایی';
      case 'closed':
        return 'بسته';
      default:
        return status ?? 'نامشخص';
    }
  }

  Future<void> _loadData() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('ابتدا وارد حساب کاربری شوید.');

      final membership = await _supabase
          .from('company_users')
          .select('company_id')
          .eq('user_id', user.id)
          .eq('role', 'company_admin')
          .eq('is_active', true)
          .maybeSingle();
      if (membership == null || membership['company_id'] == null) {
        throw Exception('شرکت فعالی برای حساب مدیر شرکت پیدا نشد.');
      }
      final companyId = membership['company_id'].toString();

      final results = await Future.wait([
        _supabase
            .from('income_categories')
            .select('id, name, category_type, is_active')
            .eq('company_id', companyId)
            .eq('is_active', true)
            .order('name'),
        _supabase
            .from('income_fiscal_periods')
            .select('id, fiscal_year_id, year, month, title, status, income_fiscal_years(title, year)')
            .eq('company_id', companyId)
            .order('year', ascending: false)
            .order('month', ascending: false),
        _supabase
            .from('income_recognitions')
            .select('id, company_id, fiscal_period_id, category_id, amount, description, created_by, created_at, income_categories(name, category_type), income_fiscal_periods(title, year, month, status, income_fiscal_years(title, year))')
            .eq('company_id', companyId)
            .order('created_at', ascending: false),
      ]);

      if (!mounted) return;
      setState(() {
        _companyId = companyId;
        _categories = List<Map<String, dynamic>>.from(results[0] as List);
        _periods = List<Map<String, dynamic>>.from(results[1] as List);
        _recognitions = List<Map<String, dynamic>>.from(results[2] as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = _friendlyError(e); });
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('income_recognitions') && text.contains('permission')) {
      return 'دسترسی دیتابیس به جدول شناسایی درآمد اجازه نمی‌دهد. سیاست‌های RLS را بررسی کنید.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  List<Map<String, dynamic>> get _filteredRecognitions {
    return _recognitions.where((row) {
      final periodId = row['fiscal_period_id']?.toString();
      if (_periodFilter != null && periodId != _periodFilter) return false;
      final category = row['income_categories'];
      final categoryName = category is Map ? (category['name'] ?? '').toString() : '';
      final period = row['income_fiscal_periods'];
      final periodName = period is Map ? (period['title'] ?? '').toString() : '';
      final description = (row['description'] ?? '').toString();
      final query = _search.toLowerCase();
      return query.isEmpty || categoryName.toLowerCase().contains(query) ||
          periodName.toLowerCase().contains(query) || description.toLowerCase().contains(query) ||
          (row['amount'] ?? '').toString().contains(query);
    }).toList();
  }

  num get _totalAmount => _filteredRecognitions.fold<num>(
      0, (sum, row) => sum + (num.tryParse(row['amount']?.toString() ?? '') ?? 0));

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    if (_companyId == null) return;
    if (_categories.isEmpty) {
      _showMessage('ابتدا از بخش دسته‌بندی‌ها حداقل یک دسته‌بندی فعال بسازید.');
      return;
    }
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(text: existing == null ? '' : _formatMoney(existing['amount']).replaceAll(',', ''));
    final descriptionController = TextEditingController(text: (existing?['description'] ?? '').toString());
    String? selectedCategory = existing?['category_id']?.toString();
    String? selectedPeriod = existing?['fiscal_period_id']?.toString();
    final openPeriods = _periods.where((p) => p['status'] == 'open').toList();
    if (selectedPeriod == null && openPeriods.isNotEmpty) selectedPeriod = openPeriods.first['id'].toString();
    if (selectedCategory == null && _categories.isNotEmpty) selectedCategory = _categories.first['id'].toString();
    if (selectedPeriod != null && !_periods.any((p) => p['id'].toString() == selectedPeriod)) selectedPeriod = null;
    if (selectedCategory != null && !_categories.any((c) => c['id'].toString() == selectedCategory)) selectedCategory = null;
    bool submitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'ثبت شناسایی درآمد' : 'ویرایش شناسایی درآمد'),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<String>(
                    value: selectedPeriod,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'دوره مالی', border: OutlineInputBorder()),
                    items: _periods.map((p) => DropdownMenuItem<String>(
                      value: p['id'].toString(),
                      child: Text('${_periodLabel(p)} — ${_statusLabel(p['status']?.toString())}', overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: submitting ? null : (v) => setDialogState(() => selectedPeriod = v),
                    validator: (v) => v == null ? 'دوره مالی را انتخاب کنید.' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'دسته‌بندی درآمد', border: OutlineInputBorder()),
                    items: _categories.map((c) => DropdownMenuItem<String>(
                      value: c['id'].toString(),
                      child: Text('${c['name']} (${c['category_type'] == 'non_operational' ? 'غیرعملیاتی' : 'عملیاتی'})', overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: submitting ? null : (v) => setDialogState(() => selectedCategory = v),
                    validator: (v) => v == null ? 'دسته‌بندی را انتخاب کنید.' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'مبلغ شناسایی‌شده (ریال)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.payments_outlined)),
                    validator: (value) {
                      final parsed = num.tryParse((value ?? '').replaceAll(',', '').trim());
                      if (parsed == null) return 'مبلغ معتبر وارد کنید.';
                      if (parsed < 0) return 'مبلغ نمی‌تواند منفی باشد.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'شرح / توضیحات (اختیاری)', border: OutlineInputBorder(), alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 8),
                  const Text('ثبت این اطلاعات در جدول income_recognitions انجام می‌شود؛ وضعیت گردش کار از وضعیت دوره مالی خوانده می‌شود.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: submitting ? null : () => Navigator.pop(dialogContext), child: const Text('انصراف')),
            FilledButton.icon(
              onPressed: submitting ? null : () async {
                if (!formKey.currentState!.validate()) return;
                final user = _supabase.auth.currentUser;
                if (user == null) { _showMessage('نشست کاربری منقضی شده است. دوباره وارد شوید.'); return; }
                setDialogState(() => submitting = true);
                try {
                  final payload = <String, dynamic>{
                    'company_id': _companyId,
                    'fiscal_period_id': selectedPeriod,
                    'category_id': selectedCategory,
                    'amount': num.parse(amountController.text.replaceAll(',', '').trim()),
                    'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                    'created_by': user.id,
                  };
                  if (existing == null) {
                    await _supabase.from('income_recognitions').insert(payload);
                  } else {
                    payload.remove('created_by');
                    payload.remove('company_id');
                    payload['updated_at'] = DateTime.now().toIso8601String();
                    await _supabase.from('income_recognitions').update(payload)
                        .eq('id', existing['id'].toString()).eq('company_id', _companyId!);
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  await _loadData();
                  if (mounted) _showMessage(existing == null ? 'شناسایی درآمد ثبت شد.' : 'اطلاعات شناسایی درآمد ویرایش شد.');
                } catch (e) {
                  setDialogState(() => submitting = false);
                  _showMessage('ثبت اطلاعات ناموفق بود: ${_friendlyError(e)}');
                }
              },
              icon: submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
              label: Text(submitting ? 'در حال ذخیره...' : 'ذخیره'),
            ),
          ],
        ),
      ),
    );
    // showDialog completes as soon as Navigator.pop is called, while the dialog
    // may still be running its reverse transition. Keep controllers alive until
    // that transition has finished so TextFormField can detach its listeners.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    amountController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deleteRecord(Map<String, dynamic> row) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف شناسایی درآمد'),
        content: const Text('از حذف این رکورد مطمئن هستید؟ این عملیات قابل بازگشت نیست.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _supabase.from('income_recognitions').delete()
          .eq('id', row['id'].toString()).eq('company_id', _companyId!);
      await _loadData();
      if (mounted) _showMessage('رکورد حذف شد.');
    } catch (e) {
      _showMessage('حذف انجام نشد: ${_friendlyError(e)}');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withOpacity(0.18))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)), const SizedBox(height: 6), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)])),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompanyAdminScaffold(
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          title: const Text('شناسایی درآمد'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          actions: [IconButton(tooltip: 'بارگذاری مجدد', onPressed: _loadData, icon: const Icon(Icons.refresh)), const SizedBox(width: 8)],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                    const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16), FilledButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh), label: const Text('تلاش مجدد')),
                  ])))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Row(children: [
                          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('مدیریت شناسایی درآمد', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), SizedBox(height: 6), Text('ثبت مبلغ درآمد شناسایی‌شده برای دسته‌بندی و دوره مالی مشخص', style: TextStyle(color: Colors.black54))])),
                          const SizedBox(width: 12),
                          FilledButton.icon(onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('ثبت شناسایی درآمد')),
                        ]),
                        const SizedBox(height: 18),
                        Wrap(spacing: 12, runSpacing: 12, children: [
                          SizedBox(width: 260, child: _metricCard('تعداد رکوردها', '${_filteredRecognitions.length}', Icons.receipt_long_outlined, Colors.blue)),
                          SizedBox(width: 300, child: _metricCard('مجموع مبلغ شناسایی‌شده', '${_formatMoney(_totalAmount)} ریال', Icons.account_balance_wallet_outlined, Colors.teal)),
                          SizedBox(width: 260, child: _metricCard('دسته‌بندی‌های فعال', '${_categories.length}', Icons.category_outlined, Colors.deepPurple)),
                        ]),
                        const SizedBox(height: 18),
                        Card(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16), child: Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: [
                          SizedBox(width: 300, child: TextField(controller: _searchController, decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'جست‌وجو در شرح و دسته‌بندی...', border: OutlineInputBorder(), isDense: true))),
                          SizedBox(width: 260, child: DropdownButtonFormField<String>(
                            value: _periodFilter,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'فیلتر دوره مالی', border: OutlineInputBorder(), isDense: true),
                            items: [const DropdownMenuItem<String>(value: null, child: Text('همه دوره‌ها')), ..._periods.map((p) => DropdownMenuItem<String>(value: p['id'].toString(), child: Text(_periodLabel(p), overflow: TextOverflow.ellipsis)))],
                            onChanged: (v) => setState(() => _periodFilter = v),
                          )),
                          OutlinedButton.icon(onPressed: () { _searchController.clear(); setState(() => _periodFilter = null); }, icon: const Icon(Icons.filter_alt_off), label: const Text('پاک‌کردن فیلترها')),
                        ]))),
                        const SizedBox(height: 14),
                        if (_categories.isEmpty)
                          _notice('دسته‌بندی فعالی وجود ندارد', 'ابتدا از بخش «دسته‌بندی‌ها» یک دسته‌بندی فعال ایجاد کنید.', Icons.category_outlined),
                        if (_periods.isEmpty)
                          _notice('دوره مالی تعریف نشده است', 'ابتدا در بخش «دوره‌های درآمد» سال مالی و دوره‌های ماهانه را ایجاد کنید.', Icons.calendar_month_outlined),
                        if (_filteredRecognitions.isEmpty)
                          _notice('رکوردی برای نمایش نیست', 'با ثبت شناسایی درآمد، اطلاعات این بخش نمایش داده می‌شود.', Icons.inbox_outlined)
                        else
                          Card(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
                            for (var i = 0; i < _filteredRecognitions.length; i++) ...[
                              _recognitionTile(_filteredRecognitions[i]),
                              if (i != _filteredRecognitions.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                            ],
                          ]))),
                        const SizedBox(height: 20),
                        Text('تاریخ امروز: ${_jalaliToday()}', style: const TextStyle(fontSize: 12, color: Colors.black45), textAlign: TextAlign.left),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _notice(String title, String message, IconData icon) {
    return Card(elevation: 0, color: Colors.white, child: Padding(padding: const EdgeInsets.all(24), child: Row(children: [
      Icon(icon, size: 34, color: Colors.blueGrey), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(message, style: const TextStyle(color: Colors.black54))])),
    ])));
  }

  Widget _recognitionTile(Map<String, dynamic> row) {
    final category = row['income_categories'];
    final period = row['income_fiscal_periods'];
    final categoryName = category is Map ? (category['name'] ?? 'دسته‌بندی حذف‌شده').toString() : 'دسته‌بندی';
    final periodName = period is Map ? _periodLabel(Map<String, dynamic>.from(period)) : 'دوره مالی';
    final type = category is Map && category['category_type'] == 'non_operational' ? 'غیرعملیاتی' : 'عملیاتی';
    final description = (row['description'] ?? '').toString().trim();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: CircleAvatar(backgroundColor: Colors.teal.withOpacity(0.10), child: const Icon(Icons.trending_up, color: Colors.teal)),
      title: Text(categoryName, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$periodName  •  $type'),
        if (description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis)),
      ])),
      trailing: SizedBox(width: 180, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Expanded(child: Text('${_formatMoney(row['amount'])} ریال', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
        PopupMenuButton<String>(tooltip: 'عملیات', onSelected: (value) {
          if (value == 'edit') _openForm(existing: row);
          if (value == 'delete') _deleteRecord(row);
        }, itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: ListTile(dense: true, leading: Icon(Icons.edit_outlined), title: Text('ویرایش'))),
          PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('حذف'))),
        ]),
      ])),
    );
  }
}
