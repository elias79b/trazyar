import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shamsi_date/shamsi_date.dart';

class AccountantPayablePeriodPage
    extends ConsumerStatefulWidget {
  final String companyId;
  final String periodId;

  const AccountantPayablePeriodPage({
    super.key,
    required this.companyId,
    required this.periodId,
  });

  @override
  ConsumerState<AccountantPayablePeriodPage>
  createState() =>
      _AccountantPayablePeriodPageState();
}

class _AccountantPayablePeriodPageState
    extends ConsumerState<AccountantPayablePeriodPage> {
  final _creditorController =
  TextEditingController();

  final _titleController =
  TextEditingController();

  final _amountController =
  TextEditingController();

  final _referenceController =
  TextEditingController();

  final _descriptionController =
  TextEditingController();

  Jalali? _dueDate;

  bool _loading = true;
  bool _saving = false;

  String? _periodStatus;
  String? _periodTitle;

  List<Map<String, dynamic>> _payables = [];

  SupabaseClient get _supabase =>
      Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _creditorController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    try {
      final period = await _supabase
          .from('payable_fiscal_periods')
          .select(
        'id, company_id, fiscal_year_id, year, month, title, status',
      )
          .eq(
        'id',
        widget.periodId,
      )
          .eq(
        'company_id',
        widget.companyId,
      )
          .maybeSingle();

      if (period == null) {
        throw Exception(
          'دوره حساب‌های پرداختنی پیدا نشد.',
        );
      }

      final payables = await _supabase
          .from('payables')
          .select(
        'id, creditor_name, title, amount, due_date, reference_number, description, status, created_at',
      )
          .eq(
        'company_id',
        widget.companyId,
      )
          .eq(
        'fiscal_period_id',
        widget.periodId,
      )
          .order(
        'created_at',
        ascending: false,
      );

      if (!mounted) return;

      setState(() {
        _periodStatus =
            period['status']?.toString();

        _periodTitle =
            period['title']?.toString() ??
                _monthTitle(
                  _toInt(period['month']),
                );

        _payables =
        List<Map<String, dynamic>>.from(
          payables,
        );

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        _errorMessage(e),
        isError: true,
      );
    }
  }

  Future<void> _savePayable() async {
    if (_saving) return;

    final creditor =
    _creditorController.text.trim();

    final title =
    _titleController.text.trim();

    final amount =
    _parseAmount(
      _amountController.text,
    );

    if (creditor.isEmpty) {
      _showMessage(
        'نام طلبکار را وارد کنید.',
        isError: true,
      );
      return;
    }

    if (title.isEmpty) {
      _showMessage(
        'عنوان پرداختنی را وارد کنید.',
        isError: true,
      );
      return;
    }

    if (amount == null || amount < 0) {
      _showMessage(
        'مبلغ واردشده معتبر نیست.',
        isError: true,
      );
      return;
    }

    if (!_canEdit) {
      _showMessage(
        'این دوره در وضعیت قابل ثبت نیست.',
        isError: true,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final userId =
          _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception(
          'کاربر وارد حساب نشده است.',
        );
      }

      await _supabase
          .from('payables')
          .insert({
        'company_id':
        widget.companyId,
        'fiscal_period_id':
        widget.periodId,
        'creditor_name':
        creditor,
        'title':
        title,
        'amount':
        amount,
        'due_date':
        _dueDate == null
            ? null
            : _jalaliToDatabaseDate(
          _dueDate!,
        ),
        'reference_number':
        _emptyToNull(
          _referenceController.text,
        ),
        'description':
        _emptyToNull(
          _descriptionController.text,
        ),
        'created_by':
        userId,
      });

      _clearForm();

      await _load();

      if (!mounted) return;

      _showMessage(
        'پرداختنی با موفقیت ثبت شد.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _errorMessage(e),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _deletePayable(
      String id,
      ) async {
    if (!_canEdit) return;

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) =>
          Directionality(
            textDirection:
            TextDirection.rtl,
            child: AlertDialog(
              title: const Text(
                'حذف پرداختنی',
              ),
              content: const Text(
                'آیا از حذف این پرداختنی مطمئن هستید؟',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(
                        context,
                        false,
                      ),
                  child:
                  const Text(
                    'انصراف',
                  ),
                ),
                FilledButton(
                  style:
                  FilledButton.styleFrom(
                    backgroundColor:
                    Colors.red,
                  ),
                  onPressed: () =>
                      Navigator.pop(
                        context,
                        true,
                      ),
                  child:
                  const Text(
                    'حذف',
                  ),
                ),
              ],
            ),
          ),
    );

    if (confirmed != true) return;

    try {
      await _supabase
          .from('payables')
          .delete()
          .eq(
        'id',
        id,
      )
          .eq(
        'company_id',
        widget.companyId,
      );

      await _load();

      if (!mounted) return;

      _showMessage(
        'پرداختنی حذف شد.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _errorMessage(e),
        isError: true,
      );
    }
  }

  Future<void> _processPeriod(
      String action,
      ) async {
    final noteController =
    TextEditingController();

    try {
      final note =
      await showDialog<String>(
        context: context,
        builder: (context) =>
            Directionality(
              textDirection:
              TextDirection.rtl,
              child: AlertDialog(
                title: Text(
                  _actionTitle(action),
                ),
                content: TextField(
                  controller:
                  noteController,
                  maxLines: 3,
                  decoration:
                  const InputDecoration(
                    labelText:
                    'توضیحات',
                    hintText:
                    'اختیاری',
                    border:
                    OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(
                          context,
                        ),
                    child:
                    const Text(
                      'انصراف',
                    ),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(
                          context,
                          noteController
                              .text
                              .trim(),
                        ),
                    child:
                    const Text(
                      'تأیید',
                    ),
                  ),
                ],
              ),
            ),
      );

      if (note == null) return;

      await _supabase.rpc(
        'process_payable_fiscal_period',
        params: {
          'p_period_id':
          widget.periodId,
          'p_action':
          action,
          'p_note':
          note.isEmpty
              ? null
              : note,
        },
      );

      await _load();

      if (!mounted) return;

      _showMessage(
        'وضعیت دوره با موفقیت تغییر کرد.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _errorMessage(e),
        isError: true,
      );
    } finally {
      noteController.dispose();
    }
  }

  Future<void> _pickJalaliDate() async {
    final selected =
    await showDialog<Jalali>(
      context: context,
      builder: (context) =>
          _JalaliCalendarDialog(
            initialDate:
            _dueDate ?? Jalali.now(),
          ),
    );

    if (selected != null) {
      setState(() {
        _dueDate = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        const Color(0xFFF6F7FB),
        body: SafeArea(
          child: _loading
              ? const Center(
            child:
            CircularProgressIndicator(),
          )
              : RefreshIndicator(
            onRefresh: _load,
            child:
            _buildContent(
              context,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      ) {
    final width =
        MediaQuery.sizeOf(context).width;

    final mobile =
        width < 800;

    final total =
    _payables.fold<double>(
      0,
          (sum, item) =>
      sum +
          _toDouble(
            item['amount'],
          ),
    );

    final pending =
        _payables.where(
              (item) =>
          item['status'] ==
              'pending',
        ).length;

    final paid =
        _payables.where(
              (item) =>
          item['status'] ==
              'paid',
        ).length;

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        mobile ? 12 : 24,
        16,
        mobile ? 12 : 24,
        32,
      ),
      children: [
        _buildHeader(
          mobile,
        ),
        const SizedBox(height: 14),
        _buildStatusBar(
          mobile,
        ),
        const SizedBox(height: 14),
        _buildSummary(
          total,
          pending,
          paid,
          mobile,
        ),
        const SizedBox(height: 14),
        _buildEntryForm(
          mobile,
        ),
        const SizedBox(height: 14),
        _buildPayablesList(
          mobile,
        ),
      ],
    );
  }

  Widget _buildHeader(
      bool mobile,
      ) {
    return Container(
      padding:
      EdgeInsets.all(
        mobile ? 16 : 22,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width:
            mobile ? 46 : 54,
            height:
            mobile ? 46 : 54,
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFEAF5F0),
              borderRadius:
              BorderRadius.circular(
                15,
              ),
            ),
            child: const Icon(
              Icons
                  .request_quote_outlined,
              color:
              Color(0xFF177A59),
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  _periodTitle ??
                      'دوره پرداختنی',
                  style:
                  const TextStyle(
                    fontSize: 21,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(0xFF111827),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                const Text(
                  'ثبت و مدیریت حساب‌های پرداختنی این دوره',
                  style:
                  TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (!mobile)
            _statusChip(
              _periodStatus ??
                  'open',
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(
      bool mobile,
      ) {
    final status =
        _periodStatus ?? 'open';

    final actions =
    <Widget>[];

    if (status == 'open') {
      actions.add(
        _actionButton(
          title:
          'ارسال به مدیر',
          icon:
          Icons
              .forward_to_inbox_outlined,
          onPressed: () =>
              _processPeriod(
                'submit_to_company_admin',
              ),
        ),
      );
    }

    if (status ==
        'submitted_to_company_admin') {
      actions.add(
        _actionButton(
          title:
          'ارسال به مشاور',
          icon:
          Icons.person_outline,
          onPressed: () =>
              _processPeriod(
                'approve_and_send_to_consultant',
              ),
        ),
      );

      actions.add(
        _actionButton(
          title:
          'برگشت به حسابدار',
          icon:
          Icons.undo_outlined,
          outlined: true,
          onPressed: () =>
              _processPeriod(
                'return_to_accountant',
              ),
        ),
      );
    }

    if (status ==
        'submitted_to_consultant') {
      actions.add(
        _actionButton(
          title:
          'تأیید توسط مشاور',
          icon:
          Icons.verified_outlined,
          onPressed: () =>
              _processPeriod(
                'approve_by_consultant',
              ),
        ),
      );

      actions.add(
        _actionButton(
          title: 'برگشت',
          icon:
          Icons.undo_outlined,
          outlined: true,
          onPressed: () =>
              _processPeriod(
                'return_by_consultant',
              ),
        ),
      );
    }

    if (status == 'approved') {
      actions.add(
        _actionButton(
          title:
          'بستن دوره',
          icon:
          Icons.lock_outline,
          onPressed: () =>
              _processPeriod(
                'close',
              ),
        ),
      );
    }

    if (status == 'closed') {
      actions.add(
        _actionButton(
          title:
          'بازگشایی دوره',
          icon:
          Icons.lock_open_outlined,
          outlined: true,
          onPressed: () =>
              _processPeriod(
                'reopen',
              ),
        ),
      );
    }

    return Container(
      padding:
      const EdgeInsets.all(14),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: mobile
          ? Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons
                    .account_tree_outlined,
                size: 20,
              ),
              const SizedBox(
                width: 8,
              ),
              const Expanded(
                child: Text(
                  'گردش کار دوره',
                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight
                        .w700,
                  ),
                ),
              ),
              _statusChip(
                status,
              ),
            ],
          ),
          if (actions
              .isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
              actions,
            ),
          ],
        ],
      )
          : Row(
        children: [
          const Icon(
            Icons
                .account_tree_outlined,
            size: 20,
          ),
          const SizedBox(
            width: 8,
          ),
          const Text(
            'گردش کار دوره',
            style:
            TextStyle(
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          _statusChip(
            status,
          ),
          const Spacer(),
          Wrap(
            spacing: 8,
            children:
            actions,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(
      double total,
      int pending,
      int paid,
      bool mobile,
      ) {
    final cards = [
      _SummaryCardData(
        title:
        'مجموع پرداختنی',
        value:
        '${_formatMoney(total)} ریال',
        icon:
        Icons
            .account_balance_wallet_outlined,
      ),
      _SummaryCardData(
        title:
        'در انتظار پرداخت',
        value:
        pending.toString(),
        icon:
        Icons
            .pending_actions_outlined,
      ),
      _SummaryCardData(
        title:
        'پرداخت‌شده',
        value:
        paid.toString(),
        icon:
        Icons
            .check_circle_outline,
      ),
      _SummaryCardData(
        title:
        'تعداد پرداختنی',
        value:
        _payables.length
            .toString(),
        icon:
        Icons
            .receipt_long_outlined,
      ),
    ];

    return LayoutBuilder(
      builder:
          (context, constraints) {
        final columns =
        mobile
            ? 1
            : constraints.maxWidth >=
            1200
            ? 4
            : 2;

        const gap = 10.0;

        final width =
        mobile
            ? constraints.maxWidth
            : (constraints.maxWidth -
            gap *
                (columns -
                    1)) /
            columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children:
          cards.map(
                (card) {
              return SizedBox(
                width: width,
                child:
                _summaryCard(
                  card,
                ),
              );
            },
          ).toList(),
        );
      },
    );
  }

  Widget _summaryCard(
      _SummaryCardData data,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(15),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFF1F5F9),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              data.icon,
              color:
              const Color(0xFF177A59),
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  data.title,
                  style:
                  const TextStyle(
                    fontSize: 11,
                    color:
                    Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  data.value,
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryForm(
      bool mobile,
      ) {
    return Container(
      padding:
      EdgeInsets.all(
        mobile ? 16 : 20,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons
                    .add_circle_outline,
                color:
                Color(0xFF177A59),
              ),
              const SizedBox(width: 8),
              const Text(
                'ثبت حساب پرداختنی',
                style:
                TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (!_canEdit)
                _statusChip(
                  _periodStatus ??
                      'open',
                ),
            ],
          ),
          const SizedBox(
            height: 18,
          ),
          LayoutBuilder(
            builder:
                (context, constraints) {
              final columns =
              mobile ? 1 : 2;

              const gap = 12.0;

              final fieldWidth =
              mobile
                  ? constraints
                  .maxWidth
                  : (constraints
                  .maxWidth -
                  gap) /
                  columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: fieldWidth,
                    child:
                    _textField(
                      controller:
                      _creditorController,
                      label:
                      'نام طلبکار',
                      hint:
                      'مثلاً شرکت تأمین‌کننده',
                      icon:
                      Icons
                          .person_outline,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child:
                    _textField(
                      controller:
                      _titleController,
                      label:
                      'عنوان پرداختنی',
                      hint:
                      'مثلاً خرید مواد اولیه',
                      icon:
                      Icons
                          .description_outlined,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child:
                    _textField(
                      controller:
                      _amountController,
                      label:
                      'مبلغ',
                      hint:
                      'مبلغ به ریال',
                      icon:
                      Icons
                          .payments_outlined,
                      keyboardType:
                      TextInputType
                          .number,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child:
                    _dateField(),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child:
                    _textField(
                      controller:
                      _referenceController,
                      label:
                      'شماره مرجع',
                      hint:
                      'اختیاری',
                      icon:
                      Icons
                          .tag_outlined,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth,
                    child:
                    _textField(
                      controller:
                      _descriptionController,
                      label:
                      'توضیحات',
                      hint:
                      'اختیاری',
                      icon:
                      Icons
                          .notes_outlined,
                      maxLines: 2,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(
            height: 16,
          ),
          Align(
            alignment:
            Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed:
              _canEdit &&
                  !_saving
                  ? _savePayable
                  : null,
              icon: _saving
                  ? const SizedBox(
                width: 17,
                height: 17,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                  Colors.white,
                ),
              )
                  : const Icon(
                Icons
                    .save_outlined,
              ),
              label: Text(
                _saving
                    ? 'در حال ثبت...'
                    : 'ثبت پرداختنی',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField() {
    final text =
    _dueDate == null
        ? ''
        : _jalaliDisplay(
      _dueDate!,
    );

    return InkWell(
      borderRadius:
      BorderRadius.circular(12),
      onTap:
      _canEdit
          ? _pickJalaliDate
          : null,
      child: InputDecorator(
        decoration:
        InputDecoration(
          labelText:
          'تاریخ سررسید',
          prefixIcon:
          const Icon(
            Icons.event_outlined,
          ),
          border:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              12,
            ),
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              12,
            ),
            borderSide:
            const BorderSide(
              color:
              Color(0xFFE5E7EB),
            ),
          ),
        ),
        child: Text(
          text.isEmpty
              ? 'انتخاب تاریخ شمسی'
              : text,
          style: TextStyle(
            color: text.isEmpty
                ? const Color(
              0xFF9CA3AF,
            )
                : const Color(
              0xFF111827,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPayablesList(
      bool mobile,
      ) {
    return Container(
      padding:
      EdgeInsets.all(
        mobile ? 14 : 20,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.list_alt_outlined,
              ),
              const SizedBox(width: 8),
              const Text(
                'پرداختنی‌های ثبت‌شده',
                style:
                TextStyle(
                  fontSize: 16,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${_payables.length} مورد',
                style:
                const TextStyle(
                  fontSize: 12,
                  color:
                  Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_payables.isEmpty)
            _emptyPayables()
          else
            ..._payables.map(
                  (item) =>
                  _payableCard(item),
            ),
        ],
      ),
    );
  }

  Widget _payableCard(
      Map<String, dynamic> item,
      ) {
    final status =
        item['status']?.toString() ??
            'pending';

    final dueDate =
    _databaseDateToJalali(
      item['due_date'],
    );

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
      const EdgeInsets.all(14),
      decoration:
      BoxDecoration(
        color:
        const Color(0xFFFAFAFA),
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color:
          const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFEAF5F0),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: const Icon(
              Icons
                  .receipt_long_outlined,
              color:
              Color(0xFF177A59),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  item['title']
                      ?.toString() ??
                      '-',
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  item['creditor_name']
                      ?.toString() ??
                      '-',
                  style:
                  const TextStyle(
                    fontSize: 12,
                    color:
                    Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Text(
                      '${_formatMoney(_toDouble(item['amount']))} ریال',
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.w700,
                        color:
                        Color(0xFF111827),
                      ),
                    ),
                    if (dueDate != null)
                      Text(
                        'سررسید: ${_jalaliDisplay(dueDate)}',
                        style:
                        const TextStyle(
                          fontSize: 11,
                          color:
                          Color(0xFF6B7280),
                        ),
                      ),
                    if (item[
                    'reference_number']
                        ?.toString()
                        .isNotEmpty ==
                        true)
                      Text(
                        'مرجع: ${item['reference_number']}',
                        style:
                        const TextStyle(
                          fontSize: 11,
                          color:
                          Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              _payableStatusChip(
                status,
              ),
              if (_canEdit)
                IconButton(
                  tooltip: 'حذف',
                  onPressed: () =>
                      _deletePayable(
                        item['id']
                            .toString(),
                      ),
                  icon:
                  const Icon(
                    Icons
                        .delete_outline,
                    color:
                    Colors.red,
                    size: 20,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyPayables() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        vertical: 40,
      ),
      child: Column(
        children: [
          Icon(
            Icons
                .receipt_long_outlined,
            size: 48,
            color:
            Colors.grey.shade400,
          ),
          const SizedBox(
            height: 10,
          ),
          const Text(
            'هنوز حساب پرداختنی ثبت نشده است.',
            style:
            TextStyle(
              fontWeight:
              FontWeight.w600,
              color:
              Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController
    controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
      keyboardType,
      maxLines: maxLines,
      decoration:
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
        Icon(icon),
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          borderSide:
          const BorderSide(
            color:
            Color(0xFFE5E7EB),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 17,
        ),
        label:
        Text(title),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 17,
      ),
      label:
      Text(title),
    );
  }

  Widget _statusChip(
      String status,
      ) {
    final color =
    _statusColor(status);

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withOpacity(.09),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        _statusTitle(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
          FontWeight.w700,
        ),
      ),
    );
  }

  Widget _payableStatusChip(
      String status,
      ) {
    final color =
    _payableStatusColor(status);

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withOpacity(.08),
        borderRadius:
        BorderRadius.circular(18),
      ),
      child: Text(
        _payableStatusTitle(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight:
          FontWeight.w700,
        ),
      ),
    );
  }

  bool get _canEdit {
    return _periodStatus == 'open';
  }

  Color _statusColor(
      String status,
      ) {
    switch (status) {
      case 'open':
        return const Color(0xFF2563EB);
      case 'submitted_to_company_admin':
        return const Color(0xFFD97706);
      case 'submitted_to_consultant':
        return const Color(0xFF7C3AED);
      case 'approved':
        return const Color(0xFF16A34A);
      case 'closed':
        return const Color(0xFF4B5563);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _statusTitle(
      String status,
      ) {
    switch (status) {
      case 'open':
        return 'باز';
      case 'submitted_to_company_admin':
        return 'ارسال به مدیر';
      case 'submitted_to_consultant':
        return 'ارسال به مشاور';
      case 'approved':
        return 'تأییدشده';
      case 'closed':
        return 'بسته';
      default:
        return status;
    }
  }

  Color _payableStatusColor(
      String status,
      ) {
    switch (status) {
      case 'paid':
        return const Color(0xFF16A34A);
      case 'cancelled':
        return const Color(0xFFDC2626);
      case 'pending':
      default:
        return const Color(0xFFD97706);
    }
  }

  String _payableStatusTitle(
      String status,
      ) {
    switch (status) {
      case 'paid':
        return 'پرداخت‌شده';
      case 'cancelled':
        return 'لغوشده';
      case 'pending':
      default:
        return 'در انتظار پرداخت';
    }
  }

  String _actionTitle(
      String action,
      ) {
    switch (action) {
      case 'submit_to_company_admin':
        return 'ارسال دوره به مدیر';
      case 'approve_and_send_to_consultant':
        return 'ارسال دوره به مشاور';
      case 'return_to_accountant':
        return 'برگشت به حسابدار';
      case 'approve_by_consultant':
        return 'تأیید دوره';
      case 'return_by_consultant':
        return 'برگشت دوره';
      case 'close':
        return 'بستن دوره';
      case 'reopen':
        return 'بازگشایی دوره';
      default:
        return 'تغییر وضعیت دوره';
    }
  }

  String _monthTitle(
      int month,
      ) {
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

    if (month < 1 ||
        month > 12) {
      return 'دوره پرداختنی';
    }

    return months[month - 1];
  }

  double? _parseAmount(
      String value,
      ) {
    var text =
    value.trim();

    const persian =
        '۰۱۲۳۴۵۶۷۸۹';

    const arabic =
        '٠١٢٣٤٥٦٧٨٩';

    for (var i = 0; i < 10; i++) {
      text = text.replaceAll(
        persian[i],
        i.toString(),
      );

      text = text.replaceAll(
        arabic[i],
        i.toString(),
      );
    }

    text = text
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll(' ', '');

    return double.tryParse(text);
  }

  int _toInt(
      dynamic value,
      ) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  double _toDouble(
      dynamic value,
      ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  String _formatMoney(
      double value,
      ) {
    final text =
    value.round().toString();

    final buffer =
    StringBuffer();

    for (var i = 0;
    i < text.length;
    i++) {
      if (i > 0 &&
          (text.length - i) % 3 ==
              0) {
        buffer.write(',');
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }

  String _jalaliToDatabaseDate(
      Jalali date,
      ) {
    final gregorian =
    date.toGregorian();

    final year =
    gregorian.year
        .toString()
        .padLeft(
      4,
      '0',
    );

    final month =
    gregorian.month
        .toString()
        .padLeft(
      2,
      '0',
    );

    final day =
    gregorian.day
        .toString()
        .padLeft(
      2,
      '0',
    );

    return '$year-$month-$day';
  }

  Jalali? _databaseDateToJalali(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    final text =
    value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    try {
      final parts =
      text.split('-');

      if (parts.length < 3) {
        return null;
      }

      final year =
      int.parse(parts[0]);

      final month =
      int.parse(parts[1]);

      final day =
      int.parse(
        parts[2]
            .split('T')
            .first,
      );

      final gregorian =
      Gregorian(
        year,
        month,
        day,
      );

      return gregorian.toJalali();
    } catch (_) {
      return null;
    }
  }

  String _jalaliDisplay(
      Jalali date,
      ) {
    return _toPersianDigits(
      '${date.year.toString().padLeft(4, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.day.toString().padLeft(2, '0')}',
    );
  }

  String _toPersianDigits(
      String value,
      ) {
    const english =
        '0123456789';

    const persian =
        '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(
        english[i],
        persian[i],
      );
    }

    return result;
  }

  String? _emptyToNull(
      String value,
      ) {
    final text =
    value.trim();

    return text.isEmpty
        ? null
        : text;
  }

  void _clearForm() {
    _creditorController.clear();
    _titleController.clear();
    _amountController.clear();
    _referenceController.clear();
    _descriptionController.clear();

    setState(() {
      _dueDate = null;
    });
  }

  String _errorMessage(
      Object error,
      ) {
    final text =
    error.toString();

    if (text.startsWith(
      'Exception: ',
    )) {
      return text.substring(
        11,
      );
    }

    return text;
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
          Text(message),
          behavior:
          SnackBarBehavior.floating,
          backgroundColor:
          isError
              ? Colors.red.shade700
              : const Color(
            0xFF166534,
          ),
        ),
      );
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
  });
}

// ============================================================
// Jalali Calendar Dialog
// ساخته‌شده با shamsi_date
// ============================================================

class _JalaliCalendarDialog
    extends StatefulWidget {
  final Jalali initialDate;

  const _JalaliCalendarDialog({
    required this.initialDate,
  });

  @override
  State<_JalaliCalendarDialog>
  createState() =>
      _JalaliCalendarDialogState();
}

class _JalaliCalendarDialogState
    extends State<_JalaliCalendarDialog> {
  late int _year;
  late int _month;

  Jalali? _selectedDate;

  @override
  void initState() {
    super.initState();

    _year =
        widget.initialDate.year;

    _month =
        widget.initialDate.month;

    _selectedDate =
        widget.initialDate;
  }

  void _previousMonth() {
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }

      _selectedDate = null;
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }

      _selectedDate = null;
    });
  }

  void _previousYear() {
    setState(() {
      _year--;
      _selectedDate = null;
    });
  }

  void _nextYear() {
    setState(() {
      _year++;
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth =
    Jalali(
      _year,
      _month,
      1,
    );

    final monthLength =
        currentMonth.monthLength;

    final firstWeekDay =
        currentMonth.weekDay;

    final leadingEmpty =
        firstWeekDay - 1;

    final totalCells =
        leadingEmpty +
            monthLength;

    final rows =
    (totalCells / 7).ceil();

    final monthName =
    _monthName(_month);

    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: Dialog(
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(24),
        ),
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 430,
          ),
          child: Padding(
            padding:
            const EdgeInsets.all(18),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                _buildHeader(
                  monthName,
                ),
                const SizedBox(
                  height: 16,
                ),
                _buildWeekDays(),
                const SizedBox(
                  height: 8,
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  itemCount:
                  rows * 7,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                  ),
                  itemBuilder:
                      (context, index) {
                    final day =
                        index -
                            leadingEmpty +
                            1;

                    if (day < 1 ||
                        day >
                            monthLength) {
                      return const SizedBox();
                    }

                    final date =
                    Jalali(
                      _year,
                      _month,
                      day,
                    );

                    final selected =
                        _selectedDate !=
                            null &&
                            _selectedDate!
                                .year ==
                                date.year &&
                            _selectedDate!
                                .month ==
                                date.month &&
                            _selectedDate!
                                .day ==
                                date.day;

                    final today =
                    Jalali.now();

                    final isToday =
                        today.year ==
                            date.year &&
                            today.month ==
                                date.month &&
                            today.day ==
                                date.day;

                    return _dayButton(
                      date,
                      selected,
                      isToday,
                    );
                  },
                ),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(
                            context,
                          ),
                      child:
                      const Text(
                        'انصراف',
                      ),
                    ),
                    const Spacer(),
                    if (_selectedDate !=
                        null)
                      FilledButton(
                        onPressed: () =>
                            Navigator.pop(
                              context,
                              _selectedDate,
                            ),
                        child:
                        const Text(
                          'انتخاب تاریخ',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      String monthName,
      ) {
    return Row(
      children: [
        IconButton(
          tooltip:
          'سال قبل',
          onPressed:
          _previousYear,
          icon:
          const Icon(
            Icons.keyboard_double_arrow_right,
          ),
        ),
        IconButton(
          tooltip:
          'ماه قبل',
          onPressed:
          _previousMonth,
          icon:
          const Icon(
            Icons.chevron_right,
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                monthName,
                style:
                const TextStyle(
                  fontSize: 17,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                _toPersianDigits(
                  _year.toString(),
                ),
                style:
                const TextStyle(
                  fontSize: 13,
                  color:
                  Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip:
          'ماه بعد',
          onPressed:
          _nextMonth,
          icon:
          const Icon(
            Icons.chevron_left,
          ),
        ),
        IconButton(
          tooltip:
          'سال بعد',
          onPressed:
          _nextYear,
          icon:
          const Icon(
            Icons.keyboard_double_arrow_left,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDays() {
    const days = [
      'شنبه',
      'یکشنبه',
      'دوشنبه',
      'سه‌شنبه',
      'چهارشنبه',
      'پنجشنبه',
      'جمعه',
    ];

    return Row(
      children:
      days.map(
            (day) {
          return Expanded(
            child: Center(
              child: Text(
                day.substring(
                  0,
                  day.length > 3
                      ? 3
                      : day.length,
                ),
                style:
                const TextStyle(
                  fontSize: 10,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(0xFF6B7280),
                ),
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _dayButton(
      Jalali date,
      bool selected,
      bool isToday,
      ) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      child: Container(
        decoration:
        BoxDecoration(
          color: selected
              ? const Color(
            0xFF177A59,
          )
              : isToday
              ? const Color(
            0xFFEAF5F0,
          )
              : Colors.transparent,
          borderRadius:
          BorderRadius.circular(
            10,
          ),
          border: isToday &&
              !selected
              ? Border.all(
            color:
            const Color(
              0xFF177A59,
            ),
          )
              : null,
        ),
        alignment:
        Alignment.center,
        child: Text(
          _toPersianDigits(
            date.day.toString(),
          ),
          style: TextStyle(
            fontSize: 13,
            fontWeight:
            selected ||
                isToday
                ? FontWeight.w800
                : FontWeight.w500,
            color: selected
                ? Colors.white
                : const Color(
              0xFF111827,
            ),
          ),
        ),
      ),
    );
  }

  String _monthName(
      int month,
      ) {
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

    return months[month - 1];
  }

  String _toPersianDigits(
      String value,
      ) {
    const english =
        '0123456789';

    const persian =
        '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(
        english[i],
        persian[i],
      );
    }

    return result;
  }
}