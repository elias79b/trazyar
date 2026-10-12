import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

class CompanyAdminIncomeFiscalPeriodDetailPage extends ConsumerStatefulWidget {
  const CompanyAdminIncomeFiscalPeriodDetailPage({
    super.key,
    required this.periodId,
  });

  final String periodId;

  @override
  ConsumerState<CompanyAdminIncomeFiscalPeriodDetailPage> createState() =>
      _CompanyAdminIncomeFiscalPeriodDetailPageState();
}

class _CompanyAdminIncomeFiscalPeriodDetailPageState
    extends ConsumerState<CompanyAdminIncomeFiscalPeriodDetailPage> {
  static const _green = Color(0xFF168052);
  static const _background = Color(0xFFF5F8F5);
  static const _border = Color(0xFFE3EAE5);
  static const _text = Color(0xFF24312B);
  static const _muted = Color(0xFF718078);
  static const _orange = Color(0xFFB66A13);
  static const _blue = Color(0xFF2878D0);

  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  bool _acting = false;

  Map<String, dynamic>? _period;
  String? _role;
  List<Map<String, dynamic>> _recognitions = [];
  List<Map<String, dynamic>> _workflow = [];
  String? _error;

  String get _status => (_period?['status'] ?? 'open').toString();

  bool get _isAccountant => _role == 'accountant';

  bool get _isCompanyAdmin => _role == 'company_admin';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final period = _period;

    return CompanyAdminScaffold(
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: _text,
          elevation: 0,
          leading: IconButton(
            tooltip: 'بازگشت به دوره‌های درآمد',
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: _goBack,
          ),
          title: const Text(
            'جزئیات دوره درآمد',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'بارگذاری مجدد',
              onPressed: _loading || _acting ? null : _loadData,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body:
        _loading
            ? const Center(child: CircularProgressIndicator(color: _green))
            : _error != null
            ? _errorView()
            : period == null
            ? _emptyState(
          icon: Icons.event_busy_outlined,
          title: 'دوره پیدا نشد',
          message:
          'این دوره وجود ندارد یا دسترسی به اطلاعات آن ممکن نیست.',
        )
            : RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _periodHeader(period),
              const SizedBox(height: 16),
              _summaryCard(),
              const SizedBox(height: 16),
              _recognitionsCard(),
              const SizedBox(height: 16),
              _actionsCard(),
              const SizedBox(height: 16),
              _workflowCard(),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/company-admin/income/periods');
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        throw Exception('نشست کاربری معتبر نیست. دوباره وارد شوید.');
      }

      final period =
      await _supabase
          .from('income_fiscal_periods')
          .select(
        'id, fiscal_year_id, company_id, year, month, title, status, '
            'created_at, updated_at',
      )
          .eq('id', widget.periodId)
          .maybeSingle();

      if (period == null) {
        throw Exception('دوره پیدا نشد یا دسترسی به آن ندارید.');
      }

      final companyId = period['company_id'].toString();

      final membership =
      await _supabase
          .from('company_users')
          .select('role, is_active')
          .eq('company_id', companyId)
          .eq('user_id', user.id)
          .eq('is_active', true)
          .maybeSingle();

      if (membership == null) {
        throw Exception('عضویت فعال شما در این شرکت پیدا نشد.');
      }

      final role = membership['role']?.toString();

      final recognitionsResponse = await _supabase
          .from('income_recognitions')
          .select(
        'id, amount, description, created_at, category_id, '
            'income_categories(name)',
      )
          .eq('company_id', companyId)
          .eq('fiscal_period_id', widget.periodId)
          .order('created_at', ascending: false);

      final workflowResponse = await _supabase
          .from('income_fiscal_period_workflow')
          .select('id, from_status, to_status, acted_by, note, created_at')
          .eq('company_id', companyId)
          .eq('period_id', widget.periodId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _period = Map<String, dynamic>.from(period);
        _role = role;
        _recognitions = List<Map<String, dynamic>>.from(
          recognitionsResponse.map((item) => Map<String, dynamic>.from(item)),
        );
        _workflow = List<Map<String, dynamic>>.from(
          workflowResponse.map((item) => Map<String, dynamic>.from(item)),
        );
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

  Widget _periodHeader(Map<String, dynamic> period) {
    final title = (period['title'] ?? 'دوره درآمد').toString();
    final month = _toInt(period['month']);
    final year = _toInt(period['year']);
    final monthName = _monthName(month);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _statusColor(_status).withOpacity(.10),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: _statusColor(_status),
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '$monthName $year',
                      style: const TextStyle(fontSize: 14, color: _muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _statusColor(_status).withOpacity(.07),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _statusColor(_status).withOpacity(.20)),
            ),
            child: Row(
              children: [
                Icon(
                  _statusIcon(_status),
                  color: _statusColor(_status),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'وضعیت فعلی دوره',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _statusLabel(_status),
                        style: TextStyle(
                          color: _statusColor(_status),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final total = _recognitions.fold<double>(
      0,
          (sum, row) => sum + _toDouble(row['amount']),
    );

    return _sectionCard(
      title: 'خلاصه درآمدهای ثبت‌شده',
      icon: Icons.analytics_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth >= 500;

          final countCard = _metricCard(
            title: 'تعداد ثبت‌ها',
            value: _recognitions.length.toString(),
            icon: Icons.receipt_long_outlined,
            color: _blue,
          );

          final amountCard = _metricCard(
            title: 'جمع مبلغ',
            value: _money(total),
            icon: Icons.account_balance_wallet_outlined,
            color: _green,
          );

          if (horizontal) {
            return Row(
              children: [
                Expanded(child: countCard),
                const SizedBox(width: 12),
                Expanded(child: amountCard),
              ],
            );
          }

          return Column(
            children: [countCard, const SizedBox(height: 12), amountCard],
          );
        },
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
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
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recognitionsCard() {
    return _sectionCard(
      title: 'ریز اطلاعات درآمد',
      icon: Icons.receipt_long_outlined,
      trailing: Text(
        '${_recognitions.length} مورد',
        style: const TextStyle(fontSize: 12, color: _muted),
      ),
      child:
      _recognitions.isEmpty
          ? _emptyState(
        icon: Icons.receipt_long_outlined,
        title: 'درآمدی ثبت نشده است',
        message: 'برای این دوره هنوز اطلاعات درآمدی ثبت نشده است.',
      )
          : Column(
        children: [
          for (var i = 0; i < _recognitions.length; i++) ...[
            _recognitionTile(_recognitions[i]),
            if (i < _recognitions.length - 1)
              const Divider(height: 22, color: _border),
          ],
        ],
      ),
    );
  }

  Widget _recognitionTile(Map<String, dynamic> row) {
    final category = row['income_categories'];
    final categoryName =
    category is Map
        ? (category['name'] ?? 'بدون دسته‌بندی').toString()
        : 'بدون دسته‌بندی';

    final description = (row['description'] ?? '').toString().trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payments_outlined, color: _green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _text,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      color: _muted,
                      height: 1.6,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Text(
                  _dateLabel(row['created_at']),
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _money(_toDouble(row['amount'])),
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: _text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionsCard() {
    final isPendingForAdmin = _status == 'submitted_to_company_admin';
    final isOpen = _status == 'open';
    final isSubmittedToConsultant = _status == 'submitted_to_consultant';

    return _sectionCard(
      title: 'اقدامات دوره',
      icon: Icons.task_alt_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _statusDescription(_status),
            style: const TextStyle(fontSize: 13, color: _muted, height: 1.8),
          ),
          const SizedBox(height: 18),

          if (_isAccountant && isOpen) ...[
            _primaryActionButton(
              label: 'ارسال دوره برای بررسی مدیرعامل',
              icon: Icons.send_rounded,
              onPressed:
                  () => _transition(
                toStatus: 'submitted_to_company_admin',
                successMessage: 'دوره برای بررسی مدیرعامل ارسال شد.',
              ),
            ),
          ] else if (_isCompanyAdmin && isPendingForAdmin) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFF0D9A7)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF9A6700)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'اطلاعات دوره را بررسی کنید. با تأیید، دوره برای مشاور ارسال می‌شود. اگر اطلاعات ناقص است، آن را برای اصلاح برگردانید.',
                      style: TextStyle(height: 1.8, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _primaryActionButton(
              label: 'تأیید و ارسال برای مشاور',
              icon: Icons.verified_rounded,
              onPressed: _confirmAndSendToConsultant,
            ),
            const SizedBox(height: 10),
            _secondaryActionButton(
              label: 'برگشت برای اصلاح',
              icon: Icons.edit_note_rounded,
              color: _orange,
              onPressed: _returnForCorrection,
            ),
          ] else if (_isCompanyAdmin && isSubmittedToConsultant) ...[
            _noticeBox(
              icon: Icons.outgoing_mail,
              color: _blue,
              message: 'دوره برای مشاور ارسال شده است.',
            ),
          ] else if (_status == 'approved') ...[
            _noticeBox(
              icon: Icons.check_circle_outline,
              color: _green,
              message: 'دوره تأیید شده است.',
            ),
          ] else if (_status == 'closed') ...[
            _noticeBox(
              icon: Icons.lock_outline,
              color: _muted,
              message: 'این دوره بسته شده و اقدامات آن غیرفعال است.',
            ),
          ] else ...[
            _noticeBox(
              icon: Icons.info_outline,
              color: _muted,
              message: _noActionMessage(),
            ),
          ],

          if (_acting) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(color: _green),
            const SizedBox(height: 8),
            const Text(
              'در حال ثبت اقدام...',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _primaryActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _acting ? null : onPressed,
        icon: Icon(icon),
        label: Text(label, textAlign: TextAlign.center),
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _green.withOpacity(.45),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  Widget _secondaryActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _acting ? null : onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(.45)),
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  Widget _noticeBox({
    required IconData icon,
    required Color color,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _text, fontSize: 13, height: 1.8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndSendToConsultant() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.verified_user_outlined,
          color: _green,
          size: 40,
        ),
        title: const Text('تأیید دوره و ارسال برای مشاور'),
        content: const Text(
          'با تأیید این دوره، وضعیت آن تغییر می‌کند و برای مشاور ارسال می‌شود. آیا اطلاعات دوره را بررسی کرده‌اید و تأیید می‌کنید؟',
          style: TextStyle(height: 1.9),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('بازبینی دوباره'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.send_rounded),
            label: const Text('تأیید و ارسال'),
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _transition(
      toStatus: 'submitted_to_consultant',
      successMessage: 'دوره تأیید و برای مشاور ارسال شد.',
    );
  }

  Future<void> _returnForCorrection() async {
    final controller = TextEditingController();

    final note = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
        icon: const Icon(Icons.edit_note_rounded, color: _orange, size: 38),
        title: const Text('برگشت دوره برای اصلاح'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'دلیل برگشت را وارد کنید تا حسابدار بداند چه مواردی باید اصلاح شوند.',
              style: TextStyle(height: 1.8),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'دلیل اصلاح',
                hintText: 'موارد نیازمند اصلاح را بنویسید...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(dialogContext, value);
            },
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('ثبت و برگشت'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (note == null || note.trim().isEmpty || !mounted) return;

    await _transition(
      toStatus: 'open',
      note: note.trim(),
      successMessage: 'دوره برای اصلاح برگشت داده شد.',
    );
  }

  Widget _workflowCard() {
    return _sectionCard(
      title: 'تاریخچه گردش کار',
      icon: Icons.history_rounded,
      trailing: Text(
        '${_workflow.length} اقدام',
        style: const TextStyle(fontSize: 12, color: _muted),
      ),
      child:
      _workflow.isEmpty
          ? _emptyState(
        icon: Icons.history_rounded,
        title: 'تاریخچه‌ای وجود ندارد',
        message: 'اقدامات این دوره در این قسمت نمایش داده می‌شوند.',
      )
          : Column(
        children: [
          for (var i = 0; i < _workflow.length; i++) ...[
            _workflowTile(_workflow[i]),
            if (i < _workflow.length - 1)
              const Padding(
                padding: EdgeInsets.only(right: 17),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 22,
                    child: VerticalDivider(
                      color: _border,
                      thickness: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _workflowTile(Map<String, dynamic> row) {
    final fromStatus = (row['from_status'] ?? '').toString();
    final toStatus = (row['to_status'] ?? '').toString();
    final actor = (row['acted_by'] ?? '').toString();
    final note = (row['note'] ?? '').toString().trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _statusColor(toStatus).withOpacity(.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _statusIcon(toStatus),
            color: _statusColor(toStatus),
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFCFA),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_statusLabel(fromStatus)} ← ${_statusLabel(toStatus)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 15,
                      color: _muted,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'شناسه کاربر: ${_shortId(actor)}',
                        style: const TextStyle(fontSize: 11, color: _muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: _muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _dateLabel(row['created_at']),
                      style: const TextStyle(fontSize: 11, color: _muted),
                    ),
                  ],
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'توضیحات: $note',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.8,
                        color: _text,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _green, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _text,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 25),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFA),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 35, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, color: _text),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, height: 1.7, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _emptyState(
          icon: Icons.error_outline_rounded,
          title: 'دریافت اطلاعات ناموفق بود',
          message: _error ?? 'خطای نامشخص',
        ),
      ),
    );
  }

  Future<void> _transition({
    required String toStatus,
    String? note,
    required String successMessage,
  }) async {
    if (_acting || _period == null) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showMessage('نشست کاربری معتبر نیست. دوباره وارد شوید.', error: true);
      return;
    }

    if (!_isAllowedTransition(_status, toStatus)) {
      _showMessage('این تغییر وضعیت در مرحله فعلی مجاز نیست.', error: true);
      return;
    }

    setState(() => _acting = true);

    try {
      // وضعیت و تاریخچه در یک تابع دیتابیس و به‌صورت اتمیک ثبت می‌شوند.
      final result = await _supabase.rpc(
        'transition_income_fiscal_period',
        params: {
          'p_period_id': widget.periodId,
          'p_to_status': toStatus,
          'p_note': note,
        },
      );

      if (result is Map && result['success'] == false) {
        throw Exception(
          result['message']?.toString() ?? 'تغییر وضعیت انجام نشد.',
        );
      }

      if (!mounted) return;
      _showMessage(successMessage);
      await _loadData();
    } catch (e) {
      if (mounted) {
        _showMessage(
          'ثبت اقدام ناموفق بود: ${_friendlyError(e)}',
          error: true,
        );
        await _loadData();
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  bool _isAllowedTransition(String from, String to) {
    if (_isAccountant) {
      return from == 'open' && to == 'submitted_to_company_admin';
    }

    if (_isCompanyAdmin) {
      return (from == 'submitted_to_company_admin' &&
          (to == 'submitted_to_consultant' || to == 'open')) ||
          (from == 'submitted_to_consultant' && to == 'closed');
    }

    return false;
  }

  String _noActionMessage() {
    if (_status == 'open' && !_isAccountant) {
      return 'این دوره باز است. ارسال برای بررسی از حسابدار انجام می‌شود.';
    }

    if (_status == 'submitted_to_company_admin' && !_isCompanyAdmin) {
      return 'این دوره برای بررسی مدیرعامل ارسال شده است.';
    }

    if (_status == 'submitted_to_consultant') {
      return 'دوره برای مشاور ارسال شده است.';
    }

    if (_status == 'approved') {
      return 'دوره تأیید شده است.';
    }

    if (_status == 'closed') {
      return 'این دوره بسته شده است.';
    }

    return 'در این مرحله اقدامی برای نقش شما تعریف نشده است.';
  }

  String _statusDescription(String status) {
    switch (status) {
      case 'open':
        return 'دوره برای تکمیل اطلاعات باز است.';
      case 'submitted_to_company_admin':
        return 'دوره منتظر بررسی مدیرعامل است.';
      case 'submitted_to_consultant':
        return 'دوره برای بررسی مشاور ارسال شده است.';
      case 'approved':
        return 'این دوره تأیید شده است.';
      case 'closed':
        return 'دوره بسته شده است.';
      default:
        return 'وضعیت فعلی دوره را بررسی کنید.';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'باز / نیازمند تکمیل';
      case 'submitted_to_company_admin':
        return 'در انتظار بررسی مدیرعامل';
      case 'submitted_to_consultant':
        return 'ارسال‌شده برای مشاور';
      case 'approved':
        return 'تأییدشده';
      case 'closed':
        return 'بسته‌شده';
      default:
        return status.isEmpty ? 'نامشخص' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return _green;
      case 'submitted_to_company_admin':
        return _orange;
      case 'submitted_to_consultant':
        return _blue;
      case 'approved':
        return _green;
      case 'closed':
        return _muted;
      default:
        return _muted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.edit_note_rounded;
      case 'submitted_to_company_admin':
        return Icons.pending_actions_rounded;
      case 'submitted_to_consultant':
        return Icons.outgoing_mail;
      case 'approved':
        return Icons.check_circle_outline_rounded;
      case 'closed':
        return Icons.lock_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String _monthName(int month) {
    const months = [
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

    if (month < 1 || month > 12) return 'ماه $month';
    return months[month - 1];
  }

  String _dateLabel(dynamic rawValue) {
    if (rawValue == null) return 'تاریخ نامشخص';

    final date = DateTime.tryParse(rawValue.toString());
    if (date == null) return rawValue.toString();

    final jalali = Jalali.fromDateTime(date.toLocal());

    return '${jalali.year}/'
        '${jalali.month.toString().padLeft(2, '0')}/'
        '${jalali.day.toString().padLeft(2, '0')}';
  }

  String _money(double value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);

      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return '${buffer.toString()} ریال';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _shortId(String id) {
    if (id.isEmpty) return 'نامشخص';
    if (id.length <= 8) return id;
    return '${id.substring(0, 8)}…';
  }

  String _friendlyError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? Colors.red.shade700 : _green,
        ),
      );
  }
}
