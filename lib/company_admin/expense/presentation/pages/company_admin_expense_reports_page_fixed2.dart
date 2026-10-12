import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

/// گزارش هزینه‌های پنل مدیرعامل بر اساس شمای فعلی دیتابیس.
/// سال مالی: expense_fiscal_years
/// دوره‌ها: expense_fiscal_periods
/// ریز هزینه‌ها: expenses و expense_recognitions
class CompanyAdminExpenseReportsPage extends StatefulWidget {
  final String? companyId;

  const CompanyAdminExpenseReportsPage({super.key, this.companyId});

  @override
  State<CompanyAdminExpenseReportsPage> createState() =>
      _CompanyAdminExpenseReportsPageState();
}

class _CompanyAdminExpenseReportsPageState
    extends State<CompanyAdminExpenseReportsPage> {
  final SupabaseClient _db = Supabase.instance.client;
  bool _loading = true;
  String? _error;
  String? _companyId;
  String? _selectedYearId;
  String _selectedPeriodId = 'all';
  List<Map<String, dynamic>> _years = [];
  List<Map<String, dynamic>> _periods = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _recognitions = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _workflow = [];

  static const _months = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد',
    'شهریور', 'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String> _resolveCompanyId() async {
    final provided = widget.companyId?.trim();
    if (provided != null && provided.isNotEmpty) return provided;
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('کاربر وارد سیستم نشده است.');

    final membership = await _db
        .from('company_users')
        .select('company_id, role, is_active')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .eq('role', 'company_admin')
        .limit(2);

    if (membership.isNotEmpty) {
      if (membership.length > 1) {
        throw Exception(
            'برای این کاربر بیش از یک شرکت فعال پیدا شد؛ انتخاب شرکت لازم است.');
      }
      return membership.first['company_id'].toString();
    }

    final owned = await _db
        .from('companies')
        .select('id')
        .or('owner_user_id.eq.${user.id},owner_id.eq.${user.id}')
        .eq('is_active', true)
        .limit(2);
    if (owned.length == 1) return owned.first['id'].toString();
    if (owned.length > 1) throw Exception(
        'چند شرکت متعلق به این حساب است؛ انتخاب شرکت لازم است.');
    throw Exception(
        'شرکت فعال برای مدیرعامل پیدا نشد. عضویت فعال در company_users را بررسی کنید.');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final company = await _resolveCompanyId();
      final yearRows = await _db
          .from('expense_fiscal_years')
          .select('id, company_id, year, title, status')
          .eq('company_id', company)
          .order('year', ascending: false);

      final years = List<Map<String, dynamic>>.from(yearRows);
      String? selectedYear = _selectedYearId;
      if (years.isEmpty) {
        selectedYear = null;
      } else if (selectedYear == null ||
          !years.any((y) => y['id'].toString() == selectedYear)) {
        selectedYear = years.first['id'].toString();
      }

      List<Map<String, dynamic>> periods = [];
      List<Map<String, dynamic>> expenses = [];
      List<Map<String, dynamic>> recognitions = [];
      List<Map<String, dynamic>> categories = [];
      List<Map<String, dynamic>> workflow = [];

      if (selectedYear != null) {
        final periodRows = await _db
            .from('expense_fiscal_periods')
            .select(
            'id, fiscal_year_id, company_id, year, month, title, status, created_at')
            .eq('company_id', company)
            .eq('fiscal_year_id', selectedYear)
            .order('month');
        periods = List<Map<String, dynamic>>.from(periodRows);

        final periodIds = periods.map((p) => p['id'].toString()).toList();
        final categoryRows = await _db
            .from('expense_categories')
            .select('id, name, code')
            .eq('company_id', company);
        categories = List<Map<String, dynamic>>.from(categoryRows);

        if (periodIds.isNotEmpty) {
          final expenseRows = await _db
              .from('expenses')
              .select(
              'id, company_id, category_id, title, description, amount, expense_date, reference_number, expense_type, source_type, created_at')
              .eq('company_id', company)
              .order('expense_date', ascending: false);
          expenses = List<Map<String, dynamic>>.from(expenseRows);
          // جدول expenses در شمای فعلی fiscal_period_id ندارد؛ این موارد گزارش مستقل هزینه‌اند.
          // هزینه‌های شناسایی‌شده به دوره متصل‌اند و بر اساس دوره فیلتر می‌شوند.
          final recognitionRows = await _db
              .from('expense_recognitions')
              .select(
              'id, company_id, fiscal_period_id, category_id, amount, description, created_at')
              .eq('company_id', company)
              .inFilter('fiscal_period_id', periodIds);
          recognitions = List<Map<String, dynamic>>.from(recognitionRows);

          final workflowRows = await _db
              .from('expense_fiscal_period_workflow')
              .select(
              'id, period_id, from_status, to_status, acted_by, note, created_at')
              .eq('company_id', company)
              .order('created_at', ascending: false);
          workflow = List<Map<String, dynamic>>.from(workflowRows);
        }
      }

      if (!mounted) return;
      setState(() {
        _companyId = company;
        _years = years;
        _selectedYearId = selectedYear;
        _periods = periods;
        _expenses = expenses;
        _recognitions = recognitions;
        _categories = categories;
        _workflow = workflow;
        if (_selectedPeriodId != 'all' &&
            !periods.any((p) => p['id'].toString() == _selectedPeriodId)) {
          _selectedPeriodId = 'all';
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _periodTitle(Map<String, dynamic> p) {
    final title = p['title']?.toString().trim();
    if (title != null && title.isNotEmpty) return title;
    final month = (p['month'] as num?)?.toInt() ?? 0;
    final year = p['year']?.toString() ?? '';
    final monthName = month >= 1 && month <= 12
        ? _months[month - 1]
        : 'ماه $month';
    return '$monthName $year';
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'open':
        return 'باز';
      case 'submitted_to_company_admin':
        return 'در انتظار بررسی مدیرعامل';
      case 'submitted_to_consultant':
        return 'ارسال‌شده به مشاور';
      case 'approved':
        return 'تأییدشده';
      case 'closed':
        return 'بسته';
      default:
        return status ?? 'نامشخص';
    }
  }

  String _money(num value) {
    final raw = value.round().toString();
    return raw.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }

  List<Map<String, dynamic>> get _visibleRecognitions {
    if (_selectedPeriodId == 'all') return _recognitions;
    return _recognitions.where((r) =>
    r['fiscal_period_id'].toString() == _selectedPeriodId).toList();
  }

  List<Map<String, dynamic>> get _visibleWorkflow {
    if (_selectedPeriodId == 'all') return _workflow;
    return _workflow.where((w) =>
    w['period_id'].toString() == _selectedPeriodId).toList();
  }

  Map<String, String> get _categoryNames =>
      {
        for (final c in _categories) c['id'].toString(): c['name']
            ?.toString() ?? 'بدون دسته‌بندی'
      };

  @override
  Widget build(BuildContext context) {
    final totalRecognized = _visibleRecognitions.fold<double>(
        0, (sum, r) => sum + ((r['amount'] as num?)?.toDouble() ?? 0));
    final categoryTotals = <String, double>{};
    for (final r in _visibleRecognitions) {
      final name = _categoryNames[r['category_id']?.toString()] ??
          'دسته‌بندی نامشخص';
      categoryTotals[name] = (categoryTotals[name] ?? 0) +
          ((r['amount'] as num?)?.toDouble() ?? 0);
    }
    final statusCounts = <String, int>{};
    for (final p in _periods.where((p) =>
    _selectedPeriodId == 'all' || p['id'].toString() == _selectedPeriodId)) {
      final status = p['status']?.toString() ?? 'unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return CompanyAdminScaffold(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          color: const Color(0xFFF6F8F7),
          child: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _errorView()
                : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(children: [
                    const Expanded(
                        child: Text('گزارش‌های هزینه', style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF17221D)))),
                    IconButton(onPressed: _load,
                        tooltip: 'بارگذاری مجدد',
                        icon: const Icon(Icons.refresh_rounded)),
                  ]),
                  const SizedBox(height: 6),
                  const Text(
                      'گزارش مدیریتی هزینه‌ها، شناسایی هزینه و وضعیت دوره‌های مالی',
                      style: TextStyle(color: Color(0xFF718078))),
                  const SizedBox(height: 20),
                  _filters(),
                  const SizedBox(height: 18),
                  if (_years.isEmpty)
                    _empty('برای این شرکت هنوز سال مالی هزینه ثبت نشده است.')
                  else
                    ...[
                      LayoutBuilder(builder: (context, c) {
                        final width = c.maxWidth < 620 ? c.maxWidth : (c
                            .maxWidth - 24) / 3;
                        return Wrap(spacing: 12, runSpacing: 12, children: [
                          SizedBox(width: width,
                              child: _metric('مجموع هزینه شناسایی‌شده',
                                  '${_money(totalRecognized)} ریال',
                                  Icons.payments_outlined,
                                  const Color(0xFF167A4A))),
                          SizedBox(width: width,
                              child: _metric('تعداد دوره‌ها', '${_periods
                                  .where((p) =>
                              _selectedPeriodId == 'all' ||
                                  p['id'].toString() == _selectedPeriodId)
                                  .length}', Icons.calendar_month_outlined,
                                  const Color(0xFF2563EB))),
                          SizedBox(width: width,
                              child: _metric('تعداد اسناد شناسایی',
                                  '${_visibleRecognitions.length}',
                                  Icons.receipt_long_outlined,
                                  const Color(0xFFD97706))),
                        ]);
                      }),
                      const SizedBox(height: 24),
                      _header('جمع هزینه بر اساس دسته‌بندی',
                          '${categoryTotals.length} دسته'),
                      const SizedBox(height: 10),
                      if (categoryTotals.isEmpty)
                        _empty(
                          'برای فیلتر انتخاب‌شده هزینه شناسایی‌شده‌ای وجود ندارد.',
                        ),
                      if (categoryTotals.isNotEmpty)
                        ...(categoryTotals.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value))).map((
                            e) => _categoryRow(e.key, e.value)),
                      const SizedBox(height: 24),
                      _header('وضعیت دوره‌های مالی',
                          '${statusCounts.values.fold<int>(0, (a, b) =>
                          a + b)} دوره'),
                      const SizedBox(height: 10),
                      if (statusCounts.isEmpty) _empty(
                          'دوره‌ای برای نمایش وجود ندارد.')
                      else
                        ...statusCounts.entries.map((e) =>
                            _statusRow(_statusLabel(e.key), e.value)),
                      const SizedBox(height: 24),
                      _header(
                          'ریز هزینه‌های ثبت‌شده', '${_expenses.length} سند'),
                      const SizedBox(height: 8),
                      const Text(
                          'جدول expenses در شمای فعلی به دوره مالی متصل نیست؛ بنابراین این بخش، اسناد هزینه شرکت را به‌صورت کلی نمایش می‌دهد.',
                          style: TextStyle(fontSize: 12, color: Color(
                              0xFF718078))),
                      const SizedBox(height: 10),
                      if (_expenses.isEmpty) _empty(
                          'سند هزینه‌ای ثبت نشده است.')
                      else
                        ..._expenses.map(_expenseRow),
                      const SizedBox(height: 24),
                      _header('گردش کار دوره‌ها',
                          '${_visibleWorkflow.length} رویداد'),
                      const SizedBox(height: 10),
                      if (_visibleWorkflow.isEmpty) _empty(
                          'رویدادی برای این فیلتر ثبت نشده است.')
                      else
                        ..._visibleWorkflow.map(_workflowRow),
                    ],
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filters() =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8E5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
              'فیلتر گزارش', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedYearId,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'سال مالی', border: OutlineInputBorder()),
            items: _years.map((y) => DropdownMenuItem<String>(
                value: y['id'].toString(), child: Text(y['title']
                ?.toString()
                .trim()
                .isNotEmpty == true ? y['title'].toString() : y['year']
                .toString()))).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedYearId = value;
                _selectedPeriodId = 'all';
              });
              _load();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedPeriodId,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'دوره مالی', border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem(
                  value: 'all', child: Text('همه دوره‌های سال مالی')),
              ..._periods.map((p) => DropdownMenuItem<String>(
                  value: p['id'].toString(), child: Text(_periodTitle(p))))
            ],
            onChanged: (value) =>
                setState(() => _selectedPeriodId = value ?? 'all'),
          ),
        ]),
      );

  Widget _metric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8E5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718078),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17221D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String title, String trailing) =>
      Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17221D)))),
        Text(trailing,
            style: const TextStyle(fontSize: 12, color: Color(0xFF718078)))
      ]);

  Widget _statusRow(String label, int count) => Card(elevation: 0,
      margin: const EdgeInsets.only(bottom: 7),
      child: ListTile(leading: const Icon(
          Icons.flag_outlined, color: Color(0xFF167A4A)),
          title: Text(label),
          trailing: CircleAvatar(radius: 15,
              backgroundColor: const Color(0xFFEAF7F0),
              child: Text('$count', style: const TextStyle(
                  color: Color(0xFF167A4A),
                  fontWeight: FontWeight.w800)))));

  Widget _categoryRow(String name, double amount) => Card(elevation: 0,
      margin: const EdgeInsets.only(bottom: 7),
      child: ListTile(leading: const Icon(
          Icons.category_outlined, color: Color(0xFF167A4A)),
          title: Text(name),
          trailing: Text('${_money(amount)} ریال',
              style: const TextStyle(fontWeight: FontWeight.w800))));

  Widget _expenseRow(Map<String, dynamic> e) {
    final category = _categoryNames[e['category_id']?.toString()] ??
        'بدون دسته‌بندی';
    final amount = (e['amount'] as num?)?.toDouble() ?? 0;
    return Card(
        elevation: 0, margin: const EdgeInsets.only(bottom: 8), child: ListTile(
      leading: const CircleAvatar(backgroundColor: Color(0xFFEAF7F0),
          child: Icon(Icons.receipt_long_outlined, color: Color(0xFF167A4A))),
      title: Text(e['title']?.toString() ?? 'بدون عنوان',
          style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('$category • ${e['expense_date']?.toString() ??
          'بدون تاریخ'}${e['reference_number'] == null
          ? ''
          : ' • مرجع: ${e['reference_number']}'}'),
      trailing: Text('${_money(amount)} ریال',
          style: const TextStyle(fontWeight: FontWeight.w800)),
    ));
  }

  Widget _workflowRow(Map<String, dynamic> w) =>
      Card(elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(
                Icons.history_rounded, color: Color(0xFF2563EB)),
            title: Text(
                '${_statusLabel(w['from_status']?.toString())} ← ${_statusLabel(
                    w['to_status']?.toString())}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${w['created_at']?.toString() ?? ''}${(w['note']
                ?.toString()
                .trim()
                .isNotEmpty ?? false) ? '\n${w['note']}' : ''}'),
            isThreeLine: (w['note']
                ?.toString()
                .trim()
                .isNotEmpty ?? false),
          ));

  Widget _empty(String text) => Container(width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8E5))),
      child: Text(text, textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF718078))));

  Widget _errorView() => Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error ?? 'خطای نامشخص', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('تلاش مجدد'))
          ])));
}

