import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

class CompanyAdminExpensePeriodDetailsPage extends StatefulWidget {
  const CompanyAdminExpensePeriodDetailsPage({
    super.key,
    required this.periodId,
  });

  final String periodId;

  @override
  State<CompanyAdminExpensePeriodDetailsPage> createState() =>
      _CompanyAdminExpensePeriodDetailsPageState();
}

class _CompanyAdminExpensePeriodDetailsPageState
    extends State<CompanyAdminExpensePeriodDetailsPage> {
  final SupabaseClient _db = Supabase.instance.client;
  final NumberFormat _money = NumberFormat('#,##0', 'en_US');

  static const Color _green = Color(0xFF176B4D);
  static const Color _background = Color(0xFFF4F8F5);
  static const Color _border = Color(0xFFD9E4DD);
  static const Color _text = Color(0xFF202B25);
  static const Color _muted = Color(0xFF718078);

  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _companyId;
  Map<String, dynamic>? _period;
  List<Map<String, dynamic>> _recognitions = [];
  List<Map<String, dynamic>> _workflow = [];
  Map<String, String> _categoryNames = {};
  Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
        throw Exception('شرکت فعال برای این حساب مدیرعامل پیدا نشد.');
      }
      final companyId = membership['company_id'].toString();

      final period = await _db
          .from('expense_fiscal_periods')
          .select('id, fiscal_year_id, company_id, year, month, title, status, created_at, updated_at')
          .eq('id', widget.periodId)
          .eq('company_id', companyId)
          .maybeSingle();
      if (period == null) throw Exception('دوره پیدا نشد یا دسترسی به آن ندارید.');

      final recognitionResponse = await _db
          .from('expense_recognitions')
          .select('id, company_id, fiscal_period_id, category_id, amount, description, created_by, created_at, updated_at')
          .eq('company_id', companyId)
          .eq('fiscal_period_id', widget.periodId)
          .order('created_at', ascending: false);
      final recognitions = List<Map<String, dynamic>>.from(recognitionResponse);

      final categoryResponse = await _db
          .from('expense_categories')
          .select('id, name')
          .eq('company_id', companyId);
      final categoryNames = <String, String>{};
      for (final row in categoryResponse) {
        categoryNames[row['id'].toString()] = (row['name'] ?? 'بدون نام').toString();
      }

      final workflowResponse = await _db
          .from('expense_fiscal_period_workflow')
          .select('id, period_id, company_id, from_status, to_status, acted_by, note, created_at')
          .eq('company_id', companyId)
          .eq('period_id', widget.periodId)
          .order('created_at', ascending: false);
      final workflow = List<Map<String, dynamic>>.from(workflowResponse);

      final userIds = <String>{
        ...recognitions
            .map((row) => row['created_by']?.toString())
            .whereType<String>(),
        ...workflow
            .map((row) => row['acted_by']?.toString())
            .whereType<String>(),
      }.toList();
      final userNames = <String, String>{};
      if (userIds.isNotEmpty) {
        final usersResponse = await _db
            .from('users')
            .select('id, full_name')
            .inFilter('id', userIds);
        for (final row in usersResponse) {
          userNames[row['id'].toString()] =
              (row['full_name'] ?? 'کاربر').toString();
        }
      }

      if (!mounted) return;
      setState(() {
        _companyId = companyId;
        _period = Map<String, dynamic>.from(period);
        _recognitions = recognitions;
        _workflow = workflow;
        _categoryNames = categoryNames;
        _userNames = userNames;
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

  static const _months = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  String _statusLabel(String? status) {
    switch (status) {
      case 'open': return 'باز';
      case 'submitted_to_company_admin': return 'در انتظار بررسی مدیرعامل';
      case 'submitted_to_consultant': return 'ارسال‌شده برای مشاور';
      case 'approved': return 'تأیید نهایی';
      case 'closed': return 'بسته';
      default: return status ?? 'نامشخص';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'open': return const Color(0xFF2D8A62);
      case 'submitted_to_company_admin': return const Color(0xFFE09A26);
      case 'submitted_to_consultant': return const Color(0xFF287EB6);
      case 'approved': return const Color(0xFF16805D);
      case 'closed': return const Color(0xFF737C76);
      default: return _muted;
    }
  }

  double get _total => _recognitions.fold<double>(
      0, (sum, row) => sum + _number(row['amount']));

  double _number(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  Future<void> _act(String action) async {
    final period = _period;
    if (period == null || _companyId == null || _busy) return;
    final status = period['status']?.toString() ?? 'open';
    final isSend = action == 'send';
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final note = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isSend ? 'ارسال دوره برای مشاور' : 'بازگشت دوره برای اصلاح'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 420,
            child: TextFormField(
              controller: noteController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: isSend ? 'یادداشت (اختیاری)' : 'دلیل بازگشت (الزامی)',
                border: const OutlineInputBorder(),
              ),
              validator: (value) => !isSend && (value == null || value.trim().isEmpty)
                  ? 'دلیل بازگشت را وارد کنید.'
                  : null,
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
                Navigator.pop(dialogContext, noteController.text.trim());
              }
            },
            child: Text(isSend ? 'ارسال' : 'بازگرداندن'),
          ),
        ],
      ),
    );
    // The dialog route may still be animating out here; do not dispose its controller yet.
    if (note == null) return;

    setState(() => _busy = true);
    try {
      final userId = _db.auth.currentUser!.id;
      final nextStatus = isSend ? 'submitted_to_consultant' : 'open';
      await _db.from('expense_fiscal_periods').update({
        'status': nextStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.periodId).eq('company_id', _companyId!);

      await _db.from('expense_fiscal_period_workflow').insert({
        'period_id': widget.periodId,
        'company_id': _companyId,
        'from_status': status,
        'to_status': nextStatus,
        'acted_by': userId,
        'note': note.isEmpty ? null : note,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isSend ? 'دوره برای مشاور ارسال شد.' : 'دوره برای اصلاح بازگردانده شد.'),
      ));
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompanyAdminScaffold(
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _green))
              : _error != null
                  ? _errorView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: [
                          _header(),
                          const SizedBox(height: 18),
                          _periodSummary(),
                          const SizedBox(height: 18),
                          _recognitionSection(),
                          const SizedBox(height: 18),
                          _workflowSection(),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _header() {
    final period = _period!;
    final month = ((period['month'] as num?)?.toInt() ?? 1).clamp(1, 12);
    final status = period['status']?.toString();
    final color = _statusColor(status);
    final canReview = status == 'submitted_to_company_admin';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextButton.icon(
        onPressed: () => context.go('/company-admin/expense/periods'),
        icon: const Icon(Icons.arrow_back_rounded),
        label: const Text('بازگشت به دوره‌های هزینه'),
        style: TextButton.styleFrom(alignment: Alignment.centerRight),
      ),
      const SizedBox(height: 8),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('هزینه / دوره‌های هزینه / جزئیات', style: TextStyle(color: _muted, fontSize: 12)),
            const SizedBox(height: 6),
            Text('${_months[month - 1]} ${period['year']}',
                style: const TextStyle(color: _text, fontSize: 25, fontWeight: FontWeight.w800)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(22)),
            child: Text(_statusLabel(status), style: TextStyle(color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      if (canReview) ...[
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilledButton.icon(
            onPressed: _busy ? null : () => _act('send'),
            icon: const Icon(Icons.send_rounded),
            label: const Text('ارسال برای مشاور'),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _act('return'),
            icon: const Icon(Icons.keyboard_return_rounded),
            label: const Text('بازگشت برای اصلاح'),
          ),
          if (_busy) const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
        ]),
      ],
    ]);
  }

  Widget _periodSummary() {
    final period = _period!;
    final items = [
      ('سال مالی', '${period['year'] ?? '—'}', Icons.calendar_today_outlined),
      ('تعداد شناسایی‌ها', '${_recognitions.length}', Icons.receipt_long_outlined),
      ('مجموع مبلغ شناسایی', '${_money.format(_total)} ریال', Icons.account_balance_wallet_outlined),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 850 ? 3 : constraints.maxWidth > 550 ? 2 : 1;
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: columns == 1 ? 4.1 : 2.7,
        children: items.map((item) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _border), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFE4F4EB), borderRadius: BorderRadius.circular(13)),
              child: Icon(item.$3, color: _green)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(item.$1, style: const TextStyle(color: _muted, fontSize: 12)),
              const SizedBox(height: 7),
              Text(item.$2, style: const TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        )).toList(),
      );
    });
  }

  Widget _recognitionSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _border), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('شناسایی‌های هزینه این دوره', style: TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('جزئیات مبالغ ثبت‌شده در این دوره از Supabase دریافت شده است.', style: TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 14),
        if (_recognitions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('برای این دوره شناسایی هزینه‌ای ثبت نشده است.', style: TextStyle(color: _muted))),
          )
        else
          ..._recognitions.map((row) {
            final categoryId = row['category_id']?.toString();
            final category = categoryId == null ? 'بدون دسته‌بندی' : _categoryNames[categoryId] ?? 'دسته‌بندی حذف‌شده';
            final creatorId = row['created_by']?.toString();
            final creator = creatorId == null ? 'نامشخص' : _userNames[creatorId] ?? 'کاربر';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFAFCFA), border: Border.all(color: _border), borderRadius: BorderRadius.circular(13)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.receipt_long_outlined, color: _green),
                  const SizedBox(width: 10),
                  Expanded(child: Text(category, style: const TextStyle(color: _text, fontWeight: FontWeight.w700))),
                  Text('${_money.format(_number(row['amount']))} ریال', style: const TextStyle(color: _green, fontWeight: FontWeight.w800)),
                ]),
                if ((row['description'] ?? '').toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(row['description'].toString(), style: const TextStyle(color: _muted, height: 1.6)),
                ],
                const SizedBox(height: 8),
                Text('ثبت‌کننده: $creator', style: const TextStyle(color: _muted, fontSize: 12)),
              ]),
            );
          }),
        const Divider(height: 24),
        Row(children: [
          const Expanded(child: Text('جمع کل', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w800))),
          Text('${_money.format(_total)} ریال', style: const TextStyle(color: _green, fontSize: 18, fontWeight: FontWeight.w900)),
        ]),
      ]),
    );
  }

  Widget _workflowSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _border), borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('تاریخچه گردش کار', style: TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (_workflow.isEmpty)
          const Text('برای این دوره هنوز رویدادی در تاریخچه ثبت نشده است.', style: TextStyle(color: _muted))
        else
          ..._workflow.map((row) {
            final actorId = row['acted_by']?.toString();
            final actor = actorId == null ? 'نامشخص' : _userNames[actorId] ?? 'کاربر';
            final note = row['note']?.toString().trim() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 10, height: 10, margin: const EdgeInsets.only(top: 6), decoration: const BoxDecoration(color: _green, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_statusLabel(row['from_status']?.toString())} ← ${_statusLabel(row['to_status']?.toString())}',
                      style: const TextStyle(color: _text, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('اقدام‌کننده: $actor', style: const TextStyle(color: _muted, fontSize: 12)),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('یادداشت: $note', style: const TextStyle(color: _muted, height: 1.5)),
                  ],
                  if (row['created_at'] != null) ...[
                    const SizedBox(height: 4),
                    Text(row['created_at'].toString(), style: const TextStyle(color: _muted, fontSize: 11)),
                  ],
                ])),
              ]),
            );
          }),
      ]),
    );
  }

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 42),
        const SizedBox(height: 12),
        Text(_error ?? 'خطای نامشخص', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('تلاش دوباره')),
      ]),
    ),
  );
}
