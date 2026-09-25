import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class BankLoansReportPage extends StatefulWidget {
  final String companyId;

  const BankLoansReportPage({super.key, required this.companyId});

  @override
  State<BankLoansReportPage> createState() => _BankLoansReportPageState();
}

class _BankLoansReportPageState extends State<BankLoansReportPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  List<Map<String, dynamic>> _loans = [];

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await _supabase
          .from('bank_loans')
          .select(
            'id, company_id, bank_name, loan_type, '
            'principal_amount, remaining_amount, interest_rate, '
            'start_date, end_date, monthly_installment, '
            'created_by, created_at',
          )
          .eq('company_id', widget.companyId)
          .order('created_at', ascending: false);

      final loans =
          (response as List)
              .map((row) => Map<String, dynamic>.from(row))
              .toList();

      if (!mounted) return;

      setState(() {
        _loans = loans;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  Future<void> _saveLoan({
    String? id,
    required String bankName,
    required String loanType,
    required double principal,
    required double remaining,
    required double interest,
    required String? startDate,
    required String? endDate,
    required double installment,
  }) async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('کاربر وارد سیستم نشده است.');
      }

      final data = <String, dynamic>{
        'company_id': widget.companyId,
        'bank_name': bankName.trim(),
        'loan_type': loanType.trim(),
        'principal_amount': principal,
        'remaining_amount': remaining,
        'interest_rate': interest,
        'start_date': startDate,
        'end_date': endDate,
        'monthly_installment': installment,
        'created_by': userId,
      };

      if (id == null) {
        await _supabase.from('bank_loans').insert(data);
      } else {
        await _supabase
            .from('bank_loans')
            .update(data)
            .eq('id', id)
            .eq('company_id', widget.companyId);
      }

      await _loadLoans();

      if (!mounted) return;

      showSuccess(
        id == null
            ? 'تسهیلات با موفقیت ثبت شد.'
            : 'اطلاعات تسهیلات با موفقیت ویرایش شد.',
      );
    } catch (e) {
      if (!mounted) return;

      showError(_cleanError(e));
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _deleteLoan(Map<String, dynamic> loan) async {
    final id = loan['id']?.toString();

    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'حذف تسهیلات',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: const Text('آیا از حذف این تسهیلات اطمینان دارید؟'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('انصراف'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _supabase
          .from('bank_loans')
          .delete()
          .eq('id', id)
          .eq('company_id', widget.companyId);

      if (!mounted) return;

      showSuccess('تسهیلات حذف شد.');

      await _loadLoans();
    } catch (e) {
      if (!mounted) return;

      showError(_cleanError(e));
    }
  }

  void _openLoanDialog({Map<String, dynamic>? loan}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return _LoanDialog(
          loan: loan,
          saving: () => _saving,
          onSave: _saveLoan,
        );
      },
    );
  }

  double _number(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    var text = value.toString();

    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const english = '0123456789';

    for (int i = 0; i < 10; i++) {
      text = text.replaceAll(persian[i], english[i]);
      text = text.replaceAll(arabic[i], english[i]);
    }

    text =
        text
            .replaceAll(',', '')
            .replaceAll('٬', '')
            .replaceAll('٪', '')
            .replaceAll('%', '')
            .trim();

    return double.tryParse(text) ?? 0;
  }

  String _money(dynamic value) {
    final number = _number(value).round();

    final negative = number < 0;
    final text = number.abs().toString();

    var result = '';

    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        result += '٬';
      }

      result += text[i];
    }

    return '${negative ? '-' : ''}${_persian(result)}';
  }

  String _percent(dynamic value) {
    final number = _number(value);

    String text;

    if (number == number.roundToDouble()) {
      text = number.toInt().toString();
    } else {
      text = number.toStringAsFixed(2);
    }

    return '${_persian(text)}٪';
  }

  String _date(dynamic value) {
    if (value == null) return '-';

    final text = value.toString();

    if (text.isEmpty) return '-';

    try {
      final date = DateTime.parse(text);

      final jalali = Jalali.fromDateTime(date);

      return _jalaliText(jalali);
    } catch (_) {
      return _persian(text);
    }
  }

  String _jalaliText(Jalali date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return _persian('$year/$month/$day');
  }

  String _persian(String value) {
    const en = '0123456789';
    const fa = '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (var i = 0; i < en.length; i++) {
      result = result.replaceAll(en[i], fa[i]);
    }

    return result;
  }

  double get _totalPrincipal {
    return _loans.fold<double>(
      0,
      (sum, loan) => sum + _number(loan['principal_amount']),
    );
  }

  double get _totalRemaining {
    return _loans.fold<double>(
      0,
      (sum, loan) => sum + _number(loan['remaining_amount']),
    );
  }

  double get _totalInstallments {
    return _loans.fold<double>(
      0,
      (sum, loan) => sum + _number(loan['monthly_installment']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute: '/consultant/companies/${widget.companyId}/banking/loans',
      title: 'تسهیلات و بدهی بانکی',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _errorView();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 650;

        return Container(
          color: const Color(0xfff5f7f6),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(mobile ? 14 : 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(mobile),
                const SizedBox(height: 18),
                _summary(),
                const SizedBox(height: 20),
                _sectionHeader(),
                const SizedBox(height: 12),
                if (_loans.isEmpty)
                  _empty()
                else if (mobile)
                  ..._loans.map(
                    (loan) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _loanCard(loan),
                    ),
                  )
                else
                  _desktopTable(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(bool mobile) {
    return Container(
      padding: EdgeInsets.all(mobile ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xff163a2b), Color(0xff245842)],
        ),
        borderRadius: BorderRadius.circular(21),
      ),
      child:
          mobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _headerIcon(),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'تسهیلات و بدهی بانکی',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _refreshButton(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'مدیریت، ثبت و کنترل تسهیلات بانکی شرکت',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 12),
                  _mobileAddButton(),
                ],
              )
              : Row(
                children: [
                  _headerIcon(),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تسهیلات و بدهی بانکی',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'مدیریت، ثبت و کنترل تسهیلات بانکی شرکت',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _addButton(),
                  const SizedBox(width: 10),
                  _refreshButton(),
                ],
              ),
    );
  }

  Widget _headerIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.request_quote_rounded,
        color: Colors.white,
        size: 29,
      ),
    );
  }

  Widget _refreshButton() {
    return IconButton(
      tooltip: 'به‌روزرسانی',
      onPressed: _loading ? null : _loadLoans,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: .12),
        foregroundColor: Colors.white,
      ),
      icon: const Icon(Icons.refresh_rounded),
    );
  }

  Widget _addButton() {
    return FilledButton.icon(
      onPressed: _saving ? null : () => _openLoanDialog(),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff163a2b),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      ),
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'افزودن تسهیلات',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _mobileAddButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _saving ? null : () => _openLoanDialog(),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xff163a2b),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'افزودن تسهیلات',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _sectionHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'لیست تسهیلات',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : () => _openLoanDialog(),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xff176044),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('تسهیلات جدید'),
        ),
      ],
    );
  }

  Widget _summary() {
    final items = [
      _SummaryItem(
        'تعداد تسهیلات',
        _persian(_loans.length.toString()),
        'فقره',
        Icons.account_balance_rounded,
      ),
      _SummaryItem(
        'مجموع اصل تسهیلات',
        _money(_totalPrincipal),
        'ریال',
        Icons.payments_outlined,
      ),
      _SummaryItem(
        'مجموع مانده بدهی',
        _money(_totalRemaining),
        'ریال',
        Icons.account_balance_wallet_outlined,
      ),
      _SummaryItem(
        'مجموع اقساط ماهانه',
        _money(_totalInstallments),
        'ریال',
        Icons.calendar_month_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth >= 1100
                ? 4
                : constraints.maxWidth >= 650
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 116,
          ),
          itemBuilder: (_, index) {
            return _summaryCard(items[index]);
          },
        );
      },
    );
  }

  Widget _summaryCard(_SummaryItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xffeaf3ee),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(item.icon, color: const Color(0xff163a2b)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Color(0xff748078),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.suffix,
                  style: const TextStyle(
                    color: Color(0xff89958f),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopTable() {
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          horizontalMargin: 18,
          columnSpacing: 25,
          headingRowHeight: 55,
          dataRowMinHeight: 62,
          dataRowMaxHeight: 76,
          columns: const [
            DataColumn(label: Text('#', style: _headerStyle)),
            DataColumn(label: Text('بانک', style: _headerStyle)),
            DataColumn(label: Text('نوع تسهیلات', style: _headerStyle)),
            DataColumn(label: Text('اصل تسهیلات', style: _headerStyle)),
            DataColumn(label: Text('مانده بدهی', style: _headerStyle)),
            DataColumn(label: Text('نرخ سود', style: _headerStyle)),
            DataColumn(label: Text('قسط ماهانه', style: _headerStyle)),
            DataColumn(label: Text('شروع', style: _headerStyle)),
            DataColumn(label: Text('پایان', style: _headerStyle)),
            DataColumn(label: Text('عملیات', style: _headerStyle)),
          ],
          rows:
              _loans.asMap().entries.map((entry) {
                final index = entry.key;
                final loan = entry.value;

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        _persian('${index + 1}'),
                        style: const TextStyle(
                          color: Color(0xff89958f),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        loan['bank_name']?.toString() ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        loan['loan_type']?.toString() ?? '-',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${_money(loan['principal_amount'])} ریال',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${_money(loan['remaining_amount'])} ریال',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        _percent(loan['interest_rate']),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${_money(loan['monthly_installment'])} ریال',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Text(
                        _date(loan['start_date']),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Text(
                        _date(loan['end_date']),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'ویرایش',
                            onPressed: () => _openLoanDialog(loan: loan),
                            icon: const Icon(Icons.edit_outlined, size: 19),
                          ),
                          IconButton(
                            tooltip: 'حذف',
                            onPressed: () => _deleteLoan(loan),
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 19,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _loanCard(Map<String, dynamic> loan) {
    final principal = _number(loan['principal_amount']);

    final remaining = _number(loan['remaining_amount']);

    final progress =
        principal <= 0
            ? 0.0
            : ((principal - remaining) / principal).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xffeaf3ee),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: Color(0xff163a2b),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan['bank_name']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loan['loan_type']?.toString() ?? '-',
                      style: const TextStyle(
                        color: Color(0xff748078),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'ویرایش',
                onPressed: () => _openLoanDialog(loan: loan),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'حذف',
                onPressed: () => _deleteLoan(loan),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: Color(0xffe8ede9)),
          const SizedBox(height: 14),
          _loanValueRow('اصل تسهیلات', '${_money(principal)} ریال'),
          _loanValueRow('مانده بدهی', '${_money(remaining)} ریال', bold: true),
          _loanValueRow('نرخ سود', _percent(loan['interest_rate'])),
          _loanValueRow(
            'قسط ماهانه',
            '${_money(loan['monthly_installment'])} ریال',
          ),
          _loanValueRow('تاریخ شروع', _date(loan['start_date'])),
          _loanValueRow('تاریخ پایان', _date(loan['end_date'])),
          const SizedBox(height: 8),
          Text(
            'درصد تسویه‌شده: ${_persian((progress * 100).toStringAsFixed(1))}٪',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xffe8ede9),
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xff176044),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loanValueRow(String title, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Color(0xff7a8580), fontSize: 11),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 11,
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 65, horizontal: 25),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(
            Icons.request_quote_outlined,
            size: 62,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 17),
          const Text(
            'هنوز تسهیلاتی ثبت نشده است',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'اولین تسهیلات بانکی شرکت را ثبت کنید.',
            style: TextStyle(color: Color(0xff7a8580), fontSize: 12),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => _openLoanDialog(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('افزودن تسهیلات'),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.red.shade600,
            ),
            const SizedBox(height: 14),
            const Text(
              'خطا در دریافت اطلاعات تسهیلات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(_error ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadLoans,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }

  String _cleanError(Object e) {
    final text = e.toString();

    if (text.contains('row-level security')) {
      return 'دسترسی مدیریت تسهیلات برای این کاربر فعال نیست.';
    }

    if (text.contains('permission denied')) {
      return 'دسترسی لازم برای این عملیات وجود ندارد.';
    }

    if (text.contains('duplicate key')) {
      return 'این تسهیلات قبلاً ثبت شده است.';
    }

    if (text.contains('does not exist')) {
      return 'یکی از ستون‌های جدول bank_loans وجود ندارد.\n$text';
    }

    return text
        .replaceFirst('PostgrestException: ', '')
        .replaceFirst('Exception: ', '');
  }

  void showSuccess(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xff176044),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _LoanDialog extends StatefulWidget {
  final Map<String, dynamic>? loan;

  final bool Function() saving;

  final Future<void> Function({
    String? id,
    required String bankName,
    required String loanType,
    required double principal,
    required double remaining,
    required double interest,
    required String? startDate,
    required String? endDate,
    required double installment,
  })
  onSave;

  const _LoanDialog({
    required this.loan,
    required this.saving,
    required this.onSave,
  });

  @override
  State<_LoanDialog> createState() => _LoanDialogState();
}

class _LoanDialogState extends State<_LoanDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _bankController;

  late final TextEditingController _typeController;

  late final TextEditingController _principalController;

  late final TextEditingController _remainingController;

  late final TextEditingController _interestController;

  late final TextEditingController _installmentController;

  Jalali? _startDate;
  Jalali? _endDate;

  bool get editing => widget.loan != null;

  @override
  void initState() {
    super.initState();

    final loan = widget.loan;

    _bankController = TextEditingController(
      text: loan?['bank_name']?.toString() ?? '',
    );

    _typeController = TextEditingController(
      text: loan?['loan_type']?.toString() ?? '',
    );

    _principalController = TextEditingController(
      text: _formatMoney(loan?['principal_amount']),
    );

    _remainingController = TextEditingController(
      text: _formatMoney(loan?['remaining_amount']),
    );

    _interestController = TextEditingController(
      text: _formatNumber(loan?['interest_rate']),
    );

    _installmentController = TextEditingController(
      text: _formatMoney(loan?['monthly_installment']),
    );

    _startDate = _parseGregorianToJalali(loan?['start_date']);

    _endDate = _parseGregorianToJalali(loan?['end_date']);
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '';

    var text = value.toString();

    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const english = '0123456789';

    for (int i = 0; i < 10; i++) {
      text = text.replaceAll(persian[i], english[i]);
      text = text.replaceAll(arabic[i], english[i]);
    }

    return _toPersianDigits(text);
  }

  String _formatMoney(dynamic value) {
    if (value == null) return '';

    double number;

    if (value is num) {
      number = value.toDouble();
    } else {
      number =
          double.tryParse(
            value.toString().replaceAll(',', '').replaceAll('٬', ''),
          ) ??
          0;
    }

    final integer = number.round().abs().toString();

    var result = '';

    for (int i = 0; i < integer.length; i++) {
      if (i > 0 && (integer.length - i) % 3 == 0) {
        result += '٬';
      }

      result += integer[i];
    }

    return _toPersianDigits(result);
  }

  String _toPersianDigits(String value) {
    const en = '0123456789';
    const fa = '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(en[i], fa[i]);
    }

    return result;
  }

  String _toEnglishDigits(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';
    const en = '0123456789';

    var result = value;

    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(fa[i], en[i]);
      result = result.replaceAll(ar[i], en[i]);
    }

    return result;
  }

  double _number(String value) {
    final text =
        _toEnglishDigits(value).replaceAll(',', '').replaceAll('٬', '').trim();

    return double.tryParse(text) ?? 0;
  }

  Jalali? _parseGregorianToJalali(dynamic value) {
    if (value == null) return null;

    try {
      final date = DateTime.parse(value.toString());

      return Jalali.fromDateTime(date);
    } catch (_) {
      return null;
    }
  }

  String _jalaliToDatabase(Jalali? date) {
    if (date == null) return '';

    final gregorian = date.toGregorian();

    final year = gregorian.year.toString().padLeft(4, '0');

    final month = gregorian.month.toString().padLeft(2, '0');

    final day = gregorian.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String _jalaliDisplay(Jalali? date) {
    if (date == null) {
      return '';
    }

    final year = date.year.toString().padLeft(4, '0');

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return _toPersianDigits('$year/$month/$day');
  }

  Future<Jalali?> _showJalaliPicker({
    required BuildContext context,
    required Jalali initialDate,
    Jalali? minimumDate,
    Jalali? maximumDate,
  }) async {
    Jalali visibleMonth = initialDate.copy(day: 1);

    return showDialog<Jalali>(
      context: context,
      barrierDismissible: true,
      builder: (calendarContext) {
        return StatefulBuilder(
          builder: (context, setCalendarState) {
            final days = visibleMonth.monthLength;

            final firstWeekDay = visibleMonth.copy(day: 1).weekDay;

            final cells = <Widget>[];

            for (int i = 1; i < firstWeekDay; i++) {
              cells.add(const SizedBox(height: 44));
            }

            bool allowed(Jalali date) {
              if (minimumDate != null && date < minimumDate) {
                return false;
              }

              if (maximumDate != null && date > maximumDate) {
                return false;
              }

              return true;
            }

            final today = Jalali.now();

            for (int day = 1; day <= days; day++) {
              final date = Jalali(visibleMonth.year, visibleMonth.month, day);

              final enabled = allowed(date);

              final isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;

              cells.add(
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap:
                      !enabled
                          ? null
                          : () {
                            Navigator.of(calendarContext).pop(date);
                          },
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color:
                          isToday
                              ? const Color(0xff176044)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          !enabled
                              ? Border.all(color: Colors.grey.shade200)
                              : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _toPersianDigits(day.toString()),
                      style: TextStyle(
                        color:
                            !enabled
                                ? Colors.grey.shade300
                                : isToday
                                ? Colors.white
                                : Colors.grey.shade800,
                        fontSize: 13,
                        fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }

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

            const weekDays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 24,
                ),
                child: Container(
                  width: 390,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xffe8f3ed),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Color(0xff176044),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'انتخاب تاریخ شمسی',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.of(calendarContext).pop();
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xfff6f8f7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'ماه قبل',
                              onPressed: () {
                                setCalendarState(() {
                                  visibleMonth = visibleMonth.addMonths(-1);
                                });
                              },
                              icon: const Icon(Icons.chevron_right_rounded),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    months[visibleMonth.month - 1],
                                    style: const TextStyle(
                                      color: Color(0xff176044),
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _toPersianDigits(
                                      visibleMonth.year.toString(),
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xff7a8580),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'ماه بعد',
                              onPressed: () {
                                setCalendarState(() {
                                  visibleMonth = visibleMonth.addMonths(1);
                                });
                              },
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children:
                            weekDays
                                .map(
                                  (day) => Expanded(
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: const TextStyle(
                                          color: Color(0xff7a8580),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),

                      const SizedBox(height: 6),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 7,
                        childAspectRatio: 1,
                        children: cells,
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final now = Jalali.now();

                            setCalendarState(() {
                              visibleMonth = now.copy(day: 1);
                            });
                          },
                          icon: const Icon(Icons.today_rounded, size: 18),
                          label: const Text('امروز'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickStartDate() async {
    final selected = await _showJalaliPicker(
      context: context,
      initialDate: _startDate ?? Jalali.now(),
      minimumDate: Jalali(1300, 1, 1),
      maximumDate: Jalali(1500, 12, 29),
    );

    if (selected == null) return;

    setState(() {
      _startDate = selected;

      if (_endDate != null && _endDate! < selected) {
        _endDate = null;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final selected = await _showJalaliPicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? Jalali.now(),
      minimumDate: _startDate ?? Jalali(1300, 1, 1),
      maximumDate: Jalali(1500, 12, 29),
    );

    if (selected == null) return;

    setState(() {
      _endDate = selected;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final principal = _number(_principalController.text);

    final remaining = _number(_remainingController.text);

    final interest = _number(_interestController.text);

    final installment = _number(_installmentController.text);

    if (principal <= 0) {
      _showError('اصل تسهیلات باید بیشتر از صفر باشد.');
      return;
    }

    if (remaining < 0) {
      _showError('مانده بدهی نمی‌تواند منفی باشد.');
      return;
    }

    if (remaining > principal) {
      _showError('مانده بدهی نمی‌تواند بیشتر از اصل تسهیلات باشد.');
      return;
    }

    if (interest < 0 || interest > 100) {
      _showError('نرخ سود باید بین صفر تا ۱۰۰ درصد باشد.');
      return;
    }

    if (_startDate != null && _endDate != null && _endDate! < _startDate!) {
      _showError('تاریخ پایان نمی‌تواند قبل از تاریخ شروع باشد.');
      return;
    }

    try {
      await widget.onSave(
        id: widget.loan?['id']?.toString(),
        bankName: _bankController.text,
        loanType: _typeController.text,
        principal: principal,
        remaining: remaining,
        interest: interest,
        startDate: _jalaliToDatabase(_startDate),
        endDate: _jalaliToDatabase(_endDate),
        installment: installment,
      );

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (_) {
      // خطا در parent نمایش داده شده.
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  void dispose() {
    _bankController.dispose();
    _typeController.dispose();
    _principalController.dispose();
    _remainingController.dispose();
    _interestController.dispose();
    _installmentController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 850),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xffedf5f0),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 22, 25, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xffe8f3ed),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.request_quote_rounded,
                          color: Color(0xff176044),
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          editing ? 'ویرایش تسهیلات' : 'ثبت تسهیلات جدید',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            widget.saving()
                                ? null
                                : () {
                                  Navigator.of(context).pop();
                                },
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(25, 0, 25, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _field(
                            _bankController,
                            'نام بانک',
                            Icons.account_balance_rounded,
                            required: true,
                          ),

                          const SizedBox(height: 12),

                          _field(
                            _typeController,
                            'نوع تسهیلات',
                            Icons.category_outlined,
                            required: true,
                          ),

                          const SizedBox(height: 12),

                          _moneyField(
                            _principalController,
                            'اصل تسهیلات',
                            Icons.payments_outlined,
                          ),

                          const SizedBox(height: 12),

                          _moneyField(
                            _remainingController,
                            'مانده بدهی',
                            Icons.account_balance_wallet_outlined,
                          ),

                          const SizedBox(height: 12),

                          _interestField(),

                          const SizedBox(height: 12),

                          _moneyField(
                            _installmentController,
                            'قسط ماهانه',
                            Icons.calendar_month_outlined,
                          ),

                          const SizedBox(height: 12),

                          _dateSelector(
                            label: 'تاریخ شروع',
                            value: _startDate,
                            onTap: _pickStartDate,
                            icon: Icons.event_rounded,
                          ),

                          const SizedBox(height: 12),

                          _dateSelector(
                            label: 'تاریخ پایان',
                            value: _endDate,
                            onTap: _pickEndDate,
                            icon: Icons.event_available_rounded,
                          ),

                          const SizedBox(height: 8),

                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'تاریخ‌ها با تقویم شمسی انتخاب و به صورت date در دیتابیس ذخیره می‌شوند.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(25, 14, 25, 20),
                  decoration: const BoxDecoration(
                    color: Color(0x99ffffff),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      FilledButton.icon(
                        onPressed: widget.saving() ? null : _submit,
                        icon:
                            widget.saving()
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Icon(Icons.save_rounded),
                        label: Text(
                          widget.saving()
                              ? 'در حال ذخیره...'
                              : editing
                              ? 'ذخیره تغییرات'
                              : 'ثبت تسهیلات',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xff176044),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      TextButton(
                        onPressed:
                            widget.saving()
                                ? null
                                : () {
                                  Navigator.of(context).pop();
                                },
                        child: const Text('انصراف'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      textDirection: TextDirection.rtl,
      validator:
          required
              ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label الزامی است';
                }

                return null;
              }
              : null,
      decoration: _inputDecoration(label: label, icon: icon),
    );
  }

  Widget _moneyField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹٠-٩,٬]')),
      ],
      onChanged: (value) {
        final formatted = _formatInputMoney(value);

        if (formatted != value) {
          controller.value = TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }
      },
      decoration: _inputDecoration(label: label, icon: icon, suffix: 'ریال'),
    );
  }

  Widget _interestField() {
    return TextFormField(
      controller: _interestController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹٠-٩.]')),
      ],
      decoration: _inputDecoration(
        label: 'نرخ سود',
        icon: Icons.percent_rounded,
        suffix: '%',
      ),
    );
  }

  String _formatInputMoney(String value) {
    var text = _toEnglishDigits(
      value,
    ).replaceAll(',', '').replaceAll('٬', '').replaceAll(' ', '');

    text = text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.isEmpty) {
      return '';
    }

    var result = '';

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        result += '٬';
      }

      result += text[i];
    }

    return _toPersianDigits(result);
  }

  Widget _dateSelector({
    required String label,
    required Jalali? value,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: widget.saving() ? null : onTap,
      borderRadius: BorderRadius.circular(13),
      child: InputDecorator(
        decoration: _inputDecoration(label: label, icon: icon),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null ? 'انتخاب تاریخ شمسی' : _jalaliDisplay(value),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color:
                      value == null
                          ? Colors.grey.shade600
                          : Colors.grey.shade900,
                  fontSize: 14,
                  fontWeight: value == null ? FontWeight.w400 : FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.calendar_month_rounded,
              size: 20,
              color: Colors.green.shade700,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      suffixText: suffix,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xff176044), width: 1.5),
      ),
    );
  }
}

class _SummaryItem {
  final String title;
  final String value;
  final String suffix;
  final IconData icon;

  const _SummaryItem(this.title, this.value, this.suffix, this.icon);
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xffe5ebe7)),
    boxShadow: const [
      BoxShadow(color: Color(0x08000000), blurRadius: 18, offset: Offset(0, 7)),
    ],
  );
}

const _headerStyle = TextStyle(
  color: Color(0xff69756f),
  fontSize: 10,
  fontWeight: FontWeight.w800,
);
