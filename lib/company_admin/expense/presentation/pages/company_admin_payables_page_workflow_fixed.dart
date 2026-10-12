import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

/// پنل مدیرعامل برای بررسی حساب‌های پرداختنی بر اساس سال و دوره مالی.
/// گردش کار دوره: open -> submitted_to_company_admin ->
/// submitted_to_consultant یا بازگشت به open.
class CompanyAdminPayablesPage extends StatefulWidget {
  const CompanyAdminPayablesPage({super.key});

  @override
  State<CompanyAdminPayablesPage> createState() => _CompanyAdminPayablesPageState();
}

class _CompanyAdminPayablesPageState extends State<CompanyAdminPayablesPage> {
  final SupabaseClient _db = Supabase.instance.client;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _companyId;
  String? _selectedYearId;
  List<Map<String, dynamic>> _years = [];
  List<Map<String, dynamic>> _periods = [];
  List<Map<String, dynamic>> _payables = [];

  static const _months = <String>[
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? yearId}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
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
        throw Exception('شرکت فعالی برای حساب مدیرعامل پیدا نشد.');
      }
      final companyId = membership['company_id'].toString();

      final yearRows = await _db
          .from('payable_fiscal_years')
          .select('id, company_id, year, title, status')
          .eq('company_id', companyId)
          .order('year', ascending: false);
      final years = List<Map<String, dynamic>>.from(yearRows);
      String? chosen = yearId ?? _selectedYearId;
      if (chosen == null || !years.any((y) => y['id'].toString() == chosen)) {
        chosen = years.isEmpty ? null : years.first['id'].toString();
      }

      List<Map<String, dynamic>> periods = [];
      List<Map<String, dynamic>> payables = [];
      if (chosen != null) {
        final periodRows = await _db
            .from('payable_fiscal_periods')
            .select('id, fiscal_year_id, company_id, year, month, title, status, created_at')
            .eq('company_id', companyId)
            .eq('fiscal_year_id', chosen)
            .order('month', ascending: true);
        periods = List<Map<String, dynamic>>.from(periodRows);
        if (periods.isNotEmpty) {
          final ids = periods.map((p) => p['id'].toString()).toList();
          final payableRows = await _db
              .from('payables')
              .select('id, fiscal_period_id, creditor_name, title, amount, due_date, reference_number, description, status, created_at')
              .eq('company_id', companyId)
              .inFilter('fiscal_period_id', ids)
              .order('due_date', ascending: true);
          payables = List<Map<String, dynamic>>.from(payableRows);
        }
      }

      if (!mounted) return;
      setState(() {
        _companyId = companyId;
        _years = years;
        _selectedYearId = chosen;
        _periods = periods;
        _payables = payables;
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

  String _yearTitle(Map<String, dynamic> y) {
    final title = y['title']?.toString().trim();
    if (title != null && title.isNotEmpty) return title;
    return 'سال مالی ${y['year'] ?? ''}';
  }

  String _periodTitle(Map<String, dynamic> p) {
    final title = p['title']?.toString().trim();
    if (title != null && title.isNotEmpty) return title;
    final month = (p['month'] as num?)?.toInt() ?? 0;
    final year = p['year']?.toString() ?? '';
    final monthName = month >= 1 && month <= 12 ? _months[month - 1] : 'ماه $month';
    return '$monthName $year';
  }

  String _money(dynamic value) {
    final n = (value as num?)?.round() ?? 0;
    return n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }

  String _status(String? status) {
    switch (status) {
      case 'open': return 'در حال تکمیل حسابدار';
      case 'submitted_to_company_admin': return 'در انتظار تأیید مدیرعامل';
      case 'submitted_to_consultant': return 'ارسال‌شده به مشاور';
      case 'approved': return 'تأیید نهایی';
      case 'closed': return 'بسته‌شده';
      default: return status ?? 'نامشخص';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'submitted_to_company_admin': return const Color(0xFFD97706);
      case 'submitted_to_consultant':
      case 'approved': return const Color(0xFF15803D);
      case 'closed': return const Color(0xFF64748B);
      default: return const Color(0xFF2563EB);
    }
  }

  List<Map<String, dynamic>> _periodPayables(String periodId) =>
      _payables.where((p) => p['fiscal_period_id']?.toString() == periodId).toList();

  double _periodTotal(String periodId) => _periodPayables(periodId).fold<double>(
      0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0));

  Future<void> _actOnPeriod(Map<String, dynamic> period, {required bool approve}) async {
    final status = period['status']?.toString();
    if (status != 'submitted_to_company_admin') {
      _message('فقط دوره‌های ارسال‌شده از طرف حسابدار قابل بررسی هستند.');
      return;
    }
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'تأیید و ارسال به مشاور' : 'بازگشت به حسابدار'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(approve
              ? 'با تأیید شما، این دوره برای بررسی مشاور ارسال می‌شود.'
              : 'دوره برای اصلاح به حسابدار برمی‌گردد. دلیل بازگشت را بنویسید.'),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'یادداشت / توضیحات',
              border: OutlineInputBorder(),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(ctx, noteController.text.trim()),
              child: Text(approve ? 'تأیید و ارسال' : 'بازگشت به حسابدار')),
        ],
      ),
    );
    noteController.dispose();
    if (note == null) return;
    if (!approve && note.trim().isEmpty) {
      _message('برای بازگرداندن دوره، دلیل را وارد کنید.');
      return;
    }

    final user = _db.auth.currentUser;
    final companyId = _companyId;
    if (user == null || companyId == null) {
      _message('اطلاعات کاربر یا شرکت در دسترس نیست.');
      return;
    }
    final periodId = period['id'].toString();
    final nextStatus = approve ? 'submitted_to_consultant' : 'open';
    setState(() => _busy = true);
    try {
      await _db.from('payable_fiscal_periods').update({
        'status': nextStatus,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', periodId).eq('company_id', companyId)
          .eq('status', 'submitted_to_company_admin');

      await _db.from('payable_fiscal_period_workflow').insert({
        'period_id': periodId,
        'company_id': companyId,
        'from_status': 'submitted_to_company_admin',
        'to_status': nextStatus,
        'acted_by': user.id,
        'note': note.isEmpty ? (approve ? 'تأیید مدیرعامل و ارسال به مشاور' : null) : note,
      });
      if (!mounted) return;
      _message(approve ? 'دوره برای مشاور ارسال شد.' : 'دوره برای اصلاح به حسابدار برگشت.');
      await _load(yearId: _selectedYearId);
    } catch (e) {
      if (mounted) _message('ثبت تصمیم انجام نشد: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _showPeriodDetails(Map<String, dynamic> period) async {
    final items = _periodPayables(period['id'].toString());
    final canReview = period['status'] == 'submitted_to_company_admin';
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(_periodTitle(period)),
          content: SizedBox(
            width: 680,
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _statusChip(period['status']?.toString()),
                const SizedBox(height: 10),
                Text('تعداد بدهی‌ها: ${items.length}'),
                Text('مجموع مبالغ: ${_money(_periodTotal(period['id'].toString()))} ریال'),
                const Divider(height: 24),
                if (items.isEmpty)
                  const Padding(padding: EdgeInsets.all(12), child: Text('برای این دوره بدهی ثبت نشده است.'))
                else
                  ...items.map((p) => Card(
                    child: ListTile(
                      title: Text(p['title']?.toString() ?? 'بدون عنوان'),
                      subtitle: Text('${p['creditor_name'] ?? 'طلبکار نامشخص'}\nمبلغ: ${_money(p['amount'])} ریال\nسررسید: ${p['due_date'] ?? 'تعیین نشده'}'),
                      isThreeLine: true,
                      trailing: Text(_payableStatus(p['status']?.toString())),
                    ),
                  )),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن')),
            if (canReview) ...[
              TextButton.icon(
                onPressed: _busy ? null : () { Navigator.pop(ctx); _actOnPeriod(period, approve: false); },
                icon: const Icon(Icons.undo_rounded), label: const Text('بازگشت به حسابدار'),
              ),
              FilledButton.icon(
                onPressed: _busy ? null : () { Navigator.pop(ctx); _actOnPeriod(period, approve: true); },
                icon: const Icon(Icons.send_rounded), label: const Text('تأیید و ارسال به مشاور'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _payableStatus(String? status) {
    switch (status) {
      case 'pending': return 'پرداخت‌نشده';
      case 'paid': return 'پرداخت‌شده';
      case 'cancelled': return 'لغوشده';
      default: return status ?? 'نامشخص';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingReview = _periods.where((p) => p['status'] == 'submitted_to_company_admin').length;
    final total = _payables.fold<double>(0, (s, p) => s + ((p['amount'] as num?)?.toDouble() ?? 0));
    final unpaid = _payables.where((p) => p['status'] == 'pending').length;

    return CompanyAdminScaffold(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          color: const Color(0xFFF6F8F7),
          child: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 42),
                          const SizedBox(height: 12), Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12), FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('تلاش مجدد')),
                        ]),
                      ))
                    : RefreshIndicator(
                        onRefresh: () => _load(yearId: _selectedYearId),
                        child: ListView(padding: const EdgeInsets.all(24), children: [
                          Row(children: [
                            const Expanded(child: Text('حساب‌های پرداختنی', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF17221D)))),
                            IconButton(onPressed: () => _load(yearId: _selectedYearId), icon: const Icon(Icons.refresh_rounded), tooltip: 'بارگذاری مجدد'),
                          ]),
                          const SizedBox(height: 6),
                          const Text('انتخاب سال مالی، مشاهده جزئیات دوره و تصمیم‌گیری مدیرعامل', style: TextStyle(color: Color(0xFF718078))),
                          const SizedBox(height: 18),
                          const Text('سال مالی', style: TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedYearId,
                            isExpanded: true,
                            decoration: const InputDecoration(border: OutlineInputBorder(), filled: true, fillColor: Colors.white, hintText: 'انتخاب سال مالی'),
                            items: _years.map((y) => DropdownMenuItem<String>(value: y['id'].toString(), child: Text(_yearTitle(y)))).toList(),
                            onChanged: _busy ? null : (value) { if (value != null) _load(yearId: value); },
                          ),
                          if (_years.isEmpty) ...[
                            const SizedBox(height: 10),
                            const Text('برای این شرکت سال مالی پرداختنی ثبت نشده است.', style: TextStyle(color: Colors.deepOrange)),
                          ],
                          const SizedBox(height: 18),
                          LayoutBuilder(builder: (context, c) {
                            final width = c.maxWidth < 600 ? c.maxWidth : (c.maxWidth - 24) / 3;
                            return Wrap(spacing: 12, runSpacing: 12, children: [
                              SizedBox(width: width, child: _metric('مجموع مبالغ دوره‌ها', '${_money(total)} ریال', Icons.account_balance_wallet_outlined, const Color(0xFF2563EB))),
                              SizedBox(width: width, child: _metric('بدهی‌های پرداخت‌نشده', '$unpaid مورد', Icons.pending_actions_rounded, const Color(0xFFD97706))),
                              SizedBox(width: width, child: _metric('در انتظار تصمیم مدیرعامل', '$pendingReview دوره', Icons.fact_check_outlined, const Color(0xFF15803D))),
                            ]);
                          }),
                          const SizedBox(height: 24),
                          _sectionHeader('دوره‌های سال مالی انتخاب‌شده', '${_periods.length} دوره'),
                          const SizedBox(height: 10),
                          if (_periods.isEmpty)
                            _empty(_selectedYearId == null ? 'ابتدا برای شرکت سال مالی ایجاد کنید.' : 'در این سال مالی دوره‌ای ثبت نشده است.')
                          else
                            ..._periods.map((p) {
                              final id = p['id'].toString();
                              final items = _periodPayables(id);
                              final review = p['status'] == 'submitted_to_company_admin';
                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 9),
                                color: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: review ? const Color(0xFFF5C16C) : const Color(0xFFE2E8E5))),
                                child: ListTile(
                                  onTap: () => _showPeriodDetails(p),
                                  leading: CircleAvatar(backgroundColor: review ? const Color(0xFFFFF3D8) : const Color(0xFFEAF7F0), child: Icon(review ? Icons.rate_review_outlined : Icons.calendar_month_outlined, color: review ? const Color(0xFFD97706) : const Color(0xFF167A4A))),
                                  title: Text(_periodTitle(p), style: const TextStyle(fontWeight: FontWeight.w800)),
                                  subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text('${items.length} بدهی • ${_money(_periodTotal(id))} ریال\n${_status(p['status']?.toString())}')),
                                  isThreeLine: true,
                                  trailing: const Icon(Icons.chevron_left_rounded),
                                ),
                              );
                            }),
                          const SizedBox(height: 24),
                          const Text('برای دیدن اقلام و تأیید یا بازگرداندن دوره، روی همان دوره کلیک کنید.', style: TextStyle(color: Color(0xFF718078))),
                        ]),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _metric(String title, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8E5))),
    child: Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF718078))), const SizedBox(height: 5), Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF17221D)))])),
    ]),
  );

  Widget _sectionHeader(String title, String trailing) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF17221D)))), Text(trailing, style: const TextStyle(fontSize: 12, color: Color(0xFF718078)))]);

  Widget _statusChip(String? status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(color: _statusColor(status).withOpacity(.1), borderRadius: BorderRadius.circular(30)),
    child: Text(_status(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status))),
  );

  Widget _empty(String text) => Container(width: double.infinity, padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8E5))), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF718078))));
}
