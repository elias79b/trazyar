import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

/// مدیریت دوره‌های هزینه مدیرعامل؛ مطابق جداول فعلی expense_* در Supabase.
class CompanyAdminExpensePeriodsPage extends StatefulWidget {
  const CompanyAdminExpensePeriodsPage({super.key});

  @override
  State<CompanyAdminExpensePeriodsPage> createState() =>
      _CompanyAdminExpensePeriodsPageState();
}

class _CompanyAdminExpensePeriodsPageState
    extends State<CompanyAdminExpensePeriodsPage> {
  final SupabaseClient _db = Supabase.instance.client;
  final NumberFormat _money = NumberFormat('#,##0', 'en_US');

  static const Color _green = Color(0xFF176B4D);
  static const Color _background = Color(0xFFF4F8F5);
  static const Color _border = Color(0xFFD9E4DD);
  static const Color _text = Color(0xFF202B25);
  static const Color _muted = Color(0xFF718078);

  static const List<String> _months = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  bool _loading = true;
  String? _error;
  String? _companyId;
  String? _selectedYearId;
  String _statusFilter = 'all';
  List<Map<String, dynamic>> _years = [];
  List<Map<String, dynamic>> _periods = [];
  Map<String, double> _totalsByPeriod = {};
  Map<String, int> _recognitionCounts = {};

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

      final membership =
          await _db
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

      final yearResponse = await _db
          .from('expense_fiscal_years')
          .select('id, company_id, year, title, status, created_at')
          .eq('company_id', companyId)
          .order('year', ascending: false);
      final years = List<Map<String, dynamic>>.from(yearResponse);

      String? selectedId = _selectedYearId;
      if (selectedId == null ||
          !years.any((row) => row['id'].toString() == selectedId)) {
        selectedId = years.isEmpty ? null : years.first['id'].toString();
      }

      List<Map<String, dynamic>> periods = [];
      if (selectedId != null) {
        final periodResponse = await _db
            .from('expense_fiscal_periods')
            .select(
              'id, fiscal_year_id, company_id, year, month, title, status, created_at, updated_at',
            )
            .eq('company_id', companyId)
            .eq('fiscal_year_id', selectedId)
            .order('month');
        periods = List<Map<String, dynamic>>.from(periodResponse);
      }

      final periodIds = periods.map((p) => p['id'].toString()).toList();
      final totals = <String, double>{};
      final counts = <String, int>{};
      if (periodIds.isNotEmpty) {
        final recognitionResponse = await _db
            .from('expense_recognitions')
            .select('fiscal_period_id, amount')
            .eq('company_id', companyId)
            .inFilter('fiscal_period_id', periodIds);
        for (final row in recognitionResponse) {
          final id = row['fiscal_period_id'].toString();
          final amount = row['amount'];
          totals[id] =
              (totals[id] ?? 0) +
              (amount is num
                  ? amount.toDouble()
                  : double.tryParse('$amount') ?? 0);
          counts[id] = (counts[id] ?? 0) + 1;
        }
      }

      if (!mounted) return;
      setState(() {
        _companyId = companyId;
        _years = years;
        _selectedYearId = selectedId;
        _periods = periods;
        _totalsByPeriod = totals;
        _recognitionCounts = counts;
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
      return 'دسترسی به اطلاعات هزینه‌ها مجاز نیست؛ سیاست‌های RLS در Supabase را بررسی کنید.';
    }
    return message.replaceFirst('Exception: ', '');
  }

  Map<String, dynamic>? get _selectedYear {
    for (final year in _years) {
      if (year['id'].toString() == _selectedYearId) return year;
    }
    return null;
  }

  List<Map<String, dynamic>> get _visiblePeriods {
    final rows =
        _statusFilter == 'all'
            ? _periods
            : _periods.where((p) => p['status'] == _statusFilter).toList();
    rows.sort(
      (a, b) => ((a['month'] as num?)?.toInt() ?? 0).compareTo(
        (b['month'] as num?)?.toInt() ?? 0,
      ),
    );
    return rows;
  }

  double get _total => _periods.fold<double>(
    0,
    (sum, p) => sum + (_totalsByPeriod[p['id'].toString()] ?? 0),
  );

  int _countStatus(String status) =>
      _periods.where((p) => p['status'] == status).length;

  String _statusLabel(String? status) {
    switch (status) {
      case 'open':
        return 'باز';
      case 'submitted_to_company_admin':
        return 'در انتظار بررسی مدیرعامل';
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

  Color _statusColor(String? status) {
    switch (status) {
      case 'open':
        return const Color(0xFF2D8A62);
      case 'submitted_to_company_admin':
        return const Color(0xFFE09A26);
      case 'submitted_to_consultant':
        return const Color(0xFF287EB6);
      case 'approved':
        return const Color(0xFF16805D);
      case 'closed':
        return const Color(0xFF737C76);
      default:
        return _muted;
    }
  }

  Future<void> _createYear() async {
    final currentJalali = Jalali.now().year;
    final yearController = TextEditingController(text: '$currentJalali');
    final titleController = TextEditingController(
      text: 'سال مالی $currentJalali',
    );
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('ایجاد سال مالی هزینه'),
            content: Form(
              key: formKey,
              child: SizedBox(
                width: 380,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'سال شمسی'),
                      validator: (value) {
                        final year = int.tryParse(value ?? '');
                        if (year == null || year < 1300 || year > 1600) {
                          return 'سال باید عددی بین ۱۳۰۰ تا ۱۶۰۰ باشد.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'عنوان سال مالی',
                      ),
                      validator:
                          (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'عنوان را وارد کنید.'
                                  : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext, {
                      'year': int.parse(yearController.text.trim()),
                      'title': titleController.text.trim(),
                    });
                  }
                },
                child: const Text('ایجاد'),
              ),
            ],
          ),
    );
    yearController.dispose();
    titleController.dispose();
    if (result == null || _companyId == null) return;

    try {
      final userId = _db.auth.currentUser!.id;
      final inserted =
          await _db
              .from('expense_fiscal_years')
              .insert({
                'company_id': _companyId,
                'year': result['year'],
                'title': result['title'],
                'status': 'open',
                'created_by': userId,
              })
              .select('id')
              .single();
      if (!mounted) return;
      setState(() => _selectedYearId = inserted['id'].toString());
      await _load();
      if (mounted) _snack('سال مالی ایجاد شد.');
    } catch (e) {
      if (mounted) _snack(_friendlyError(e), error: true);
    }
  }

  Future<void> _createMonths() async {
    final year = _selectedYear;
    if (year == null || _companyId == null) return;
    if (year['status'] == 'closed') {
      _snack(
        'سال مالی بسته است و امکان ایجاد دوره جدید وجود ندارد.',
        error: true,
      );
      return;
    }
    try {
      final existing = _periods.map((p) => (p['month'] as num).toInt()).toSet();
      final missing =
          List<int>.generate(
            12,
            (i) => i + 1,
          ).where((month) => !existing.contains(month)).toList();
      if (missing.isEmpty) {
        _snack('هر ۱۲ دوره این سال مالی از قبل وجود دارد.');
        return;
      }
      await _db
          .from('expense_fiscal_periods')
          .insert(
            missing
                .map(
                  (month) => {
                    'fiscal_year_id': year['id'],
                    'company_id': _companyId,
                    'year': year['year'],
                    'month': month,
                    'title': '${_months[month - 1]} ${year['year']}',
                    'status': 'open',
                  },
                )
                .toList(),
          );
      await _load();
      if (mounted) _snack('${missing.length} دوره ماهانه ایجاد شد.');
    } catch (e) {
      if (mounted) _snack(_friendlyError(e), error: true);
    }
  }

  Future<void> _changeYearStatus(Map<String, dynamic> year) async {
    final isClosed = year['status'] == 'closed';
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(isClosed ? 'بازگشایی سال مالی' : 'بستن سال مالی'),
            content: Text(
              isClosed
                  ? 'سال مالی دوباره باز شود؟'
                  : 'با بستن سال مالی، امکان ایجاد دوره‌های جدید برای این سال غیرفعال می‌شود. ادامه می‌دهید؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('تأیید'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await _db
          .from('expense_fiscal_years')
          .update({
            'status': isClosed ? 'open' : 'closed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', year['id'])
          .eq('company_id', _companyId!);
      await _load();
      if (mounted) _snack(isClosed ? 'سال مالی باز شد.' : 'سال مالی بسته شد.');
    } catch (e) {
      if (mounted) _snack(_friendlyError(e), error: true);
    }
  }

  Future<void> _actOnPeriod(Map<String, dynamic> period, String action) async {
    final status = period['status']?.toString() ?? 'open';
    String nextStatus;
    String title;
    String message;
    if (action == 'send') {
      nextStatus = 'submitted_to_consultant';
      title = 'ارسال برای مشاور';
      message =
          'پس از ارسال، این دوره برای بررسی نهایی در اختیار مشاور قرار می‌گیرد.';
    } else {
      nextStatus = 'open';
      title = 'بازگشت برای اصلاح';
      message = 'دوره به وضعیت باز برمی‌گردد. لطفاً دلیل بازگشت را ثبت کنید.';
    }
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String?>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 12),
                  Form(
                    key: formKey,
                    child: TextFormField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText:
                            action == 'return'
                                ? 'دلیل بازگشت (الزامی)'
                                : 'یادداشت (اختیاری)',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (action == 'return' &&
                            (value == null || value.trim().isEmpty)) {
                          return 'برای بازگشت، دلیل را ثبت کنید.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext, noteController.text.trim());
                  }
                },
                child: Text(action == 'send' ? 'ارسال' : 'بازگرداندن'),
              ),
            ],
          ),
    );
    // The dialog route may still be animating out here; do not dispose its controller yet.
    if (result == null) return;

    try {
      final userId = _db.auth.currentUser!.id;
      await _db
          .from('expense_fiscal_periods')
          .update({
            'status': nextStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', period['id'])
          .eq('company_id', _companyId!);
      await _db.from('expense_fiscal_period_workflow').insert({
        'period_id': period['id'],
        'company_id': _companyId,
        'from_status': status,
        'to_status': nextStatus,
        'acted_by': userId,
        'note': result.isEmpty ? null : result,
      });
      await _load();
      if (mounted)
        _snack(
          action == 'send'
              ? 'دوره برای مشاور ارسال شد.'
              : 'دوره برای اصلاح بازگردانده شد.',
        );
    } catch (e) {
      if (mounted) _snack(_friendlyError(e), error: true);
    }
  }

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
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
                  _yearPanel(),
                  const SizedBox(height: 18),
                  _workflowGuide(),
                  const SizedBox(height: 20),
                  _filterBar(),
                  const SizedBox(height: 12),
                  if (_visiblePeriods.isEmpty)
                    _emptyState()
                  else
                    ..._visiblePeriods.map(_periodCard),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'هزینه  /  دوره‌های هزینه',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'مدیریت دوره‌های هزینه',
                    style: TextStyle(
                      color: _text,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'دوره‌های مالی را بررسی کنید و موارد آماده ارسال برای مشاور را مدیریت کنید.',
                    style: TextStyle(color: _muted, fontSize: 13, height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (!compact)
              OutlinedButton.icon(
                onPressed: _loading ? null : _createYear,
                icon: const Icon(Icons.add_rounded),
                label: const Text('سال مالی جدید'),
              )
            else
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        );
      },
    );
  }

  Widget _summary() {
    final items = [
      _Metric(
        'تعداد دوره‌ها',
        '${_periods.length}',
        Icons.calendar_month_rounded,
      ),
      _Metric(
        'مجموع شناسایی هزینه',
        '${_money.format(_total)} ریال',
        Icons.account_balance_wallet_outlined,
      ),
      _Metric(
        'در انتظار بررسی مدیرعامل',
        '${_countStatus('submitted_to_company_admin')}',
        Icons.pending_actions_rounded,
      ),
      _Metric(
        'ارسال‌شده برای مشاور',
        '${_countStatus('submitted_to_consultant')}',
        Icons.outgoing_mail,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth > 1100
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
          childAspectRatio:
              columns == 1
                  ? 4.0
                  : columns == 2
                  ? 2.5
                  : 2.0,
          children:
              items
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.label,
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  item.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _text,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }

  Widget _yearPanel() {
    final year = _selectedYear;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'سال مالی',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String>(
                  value: _selectedYearId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  hint: const Text('انتخاب سال مالی'),
                  items:
                      _years
                          .map(
                            (row) => DropdownMenuItem<String>(
                              value: row['id'].toString(),
                              child: Text(
                                '${row['title'] ?? 'سال مالی ${row['year']}'}${row['status'] == 'closed' ? ' (بسته)' : ''}',
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() => _selectedYearId = value);
                    _load();
                  },
                ),
              ),
              OutlinedButton.icon(
                onPressed: _createYear,
                icon: const Icon(Icons.add),
                label: const Text('سال جدید'),
              ),
              if (year != null)
                OutlinedButton.icon(
                  onPressed: () => _changeYearStatus(year),
                  icon: Icon(
                    year['status'] == 'closed'
                        ? Icons.lock_open
                        : Icons.lock_outline,
                  ),
                  label: Text(
                    year['status'] == 'closed'
                        ? 'بازگشایی سال'
                        : 'بستن سال مالی',
                  ),
                ),
              if (year != null && year['status'] != 'closed')
                FilledButton.icon(
                  onPressed: _createMonths,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('ایجاد دوره‌های ۱۲ ماه'),
                ),
            ],
          ),
          if (year != null) ...[
            const SizedBox(height: 12),
            Text(
              '${year['title'] ?? 'سال مالی ${year['year']}'} • وضعیت: ${year['status'] == 'closed' ? 'بسته' : 'باز'}',
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _workflowGuide() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'گردش کار دوره هزینه',
            style: TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'حسابدار اطلاعات دوره را ثبت و برای مدیرعامل ارسال می‌کند. مدیرعامل می‌تواند دوره را برای اصلاح برگرداند یا برای بررسی نهایی به مشاور ارسال کند. پس از تأیید مشاور، دوره قابل بستن است.',
            style: TextStyle(color: _muted, height: 1.8, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    const filters = [
      ('all', 'همه'),
      ('open', 'باز'),
      ('submitted_to_company_admin', 'در انتظار من'),
      ('submitted_to_consultant', 'نزد مشاور'),
      ('approved', 'تأییدشده'),
      ('closed', 'بسته'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          filters.map((item) {
            final selected = _statusFilter == item.$1;
            return ChoiceChip(
              label: Text(item.$2),
              selected: selected,
              onSelected: (_) => setState(() => _statusFilter = item.$1),
              selectedColor: const Color(0xFFDDF1E5),
              side: BorderSide(color: selected ? _green : _border),
              labelStyle: TextStyle(
                color: selected ? _green : _text,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            );
          }).toList(),
    );
  }

  Widget _periodCard(Map<String, dynamic> period) {
    final month = (period['month'] as num?)?.toInt() ?? 1;
    final status = period['status']?.toString();
    final id = period['id'].toString();
    final color = _statusColor(status);
    final total = _totalsByPeriod[id] ?? 0;
    final canReview = status == 'submitted_to_company_admin';
    return InkWell(
      onTap: () => context.go('/company-admin/expense/periods/${period['id']}'),
      borderRadius: BorderRadius.circular(17),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F4EB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: _green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_months[(month - 1).clamp(0, 11)]} ${period['year']}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          Text(
                            'شناسایی‌ها: ${_recognitionCounts[id] ?? 0}',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                          Text(
                            'مبلغ: ${_money.format(total)} ریال',
                            style: const TextStyle(
                              color: _text,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (canReview) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (canReview)
                    FilledButton.icon(
                      onPressed: () => _actOnPeriod(period, 'send'),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('ارسال برای مشاور'),
                    ),
                  if (canReview)
                    OutlinedButton.icon(
                      onPressed: () => _actOnPeriod(period, 'return'),
                      icon: const Icon(Icons.keyboard_return_rounded),
                      label: const Text('بازگشت برای اصلاح'),
                    ),
                  TextButton.icon(
                    onPressed:
                        () => context.go('/company-admin/expense/recognitions'),
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('مشاهده شناسایی هزینه‌ها'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    final year = _selectedYear;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.calendar_month_outlined, size: 48, color: _green),
          const SizedBox(height: 12),
          Text(
            year == null
                ? 'هنوز سال مالی هزینه‌ای ثبت نشده است.'
                : 'برای این سال مالی دوره‌ای ثبت نشده است.',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'سال مالی ایجاد کنید و سپس دوره‌های ماهانه را بسازید.',
            style: TextStyle(color: _muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _createYear,
                icon: const Icon(Icons.add),
                label: const Text('ایجاد سال مالی'),
              ),
              if (year != null && year['status'] != 'closed')
                FilledButton.icon(
                  onPressed: _createMonths,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('ایجاد ۱۲ دوره'),
                ),
            ],
          ),
        ],
      ),
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
        const Text(
          'بارگذاری دوره‌های هزینه ناموفق بود',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
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
