import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';
import 'package:tarazyar/company_admin/income/application/company_admin_income_fiscal_periods_provider.dart';

class CompanyAdminIncomeFiscalPeriodsPage extends ConsumerStatefulWidget {
  const CompanyAdminIncomeFiscalPeriodsPage({super.key});

  @override
  ConsumerState<CompanyAdminIncomeFiscalPeriodsPage> createState() =>
      _CompanyAdminIncomeFiscalPeriodsPageState();
}

class _CompanyAdminIncomeFiscalPeriodsPageState
    extends ConsumerState<CompanyAdminIncomeFiscalPeriodsPage> {
  static const Color _green = Color(0xFF168052);
  static const Color _background = Color(0xFFF5F8F6);
  static const Color _border = Color(0xFFE3EAE5);
  static const Color _text = Color(0xFF24312B);
  static const Color _muted = Color(0xFF748078);

  String? _selectedYearId;
  String _statusFilter = 'all';

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

  static const List<_StatusFilter> _filters = [
    _StatusFilter(value: 'all', label: 'همه', icon: Icons.grid_view_rounded),
    _StatusFilter(value: 'open', label: 'باز', icon: Icons.edit_calendar_outlined),
    _StatusFilter(
      value: 'submitted_to_company_admin',
      label: 'در انتظار من',
      icon: Icons.pending_actions_rounded,
    ),
    _StatusFilter(
      value: 'submitted_to_consultant',
      label: 'نزد مشاور',
      icon: Icons.outgoing_mail,
    ),
    _StatusFilter(
      value: 'approved',
      label: 'تأییدشده',
      icon: Icons.verified_outlined,
    ),
    _StatusFilter(
      value: 'closed',
      label: 'بسته',
      icon: Icons.lock_outline_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(
          () => ref.read(companyAdminIncomeFiscalPeriodsProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyAdminIncomeFiscalPeriodsProvider);

    final selectedYear = state.years
        .where((year) => year.id == _selectedYearId)
        .firstOrNull;

    final yearPeriods = selectedYear == null
        ? state.periods
        : state.periods
        .where((period) => period.fiscalYearId == selectedYear.id)
        .toList();

    final filteredPeriods = _statusFilter == 'all'
        ? yearPeriods
        : yearPeriods
        .where((period) => period.status == _statusFilter)
        .toList();

    final sortedPeriods = [...filteredPeriods]
      ..sort((a, b) {
        final yearCompare = b.year.compareTo(a.year);
        if (yearCompare != 0) return yearCompare;
        return b.month.compareTo(a.month);
      });

    return CompanyAdminScaffold(
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(companyAdminIncomeFiscalPeriodsProvider.notifier)
                .load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
              children: [
                _header(),
                const SizedBox(height: 22),
                if (state.loading)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: CircularProgressIndicator(color: _green),
                    ),
                  )
                else if (state.error != null)
                  _errorCard(state.error!)
                else ...[
                    _overview(state),
                    const SizedBox(height: 20),
                    _yearSelector(state),
                    if (selectedYear != null) ...[
                      const SizedBox(height: 14),
                      _selectedYearPanel(selectedYear),
                    ],
                    const SizedBox(height: 22),
                    _workflowGuide(),
                    const SizedBox(height: 20),
                    _periodSectionHeader(sortedPeriods.length),
                    const SizedBox(height: 12),
                    _filterBar(yearPeriods),
                    const SizedBox(height: 14),
                    if (sortedPeriods.isEmpty)
                      _emptyPeriods(selectedYear)
                    else
                      ...sortedPeriods.map(_periodCard),
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
        final compact = constraints.maxWidth < 600;
        final titleBlock = const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'درآمد  /  دوره‌های درآمد',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
            SizedBox(height: 8),
            Text(
              'مدیریت دوره‌های درآمد',
              style: TextStyle(
                fontSize: 25,
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: _text,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'وضعیت دوره‌ها را پیگیری و موارد نیازمند اقدام را بررسی کنید.',
              style: TextStyle(fontSize: 13, height: 1.7, color: _muted),
            ),
          ],
        );

        final createButton = FilledButton.icon(
          onPressed: () => _showYearDialog(initialYear: Jalali.now().year),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('ایجاد سال مالی'),
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerRight, child: createButton),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 18),
            createButton,
          ],
        );
      },
    );
  }

  Widget _overview(IncomeFiscalPeriodsState state) {
    final openYears = state.years.where((year) => year.status == 'open').length;
    final openPeriods =
        state.periods.where((period) => period.status == 'open').length;
    final waitingAdmin = state.periods
        .where((period) => period.status == 'submitted_to_company_admin')
        .length;
    final waitingConsultant = state.periods
        .where((period) => period.status == 'submitted_to_consultant')
        .length;
    final approved =
        state.periods.where((period) => period.status == 'approved').length;
    final closed =
        state.periods.where((period) => period.status == 'closed').length;

    final cards = [
      _SummaryItem(
        title: 'سال‌های مالی باز',
        value: '$openYears',
        helper: 'سال قابل استفاده',
        icon: Icons.calendar_month_rounded,
        color: _green,
      ),
      _SummaryItem(
        title: 'نیازمند بررسی مدیرعامل',
        value: '$waitingAdmin',
        helper: waitingAdmin > 0 ? 'نیازمند اقدام شما' : 'موردی در صف نیست',
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFB66A13),
        emphasized: waitingAdmin > 0,
      ),
      _SummaryItem(
        title: 'در انتظار مشاور',
        value: '$waitingConsultant',
        helper: 'ارسال‌شده برای بررسی',
        icon: Icons.outgoing_mail,
        color: const Color(0xFF2878D0),
      ),
      _SummaryItem(
        title: 'دوره‌های باز',
        value: '$openPeriods',
        helper: 'در حال تکمیل اطلاعات',
        icon: Icons.edit_calendar_outlined,
        color: const Color(0xFF168E9B),
      ),
      _SummaryItem(
        title: 'تأییدشده',
        value: '$approved',
        helper: 'تأیید نهایی',
        icon: Icons.verified_outlined,
        color: const Color(0xFF23845A),
      ),
      _SummaryItem(
        title: 'بسته‌شده',
        value: '$closed',
        helper: 'غیرقابل ویرایش',
        icon: Icons.lock_outline_rounded,
        color: const Color(0xFF7651C9),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100 ? 3 : width >= 650 ? 2 : 1;

        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 126,
          ),
          itemBuilder: (context, index) => _summaryCard(cards[index]),
        );
      },
    );
  }

  Widget _summaryCard(_SummaryItem item) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: item.emphasized ? const Color(0xFFFFF8EE) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.emphasized
              ? item.color.withOpacity(.35)
              : _border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.018),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: item.color.withOpacity(.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(item.icon, color: item.color, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: item.color,
                  ),
                ),
                Text(
                  item.helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _yearSelector(IncomeFiscalPeriodsState state) {
    final years = [...state.years]..sort((a, b) => b.year.compareTo(a.year));
    final hasSelectedYear = years.any((year) => year.id == _selectedYearId);

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'انتخاب سال مالی',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: _text,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'برای مشاهده ماه‌ها و وضعیت‌های همان سال، سال مالی را انتخاب کنید.',
            style: TextStyle(fontSize: 12, height: 1.7, color: _muted),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: hasSelectedYear ? _selectedYearId : null,
            isExpanded: true,
            decoration: _inputDecoration('همه سال‌ها'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('همه سال‌ها'),
              ),
              ...years.map(
                    (year) => DropdownMenuItem<String>(
                  value: year.id,
                  child: Text(
                    '${year.title} (${year.year}) • ${year.status == 'open' ? 'باز' : 'بسته'}',
                  ),
                ),
              ),
            ],
            onChanged: (value) => setState(() {
              _selectedYearId = value;
              _statusFilter = 'all';
            }),
          ),
        ],
      ),
    );
  }

  Widget _selectedYearPanel(IncomeFiscalYear year) {
    final yearPeriods = ref
        .read(companyAdminIncomeFiscalPeriodsProvider)
        .periods
        .where((period) => period.fiscalYearId == year.id)
        .toList();

    final openCount = yearPeriods.where((p) => p.status == 'open').length;
    final pendingCount = yearPeriods
        .where((p) => p.status == 'submitted_to_company_admin')
        .length;
    final consultantCount = yearPeriods
        .where((p) => p.status == 'submitted_to_consultant')
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3E9DA)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                year.title,
                style: const TextStyle(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'سال شمسی ${year.year} • ${year.status == 'open' ? 'باز' : 'بسته'}',
                style: const TextStyle(fontSize: 12, color: _muted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _smallCount('$openCount باز', _green),
                  _smallCount('$pendingCount در انتظار مدیرعامل', const Color(0xFFB66A13)),
                  _smallCount('$consultantCount نزد مشاور', const Color(0xFF2878D0)),
                ],
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showYearDialog(year: year),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('ویرایش سال'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _green,
                  side: const BorderSide(color: Color(0xFFB8D9C5)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: year.status == 'open'
                    ? () => _generateMonths(year)
                    : null,
                icon: const Icon(Icons.calendar_view_month_rounded, size: 18),
                label: const Text('ایجاد ماه‌های سال'),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: 16),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: info),
              const SizedBox(width: 16),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _smallCount(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _workflowGuide() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_tree_outlined, color: _green),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'مسیر گردش کار دوره',
                  style: TextStyle(
                    fontSize: 15,
                    color: _text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'وضعیت دوره از طریق صفحه جزئیات و اقدامات مجاز تغییر می‌کند؛ از تغییر مستقیم وضعیت برای دور زدن مراحل بررسی استفاده نکنید.',
            style: TextStyle(fontSize: 12, height: 1.8, color: _muted),
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _workflowStep('۱', 'باز', _green),
                _workflowArrow(),
                _workflowStep('۲', 'بررسی مدیرعامل', const Color(0xFFB66A13)),
                _workflowArrow(),
                _workflowStep('۳', 'بررسی مشاور', const Color(0xFF2878D0)),
                _workflowArrow(),
                _workflowStep('۴', 'تأیید نهایی', const Color(0xFF23845A)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _workflowStep(String number, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        border: Border.all(color: color.withOpacity(.20)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: color,
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _workflowArrow() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 7),
    child: Icon(
      Icons.arrow_back_rounded,
      size: 17,
      color: Color(0xFF9AA69F),
    ),
  );

  Widget _periodSectionHeader(int count) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'دوره‌های درآمد',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '$count دوره',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterBar(List<IncomeFiscalPeriod> periods) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final selected = _statusFilter == filter.value;
            final count = filter.value == 'all'
                ? periods.length
                : periods.where((p) => p.status == filter.value).length;
            final color = _statusColor(
              filter.value == 'all' ? 'open' : filter.value,
            );

            return Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                selected: selected,
                showCheckmark: false,
                avatar: Icon(
                  filter.icon,
                  size: 17,
                  color: selected ? Colors.white : color,
                ),
                label: Text('${filter.label}  $count'),
                onSelected: (_) => setState(() => _statusFilter = filter.value),
                selectedColor: _green,
                backgroundColor: const Color(0xFFF8FAF8),
                side: BorderSide(
                  color: selected ? _green : _border,
                ),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _text,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _periodCard(IncomeFiscalPeriod period) {
    final color = _statusColor(period.status);
    final label = _statusLabel(period.status);
    final subtitle = _statusHint(period.status);
    final action = _primaryActionLabel(period.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: period.status == 'submitted_to_company_admin'
              ? const Color(0xFFEFD7B5)
              : _border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.018),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openPeriodDetails(period),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 550;

                final icon = Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_statusIcon(period.status), color: color, size: 23),
                );

                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_monthLabel(period.month)} ${period.year}',
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _statusBadge(label, color),
                        if (period.status == 'submitted_to_company_admin')
                          _statusBadge('نیازمند اقدام', const Color(0xFFB66A13)),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.6,
                        color: _muted,
                      ),
                    ),
                  ],
                );

                final button = OutlinedButton.icon(
                  onPressed: () => _openPeriodDetails(period),
                  icon: Icon(
                    period.status == 'submitted_to_company_admin'
                        ? Icons.fact_check_outlined
                        : Icons.open_in_new_rounded,
                    size: 17,
                  ),
                  label: Text(action),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: period.status == 'submitted_to_company_admin'
                        ? const Color(0xFF9A5A0A)
                        : _green,
                    side: BorderSide(
                      color: period.status == 'submitted_to_company_admin'
                          ? const Color(0xFFE6C18F)
                          : const Color(0xFFB8D9C5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          icon,
                          const SizedBox(width: 12),
                          Expanded(child: details),
                          const Icon(
                            Icons.chevron_left_rounded,
                            color: Color(0xFF9AA69F),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      button,
                    ],
                  );
                }

                return Row(
                  children: [
                    icon,
                    const SizedBox(width: 14),
                    Expanded(child: details),
                    const SizedBox(width: 14),
                    button,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _emptyPeriods(IncomeFiscalYear? year) {
    final isFiltered = _statusFilter != 'all';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF6EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              size: 31,
              color: _green,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isFiltered
                ? 'دوره‌ای با این وضعیت پیدا نشد'
                : year == null
                ? 'هنوز دوره درآمدی ثبت نشده است'
                : 'برای این سال هنوز ماهی ایجاد نشده است',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: _text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltered
                ? 'فیلتر دیگری را انتخاب کنید تا دوره‌های بیشتری نمایش داده شوند.'
                : year == null
                ? 'یک سال مالی انتخاب کنید یا سال مالی جدید بسازید.'
                : year.status == 'open'
                ? 'برای ساخت ماه‌های سال، از دکمه «ایجاد ماه‌های سال» استفاده کنید.'
                : 'این سال مالی بسته است و امکان ایجاد ماه جدید ندارد.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.8,
              color: _muted,
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 15),
            OutlinedButton.icon(
              onPressed: () => setState(() => _statusFilter = 'all'),
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('حذف فیلتر وضعیت'),
            ),
          ] else if (year == null &&
              ref.read(companyAdminIncomeFiscalPeriodsProvider).years.isEmpty) ...[
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: () => _showYearDialog(
                initialYear: Jalali.now().year,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('ایجاد اولین سال مالی'),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _errorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2CACA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
          const SizedBox(height: 12),
          const Text(
            'دریافت اطلاعات دوره‌های درآمد ناموفق بود',
            style: TextStyle(fontWeight: FontWeight.w800, color: _text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(fontSize: 12, color: _muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => ref
                .read(companyAdminIncomeFiscalPeriodsProvider.notifier)
                .load(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تلاش مجدد'),
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showYearDialog({
    IncomeFiscalYear? year,
    int? initialYear,
  }) async {
    final yearController = TextEditingController(
      text: (year?.year ?? initialYear ?? Jalali.now().year).toString(),
    );
    final titleController = TextEditingController(
      text: year?.title ?? 'سال مالی ${initialYear ?? Jalali.now().year}',
    );
    String status = year?.status ?? 'open';
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(year == null ? 'ایجاد سال مالی' : 'ویرایش سال مالی'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: yearController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('سال شمسی'),
                        validator: (value) {
                          final parsed = int.tryParse(value?.trim() ?? '');
                          if (parsed == null || parsed < 1300 || parsed > 1600) {
                            return 'سال شمسی معتبر بین ۱۳۰۰ تا ۱۶۰۰ وارد کنید';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          final parsed = int.tryParse(value);
                          if (parsed != null && year == null) {
                            titleController.text = 'سال مالی $parsed';
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: titleController,
                        decoration: _inputDecoration('عنوان سال مالی'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'عنوان را وارد کنید';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: _inputDecoration('وضعیت سال مالی'),
                        items: const [
                          DropdownMenuItem(value: 'open', child: Text('باز')),
                          DropdownMenuItem(value: 'closed', child: Text('بسته')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => status = value);
                          }
                        },
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
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final parsedYear = int.parse(yearController.text.trim());

                    try {
                      await ref
                          .read(companyAdminIncomeFiscalPeriodsProvider.notifier)
                          .saveYear(
                        id: year?.id,
                        year: parsedYear,
                        title: titleController.text.trim(),
                        status: status,
                      );

                      if (!mounted) return;
                      setState(() => _selectedYearId = year?.id);
                      Navigator.pop(dialogContext);
                      _showMessage('سال مالی ذخیره شد.');
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('ذخیره ناموفق بود: $e')),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ذخیره'),
                ),
              ],
            );
          },
        );
      },
    );

    yearController.dispose();
    titleController.dispose();
  }

  Future<void> _generateMonths(IncomeFiscalYear year) async {
    try {
      await ref
          .read(companyAdminIncomeFiscalPeriodsProvider.notifier)
          .generateMonths(year);

      if (!mounted) return;
      setState(() {
        _selectedYearId = year.id;
        _statusFilter = 'all';
      });
      _showMessage('ماه‌های ایجادنشده سال مالی اضافه شدند.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('ایجاد ماه‌ها ناموفق بود: $e', error: true);
    }
  }

  void _openPeriodDetails(IncomeFiscalPeriod period) {
    context.push(
      '/company-admin/income/periods/${Uri.encodeComponent(period.id)}',
    );
  }

  String _monthLabel(int month) {
    if (month < 1 || month > 12) return 'ماه $month';
    return _months[month - 1];
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'باز';
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

  String _statusHint(String status) {
    switch (status) {
      case 'open':
        return 'اطلاعات دوره در حال تکمیل است.';
      case 'submitted_to_company_admin':
        return 'دوره برای بررسی شما ارسال شده است.';
      case 'submitted_to_consultant':
        return 'منتظر بررسی مشاور است.';
      case 'approved':
        return 'بررسی نهایی انجام شده است.';
      case 'closed':
        return 'دوره بسته است و از اینجا تغییر وضعیت نمی‌کند.';
      default:
        return 'برای مشاهده جزئیات و تاریخچه وارد دوره شوید.';
    }
  }

  String _primaryActionLabel(String status) {
    switch (status) {
      case 'submitted_to_company_admin':
        return 'بررسی دوره';
      case 'open':
        return 'مشاهده و تکمیل';
      case 'submitted_to_consultant':
        return 'پیگیری بررسی';
      case 'approved':
        return 'مشاهده نتیجه';
      case 'closed':
        return 'مشاهده بایگانی';
      default:
        return 'مشاهده جزئیات';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'open':
        return Icons.edit_calendar_outlined;
      case 'submitted_to_company_admin':
        return Icons.pending_actions_rounded;
      case 'submitted_to_consultant':
        return Icons.outgoing_mail;
      case 'approved':
        return Icons.verified_outlined;
      case 'closed':
        return Icons.lock_outline_rounded;
      default:
        return Icons.calendar_month_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFF168052);
      case 'submitted_to_company_admin':
        return const Color(0xFFB66A13);
      case 'submitted_to_consultant':
        return const Color(0xFF2878D0);
      case 'approved':
        return const Color(0xFF23845A);
      case 'closed':
        return const Color(0xFF7651C9);
      default:
        return _muted;
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFFAFCFA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _green, width: 1.5),
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.015),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
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

class _SummaryItem {
  final String title;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;
  final bool emphasized;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
    this.emphasized = false,
  });
}

class _StatusFilter {
  final String value;
  final String label;
  final IconData icon;

  const _StatusFilter({
    required this.value,
    required this.label,
    required this.icon,
  });
}
