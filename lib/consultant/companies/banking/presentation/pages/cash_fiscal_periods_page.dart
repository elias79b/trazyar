import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';
import 'cash_monthly_entry_page.dart';

class CashFiscalPeriodsPage extends StatefulWidget {
  final String companyId;

  const CashFiscalPeriodsPage({super.key, required this.companyId});

  @override
  State<CashFiscalPeriodsPage> createState() => _CashFiscalPeriodsPageState();
}

class _CashFiscalPeriodsPageState extends State<CashFiscalPeriodsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _loading = true;
  bool _creating = false;

  List<Map<String, dynamic>> _years = [];

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  Future<void> _loadYears() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final response = await _supabase
          .from('cash_fiscal_years')
          .select('id, company_id, year, title, status, created_at')
          .eq('company_id', widget.companyId)
          .order('year', ascending: false);

      final years =
          (response as List)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

      if (!mounted) return;

      setState(() {
        _years = years;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showError(_cleanError(e));
    }
  }

  Future<void> _createFiscalYear() async {
    if (_creating) return;

    final controller = TextEditingController(text: '1405');

    final year = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'ایجاد سال مالی',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            content: SizedBox(
              width: 380,
              child: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'سال مالی',
                  hintText: 'مثلاً ۱۴۰۵',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                onPressed: () {
                  final value = int.tryParse(controller.text.trim());

                  if (value == null) return;

                  Navigator.of(dialogContext).pop(value);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff126044),
                  foregroundColor: Colors.white,
                ),
                child: const Text('ایجاد'),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (year == null) return;

    if (year < 1300 || year > 1600) {
      _showError('سال مالی باید بین ۱۳۰۰ تا ۱۶۰۰ باشد.');
      return;
    }

    setState(() => _creating = true);

    try {
      await _supabase.rpc(
        'create_cash_fiscal_year',
        params: {
          'p_company_id': widget.companyId,
          'p_year': year,
          'p_created_by': _supabase.auth.currentUser?.id,
        },
      );

      await _loadYears();

      if (!mounted) return;

      _showSuccess('سال مالی $year با موفقیت ایجاد شد.');
    } catch (e) {
      if (!mounted) return;

      _showError(_cleanError(e));
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadPeriods(String fiscalYearId) async {
    final response = await _supabase
        .from('cash_fiscal_periods')
        .select('id, fiscal_year_id, company_id, year, month, title, status')
        .eq('company_id', widget.companyId)
        .eq('fiscal_year_id', fiscalYearId)
        .order('month');

    return (response as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  void _openPeriod(Map<String, dynamic> period) {
    final periodId = period['id']?.toString();

    if (periodId == null || periodId.isEmpty) {
      _showError('شناسه دوره مالی معتبر نیست.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => CashMonthlyEntryPage(
              companyId: widget.companyId,
              periodId: periodId,
            ),
      ),
    );
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

    if (month < 1 || month > 12) {
      return 'ماه $month';
    }

    return months[month - 1];
  }

  String _statusTitle(String? status) {
    if (status == 'open') return 'باز';
    if (status == 'closed') return 'بسته';
    return status ?? 'نامشخص';
  }

  Color _statusColor(String? status) {
    if (status == 'open') {
      return const Color(0xff16834f);
    }

    if (status == 'closed') {
      return Colors.red.shade700;
    }

    return Colors.grey.shade700;
  }

  Color _statusBackground(String? status) {
    if (status == 'open') {
      return const Color(0xffe5f5ec);
    }

    if (status == 'closed') {
      return const Color(0xffffeeee);
    }

    return const Color(0xfff1f3f2);
  }

  @override
  Widget build(BuildContext context) {
    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute:
          '/consultant/companies/${widget.companyId}/banking/fiscal-periods',
      title: 'دوره‌های مالی',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildPage(),
      ),
    );
  }

  Widget _buildPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final horizontalPadding = width < 700 ? 14.0 : 28.0;

        return SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(width),
                  const SizedBox(height: 20),
                  if (_years.isEmpty)
                    _buildEmpty()
                  else
                    ..._years.map(
                      (year) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _FiscalYearCard(
                          year: year,
                          onLoadPeriods: () {
                            return _loadPeriods(year['id'].toString());
                          },
                          onOpenPeriod: _openPeriod,
                          monthName: _monthName,
                          statusTitle: _statusTitle,
                          statusColor: _statusColor,
                          statusBackground: _statusBackground,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(double width) {
    final compact = width < 700;

    final title = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xffdceee5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: Color(0xff14533d),
            size: 29,
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'دوره‌های مالی',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 5),
              Text(
                'مدیریت سال‌های مالی و ثبت اطلاعات ماهانه',
                style: TextStyle(color: Color(0xff68736e), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );

    final button = SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: _creating ? null : _createFiscalYear,
        icon:
            _creating
                ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.add_rounded),
        label: const Text('ایجاد سال مالی'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff126044),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 17 : 22),
      decoration: BoxDecoration(
        color: const Color(0xfff4f9f6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffdfeae5)),
      ),
      child:
          compact
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [title, const SizedBox(height: 16), button],
              )
              : Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 20),
                  button,
                ],
              ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 70),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe4ebe7)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 58,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 15),
          const Text(
            'هنوز سال مالی ایجاد نشده است.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            'برای شروع یک سال مالی ایجاد کنید.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.contains('23505')) {
      return 'این سال مالی قبلاً ایجاد شده است.';
    }

    if (text.contains('permission denied')) {
      return 'دسترسی لازم برای انجام این عملیات وجود ندارد.';
    }

    if (text.contains('23514')) {
      return 'مقدار وضعیت سال مالی با ساختار دیتابیس سازگار نیست.';
    }

    return text.replaceFirst('Exception: ', '');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xff176044),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _FiscalYearCard extends StatefulWidget {
  final Map<String, dynamic> year;

  final Future<List<Map<String, dynamic>>> Function() onLoadPeriods;

  final void Function(Map<String, dynamic>) onOpenPeriod;

  final String Function(int) monthName;

  final String Function(String?) statusTitle;

  final Color Function(String?) statusColor;

  final Color Function(String?) statusBackground;

  const _FiscalYearCard({
    required this.year,
    required this.onLoadPeriods,
    required this.onOpenPeriod,
    required this.monthName,
    required this.statusTitle,
    required this.statusColor,
    required this.statusBackground,
  });

  @override
  State<_FiscalYearCard> createState() => _FiscalYearCardState();
}

