import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/accountant/expenses/application/accountant_expense_recognition_provider.dart';

class AccountantExpenseRecognitionPage extends ConsumerStatefulWidget {
  final String companyId;
  final String periodId;

  const AccountantExpenseRecognitionPage({
    super.key,
    required this.companyId,
    required this.periodId,
  });

  @override
  ConsumerState<AccountantExpenseRecognitionPage> createState() =>
      _AccountantExpenseRecognitionPageState();
}

class _AccountantExpenseRecognitionPageState
    extends ConsumerState<AccountantExpenseRecognitionPage> {
  final NumberFormat _numberFormat = NumberFormat('#,###');

  final SupabaseClient _supabaseClient = Supabase.instance.client;

  bool _busy = false;
  bool _fiscalLoading = true;

  List<_FiscalYearItem> _fiscalYears = [];
  List<_FiscalPeriodItem> _fiscalPeriods = [];

  String? _selectedFiscalYearId;

  @override
  void initState() {
    super.initState();
    _loadFiscalYears();
  }

  @override
  void didUpdateWidget(
      covariant AccountantExpenseRecognitionPage oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.periodId != widget.periodId ||
        oldWidget.companyId != widget.companyId) {
      ref.invalidate(
        accountantExpenseRecognitionProvider(widget.periodId),
      );

      _loadFiscalYears();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = accountantExpenseRecognitionProvider(widget.periodId);
    final state = ref.watch(provider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: state.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => _ErrorView(
            message: _errorMessage(error),
            onRetry: () {
              ref.invalidate(provider);
              _loadFiscalYears();
            },
          ),
          data: (data) => _buildContent(
            context,
            data,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FISCAL YEARS / PERIODS
  // ============================================================

  Future<void> _loadFiscalYears() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _fiscalLoading = true;
    });

    try {
      final response = await _supabaseClient
          .from('expense_fiscal_years')
          .select(
        'id, company_id, year, title, status, created_at, updated_at',
      )
          .eq('company_id', widget.companyId)
          .order('year', ascending: false);

      final years = response
          .map(
            (item) => _FiscalYearItem.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();

      String? selectedYearId;

      for (final year in years) {
        if (year.year == _currentPeriodYear) {
          selectedYearId = year.id;
          break;
        }
      }

      selectedYearId ??= years.isNotEmpty ? years.first.id : null;

      if (!mounted) {
        return;
      }

      setState(() {
        _fiscalYears = years;
        _selectedFiscalYearId = selectedYearId;
      });

      if (selectedYearId != null) {
        await _loadFiscalPeriods(
          selectedYearId,
          navigateToCurrentPeriod: false,
        );
      } else {
        if (mounted) {
          setState(() {
            _fiscalPeriods = [];
            _fiscalLoading = false;
          });
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _fiscalLoading = false;
      });

      _showMessage(
        context,
        _errorMessage(error),
        isError: true,
      );
    }
  }

  Future<void> _loadFiscalPeriods(
      String fiscalYearId, {
        bool navigateToCurrentPeriod = false,
      }) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _fiscalLoading = true;
    });

    try {
      final response = await _supabaseClient
          .from('expense_fiscal_periods')
          .select(
        'id, fiscal_year_id, company_id, year, month, title, status, '
            'created_at, updated_at',
      )
          .eq('company_id', widget.companyId)
          .eq('fiscal_year_id', fiscalYearId)
          .order('month');

      final periods = response
          .map(
            (item) => _FiscalPeriodItem.fromMap(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _fiscalPeriods = periods;
        _fiscalLoading = false;
      });

      if (navigateToCurrentPeriod && periods.isNotEmpty) {
        final currentPeriod = periods.firstWhere(
              (item) => item.id == widget.periodId,
          orElse: () => periods.first,
        );

        if (currentPeriod.id != widget.periodId) {
          _openPeriod(currentPeriod.id);
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _fiscalPeriods = [];
        _fiscalLoading = false;
      });

      _showMessage(
        context,
        _errorMessage(error),
        isError: true,
      );
    }
  }

  Future<void> _onFiscalYearChanged(String? yearId) async {
    if (yearId == null || yearId == _selectedFiscalYearId) {
      return;
    }

    setState(() {
      _selectedFiscalYearId = yearId;
      _fiscalPeriods = [];
    });

    await _loadFiscalPeriods(yearId);
  }

  void _onFiscalPeriodChanged(String? periodId) {
    if (periodId == null || periodId == widget.periodId) {
      return;
    }

    _openPeriod(periodId);
  }

  void _openPeriod(String periodId) {
    context.go(
      '/accountant/expenses/recognition/$periodId',
    );
  }

  int get _currentPeriodYear {
    final provider =
    ref.read(accountantExpenseRecognitionProvider(widget.periodId));

    final state = provider;

    // مقدار واقعی سال از periodId/provider بعداً در data استفاده می‌شود.
    // برای انتخاب اولیه، سال جاری موجود در route را از DB می‌گیریم.
    return _fallbackJalaliYear;
  }

  int get _fallbackJalaliYear {
    return 1406;
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(
      BuildContext context,
      AccountantExpenseRecognitionData data,
      ) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 700;

    _syncSelectedYearWithData(data);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(
          accountantExpenseRecognitionProvider(widget.periodId),
        );

        await ref.read(
          accountantExpenseRecognitionProvider(widget.periodId).future,
        );

        await _loadFiscalYears();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(
              context,
              data,
              isMobile,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildFiscalSelector(
              context,
              data,
              isMobile,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildSummary(
              context,
              data,
              isMobile,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildRecognitionSection(
              context,
              data,
              isMobile,
            ),
          ),
          SliverToBoxAdapter(
            child: _buildWorkflowSection(
              context,
              data,
              isMobile,
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 32),
          ),
        ],
      ),
    );
  }

  void _syncSelectedYearWithData(
      AccountantExpenseRecognitionData data,
      ) {
    if (_fiscalYears.isEmpty) {
      return;
    }

    final matchingYear = _fiscalYears.where(
          (item) => item.year == data.period.year,
    );

    if (matchingYear.isNotEmpty &&
        _selectedFiscalYearId != matchingYear.first.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _selectedFiscalYearId = matchingYear.first.id;
        });
      });
    }
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
      BuildContext context,
      AccountantExpenseRecognitionData data,
      bool isMobile,
      ) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        16,
        isMobile ? 12 : 24,
        12,
      ),
      padding: EdgeInsets.all(
        isMobile ? 16 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(.04),
          ),
        ],
      ),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(data),
          const SizedBox(height: 14),
          _buildStatusChip(data.period),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: _buildTitle(data),
          ),
          _buildStatusChip(data.period),
        ],
      ),
    );
  }

  Widget _buildTitle(
      AccountantExpenseRecognitionData data,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ثبت هزینه — ${data.period.displayTitle}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFBFDBFE),
            ),
          ),
          child: Text(
            'ماه انتخاب‌شده: ${data.period.monthTitle}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'هزینه‌های ماهانه به تفکیک سرفصل',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(
      AccountantExpensePeriod period,
      ) {
    final color = _statusColor(period.status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withOpacity(.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            period.statusTitle,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FISCAL SELECTORS
  // ============================================================

  Widget _buildFiscalSelector(
      BuildContext context,
      AccountantExpenseRecognitionData data,
      bool isMobile,
      ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
      ),
      padding: EdgeInsets.all(
        isMobile ? 14 : 18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: isMobile
          ? Column(
        children: [
          _buildFiscalYearDropdown(data),
          const SizedBox(height: 12),
          _buildFiscalPeriodDropdown(data),
        ],
      )
          : Row(
        children: [
          Expanded(
            child: _buildFiscalYearDropdown(data),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildFiscalPeriodDropdown(data),
          ),
        ],
      ),
    );
  }

  Widget _buildFiscalYearDropdown(
      AccountantExpenseRecognitionData data,
      ) {
    if (_fiscalLoading && _fiscalYears.isEmpty) {
      return _selectorLoading(
        label: 'سال مالی',
      );
    }

    if (_fiscalYears.isEmpty) {
      return _selectorEmpty(
        label: 'سال مالی',
        message: 'سال مالی‌ای ثبت نشده است',
      );
    }

    final validSelectedYear = _fiscalYears.any(
          (item) => item.id == _selectedFiscalYearId,
    );

    return DropdownButtonFormField<String>(
      value: validSelectedYear ? _selectedFiscalYearId : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'سال مالی',
        prefixIcon: const Icon(
          Icons.calendar_month_outlined,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      items: _fiscalYears.map(
            (year) {
          return DropdownMenuItem<String>(
            value: year.id,
            child: Text(
              year.displayTitle,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged: _fiscalLoading
          ? null
          : _onFiscalYearChanged,
    );
  }

  Widget _buildFiscalPeriodDropdown(
      AccountantExpenseRecognitionData data,
      ) {
    if (_fiscalLoading && _fiscalPeriods.isEmpty) {
      return _selectorLoading(
        label: 'ماه مالی',
      );
    }

    if (_fiscalPeriods.isEmpty) {
      return _selectorEmpty(
        label: 'ماه مالی',
        message: 'ماه مالی‌ای برای این سال وجود ندارد',
      );
    }

    final validSelectedPeriod = _fiscalPeriods.any(
          (item) => item.id == widget.periodId,
    );

    return DropdownButtonFormField<String>(
      value: validSelectedPeriod ? widget.periodId : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'ماه مالی',
        prefixIcon: const Icon(
          Icons.date_range_outlined,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      items: _fiscalPeriods.map(
            (period) {
          return DropdownMenuItem<String>(
            value: period.id,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    period.displayTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _smallStatusChip(period.status),
              ],
            ),
          );
        },
      ).toList(),
      onChanged: _fiscalLoading
          ? null
          : _onFiscalPeriodChanged,
    );
  }

  Widget _selectorLoading({
    required String label,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.calendar_month_outlined,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const SizedBox(
        height: 24,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectorEmpty({
    required String label,
    required String message,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(
          Icons.calendar_month_outlined,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _smallStatusChip(
      String status,
      ) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusTitle(status),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(
      BuildContext context,
      AccountantExpenseRecognitionData data,
      bool isMobile,
      ) {
    final cards = [
      _SummaryItem(
        title: 'کل هزینه',
        value: data.totalExpense,
        icon: Icons.account_balance_wallet_outlined,
      ),
      _SummaryItem(
        title: 'هزینه عملیاتی',
        value: data.operationalTotal,
        icon: Icons.business_center_outlined,
      ),
      _SummaryItem(
        title: 'هزینه غیرعملیاتی',
        value: data.nonOperationalTotal,
        icon: Icons.category_outlined,
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
          final cardWidth = isMobile
              ? constraints.maxWidth
              : (constraints.maxWidth - 24) / 3;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in cards)
                SizedBox(
                  width: cardWidth,
                  child: _summaryCard(item),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(
      _SummaryItem item,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.icon,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatNumber(item.value)} ریال',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
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

  // ============================================================
  // RECOGNITION
  // ============================================================

  Widget _buildRecognitionSection(
      BuildContext context,
      AccountantExpenseRecognitionData data,
      bool isMobile,
      ) {
    final isEditable = data.period.isOpen;

    return Container(
      margin: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        20,
        isMobile ? 12 : 24,
        0,
      ),
      padding: EdgeInsets.all(
        isMobile ? 14 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'سرفصل‌های هزینه',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              if (isEditable)
                Text(
                  'دوره باز است',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isEditable
                ? 'برای هر سرفصل مبلغ هزینه و توضیحات را ثبت کنید.'
                : 'این دوره در وضعیت ${data.period.statusTitle} قرار دارد و قابل ویرایش نیست.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 18),
          if (data.categories.isEmpty)
            _emptyCategories()
          else
            ...data.categories.map(
                  (category) => _categoryRow(
                context,
                data,
                category,
                isEditable,
                isMobile,
              ),
            ),
          if (isEditable) ...[
            const SizedBox(height: 12),
            _buildSubmitButton(
              context,
              data,
            ),
          ],
        ],
      ),
    );
  }

  Widget _categoryRow(
      BuildContext context,
      AccountantExpenseRecognitionData data,
      AccountantExpenseCategory category,
      bool editable,
      bool isMobile,
      ) {
    final recognition = data.recognitionForCategory(
      category.id,
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: EdgeInsets.all(
        isMobile ? 13 : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _categoryTitle(
            category,
            recognition,
          ),
          const SizedBox(height: 13),
          _amountField(
            context,
            data,
            category,
            recognition,
            editable,
          ),
          const SizedBox(height: 10),
          _descriptionField(
            context,
            data,
            category,
            recognition,
            editable,
          ),
        ],
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: _categoryTitle(
              category,
              recognition,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 210,
            child: _amountField(
              context,
              data,
              category,
              recognition,
              editable,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: _descriptionField(
              context,
              data,
              category,
              recognition,
              editable,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryTitle(
      AccountantExpenseCategory category,
      AccountantExpenseRecognition? recognition,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: category.isOperational
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            category.isOperational
                ? Icons.trending_up_rounded
                : Icons.swap_vertical_circle_outlined,
            size: 20,
            color: category.isOperational
                ? const Color(0xFF15803D)
                : const Color(0xFFC2410C),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    category.expenseTypeTitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: category.isOperational
                          ? const Color(0xFF15803D)
                          : const Color(0xFFC2410C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (category.code != null &&
                      category.code!.trim().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      category.code!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
              if (recognition != null &&
                  recognition.description != null &&
                  recognition.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  recognition.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _amountField(
      BuildContext context,
      AccountantExpenseRecognitionData data,
      AccountantExpenseCategory category,
      AccountantExpenseRecognition? recognition,
      bool editable,
      ) {
    final controller = TextEditingController(
      text: recognition == null || recognition.amount == 0
          ? ''
          : _formatNumber(recognition.amount),
    );

    return TextField(
      controller: controller,
      enabled: editable && !_busy,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: 'مبلغ',
        suffixText: 'ریال',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 12,
        ),
      ),
      onSubmitted: (_) {
        if (editable) {
          _saveFromControllers(
            context: context,
            data: data,
            category: category,
            amountController: controller,
            description: recognition?.description ?? '',
          );
        }
      },
      onTapOutside: (_) {
        if (editable && controller.text.trim().isNotEmpty) {
          _saveFromControllers(
            context: context,
            data: data,
            category: category,
            amountController: controller,
            description: recognition?.description ?? '',
            showMessage: false,
          );
        }
      },
    );
  }

  Widget _descriptionField(
      BuildContext context,
      AccountantExpenseRecognitionData data,
      AccountantExpenseCategory category,
      AccountantExpenseRecognition? recognition,
      bool editable,
      ) {
    final controller = TextEditingController(
      text: recognition?.description ?? '',
    );

    return TextField(
      controller: controller,
      enabled: editable && !_busy,
      maxLines: 1,
      decoration: InputDecoration(
        labelText: 'توضیحات',
        hintText: 'توضیحات اختیاری',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 12,
        ),
      ),
      onSubmitted: (_) {
        if (editable) {
          final amount = recognition?.amount ?? 0;

          if (amount > 0) {
            _saveRecognition(
              context: context,
              category: category,
              amount: amount,
              description: controller.text,
              recognitionId: recognition?.id,
            );
          }
        }
      },
    );
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Widget _buildSubmitButton(
      BuildContext context,
      AccountantExpenseRecognitionData data,
      ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: _busy
            ? null
            : () => _submitToCompanyAdmin(
          context,
          data,
        ),
        icon: _busy
            ? const SizedBox(
          width: 17,
          height: 17,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(
          Icons.send_outlined,
        ),
        label: const Text(
          'ارسال به مدیر شرکت',
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _saveFromControllers({
    required BuildContext context,
    required AccountantExpenseRecognitionData data,
    required AccountantExpenseCategory category,
    required TextEditingController amountController,
    required String description,
    bool showMessage = true,
  }) async {
    final amount = _parseAmount(
      amountController.text,
    );

    if (amount <= 0) {
      return;
    }

    await _saveRecognition(
      context: context,
      category: category,
      amount: amount,
      description: description,
      recognitionId: data
          .recognitionForCategory(
        category.id,
      )
          ?.id,
      showMessage: showMessage,
    );
  }

  Future<void> _saveRecognition({
    required BuildContext context,
    required AccountantExpenseCategory category,
    required double amount,
    required String description,
    String? recognitionId,
    bool showMessage = true,
  }) async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final repository =
      AccountantExpenseRecognitionRepository(
        _supabaseClient,
      );

      await repository.saveRecognition(
        periodId: widget.periodId,
        companyId: widget.companyId,
        categoryId: category.id,
        amount: amount,
        description: description,
        recognitionId: recognitionId,
      );

      ref.invalidate(
        accountantExpenseRecognitionProvider(
          widget.periodId,
        ),
      );

      if (mounted && showMessage) {
        _showMessage(
          context,
          'هزینه با موفقیت ثبت شد.',
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          context,
          _errorMessage(error),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ============================================================
  // WORKFLOW
  // ============================================================

  Future<void> _submitToCompanyAdmin(
      BuildContext context,
      AccountantExpenseRecognitionData data,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'ارسال دوره',
          ),
          content: const Text(
            'پس از ارسال دوره به مدیر شرکت، ثبت و ویرایش هزینه‌ها متوقف می‌شود. ادامه می‌دهید؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'انصراف',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'ارسال',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || _busy) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final repository =
      AccountantExpenseRecognitionRepository(
        _supabaseClient,
      );

      await repository.processPeriod(
        periodId: data.period.id,
        action: 'submit_to_company_admin',
      );

      ref.invalidate(
        accountantExpenseRecognitionProvider(
          widget.periodId,
        ),
      );

      if (mounted) {
        _showMessage(
          context,
          'دوره با موفقیت به مدیر شرکت ارسال شد.',
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(
          context,
          _errorMessage(error),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  // ============================================================
  // WORKFLOW HISTORY
  // ============================================================

  Widget _buildWorkflowSection(
      BuildContext context,
      AccountantExpenseRecognitionData data,
      bool isMobile,
      ) {
    if (data.workflow.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.fromLTRB(
        isMobile ? 12 : 24,
        20,
        isMobile ? 12 : 24,
        0,
      ),
      padding: EdgeInsets.all(
        isMobile ? 14 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'گردش تأیید دوره',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 15),
          ...data.workflow.map(
                (item) => _workflowItem(item),
          ),
        ],
      ),
    );
  }

  Widget _workflowItem(
      ExpenseRecognitionWorkflowItem item,
      ) {
    final date = item.createdAt == null
        ? '-'
        : _formatDateTime(
      item.createdAt!,
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.history,
              size: 18,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.fromStatusTitle} ← ${item.toStatusTitle}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (item.note != null &&
                    item.note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.note!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _emptyCategories() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 35,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(
            Icons.category_outlined,
            size: 42,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          const Text(
            'سرفصل فعالی برای این شرکت ثبت نشده است.',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _parseAmount(
      String value,
      ) {
    var text = value.trim();

    if (text.isEmpty) {
      return 0;
    }

    text = text.replaceAll(
      ',',
      '',
    );
    text = text.replaceAll(
      '٬',
      '',
    );
    text = text.replaceAll(
      ' ',
      '',
    );
    text = text.replaceAll(
      'ریال',
      '',
    );
    text = text.replaceAll(
      'تومان',
      '',
    );

    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';

    for (var i = 0; i < 10; i++) {
      text = text.replaceAll(
        persianDigits[i],
        i.toString(),
      );

      text = text.replaceAll(
        arabicDigits[i],
        i.toString(),
      );
    }

    return double.tryParse(text) ?? 0;
  }

  String _formatNumber(
      double value,
      ) {
    return _numberFormat.format(
      value.round(),
    );
  }

  String _formatDateTime(
      DateTime value,
      ) {
    final local = value.toLocal();

    return '${local.year}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
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
        return 'مدیر شرکت';
      case 'submitted_to_consultant':
        return 'مشاور';
      case 'approved':
        return 'تأیید';
      case 'closed':
        return 'بسته';
      default:
        return status;
    }
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
          content: Text(
            message,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFDC2626)
              : const Color(0xFF166534),
        ),
      );
  }

  String _errorMessage(
      Object error,
      ) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(
        'Exception: '.length,
      );
    }

    return text;
  }
}

// ============================================================
// FISCAL YEAR MODEL
// ============================================================

class _FiscalYearItem {
  final String id;
  final String companyId;
  final int year;
  final String? title;
  final String status;

  const _FiscalYearItem({
    required this.id,
    required this.companyId,
    required this.year,
    required this.title,
    required this.status,
  });

  factory _FiscalYearItem.fromMap(
      Map<String, dynamic> map,
      ) {
    return _FiscalYearItem(
      id: map['id'].toString(),
      companyId: map['company_id'].toString(),
      year: _toInt(map['year']),
      title: map['title']?.toString(),
      status: map['status']?.toString() ?? 'open',
    );
  }

  String get displayTitle {
    if (title != null &&
        title!.trim().isNotEmpty) {
      return title!.trim();
    }

    return 'سال مالی $year';
  }
}

// ============================================================
// FISCAL PERIOD MODEL
// ============================================================

class _FiscalPeriodItem {
  final String id;
  final String fiscalYearId;
  final String companyId;
  final int year;
  final int month;
  final String? title;
  final String status;

  const _FiscalPeriodItem({
    required this.id,
    required this.fiscalYearId,
    required this.companyId,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
  });

  factory _FiscalPeriodItem.fromMap(
      Map<String, dynamic> map,
      ) {
    return _FiscalPeriodItem(
      id: map['id'].toString(),
      fiscalYearId: map['fiscal_year_id'].toString(),
      companyId: map['company_id'].toString(),
      year: _toInt(map['year']),
      month: _toInt(map['month']),
      title: map['title']?.toString(),
      status: map['status']?.toString() ?? 'open',
    );
  }

  String get monthTitle {
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

  String get displayTitle {
    if (title != null &&
        title!.trim().isNotEmpty) {
      return title!.trim();
    }

    return '$monthTitle $year';
  }
}

// ============================================================
// SUMMARY MODEL
// ============================================================

class _SummaryItem {
  final String title;
  final double value;
  final IconData icon;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
  });
}

// ============================================================
// ERROR VIEW
// ============================================================

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'تلاش مجدد',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// UTILITY
// ============================================================

int _toInt(
    dynamic value,
    ) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    value?.toString() ?? '',
  ) ??
      0;
}