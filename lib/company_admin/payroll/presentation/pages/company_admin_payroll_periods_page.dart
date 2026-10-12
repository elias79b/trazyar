import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tarazyar/company_admin/dashboard/presentation/widgets/company_admin_scaffold.dart';

import '../../application/company_admin_payroll_periods_provider.dart';

class CompanyAdminPayrollPeriodsPage
    extends ConsumerStatefulWidget {
  const CompanyAdminPayrollPeriodsPage({
    super.key,
  });

  @override
  ConsumerState<CompanyAdminPayrollPeriodsPage>
  createState() =>
      _CompanyAdminPayrollPeriodsPageState();
}

class _CompanyAdminPayrollPeriodsPageState
    extends ConsumerState<
        CompanyAdminPayrollPeriodsPage> {
  int? selectedYear;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      companyAdminPayrollPeriodsProvider,
    );

    return state.when(
      loading: () {
        return const CompanyAdminScaffold(
          child: Scaffold(
            backgroundColor:
            Color(0xfff5f7fb),
            body: Center(
              child:
              CircularProgressIndicator(),
            ),
          ),
        );
      },
      error: (error, stackTrace) {
        return CompanyAdminScaffold(
          child: Scaffold(
            backgroundColor:
            const Color(0xfff5f7fb),
            body: Center(
              child: _ErrorState(
                error: error,
              ),
            ),
          ),
        );
      },
      data: (data) {
        return CompanyAdminScaffold(
          child: _buildContent(
            context,
            data,
          ),
        );
      },
    );
  }

  Widget _buildContent(
      BuildContext context,
      CompanyAdminPayrollPeriodsData data,
      ) {
    final years = data.years;

    if (selectedYear == null) {
      selectedYear =
          data.currentJalaliYear;
    }

    if (!years.contains(selectedYear)) {
      selectedYear =
      years.isNotEmpty
          ? years.first
          : data.currentJalaliYear;
    }

    final currentYear =
        selectedYear ??
            data.currentJalaliYear;

    final months =
    data.monthItemsForYear(
      currentYear,
    );

    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        const Color(0xfff5f7fb),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                companyAdminPayrollPeriodsProvider,
              );

              await ref.read(
                companyAdminPayrollPeriodsProvider
                    .future,
              );
            },
            child: SingleChildScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding:
              const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    data: data,
                    selectedYear:
                    currentYear,
                  ),

                  const SizedBox(height: 18),

                  _SummaryCards(
                    data: data,
                    months: months,
                  ),

                  const SizedBox(height: 20),

                  _YearSelector(
                    years: years,
                    selectedYear:
                    currentYear,
                    onChanged: (year) {
                      setState(() {
                        selectedYear =
                            year;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  _MonthsSection(
                    year: currentYear,
                    months: months,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class _Header extends StatelessWidget {
  final CompanyAdminPayrollPeriodsData data;
  final int selectedYear;

  const _Header({
    required this.data,
    required this.selectedYear,
  });

  @override
  Widget build(BuildContext context) {
    final pendingCount = data.periods
        .where(
          (e) =>
      e.periodYear ==
          selectedYear &&
          e.isPendingCeo,
    )
        .length;

    return Container(
      padding:
      const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xffe5e7eb),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(.035),
            blurRadius: 16,
            offset:
            const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration:
            BoxDecoration(
              color:
              const Color(0xffeef6ff),
              borderRadius:
              BorderRadius.circular(
                16,
              ),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color:
              Color(0xff1677d2),
              size: 31,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'دوره‌های حقوق و دستمزد',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'سال ${_persianNumber(selectedYear.toString())} • نمایش کامل دوره‌های ماهانه',
                  style:
                  const TextStyle(
                    fontSize: 13,
                    color:
                    Color(0xff6b7280),
                  ),
                ),
              ],
            ),
          ),
          if (pendingCount > 0)
            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(0xfffff7ed),
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color:
                  const Color(0xffffd7aa),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .notification_important_outlined,
                    size: 19,
                    color:
                    Color(0xffea580c),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${_number(pendingCount)} دوره در انتظار بررسی',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.w700,
                      fontSize: 12,
                      color:
                      Color(0xffc2410c),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// SUMMARY
// ============================================================

class _SummaryCards extends StatelessWidget {
  final CompanyAdminPayrollPeriodsData data;
  final List<CompanyAdminPayrollMonthItem>
  months;

  const _SummaryCards({
    required this.data,
    required this.months,
  });

  @override
  Widget build(BuildContext context) {
    final created =
        months.where(
              (e) => !e.isMissing,
        ).length;

    final missing =
        months.where(
              (e) => e.isMissing,
        ).length;

    final pending =
        months.where(
              (e) => e.isPendingCeo,
        ).length;

    final approved =
        months.where(
              (e) =>
          e.period?.isCeoApproved ??
              false,
        ).length;

    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        final width =
            constraints.maxWidth;

        final cardWidth =
        width >= 1100
            ? (width - 48) / 4
            : width >= 700
            ? (width - 16) / 2
            : width;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _SummaryCard(
              width: cardWidth,
              title:
              'کل ماه‌های سال',
              value: '۱۲',
              icon:
              Icons.calendar_month_outlined,
              color:
              const Color(0xff2563eb),
            ),
            _SummaryCard(
              width: cardWidth,
              title:
              'دوره‌های ثبت‌شده',
              value:
              _number(created),
              icon:
              Icons.fact_check_outlined,
              color:
              const Color(0xff059669),
            ),
            _SummaryCard(
              width: cardWidth,
              title:
              'در انتظار مدیرعامل',
              value:
              _number(pending),
              icon:
              Icons.pending_actions_outlined,
              color:
              const Color(0xffea580c),
            ),
            _SummaryCard(
              width: cardWidth,
              title:
              'دوره‌های بدون ثبت',
              value:
              _number(missing),
              icon:
              Icons
                  .event_busy_outlined,
              color:
              const Color(0xff64748b),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard
    extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding:
        const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color:
            const Color(0xffe5e7eb),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration:
              BoxDecoration(
                color:
                color.withOpacity(.10),
                borderRadius:
                BorderRadius.circular(
                  13,
                ),
              ),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                    TextStyle(
                      fontSize: 12,
                      color: Colors
                          .grey
                          .shade600,
                    ),
                  ),
                  const SizedBox(
                      height: 5),
                  Text(
                    value,
                    style:
                    const TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// YEAR SELECTOR
// ============================================================

class _YearSelector
    extends StatelessWidget {
  final List<int> years;
  final int selectedYear;
  final ValueChanged<int> onChanged;

  const _YearSelector({
    required this.years,
    required this.selectedYear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final visibleYears =
    years.isEmpty
        ? [selectedYear]
        : years;

    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
          const Color(0xffe5e7eb),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
            BoxDecoration(
              color:
              const Color(0xffeff6ff),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color:
              Color(0xff2563eb),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'سال مالی / حقوق',
            style:
            TextStyle(
              fontWeight:
              FontWeight.w800,
            ),
          ),
          const Spacer(),
          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            decoration:
            BoxDecoration(
              color:
              const Color(0xfff8fafc),
              borderRadius:
              BorderRadius.circular(
                10,
              ),
              border: Border.all(
                color:
                const Color(0xffe2e8f0),
              ),
            ),
            child:
            DropdownButtonHideUnderline(
              child:
              DropdownButton<int>(
                value:
                visibleYears.contains(
                  selectedYear,
                )
                    ? selectedYear
                    : visibleYears.first,
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
                items:
                visibleYears.map(
                      (year) {
                    return DropdownMenuItem<
                        int>(
                      value: year,
                      child: Padding(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 8,
                        ),
                        child: Text(
                          _persianNumber(
                            year.toString(),
                          ),
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
                onChanged:
                    (year) {
                  if (year != null) {
                    onChanged(year);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MONTHS
// ============================================================

class _MonthsSection
    extends StatelessWidget {
  final int year;
  final List<CompanyAdminPayrollMonthItem>
  months;

  const _MonthsSection({
    required this.year,
    required this.months,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
          const Color(0xffe5e7eb),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'دوره‌های سال',
                  style:
                  TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(0xffeff6ff),
                  borderRadius:
                  BorderRadius.circular(
                    9,
                  ),
                ),
                child: Text(
                  _persianNumber(
                    year.toString(),
                  ),
                  style:
                  const TextStyle(
                    color:
                    Color(0xff2563eb),
                    fontWeight:
                    FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (
                context,
                constraints,
                ) {
              final columns =
              constraints.maxWidth >=
                  1200
                  ? 4
                  : constraints.maxWidth >=
                  800
                  ? 3
                  : constraints
                  .maxWidth >=
                  500
                  ? 2
                  : 1;

              const spacing = 14.0;

              final itemWidth =
                  (constraints.maxWidth -
                      ((columns - 1) *
                          spacing)) /
                      columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children:
                months.map(
                      (month) {
                    return SizedBox(
                      width: itemWidth,
                      child:
                      _MonthCard(
                        item: month,
                      ),
                    );
                  },
                ).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MONTH CARD
// ============================================================

class _MonthCard
    extends StatelessWidget {
  final CompanyAdminPayrollMonthItem
  item;

  const _MonthCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final period = item.period;

    final pending =
        item.isPendingCeo;

    final missing =
        item.isMissing;

    final statusColor =
    missing
        ? const Color(0xff94a3b8)
        : _statusColor(
      period!.status,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        onTap: missing
            ? null
            : () {
          context.go(
            '/company-admin/payroll/periods/${period!.id}',
          );
        },
        child: AnimatedContainer(
          duration:
          const Duration(
            milliseconds: 180,
          ),
          padding:
          const EdgeInsets.all(16),
          decoration:
          BoxDecoration(
            color: pending
                ? const Color(0xfffffbeb)
                : missing
                ? const Color(0xfff8fafc)
                : Colors.white,
            borderRadius:
            BorderRadius.circular(
              16,
            ),
            border: Border.all(
              color: pending
                  ? const Color(0xfff59e0b)
                  : missing
                  ? const Color(
                0xffe2e8f0,
              )
                  : const Color(
                0xffe5e7eb,
              ),
              width:
              pending ? 1.5 : 1,
            ),
            boxShadow: pending
                ? [
              BoxShadow(
                color:
                const Color(
                  0xfff59e0b,
                ).withOpacity(.10),
                blurRadius: 12,
                offset:
                const Offset(
                  0,
                  4,
                ),
              ),
            ]
                : null,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration:
                    BoxDecoration(
                      color: pending
                          ? const Color(
                        0xffffedd5,
                      )
                          : missing
                          ? const Color(
                        0xfff1f5f9,
                      )
                          : const Color(
                        0xffeff6ff,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Icon(
                      missing
                          ? Icons
                          .event_busy_outlined
                          : Icons
                          .calendar_month_outlined,
                      color: pending
                          ? const Color(
                        0xffea580c,
                      )
                          : missing
                          ? const Color(
                        0xff64748b,
                      )
                          : const Color(
                        0xff2563eb,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.monthName,
                          style:
                          const TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          _persianNumber(
                            item.year
                                .toString(),
                          ),
                          style:
                          TextStyle(
                            fontSize: 11,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pending)
                    const Icon(
                      Icons
                          .priority_high_rounded,
                      color:
                      Color(0xffea580c),
                      size: 21,
                    ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                decoration:
                BoxDecoration(
                  color:
                  statusColor.withOpacity(
                    .08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                      BoxDecoration(
                        color: statusColor,
                        shape:
                        BoxShape.circle,
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Text(
                        item.statusTitle,
                        style:
                        TextStyle(
                          color:
                          statusColor,
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.statusDescription,
                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,
                style:
                TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color:
                  Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      missing
                          ? 'منتظر ایجاد دوره'
                          : 'مشاهده جزئیات',
                      style:
                      TextStyle(
                        fontSize: 11,
                        color: missing
                            ? const Color(
                          0xff64748b,
                        )
                            : pending
                            ? const Color(
                          0xffea580c,
                        )
                            : const Color(
                          0xff2563eb,
                        ),
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!missing)
                    Icon(
                      Icons
                          .arrow_back_ios_new_rounded,
                      size: 13,
                      color: pending
                          ? const Color(
                        0xffea580c,
                      )
                          : const Color(
                        0xff2563eb,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _ErrorState
    extends StatelessWidget {
  final Object error;

  const _ErrorState({
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
      const BoxConstraints(
        maxWidth: 600,
      ),
      padding:
      const EdgeInsets.all(28),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
          const Color(0xfffecaca),
        ),
      ),
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color:
            Color(0xffdc2626),
            size: 52,
          ),
          const SizedBox(height: 15),
          const Text(
            'خطا در دریافت دوره‌های حقوق',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              fontWeight:
              FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            error.toString(),
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              color:
              Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

Color _statusColor(
    String status,
    ) {
  switch (status) {
    case 'draft':
      return const Color(0xff64748b);

    case 'pending_ceo':
      return const Color(0xffea580c);

    case 'ceo_approved':
      return const Color(0xff2563eb);

    case 'pending_consultant':
      return const Color(0xff7c3aed);

    case 'consultant_approved':
      return const Color(0xff059669);

    case 'rejected':
      return const Color(0xffdc2626);

    case 'paid':
      return const Color(0xff0891b2);

    case 'cancelled':
      return const Color(0xff64748b);

    default:
      return const Color(0xff64748b);
  }
}

String _number(
    int value,
    ) {
  return _persianNumber(
    value.toString(),
  );
}

String _persianNumber(
    String value,
    ) {
  return value
      .replaceAll('0', '۰')
      .replaceAll('1', '۱')
      .replaceAll('2', '۲')
      .replaceAll('3', '۳')
      .replaceAll('4', '۴')
      .replaceAll('5', '۵')
      .replaceAll('6', '۶')
      .replaceAll('7', '۷')
      .replaceAll('8', '۸')
      .replaceAll('9', '۹');
}