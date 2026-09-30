import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/accountant/expenses/application/accountant_payable_fiscal_periods_provider.dart';

class AccountantPayableFiscalPeriodsPage extends ConsumerStatefulWidget {
  final String companyId;

  const AccountantPayableFiscalPeriodsPage({
    super.key,
    required this.companyId,
  });

  @override
  ConsumerState<AccountantPayableFiscalPeriodsPage> createState() =>
      _AccountantPayableFiscalPeriodsPageState();
}

class _AccountantPayableFiscalPeriodsPageState
    extends ConsumerState<AccountantPayableFiscalPeriodsPage> {
  String? _selectedYearId;
  bool _busy = false;

  AccountantPayableFiscalPeriodsRepository get _repository =>
      AccountantPayableFiscalPeriodsRepository(Supabase.instance.client);

  @override
  Widget build(BuildContext context) {
    final provider = accountantPayableFiscalPeriodsProvider(widget.companyId);

    final state = ref.watch(provider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        body: SafeArea(
          child: state.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (error, stackTrace) => _ErrorView(
                  message: _errorMessage(error),
                  onRetry: () {
                    ref.invalidate(provider);
                  },
                ),
            data: (data) => _buildContent(context, data),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AccountantPayableFiscalPeriodsData data,
  ) {
    if (data.years.isNotEmpty) {
      final selectedExists =
          _selectedYearId != null &&
          data.years.any((year) => year.id == _selectedYearId);

      if (!selectedExists) {
        _selectedYearId = data.years.first.id;
      }
    } else {
      _selectedYearId = null;
    }

    final selectedYear =
        _selectedYearId == null ? null : data.yearById(_selectedYearId!);

    final periods =
        selectedYear == null
            ? <AccountantPayableFiscalPeriod>[]
            : data.periodsForYear(selectedYear.id);

    final width = MediaQuery.sizeOf(context).width;

    final isMobile = width < 700;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
          accountantPayableFiscalPeriodsProvider(widget.companyId),
        );

        await ref.read(
          accountantPayableFiscalPeriodsProvider(widget.companyId).future,
        );
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, isMobile)),
          SliverToBoxAdapter(child: _buildYearSelector(data, isMobile)),
          SliverToBoxAdapter(
            child: _buildYearSummary(selectedYear, periods, isMobile),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 12 : 24,
              16,
              isMobile ? 12 : 24,
              32,
            ),
            sliver: SliverToBoxAdapter(
              child:
                  periods.isEmpty
                      ? _emptyPeriods(hasYear: selectedYear != null)
                      : _buildMonthsGrid(context, periods, isMobile),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        16,
        isMobile ? 12 : 24,
        12,
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(.04),
          ),
        ],
      ),
      child:
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerTitle(),
                  const SizedBox(height: 14),
                  _createYearButton(),
                ],
              )
              : Row(
                children: [
                  Expanded(child: _headerTitle()),
                  _createYearButton(),
                ],
              ),
    );
  }

  Widget _headerTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'دوره‌های حساب‌های پرداختنی',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: 7),
        Text(
          'سال مالی و ماه‌های مستقل حساب‌های پرداختنی',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _createYearButton() {
    return FilledButton.icon(
      onPressed: _busy ? null : () => _showCreateYearDialog(context),
      icon: const Icon(Icons.add),
      label: const Text('ایجاد سال مالی'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildYearSelector(
    AccountantPayableFiscalPeriodsData data,
    bool isMobile,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child:
          data.years.isEmpty
              ? const Text(
                'هنوز سال مالی پرداختنی ایجاد نشده است.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              )
              : DropdownButtonFormField<String>(
                value:
                    data.years.any((year) => year.id == _selectedYearId)
                        ? _selectedYearId
                        : data.years.first.id,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'سال مالی پرداختنی',
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                items:
                    data.years.map((year) {
                      return DropdownMenuItem<String>(
                        value: year.id,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                year.displayTitle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _statusChip(year.status),
                          ],
                        ),
                      );
                    }).toList(),
                onChanged:
                    _busy
                        ? null
                        : (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _selectedYearId = value;
                          });
                        },
              ),
    );
  }

  Widget _buildYearSummary(
    AccountantPayableFiscalYear? year,
    List<AccountantPayableFiscalPeriod> periods,
    bool isMobile,
  ) {
    if (year == null) {
      return const SizedBox.shrink();
    }

    final open = periods.where((period) => period.status == 'open').length;

    final submittedToAdmin =
        periods
            .where((period) => period.status == 'submitted_to_company_admin')
            .length;

    final submittedToConsultant =
        periods
            .where((period) => period.status == 'submitted_to_consultant')
            .length;

    final approved =
        periods.where((period) => period.status == 'approved').length;

    final closed = periods.where((period) => period.status == 'closed').length;

    final items = [
      _SummaryItem(
        title: 'باز',
        value: open.toString(),
        icon: Icons.lock_open_outlined,
      ),
      _SummaryItem(
        title: 'ارسال به مدیر',
        value: submittedToAdmin.toString(),
        icon: Icons.forward_to_inbox_outlined,
      ),
      _SummaryItem(
        title: 'ارسال به مشاور',
        value: submittedToConsultant.toString(),
        icon: Icons.person_outline,
      ),
      _SummaryItem(
        title: 'تأییدشده',
        value: approved.toString(),
        icon: Icons.verified_outlined,
      ),
      _SummaryItem(
        title: 'بسته',
        value: closed.toString(),
        icon: Icons.lock_outline,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        14,
        isMobile ? 12 : 24,
        0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;

          final count = isMobile ? 1 : 5;

          final itemWidth =
              isMobile
                  ? constraints.maxWidth
                  : (constraints.maxWidth - (spacing * (count - 1))) / count;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children:
                items.map((item) {
                  return SizedBox(width: itemWidth, child: _summaryCard(item));
                }).toList(),
          );
        },
      ),
    );
  }

  Widget _summaryCard(_SummaryItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, size: 19, color: const Color(0xFF374151)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthsGrid(
    BuildContext context,
    List<AccountantPayableFiscalPeriod> periods,
    bool isMobile,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            isMobile
                ? 1
                : constraints.maxWidth >= 1200
                ? 4
                : constraints.maxWidth >= 800
                ? 3
                : 2;

        const spacing = 12.0;

        final cardWidth =
            isMobile
                ? constraints.maxWidth
                : (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              periods.map((period) {
                return SizedBox(
                  width: cardWidth,
                  child: _periodCard(context, period),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _periodCard(
    BuildContext context,
    AccountantPayableFiscalPeriod period,
  ) {
    final color = _statusColor(period.status);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        context.go('/accountant/expenses/payables/periods/${period.id}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.receipt_long_outlined, color: color),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    period.displayTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_left, color: Color(0xFF9CA3AF)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                period.statusTitle,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  period.isOpen
                      ? Icons.edit_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 7),
                Text(
                  period.isOpen ? 'ورود و ثبت پرداختنی' : 'مشاهده دوره',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyPeriods({required bool hasYear}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 52,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          Text(
            hasYear
                ? 'برای این سال مالی دوره‌ای وجود ندارد.'
                : 'هنوز سال مالی پرداختنی ایجاد نشده است.',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateYearDialog(BuildContext context) async {
    final yearController = TextEditingController();

    final titleController = TextEditingController();

    final result = await showDialog<_CreateYearResult>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('ایجاد سال مالی پرداختنی'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: yearController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'سال مالی',
                      hintText: 'مثلاً ۱۴۰۵',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'عنوان سال مالی',
                      hintText: 'اختیاری',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'پس از ایجاد سال، ۱۲ ماه پرداختنی به‌صورت خودکار ساخته می‌شود.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () {
                  final year = _parseYear(yearController.text);

                  if (year == null) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('سال مالی باید بین ۱۳۰۰ تا ۱۶۰۰ باشد.'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(
                    dialogContext,
                    _CreateYearResult(
                      year: year,
                      title: titleController.text.trim(),
                    ),
                  );
                },
                child: const Text('ایجاد'),
              ),
            ],
          ),
        );
      },
    );

    yearController.dispose();
    titleController.dispose();

    if (result == null || _busy) {
      return;
    }

    await _createYear(result.year, result.title);
  }

  Future<void> _createYear(int year, String? title) async {
    setState(() {
      _busy = true;
    });

    try {
      final yearId = await _repository.createFiscalYear(
        companyId: widget.companyId,
        year: year,
        title: title,
      );

      ref.invalidate(accountantPayableFiscalPeriodsProvider(widget.companyId));

      final freshData = await ref.read(
        accountantPayableFiscalPeriodsProvider(widget.companyId).future,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        if (yearId.isNotEmpty &&
            freshData.years.any((item) => item.id == yearId)) {
          _selectedYearId = yearId;
        } else {
          final createdYear =
              freshData.years.where((item) => item.year == year).toList();

          if (createdYear.isNotEmpty) {
            _selectedYearId = createdYear.first.id;
          }
        }
      });

      _showMessage(
        context,
        'سال مالی $year با موفقیت ایجاد شد و ۱۲ ماه آن ساخته شد.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(context, _errorMessage(error), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusTitle(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
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

  String _statusTitle(String status) {
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

  int? _parseYear(String value) {
    var text = value.trim();

    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';

    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';

    for (var i = 0; i < 10; i++) {
      text = text.replaceAll(persianDigits[i], i.toString());

      text = text.replaceAll(arabicDigits[i], i.toString());
    }

    final year = int.tryParse(text);

    if (year == null || year < 1300 || year > 1600) {
      return null;
    }

    return year;
  }

  void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              isError ? const Color(0xFFDC2626) : const Color(0xFF166534),
        ),
      );
  }

  String _errorMessage(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }

    return text;
  }
}

class _SummaryItem {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class _CreateYearResult {
  final int year;
  final String? title;

  const _CreateYearResult({required this.year, required this.title});
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}