class _FiscalYearCardState extends State<_FiscalYearCard> {
  bool _expanded = false;
  bool _loading = false;

  List<Map<String, dynamic>> _periods = [];

  Future<void> _toggle() async {
    if (_expanded) {
      setState(() {
        _expanded = false;
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final periods = await widget.onLoadPeriods();

      if (!mounted) return;

      setState(() {
        _periods = periods;
        _expanded = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = widget.year['year']?.toString() ?? '';
    final title = widget.year['title']?.toString() ?? 'سال مالی $year';

    final status = widget.year['status']?.toString();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe3eae6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 600;

                    final information = _yearInformation(title, year, status);

                    final action = _yearAction();

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          information,
                          const SizedBox(height: 14),
                          Align(alignment: Alignment.centerLeft, child: action),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: information),
                        const SizedBox(width: 16),
                        action,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(
              height: 1,
              color: Colors.grey.shade200,
              indent: 18,
              endIndent: 18,
            ),
            Padding(padding: const EdgeInsets.all(16), child: _buildPeriods()),
          ],
        ],
      ),
    );
  }

  Widget _yearInformation(String title, String year, String? status) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xffe6f3ec),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.event_note_rounded, color: Color(0xff176044)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'سال $year',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: widget.statusBackground(status),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  widget.statusTitle(status),
                  style: TextStyle(
                    color: widget.statusColor(status),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _yearAction() {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xfff3f7f5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_loading)
            const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              _expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: const Color(0xff176044),
            ),
          const SizedBox(width: 6),
          Text(
            _expanded ? 'بستن دوره‌ها' : 'نمایش ۱۲ دوره',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriods() {
    if (_periods.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xfffafcfb),
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Center(
          child: Text('دوره‌ای برای این سال مالی وجود ندارد.'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;

        if (width >= 1000) {
          columns = 4;
        } else if (width >= 700) {
          columns = 3;
        } else if (width >= 450) {
          columns = 2;
        } else {
          columns = 1;
        }

        final itemWidth = (width - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final period in _periods)
              SizedBox(width: itemWidth, child: _periodCard(period)),
          ],
        );
      },
    );
  }

  Widget _periodCard(Map<String, dynamic> period) {
    final month = int.tryParse(period['month']?.toString() ?? '') ?? 0;

    final dbTitle = period['title']?.toString().trim() ?? '';

    final title = dbTitle.isNotEmpty ? dbTitle : widget.monthName(month);

    final status = period['status']?.toString();

    final isOpen = status == 'open';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onOpenPeriod(period),
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 82),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xfffafcfb),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xffe2ebe6)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xffe4f2eb),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    month.toString(),
                    style: const TextStyle(
                      color: Color(0xff176044),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOpen ? 'آماده ثبت اطلاعات' : 'دوره بسته شده',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            isOpen
                                ? const Color(0xff16834f)
                                : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 13,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
