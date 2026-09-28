import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tarazyar/accountant/dashboard/presentation/widgets/accountant_scaffold.dart';
import 'package:tarazyar/accountant/income/application/accountant_income_fiscal_periods_provider.dart';

class AccountantIncomeFiscalPeriodsPage
    extends ConsumerStatefulWidget {
  final String companyId;

  const AccountantIncomeFiscalPeriodsPage({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<AccountantIncomeFiscalPeriodsPage> createState() =>
      _AccountantIncomeFiscalPeriodsPageState();
}

class _AccountantIncomeFiscalPeriodsPageState
    extends ConsumerState<AccountantIncomeFiscalPeriodsPage> {
  String? _selectedYearId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      accountantIncomeFiscalPeriodsProvider(
        widget.companyId,
      ),
    );

    return AccountantScaffold(
      currentRoute: '/accountant/income/periods',
      title: 'دوره‌های مالی درآمد',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => _ErrorView(
            error: error,
            onRetry: () {
              ref.invalidate(
                accountantIncomeFiscalPeriodsProvider(
                  widget.companyId,
                ),
              );
            },
          ),
          data: (data) {
            if (data.years.isEmpty) {
              return _EmptyYearView(
                onCreate: () => _createYear(context),
              );
            }

            final selectedYear =
            _resolveSelectedYear(data);

            if (selectedYear == null) {
              return const Center(
                child: Text(
                  'سال مالی معتبر پیدا نشد.',
                ),
              );
            }

            final periods =
            List<AccountantIncomeFiscalPeriod>.from(
              selectedYear.periods,
            )..sort(
                  (a, b) => a.month.compareTo(b.month),
            );

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(
                  accountantIncomeFiscalPeriodsProvider(
                    widget.companyId,
                  ),
                );

                await ref.read(
                  accountantIncomeFiscalPeriodsProvider(
                    widget.companyId,
                  ).future,
                );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final mobile =
                      constraints.maxWidth < 850;

                  return SingleChildScrollView(
                    physics:
                    const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(
                      mobile ? 16 : 28,
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        _Header(
                          year: selectedYear.year,
                          periodCount: periods.length,
                          onCreateYear: () =>
                              _createYear(context),
                          onCompleteYear:
                          periods.length < 12
                              ? () => _completeYear(
                            context,
                            selectedYear,
                          )
                              : null,
                        ),
                        const SizedBox(height: 18),

                        const _WorkflowLegend(),
                        const SizedBox(height: 18),

                        _Summary(
                          periods: periods,
                          mobile: mobile,
                        ),
                        const SizedBox(height: 18),

                        _YearSelector(
                          years: data.years,
                          selectedYearId:
                          selectedYear.id,
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }

                            setState(() {
                              _selectedYearId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 22),

                        if (periods.length < 12) ...[
                          _IncompleteYearBanner(
                            count: periods.length,
                            onComplete: () =>
                                _completeYear(
                                  context,
                                  selectedYear,
                                ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        _SectionTitle(
                          title:
                          'ماه‌های سال مالی ${selectedYear.year}',
                          subtitle:
                          'ثبت درآمد به‌صورت ماهانه و طی فرآیند تأیید انجام می‌شود.',
                        ),
                        const SizedBox(height: 12),

                        _PeriodsGrid(
                          periods: periods,
                          mobile: mobile,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  AccountantIncomeFiscalYear? _resolveSelectedYear(
      AccountantIncomeFiscalPeriodsData data,
      ) {
    if (_selectedYearId != null) {
      for (final year in data.years) {
        if (year.id == _selectedYearId) {
          return year;
        }
      }
    }

    if (data.selectedYear != null) {
      return data.selectedYear;
    }

    if (data.years.isNotEmpty) {
      return data.years.first;
    }

    return null;
  }

  Future<void> _createYear(
      BuildContext context,
      ) async {
    final controller = TextEditingController();

    final year = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'ایجاد سال مالی درآمد',
            ),
            content: SizedBox(
              width: 420,
              child: TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                TextInputType.number,
                decoration:
                const InputDecoration(
                  labelText: 'سال مالی',
                  hintText: 'مثلاً ۱۴۰۵',
                  prefixIcon: Icon(
                    Icons.calendar_month_rounded,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(
                      dialogContext,
                    ).pop(),
                child:
                const Text('انصراف'),
              ),
              FilledButton.icon(
                onPressed: () {
                  final value = int.tryParse(
                    controller.text.trim(),
                  );

                  if (value == null) {
                    return;
                  }

                  Navigator.of(
                    dialogContext,
                  ).pop(value);
                },
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label:
                const Text('ایجاد سال'),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (year == null) {
      return;
    }

    try {
      await AccountantIncomeFiscalPeriodsRepository
          .createFiscalYear(
        companyId: widget.companyId,
        year: year,
      );

      ref.invalidate(
        accountantIncomeFiscalPeriodsProvider(
          widget.companyId,
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'سال مالی $year با موفقیت ایجاد/تکمیل شد.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(context, e);
    }
  }

  Future<void> _completeYear(
      BuildContext context,
      AccountantIncomeFiscalYear year,
      ) async {
    try {
      await AccountantIncomeFiscalPeriodsRepository
          .ensureMissingPeriods(
        fiscalYearId: year.id,
        companyId: widget.companyId,
        year: year.year,
      );

      ref.invalidate(
        accountantIncomeFiscalPeriodsProvider(
          widget.companyId,
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ماه‌های باقی‌مانده سال مالی ایجاد شدند.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(context, e);
    }
  }

  void _showError(
      BuildContext context,
      Object error,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error
              .toString()
              .replaceFirst(
            'Exception: ',
            '',
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int year;
  final int periodCount;
  final VoidCallback onCreateYear;
  final VoidCallback? onCompleteYear;

  const _Header({
    required this.year,
    required this.periodCount,
    required this.onCreateYear,
    required this.onCompleteYear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary
                .withValues(alpha: .86),
          ],
        ),
        borderRadius:
        BorderRadius.circular(22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 650;

          final title = Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white
                      .withValues(alpha: .14),
                  borderRadius:
                  BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'دوره‌های مالی درآمد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'سال مالی $year • $periodCount از ۱۲ ماه',
                      style: TextStyle(
                        color: Colors.white
                            .withValues(alpha: .82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onCompleteYear != null)
                OutlinedButton.icon(
                  onPressed: onCompleteYear,
                  icon: const Icon(
                    Icons.playlist_add_rounded,
                  ),
                  label: const Text(
                    'تکمیل ۱۲ ماه',
                  ),
                  style:
                  OutlinedButton.styleFrom(
                    foregroundColor:
                    Colors.white,
                    side:
                    const BorderSide(
                      color: Colors.white,
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: onCreateYear,
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label:
                const Text('سال جدید'),
                style:
                FilledButton.styleFrom(
                  backgroundColor:
                  Colors.white,
                  foregroundColor:
                  theme.colorScheme.primary,
                ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                title,
                const SizedBox(height: 18),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              const SizedBox(width: 20),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _WorkflowLegend extends StatelessWidget {
  const _WorkflowLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context)
              .dividerColor
              .withValues(alpha: .45),
        ),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 10,
        children: const [
          _LegendItem(
            color: Color(0xFF198754),
            icon: Icons.edit_rounded,
            title: 'باز و قابل ثبت',
          ),
          _LegendItem(
            color: Color(0xFFF59E0B),
            icon: Icons.forward_to_inbox_rounded,
            title: 'در انتظار مدیرعامل',
          ),
          _LegendItem(
            color: Color(0xFF2563EB),
            icon: Icons.person_search_rounded,
            title: 'در انتظار مشاور',
          ),
          _LegendItem(
            color: Color(0xFF7C3AED),
            icon: Icons.verified_rounded,
            title: 'تأیید نهایی',
          ),
          _LegendItem(
            color: Color(0xFF64748B),
            icon: Icons.lock_rounded,
            title: 'بسته',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize:
      MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(
              alpha: .10,
            ),
            borderRadius:
            BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final List<AccountantIncomeFiscalPeriod>
  periods;
  final bool mobile;

  const _Summary({
    required this.periods,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    final open = periods
        .where(
          (e) => e.status == 'open',
    )
        .length;

    final ceo = periods
        .where(
          (e) =>
      e.status ==
          'submitted_to_company_admin',
    )
        .length;

    final consultant = periods
        .where(
          (e) =>
      e.status ==
          'submitted_to_consultant',
    )
        .length;

    final approved = periods
        .where(
          (e) => e.status == 'approved',
    )
        .length;

    final closed = periods
        .where(
          (e) => e.status == 'closed',
    )
        .length;

    final cards = [
      _SummaryCardData(
        title: 'کل ماه‌ها',
        value: '${periods.length}',
        icon: Icons.calendar_month_rounded,
        color: const Color(0xFF0F766E),
      ),
      _SummaryCardData(
        title: 'قابل ثبت',
        value: '$open',
        icon: Icons.edit_rounded,
        color: const Color(0xFF198754),
      ),
      _SummaryCardData(
        title: 'در انتظار مدیرعامل',
        value: '$ceo',
        icon: Icons.forward_to_inbox_rounded,
        color: const Color(0xFFF59E0B),
      ),
      _SummaryCardData(
        title: 'در انتظار مشاور',
        value: '$consultant',
        icon: Icons.person_search_rounded,
        color: const Color(0xFF2563EB),
      ),
      _SummaryCardData(
        title: 'تأیید نهایی',
        value: '$approved',
        icon: Icons.verified_rounded,
        color: const Color(0xFF7C3AED),
      ),
      _SummaryCardData(
        title: 'بسته',
        value: '$closed',
        icon: Icons.lock_rounded,
        color: const Color(0xFF64748B),
      ),
    ];

    if (mobile) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
            padding:
            const EdgeInsets.only(
              bottom: 10,
            ),
            child: _SummaryCard(
              data: card,
            ),
          ),
        )
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 108,
      ),
      itemBuilder: (context, index) {
        return _SummaryCard(
          data: cards[index],
        );
      },
    );
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;

  const _SummaryCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: data.color.withValues(
            alpha: .16,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.color.withValues(
                alpha: .09,
              ),
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Icon(
              data.icon,
              color: data.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
                const SizedBox(height: 5),
                Text(
                  data.value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                    fontWeight:
                    FontWeight.w800,
                    color: data.color,
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

class _YearSelector extends StatelessWidget {
  final List<AccountantIncomeFiscalYear> years;
  final String selectedYearId;
  final ValueChanged<String?> onChanged;

  const _YearSelector({
    required this.years,
    required this.selectedYearId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedYearId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'سال مالی',
        prefixIcon: const Icon(
          Icons.calendar_today_rounded,
        ),
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surface,
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context)
                .dividerColor
                .withValues(alpha: .5),
          ),
        ),
      ),
      items: years
          .map(
            (year) => DropdownMenuItem<String>(
          value: year.id,
          child: Text(
            'سال مالی ${year.year} — ${year.periods.length} ماه',
          ),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .primary,
            borderRadius:
            BorderRadius.circular(10),
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
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IncompleteYearBanner
    extends StatelessWidget {
  final int count;
  final VoidCallback onComplete;

  const _IncompleteYearBanner({
    required this.count,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF59E0B)
              .withValues(alpha: .25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'این سال مالی $count ماه دارد. برای ساختار کامل سال مالی، ماه‌های باقی‌مانده را ایجاد کنید.',
              style: const TextStyle(
                color: Color(0xFF92400E),
              ),
            ),
          ),
          TextButton(
            onPressed: onComplete,
            child: const Text(
              'تکمیل ۱۲ ماه',
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodsGrid extends StatelessWidget {
  final List<AccountantIncomeFiscalPeriod>
  periods;
  final bool mobile;

  const _PeriodsGrid({
    required this.periods,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      itemCount: periods.length,
      gridDelegate:
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: mobile ? 1 : 3,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 225,
      ),
      itemBuilder: (context, index) {
        return _PeriodCard(
          period: periods[index],
        );
      },
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final AccountantIncomeFiscalPeriod period;

  const _PeriodCard({
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final info = _statusInfo(
      context,
      period.status,
    );

    final isOpen =
        period.status == 'open';

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: info.color.withValues(
            alpha: .24,
          ),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: .025,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                decoration: BoxDecoration(
                  color: info.color.withValues(
                    alpha: .09,
                  ),
                  borderRadius:
                  BorderRadius.circular(13),
                ),
                child: Icon(
                  info.icon,
                  color: info.color,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      period.title,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'سال ${period.year}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: info.color.withValues(
                alpha: .07,
              ),
              borderRadius:
              BorderRadius.circular(11),
            ),
            child: Row(
              children: [
                Icon(
                  info.icon,
                  size: 17,
                  color: info.color,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    info.title,
                    style: TextStyle(
                      color: info.color,
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (period.status ==
              'submitted_to_company_admin')
            const _WaitingMessage(
              text:
              'منتظر بررسی و تأیید مدیرعامل',
              color:
              Color(0xFFF59E0B),
            )
          else if (period.status ==
              'submitted_to_consultant')
            const _WaitingMessage(
              text:
              'منتظر بررسی نهایی مشاور',
              color:
              Color(0xFF2563EB),
            )
          else if (period.status ==
                'approved')
              const _WaitingMessage(
                text:
                'تأیید نهایی انجام شده است',
                color:
                Color(0xFF7C3AED),
              )
            else if (period.status == 'closed')
                const _WaitingMessage(
                  text:
                  'این دوره بسته شده است',
                  color:
                  Color(0xFF64748B),
                ),
          const SizedBox(height: 10),
          SizedBox(
            height: 43,
            child: FilledButton.icon(
              onPressed: () {
                context.push(
                  '/accountant/income/recognition/${period.id}',
                );
              },
              icon: Icon(
                isOpen
                    ? Icons.edit_rounded
                    : Icons.visibility_outlined,
                size: 18,
              ),
              label: Text(
                isOpen
                    ? 'ثبت درآمد'
                    : 'مشاهده درآمد',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isOpen
                    ? Theme.of(context)
                    .colorScheme
                    .primary
                    : Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                foregroundColor: isOpen
                    ? Theme.of(context)
                    .colorScheme
                    .onPrimary
                    : Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
                elevation: 0,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _PeriodStatusInfo _statusInfo(
      BuildContext context,
      String status,
      ) {
    switch (status) {
      case 'submitted_to_company_admin':
        return const _PeriodStatusInfo(
          title: 'ارسال‌شده برای مدیرعامل',
          color: Color(0xFFF59E0B),
          icon:
          Icons.forward_to_inbox_rounded,
        );

      case 'submitted_to_consultant':
        return const _PeriodStatusInfo(
          title: 'ارسال‌شده برای مشاور',
          color: Color(0xFF2563EB),
          icon:
          Icons.person_search_rounded,
        );

      case 'approved':
        return const _PeriodStatusInfo(
          title: 'تأیید نهایی‌شده',
          color: Color(0xFF7C3AED),
          icon: Icons.verified_rounded,
        );

      case 'closed':
        return const _PeriodStatusInfo(
          title: 'بسته‌شده',
          color: Color(0xFF64748B),
          icon: Icons.lock_rounded,
        );

      case 'open':
      default:
        return const _PeriodStatusInfo(
          title: 'باز و آماده ثبت',
          color: Color(0xFF198754),
          icon: Icons.edit_rounded,
        );
    }
  }
}

class _PeriodStatusInfo {
  final String title;
  final Color color;
  final IconData icon;

  const _PeriodStatusInfo({
    required this.title,
    required this.color,
    required this.icon,
  });
}

class _WaitingMessage extends StatelessWidget {
  final String text;
  final Color color;

  const _WaitingMessage({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyYearView extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyYearView({
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(40),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 60,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'هنوز سال مالی درآمدی ایجاد نشده است.',
              textAlign:
              TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(
                Icons.add_rounded,
              ),
              label:
              const Text('ایجاد سال مالی'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 54,
            ),
            const SizedBox(height: 12),
            Text(
              error
                  .toString()
                  .replaceFirst(
                'Exception: ',
                '',
              ),
              textAlign:
              TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label:
              const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}