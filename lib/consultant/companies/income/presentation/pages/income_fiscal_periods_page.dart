import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tarazyar/consultant/companies/income/application/income_access_provider.dart';
import 'package:tarazyar/consultant/companies/income/data/income_fiscal_provider.dart';
import 'package:tarazyar/consultant/dashboard/presentation/widgets/company_scaffold.dart';

class IncomeFiscalPeriodsPage extends ConsumerStatefulWidget {
  final String companyId;

  const IncomeFiscalPeriodsPage({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<IncomeFiscalPeriodsPage> createState() =>
      _IncomeFiscalPeriodsPageState();
}

class _IncomeFiscalPeriodsPageState
    extends ConsumerState<IncomeFiscalPeriodsPage> {
  bool _creatingYear = false;

  @override
  Widget build(BuildContext context) {
    final accessAsync =
    ref.watch(incomeAccessProvider(widget.companyId));

    final yearsAsync =
    ref.watch(incomeFiscalYearsProvider(widget.companyId));

    return CompanyScaffold(
      companyId: widget.companyId,
      currentRoute: '/income/periods',
      title: 'دوره‌های درآمد',
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: accessAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => _ErrorState(
            message: error.toString(),
            onRetry: () {
              ref.invalidate(
                incomeAccessProvider(widget.companyId),
              );
            },
          ),
          data: (access) {
            if (!access.canView) {
              return const _AccessDenied();
            }

            return yearsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => _ErrorState(
                message: error.toString(),
                onRetry: () {
                  ref.invalidate(
                    incomeFiscalYearsProvider(widget.companyId),
                  );
                },
              ),
              data: (years) {
                return _buildContent(
                  context,
                  access,
                  years,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      IncomeAccess access,
      List<Map<String, dynamic>> years,
      ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 800;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(
              incomeFiscalYearsProvider(widget.companyId),
            );
            await ref.read(
              incomeFiscalYearsProvider(widget.companyId).future,
            );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(compact ? 16 : 24),
            children: [
              _HeaderSection(
                canCreate: access.canCreatePeriods,
                creating: _creatingYear,
                onCreate: () => _createYear(context),
              ),
              const SizedBox(height: 20),
              if (years.isEmpty)
                _EmptyYears(
                  canCreate: access.canCreatePeriods,
                  onCreate: () => _createYear(context),
                )
              else
                ...years.map(
                      (year) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _FiscalYearCard(
                      companyId: widget.companyId,
                      year: year,
                      access: access,
                      onChanged: () {
                        ref.invalidate(
                          incomeFiscalYearsProvider(
                            widget.companyId,
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createYear(BuildContext context) async {
    if (_creatingYear) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _CreateYearDialog(),
    );

    if (result == null) return;

    setState(() {
      _creatingYear = true;
    });

    try {
      await IncomeFiscalService.createFiscalYear(
        companyId: widget.companyId,
        year: result['year'] as int,
        title: result['title'] as String?,
      );

      ref.invalidate(
        incomeFiscalYearsProvider(widget.companyId),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سال مالی با موفقیت ایجاد شد.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _friendlyError(e),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creatingYear = false;
        });
      }
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();

    if (text.contains('مجوز') ||
        text.contains('permission') ||
        text.contains('42501')) {
      return 'شما مجوز انجام این عملیات را ندارید.';
    }

    return text.replaceFirst('Exception: ', '');
  }
}

class _HeaderSection extends StatelessWidget {
  final bool canCreate;
  final bool creating;
  final VoidCallback onCreate;

  const _HeaderSection({
    required this.canCreate,
    required this.creating,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withOpacity(.5),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'دوره‌های درآمد',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'مدیریت سال مالی و دوره‌های ماهانه درآمد شرکت',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );

          final button = canCreate
              ? FilledButton.icon(
            onPressed: creating ? null : onCreate,
            icon: creating
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.add_rounded),
            label: const Text('ایجاد سال مالی'),
          )
              : const SizedBox.shrink();

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                if (canCreate) ...[
                  const SizedBox(height: 16),
                  button,
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: title),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _FiscalYearCard extends ConsumerStatefulWidget {
  final String companyId;
  final Map<String, dynamic> year;
  final IncomeAccess access;
  final VoidCallback onChanged;

  const _FiscalYearCard({
    required this.companyId,
    required this.year,
    required this.access,
    required this.onChanged,
  });

  @override
  ConsumerState<_FiscalYearCard> createState() =>
      _FiscalYearCardState();
}

class _FiscalYearCardState
    extends ConsumerState<_FiscalYearCard> {
  bool _loading = false;

  String get _yearId =>
      widget.year['id']?.toString() ?? '';

  int get _year {
    final value = widget.year['year'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get _title {
    final value = widget.year['title']?.toString().trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'سال مالی $_year';
  }

  bool get _isOpen =>
      widget.year['status']?.toString() != 'closed';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final periodsAsync =
    ref.watch(incomeFiscalPeriodsProvider(_yearId));

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withOpacity(.55),
        ),
      ),
      child: Column(
        children: [
          _buildYearHeader(context),
          const Divider(height: 1),
          periodsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(28),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: _InlineError(
                message: error.toString(),
                onRetry: () {
                  ref.invalidate(
                    incomeFiscalPeriodsProvider(_yearId),
                  );
                },
              ),
            ),
            data: (periods) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: _PeriodsGrid(
                  companyId: widget.companyId,
                  periods: periods,
                  yearOpen: _isOpen,
                  access: widget.access,
                  onChanged: () {
                    ref.invalidate(
                      incomeFiscalPeriodsProvider(_yearId),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildYearHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          final titleSection = Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style:
                      theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isOpen
                                ? Colors.green.withOpacity(.10)
                                : Colors.red.withOpacity(.10),
                            borderRadius:
                            BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isOpen ? 'باز' : 'بسته',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _isOpen
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'سال $_year',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final action = widget.access.canSubmitPeriods
              ? PopupMenuButton<String>(
            tooltip: 'عملیات سال مالی',
            onSelected: _handleYearAction,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _isOpen ? 'close' : 'open',
                child: Row(
                  children: [
                    Icon(
                      _isOpen
                          ? Icons.lock_outline_rounded
                          : Icons.lock_open_rounded,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isOpen
                          ? 'بستن سال مالی'
                          : 'بازکردن سال مالی',
                    ),
                  ],
                ),
              ),
            ],
          )
              : const SizedBox.shrink();

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: titleSection),
                    action,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: titleSection),
              action,
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleYearAction(String action) async {
    if (!widget.access.canSubmitPeriods) return;
    if (_loading) return;

    final close = action == 'close';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          close
              ? 'بستن سال مالی'
              : 'بازکردن سال مالی',
        ),
        content: Text(
          close
              ? 'آیا از بستن سال مالی $_year اطمینان دارید؟'
              : 'آیا می‌خواهید سال مالی $_year دوباره باز شود؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              close ? 'بستن سال' : 'بازکردن سال',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _loading = true;
    });

    try {
      if (close) {
        await IncomeFiscalService.closeFiscalYear(
          _yearId,
        );
      } else {
        await IncomeFiscalService.reopenFiscalYear(
          _yearId,
        );
      }

      widget.onChanged();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            close
                ? 'سال مالی بسته شد.'
                : 'سال مالی باز شد.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}

class _PeriodsGrid extends StatelessWidget {
  final String companyId;
  final List<Map<String, dynamic>> periods;
  final bool yearOpen;
  final IncomeAccess access;
  final VoidCallback onChanged;

  const _PeriodsGrid({
    required this.companyId,
    required this.periods,
    required this.yearOpen,
    required this.access,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text('دوره‌ای برای این سال مالی ثبت نشده است.'),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;

        if (width >= 1200) {
          columns = 4;
        } else if (width >= 850) {
          columns = 3;
        } else if (width >= 520) {
          columns = 2;
        } else {
          columns = 1;
        }

        final itemWidth =
            (width - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: periods.map((period) {
            return SizedBox(
              width: itemWidth,
              child: _PeriodCard(
                companyId: companyId,
                period: period,
                yearOpen: yearOpen,
                access: access,
                onChanged: onChanged,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final String companyId;
  final Map<String, dynamic> period;
  final bool yearOpen;
  final IncomeAccess access;
  final VoidCallback onChanged;

  const _PeriodCard({
    required this.companyId,
    required this.period,
    required this.yearOpen,
    required this.access,
    required this.onChanged,
  });

  int get _month {
    final value = period['month'];

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  String get _periodId =>
      period['id']?.toString() ?? '';

  String get _title {
    final value =
    period['title']?.toString().trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'ماه $_month';
  }

  bool get _isOpen =>
      period['status']?.toString() != 'closed';

  bool get _canEnter =>
      yearOpen &&
          _isOpen &&
          access.canEnterPeriods;

  bool get _canOpenReceivables =>
      yearOpen &&
          access.canViewReceivables;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _isOpen
            ? theme.colorScheme.surface
            : theme
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isOpen
              ? theme.dividerColor.withOpacity(.5)
              : Colors.red.withOpacity(.18),
        ),
      ),
      child: Column(
        children: [
          // =====================================================
          // HEADER
          // =====================================================

          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isOpen
                      ? theme
                      .colorScheme
                      .primaryContainer
                      : Colors.red.withOpacity(.10),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$_month',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w900,
                      color: _isOpen
                          ? theme
                          .colorScheme
                          .onPrimaryContainer
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: theme
                          .textTheme
                          .titleSmall
                          ?.copyWith(
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        Icon(
                          _isOpen
                              ? Icons
                              .lock_open_rounded
                              : Icons
                              .lock_rounded,
                          size: 14,
                          color: _isOpen
                              ? Colors
                              .green
                              .shade700
                              : Colors
                              .red
                              .shade700,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isOpen
                              ? 'دوره باز'
                              : 'دوره بسته',
                          style: theme
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color: _isOpen
                                ? Colors
                                .green
                                .shade700
                                : Colors
                                .red
                                .shade700,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              PopupMenuButton<String>(
                enabled: yearOpen,
                tooltip: 'عملیات دوره',
                onSelected: (value) {
                  _handleAction(
                    context,
                    value,
                  );
                },
                itemBuilder: (_) => [
                  if (access.canSubmitPeriods)
                    PopupMenuItem(
                      value:
                      _isOpen
                          ? 'close'
                          : 'open',
                      child: Row(
                        children: [
                          Icon(
                            _isOpen
                                ? Icons
                                .lock_outline_rounded
                                : Icons
                                .lock_open_rounded,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            _isOpen
                                ? 'بستن دوره'
                                : 'بازکردن دوره',
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // =====================================================
          // ACTIONS
          // =====================================================

          Row(
            children: [
              // -------------------------------------------------
              // ثبت درآمد
              // -------------------------------------------------

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _canEnter
                      ? () {
                    context.push(
                      '/consultant/companies/'
                          '$companyId'
                          '/income/recognition/'
                          '$_periodId',
                    );
                  }
                      : null,
                  icon: const Icon(
                    Icons.fact_check_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'ثبت درآمد',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        11,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // -------------------------------------------------
              // حساب‌های دریافتنی
              // -------------------------------------------------

              Expanded(
                child: FilledButton.icon(
                  onPressed:
                  _canOpenReceivables
                      ? () {
                    context.go(
                      '/consultant/companies/'
                          '$companyId'
                          '/income/receivables',
                    );
                  }
                      : null,
                  icon: const Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'دریافتنی‌ها',
                  ),
                  style: FilledButton.styleFrom(
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // =====================================================
          // CLOSED MESSAGE
          // =====================================================

          if (yearOpen && !_isOpen) ...[
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.06),
                borderRadius:
                BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'این دوره بسته است و امکان ثبت اطلاعات جدید وجود ندارد.',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                        Colors.red.shade700,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // =====================================================
          // YEAR CLOSED MESSAGE
          // =====================================================

          if (!yearOpen) ...[
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.orange
                    .withOpacity(.07),
                borderRadius:
                BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color:
                    Colors.orange.shade800,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'سال مالی بسته است.',
                      style: TextStyle(
                        fontSize: 11,
                        color:
                        Colors.orange.shade800,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================
  // ACTION HANDLER
  // ===========================================================

  Future<void> _handleAction(
      BuildContext context,
      String action,
      ) async {
    switch (action) {
      case 'close':
        if (!access.canSubmitPeriods) {
          return;
        }

        await _changeStatus(
          context,
          close: true,
        );
        break;

      case 'open':
        if (!access.canSubmitPeriods) {
          return;
        }

        await _changeStatus(
          context,
          close: false,
        );
        break;
    }
  }

  // ===========================================================
  // CHANGE STATUS
  // ===========================================================

  Future<void> _changeStatus(
      BuildContext context, {
        required bool close,
      }) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          close
              ? 'بستن دوره'
              : 'بازکردن دوره',
        ),
        content: Text(
          close
              ? 'آیا از بستن «$_title» اطمینان دارید؟'
              : 'آیا می‌خواهید «$_title» دوباره باز شود؟',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(
                  context,
                  false,
                ),
            child:
            const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(
                  context,
                  true,
                ),
            child: Text(
              close
                  ? 'بستن دوره'
                  : 'بازکردن دوره',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      if (close) {
        await IncomeFiscalService
            .closeFiscalPeriod(
          _periodId,
        );
      } else {
        await IncomeFiscalService
            .reopenFiscalPeriod(
          _periodId,
        );
      }

      onChanged();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            close
                ? 'دوره با موفقیت بسته شد.'
                : 'دوره با موفقیت باز شد.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }
}

class _CreateYearDialog extends StatefulWidget {
  const _CreateYearDialog();

  @override
  State<_CreateYearDialog> createState() =>
      _CreateYearDialogState();
}

class _CreateYearDialogState
    extends State<_CreateYearDialog> {
  late final TextEditingController _yearController;
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();

    _yearController = TextEditingController(
      text: '1405',
    );

    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _yearController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('ایجاد سال مالی'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'سال مالی',
                  hintText: 'مثلاً ۱۴۰۵',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان',
                  hintText: 'مثلاً سال مالی ۱۴۰۵',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: _submit,
            child: const Text('ایجاد'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final yearText = _normalizeDigits(
      _yearController.text,
    ).replaceAll(',', '').trim();

    final year = int.tryParse(yearText);

    if (year == null || year < 1300 || year > 1600) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'سال مالی باید بین ۱۳۰۰ تا ۱۶۰۰ باشد.',
          ),
        ),
      );
      return;
    }

    final title = _titleController.text.trim();

    Navigator.pop(
      context,
      {
        'year': year,
        'title': title.isEmpty ? null : title,
      },
    );
  }

  String _normalizeDigits(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';
    const en = '0123456789';

    var result = value;

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(
        fa[i],
        en[i],
      );
      result = result.replaceAll(
        ar[i],
        en[i],
      );
    }

    return result;
  }
}

class _EmptyYears extends StatelessWidget {
  final bool canCreate;
  final VoidCallback onCreate;

  const _EmptyYears({
    required this.canCreate,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withOpacity(.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 58,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 14),
          Text(
            'هنوز سال مالی درآمدی ایجاد نشده است.',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (canCreate) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('ایجاد اولین سال مالی'),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  const _AccessDenied();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 460,
        ),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 58,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'دسترسی به بخش درآمد برای شما فعال نیست.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}