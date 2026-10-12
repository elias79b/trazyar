import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

/// مدیرعامل: نمای سال‌ها و ماه‌های مستقل مطالبات
class CompanyAdminIncomeReceivablesPage extends StatefulWidget {
  const CompanyAdminIncomeReceivablesPage({super.key});

  @override
  State<CompanyAdminIncomeReceivablesPage> createState() =>
      _CompanyAdminIncomeReceivablesPageState();
}

class _CompanyAdminIncomeReceivablesPageState
    extends State<CompanyAdminIncomeReceivablesPage> {
  final SupabaseClient _db = Supabase.instance.client;
  bool _loading = true;
  String? _error;
  String? _companyId;
  List<Map<String, dynamic>> _periods = [];

  static const _months = <int, String>{
    1: 'فروردین',
    2: 'اردیبهشت',
    3: 'خرداد',
    4: 'تیر',
    5: 'مرداد',
    6: 'شهریور',
    7: 'مهر',
    8: 'آبان',
    9: 'آذر',
    10: 'دی',
    11: 'بهمن',
    12: 'اسفند',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final user = _db.auth.currentUser;
      if (user == null) throw Exception('ابتدا وارد حساب کاربری شوید.');

      final membership = await _db
          .from('company_users')
          .select('company_id')
          .eq('user_id', user.id)
          .eq('role', 'company_admin')
          .eq('is_active', true)
          .maybeSingle();

      if (membership == null || membership['company_id'] == null) {
        throw Exception('شرکت فعالی برای حساب مدیرعامل پیدا نشد.');
      }
      final companyId = membership['company_id'].toString();

      final rows = await _db
          .from('income_receivable_fiscal_periods')
          .select('id, fiscal_year_id, company_id, year, month, title, status')
          .eq('company_id', companyId)
          .order('year', ascending: false)
          .order('month', ascending: true);

      if (!mounted) return;
      setState(() {
        _companyId = companyId;
        _periods = List<Map<String, dynamic>>.from(rows as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = _friendly(e); _loading = false; });
    }
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('permission denied') || s.contains('row-level security')) {
      return 'دسترسی RLS برای مشاهده دوره‌های مطالبات مدیرعامل کافی نیست.';
    }
    return s.replaceFirst('Exception: ', '');
  }

  String _status(String? value) {
    switch (value) {
      case 'open': return 'باز';
      case 'submitted_to_company_admin': return 'ارسال‌شده برای مدیرعامل';
      case 'submitted_to_consultant': return 'ارسال‌شده برای مشاور';
      case 'approved': return 'تأییدشده';
      case 'closed': return 'بسته';
      default: return value ?? 'نامشخص';
    }
  }

  Color _statusColor(String? value) {
    switch (value) {
      case 'submitted_to_company_admin': return const Color(0xFFED9B24);
      case 'submitted_to_consultant': return const Color(0xFF2874A6);
      case 'approved': return const Color(0xFF188568);
      case 'closed': return Colors.blueGrey;
      default: return const Color(0xFF63766D);
    }
  }

  String _monthTitle(Map<String, dynamic> row) {
    final title = (row['title'] ?? '').toString().trim();
    if (title.isNotEmpty) return title;
    final month = int.tryParse('${row['month']}') ?? 0;
    return _months[month] ?? 'ماه $month';
  }

  Future<void> _openPeriod(Map<String, dynamic> period) async {
    if (_companyId == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompanyAdminReceivablePeriodDetailPage(
          companyId: _companyId!,
          period: period,
          router: GoRouter.of(context),
        ),
      ),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return CompanyAdminScaffold(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8F6),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _periods.isEmpty
                          ? ListView(children: const [
                              SizedBox(height: 140),
                              Icon(Icons.calendar_month_outlined, size: 60, color: Color(0xFF207653)),
                              SizedBox(height: 16),
                              Center(child: Text('هنوز دوره‌ای برای مطالبات ایجاد نشده است.', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
                              SizedBox(height: 8),
                              Center(child: Text('ابتدا دوره‌های مالی مستقل مطالبات را ایجاد کنید.')),
                            ])
                          : _buildPeriodList(),
                    ),
        ),
      ),
    );
  }

  Widget _buildPeriodList() {
    final grouped = <int, List<Map<String, dynamic>>>{};
    for (final p in _periods) {
      final year = int.tryParse('${p['year']}') ?? 0;
      grouped.putIfAbsent(year, () => []).add(p);
    }
    final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مطالبات درآمد', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF17231D))),
                  SizedBox(height: 6),
                  Text('بررسی دوره‌های مطالبات و پیگیری گردش کار', style: TextStyle(color: Color(0xFF66736C))),
                ],
              ),
            ),
            IconButton(tooltip: 'بارگذاری مجدد', onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(label: 'تعداد دوره‌ها', value: '${_periods.length}', icon: Icons.calendar_month_outlined),
            _MetricCard(label: 'در انتظار بررسی', value: '${_periods.where((p) => p['status'] == 'submitted_to_company_admin').length}', icon: Icons.pending_actions_outlined),
            _MetricCard(label: 'ارسال‌شده برای مشاور', value: '${_periods.where((p) => p['status'] == 'submitted_to_consultant').length}', icon: Icons.send_outlined),
          ],
        ),
        const SizedBox(height: 24),
        for (final year in years) ...[
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4F0),
              border: Border.all(color: const Color(0xFFD5E0D9)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('سال مالی مطالبات $year', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 1000
                        ? (constraints.maxWidth - 48) / 5
                        : constraints.maxWidth >= 700
                            ? (constraints.maxWidth - 24) / 3
                            : constraints.maxWidth >= 420
                                ? (constraints.maxWidth - 12) / 2
                                : constraints.maxWidth;
                    final months = grouped[year]!..sort((a, b) => (int.tryParse('${a['month']}') ?? 0).compareTo(int.tryParse('${b['month']}') ?? 0));
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: months.map((p) {
                        final status = p['status']?.toString();
                        final color = _statusColor(status);
                        return SizedBox(
                          width: width,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openPeriod(p),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.45),
                                border: Border.all(color: const Color(0xFFC8D6CE)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.calendar_month_outlined, color: Color(0xFF207653)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(_monthTitle(p), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                  ]),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(9)),
                                    child: Text(_status(status), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                                  ),
                                  const SizedBox(height: 8),
                                  const Align(alignment: Alignment.centerLeft, child: Icon(Icons.chevron_left, color: Color(0xFF207653))),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// مدیرعامل: جزئیات ماه، بررسی مطالبات و اقدام روی گردش کار دوره

class _CompanyAdminIncomeSidebar extends StatelessWidget {
  final GoRouter router;

  const _CompanyAdminIncomeSidebar({required this.router});

  static const Color _green = Color(0xFF207653);
  static const Color _background = Color(0xFFF3F8F5);

  void _go(BuildContext context, String path) {
    // Navigate through the root GoRouter, not the Navigator-pushed detail context.
    Navigator.of(context).pop();
    router.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 900) return const SizedBox.shrink();

    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: _background,
        border: Border(left: BorderSide(color: Color(0xFFDCE7E0))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEFE5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      color: _green, size: 27),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ترازیار',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 3),
                      Text('پنل مدیرعامل',
                          style: TextStyle(fontSize: 12, color: Color(0xFF7B8B82))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFDCE7E0)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('اصلی',
                      style: TextStyle(fontSize: 12, color: Color(0xFF829087))),
                ),
                _item(context, Icons.dashboard_outlined, 'داشبورد مدیرعامل',
                    '/company-admin'),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 22, 12, 8),
                  child: Text('عملیات مالی',
                      style: TextStyle(fontSize: 12, color: Color(0xFF829087))),
                ),
                _item(context, Icons.account_balance_outlined, 'نقد و بانک',
                    '/company-admin/cash-bank'),
                _item(context, Icons.groups_outlined, 'حقوق و دستمزد',
                    '/company-admin/payroll'),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3ED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _item(context, Icons.trending_up, 'درآمد',
                          '/company-admin/income', active: true),
                      _item(context, Icons.dashboard_customize_outlined,
                          'نمای کلی درآمد', '/company-admin/income'),
                      _item(context, Icons.calendar_month_outlined,
                          'دوره‌های مالی', '/company-admin/income/periods'),
                      _item(context, Icons.category_outlined, 'دسته‌بندی‌ها',
                          '/company-admin/income/categories'),
                      _item(context, Icons.fact_check_outlined, 'شناسایی درآمد',
                          '/company-admin/income/recognitions'),
                      _item(context, Icons.receipt_long_outlined, 'مطالبات',
                          '/company-admin/income/receivables', active: true),
                      _item(context, Icons.bar_chart_outlined, 'گزارش درآمد',
                          '/company-admin/income/reports'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _item(context, Icons.show_chart, 'هزینه',
                    '/company-admin/expenses'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFDCE7E0)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('خروج از حساب',
                style: TextStyle(color: Colors.red, fontSize: 13)),
            onTap: () => router.go('/login'),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String path, {
    bool active = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: active ? const Color(0xFFD8EBE1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _go(context, path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20,
                    color: active ? _green : const Color(0xFF65756C)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? _green : const Color(0xFF34443B),
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CompanyAdminReceivablePeriodDetailPage extends StatefulWidget {
  final String companyId;
  final Map<String, dynamic> period;
  final GoRouter router;

  const CompanyAdminReceivablePeriodDetailPage({
    super.key,
    required this.companyId,
    required this.period,
    required this.router,
  });

  @override
  State<CompanyAdminReceivablePeriodDetailPage> createState() =>
      _CompanyAdminReceivablePeriodDetailPageState();
}

class _CompanyAdminReceivablePeriodDetailPageState
    extends State<CompanyAdminReceivablePeriodDetailPage> {
  final SupabaseClient _db = Supabase.instance.client;
  bool _loading = true;
  bool _acting = false;
  String? _error;
  List<Map<String, dynamic>> _receivables = [];
  List<Map<String, dynamic>> _workflow = [];

  static const _months = <int, String>{
    1: 'فروردین', 2: 'اردیبهشت', 3: 'خرداد', 4: 'تیر',
    5: 'مرداد', 6: 'شهریور', 7: 'مهر', 8: 'آبان',
    9: 'آذر', 10: 'دی', 11: 'بهمن', 12: 'اسفند',
  };

  String get _periodId => widget.period['id'].toString();
  String get _periodStatus => (widget.period['status'] ?? 'open').toString();
  int get _year => int.tryParse('${widget.period['year']}') ?? 0;
  int get _month => int.tryParse('${widget.period['month']}') ?? 0;
  String get _periodTitle {
    final title = (widget.period['title'] ?? '').toString().trim();
    return 'سال مالی مطالبات $_year — ${title.isNotEmpty ? title : (_months[_month] ?? 'ماه $_month')}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _db.from('income_receivables')
            .select('id, company_id, fiscal_period_id, title, amount, received_documents_amount, description, created_by, created_at, updated_at, status')
            .eq('company_id', widget.companyId)
            .eq('fiscal_period_id', _periodId)
            .order('created_at', ascending: false),
        _db.from('income_receivable_period_workflow')
            .select('id, period_id, company_id, from_status, to_status, acted_by, note, created_at')
            .eq('company_id', widget.companyId)
            .eq('period_id', _periodId)
            .order('created_at', ascending: false),
      ]);
      if (!mounted) return;
      setState(() {
        _receivables = List<Map<String, dynamic>>.from(results[0] as List);
        _workflow = List<Map<String, dynamic>>.from(results[1] as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = _friendly(e); _loading = false; });
    }
  }

  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('permission denied') || s.contains('row-level security')) {
      return 'دسترسی RLS برای مشاهده مطالبات یا گردش کار این دوره کافی نیست.';
    }
    return s.replaceFirst('Exception: ', '');
  }

  String _statusLabel(String? value) {
    switch (value) {
      case 'open': return 'باز';
      case 'submitted_to_company_admin': return 'ارسال‌شده برای مدیرعامل';
      case 'submitted_to_consultant': return 'ارسال‌شده برای مشاور';
      case 'approved': return 'تأییدشده';
      case 'closed': return 'بسته';
      default: return value ?? 'نامشخص';
    }
  }

  Color _statusColor(String? value) {
    switch (value) {
      case 'submitted_to_company_admin': return const Color(0xFFED9B24);
      case 'submitted_to_consultant': return const Color(0xFF2874A6);
      case 'approved': return const Color(0xFF188568);
      case 'closed': return Colors.blueGrey;
      default: return const Color(0xFF63766D);
    }
  }

  num _sum(String key) => _receivables.fold<num>(
      0, (sum, r) => sum + (num.tryParse('${r[key] ?? 0}') ?? 0));

  String _money(dynamic value) =>
      NumberFormat('#,##0.##', 'en_US').format(num.tryParse('$value') ?? 0);

  Future<void> _takeAction({
    required String toStatus,
    required String actionTitle,
    required String successMessage,
    required bool requireNote,
  }) async {
    if (_acting) return;
    final user = _db.auth.currentUser;
    if (user == null) {
      _message('نشست کاربری معتبر نیست. دوباره وارد شوید.');
      return;
    }

    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(actionTitle),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 440,
            child: TextFormField(
              controller: noteController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: requireNote ? 'دلیل / توضیح (اجباری)' : 'توضیح (اختیاری)',
                border: const OutlineInputBorder(),
              ),
              validator: (v) => requireNote && (v ?? '').trim().isEmpty
                  ? 'لطفاً دلیل را وارد کنید.'
                  : null,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('انصراف')),
          FilledButton(onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(dialogContext, true);
            }
          }, child: Text(actionTitle)),
        ],
      ),
    );

    if (confirmed != true) {
      noteController.dispose();
      return;
    }

    if (!mounted) {
      noteController.dispose();
      return;
    }
    setState(() => _acting = true);
    try {
      final fromStatus = _periodStatus;
      await _db.from('income_receivable_fiscal_periods')
          .update({'status': toStatus, 'updated_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', _periodId)
          .eq('company_id', widget.companyId);

      await _db.from('income_receivable_period_workflow').insert({
        'period_id': _periodId,
        'company_id': widget.companyId,
        'from_status': fromStatus,
        'to_status': toStatus,
        'acted_by': user.id,
        'note': noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      });

      if (mounted) {
        _message(successMessage);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _message('ثبت گردش کار ناموفق بود: ${_friendly(e)}');
    } finally {
      noteController.dispose();
      if (mounted) setState(() => _acting = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    final status = _periodStatus;
    // This detail page is pushed with Navigator; use the passed root router for sidebar navigation.
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      body: SafeArea(
        child: Row(
          children: [
            _CompanyAdminIncomeSidebar(router: widget.router),
            Expanded(
              child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _load)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Row(children: [
                            IconButton(tooltip: 'بازگشت', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_forward)),
                            const SizedBox(width: 8),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('مطالبات', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              Text(_periodTitle, style: const TextStyle(color: Color(0xFF63736B))),
                            ])),
                            IconButton(tooltip: 'بارگذاری مجدد', onPressed: _load, icon: const Icon(Icons.refresh)),
                          ]),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFD5DED8)),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              Row(children: [
                                const Expanded(child: Text('وضعیت گردش کار دوره', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(color: _statusColor(status).withOpacity(.12), borderRadius: BorderRadius.circular(20)),
                                  child: Text(_statusLabel(status), style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600)),
                                ),
                              ]),
                              const SizedBox(height: 16),
                              if (status == 'submitted_to_company_admin') ...[
                                Wrap(spacing: 10, runSpacing: 10, children: [
                                  FilledButton.icon(
                                    onPressed: _acting ? null : () => _takeAction(
                                      toStatus: 'submitted_to_consultant',
                                      actionTitle: 'ارسال برای مشاور',
                                      successMessage: 'دوره مطالبات برای مشاور ارسال شد.',
                                      requireNote: false,
                                    ),
                                    icon: const Icon(Icons.send_outlined),
                                    label: const Text('تأیید و ارسال برای مشاور'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: _acting ? null : () => _takeAction(
                                      toStatus: 'open',
                                      actionTitle: 'بازگرداندن برای اصلاح',
                                      successMessage: 'دوره برای اصلاح به حسابدار بازگردانده شد.',
                                      requireNote: true,
                                    ),
                                    icon: const Icon(Icons.undo),
                                    label: const Text('بازگشت برای اصلاح'),
                                  ),
                                ]),
                                if (_acting) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
                              ] else if (status == 'open') ...[
                                const Text('این دوره هنوز از طرف حسابدار برای مدیرعامل ارسال نشده است.'),
                              ] else if (status == 'submitted_to_consultant') ...[
                                const Text('این دوره برای مشاور ارسال شده است و در انتظار بررسی نهایی مشاور است.'),
                              ] else if (status == 'approved') ...[
                                const Text('این دوره توسط مشاور تأیید شده است.'),
                              ] else if (status == 'closed') ...[
                                const Text('این دوره بسته شده است و در این صفحه فقط قابل مشاهده است.'),
                              ],
                            ]),
                          ),
                          const SizedBox(height: 16),
                          Wrap(spacing: 12, runSpacing: 12, children: [
                            _MetricCard(label: 'تعداد مطالبات', value: '${_receivables.length}', icon: Icons.receipt_long_outlined),
                            _MetricCard(label: 'کل مطالبات', value: '${_money(_sum('amount'))} ریال', icon: Icons.account_balance_wallet_outlined),
                            _MetricCard(label: 'اسناد دریافت‌شده', value: '${_money(_sum('received_documents_amount'))} ریال', icon: Icons.description_outlined),
                            _MetricCard(label: 'مانده مطالبات', value: '${_money(_sum('amount') - _sum('received_documents_amount'))} ریال', icon: Icons.pending_actions_outlined),
                          ]),
                          const SizedBox(height: 20),
                          _sectionCard(
                            title: 'فهرست مطالبات این دوره',
                            child: _receivables.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(28),
                                    child: Center(child: Text('هنوز مطالبه‌ای برای این ماه ثبت نشده است.')),
                                  )
                                : Column(
                                    children: _receivables.map((r) {
                                      final amount = num.tryParse('${r['amount'] ?? 0}') ?? 0;
                                      final docs = num.tryParse('${r['received_documents_amount'] ?? 0}') ?? 0;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE1E8E3)))),
                                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          const CircleAvatar(backgroundColor: Color(0xFFE5F3EB), child: Icon(Icons.receipt_long_outlined, color: Color(0xFF207653))),
                                          const SizedBox(width: 12),
                                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                            Text('${r['title'] ?? 'بدون عنوان'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                            if ((r['description'] ?? '').toString().trim().isNotEmpty) ...[
                                              const SizedBox(height: 5),
                                              Text('${r['description']}', style: const TextStyle(color: Color(0xFF65736B))),
                                            ],
                                            const SizedBox(height: 8),
                                            Wrap(spacing: 14, runSpacing: 6, children: [
                                              Text('مبلغ: ${_money(amount)} ریال'),
                                              Text('اسناد دریافت‌شده: ${_money(docs)} ریال'),
                                              Text('مانده: ${_money(amount - docs)} ریال'),
                                            ]),
                                          ])),
                                          const SizedBox(width: 8),
                                          Text(_statusLabel(r['status']?.toString()), style: TextStyle(color: _statusColor(r['status']?.toString()), fontSize: 12)),
                                        ]),
                                      );
                                    }).toList(),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          _sectionCard(
                            title: 'سوابق گردش کار',
                            child: _workflow.isEmpty
                                ? const Padding(padding: EdgeInsets.all(20), child: Text('برای این دوره هنوز سابقه گردش کار ثبت نشده است.'))
                                : Column(
                                    children: _workflow.map((w) {
                                      final date = DateTime.tryParse('${w['created_at'] ?? ''}');
                                      final dateText = date == null ? '' : DateFormat('yyyy/MM/dd  HH:mm').format(date.toLocal());
                                      final note = (w['note'] ?? '').toString().trim();
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const CircleAvatar(child: Icon(Icons.history)),
                                        title: Text('${_statusLabel(w['from_status']?.toString())} ← ${_statusLabel(w['to_status']?.toString())}'),
                                        subtitle: Text([if (dateText.isNotEmpty) dateText, if (note.isNotEmpty) note].join('\n')),
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ],
                      ),
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFD5DED8)), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFD5DED8)), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: const Color(0xFFDDF5E8), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF207653)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Color(0xFF66736D), fontSize: 12)),
            const SizedBox(height: 5),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ])),
        ]),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
        const SizedBox(height: 12),
        const Text('خطا در دریافت اطلاعات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('تلاش مجدد')),
      ]),
    ),
  );
}
