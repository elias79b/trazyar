import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final companyAdminCashFiscalPeriodsProvider =
StateNotifierProvider<
    CompanyAdminCashFiscalPeriodsNotifier,
    CompanyAdminCashFiscalPeriodsState>(
      (ref) {
    return CompanyAdminCashFiscalPeriodsNotifier(
      Supabase.instance.client,
    );
  },
);

// ============================================================================
// PROVIDER
// ============================================================================

class CompanyAdminCashFiscalPeriodsNotifier
    extends StateNotifier<CompanyAdminCashFiscalPeriodsState> {
  final SupabaseClient _supabase;

  CompanyAdminCashFiscalPeriodsNotifier(
      this._supabase,
      ) : super(
    const CompanyAdminCashFiscalPeriodsState(),
  );

  // ==========================================================================
  // COMPANY
  // ==========================================================================

  Future<String> _getCompanyId() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception(
        'کاربر وارد سیستم نشده است.',
      );
    }

    final response = await _supabase
        .from('company_users')
        .select('company_id, role, is_active')
        .eq(
      'user_id',
      user.id,
    )
        .eq(
      'role',
      'company_admin',
    )
        .eq(
      'is_active',
      true,
    )
        .limit(1)
        .maybeSingle();

    if (response == null) {
      throw Exception(
        'شرکت فعال مدیرعامل پیدا نشد.',
      );
    }

    final companyId =
    response['company_id']?.toString();

    if (companyId == null ||
        companyId.isEmpty) {
      throw Exception(
        'شناسه شرکت مدیرعامل معتبر نیست.',
      );
    }

    return companyId;
  }

  // ==========================================================================
  // LOAD
  // ==========================================================================

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final companyId = await _getCompanyId();

      // ----------------------------------------------------------------------
      // FISCAL YEARS
      // ----------------------------------------------------------------------

      final yearsResponse = await _supabase
          .from('cash_fiscal_years')
          .select(
        'id, company_id, year, title, status',
      )
          .eq(
        'company_id',
        companyId,
      )
          .order(
        'year',
        ascending: false,
      );

      final fiscalYears =
      (yearsResponse as List)
          .map(
            (row) =>
            CompanyAdminCashFiscalYear.fromMap(
              Map<String, dynamic>.from(row),
            ),
      )
          .toList();

      // ----------------------------------------------------------------------
      // FISCAL PERIODS
      // ----------------------------------------------------------------------

      final periodsResponse = await _supabase
          .from('cash_fiscal_periods')
          .select(
        '''
            id,
            fiscal_year_id,
            company_id,
            year,
            month,
            title,
            status,
            created_at,
            updated_at
            ''',
      )
          .eq(
        'company_id',
        companyId,
      )
          .order(
        'year',
        ascending: false,
      )
          .order(
        'month',
        ascending: true,
      );

      final periods =
      (periodsResponse as List)
          .map(
            (row) =>
            CompanyAdminCashFiscalPeriod.fromMap(
              Map<String, dynamic>.from(row),
            ),
      )
          .toList();

      // ----------------------------------------------------------------------
      // WORKFLOW
      // ----------------------------------------------------------------------

      final workflowResponse = await _supabase
          .from(
        'cash_fiscal_period_workflow',
      )
          .select(
        '''
            id,
            period_id,
            company_id,
            from_status,
            to_status,
            acted_by,
            note,
            created_at
            ''',
      )
          .eq(
        'company_id',
        companyId,
      )
          .order(
        'created_at',
        ascending: true,
      );

      final workflows =
      (workflowResponse as List)
          .map(
            (row) =>
            CompanyAdminCashFiscalPeriodWorkflow.fromMap(
              Map<String, dynamic>.from(row),
            ),
      )
          .toList();

      state = state.copyWith(
        isLoading: false,
        fiscalYears: fiscalYears,
        periods: periods,
        workflows: workflows,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      rethrow;
    }
  }

  // ==========================================================================
  // YEARS
  // ==========================================================================

  Future<String> createFiscalYear({
    required int year,
    required String title,
    String status = 'open',
  }) async {
    final companyId = await _getCompanyId();

    final existing = await _supabase
        .from('cash_fiscal_years')
        .select('id')
        .eq(
      'company_id',
      companyId,
    )
        .eq(
      'year',
      year,
    )
        .maybeSingle();

    if (existing != null) {
      throw Exception(
        'سال مالی $year قبلاً ایجاد شده است.',
      );
    }

    final inserted = await _supabase
        .from('cash_fiscal_years')
        .insert(
      {
        'company_id': companyId,
        'year': year,
        'title': title,
        'status': status,
        'created_by':
        _supabase.auth.currentUser?.id,
      },
    )
        .select('id')
        .single();

    final id = inserted['id'].toString();

    await load();

    return id;
  }

  Future<void> updateFiscalYear({
    required String id,
    required String title,
    required String status,
  }) async {
    final companyId = await _getCompanyId();

    await _supabase
        .from('cash_fiscal_years')
        .update(
      {
        'title': title,
        'status': status,
        'updated_at':
        DateTime.now().toIso8601String(),
      },
    )
        .eq(
      'id',
      id,
    )
        .eq(
      'company_id',
      companyId,
    );

    await load();
  }

  Future<void> deleteFiscalYear(
      String id,
      ) async {
    final companyId = await _getCompanyId();

    final hasPeriods = state.periods.any(
          (period) =>
      period.fiscalYearId == id,
    );

    if (hasPeriods) {
      throw Exception(
        'این سال مالی دارای دوره است و قابل حذف نیست.',
      );
    }

    await _supabase
        .from('cash_fiscal_years')
        .delete()
        .eq(
      'id',
      id,
    )
        .eq(
      'company_id',
      companyId,
    );

    await load();
  }

  // ==========================================================================
  // PERIODS
  // ==========================================================================

  Future<String> createPeriod({
    required String fiscalYearId,
    required int year,
    required int month,
    required String title,
    String status = 'open',
  }) async {
    final companyId = await _getCompanyId();

    if (month < 1 || month > 12) {
      throw Exception(
        'ماه مالی باید بین ۱ تا ۱۲ باشد.',
      );
    }

    final existing = await _supabase
        .from('cash_fiscal_periods')
        .select('id')
        .eq(
      'company_id',
      companyId,
    )
        .eq(
      'fiscal_year_id',
      fiscalYearId,
    )
        .eq(
      'month',
      month,
    )
        .maybeSingle();

    if (existing != null) {
      throw Exception(
        'این ماه قبلاً برای سال مالی ایجاد شده است.',
      );
    }

    final inserted = await _supabase
        .from('cash_fiscal_periods')
        .insert(
      {
        'company_id': companyId,
        'fiscal_year_id': fiscalYearId,
        'year': year,
        'month': month,
        'title': title,
        'status': status,
      },
    )
        .select('id')
        .single();

    final periodId =
    inserted['id'].toString();

    await _supabase
        .from(
      'cash_fiscal_period_workflow',
    )
        .insert(
      {
        'period_id': periodId,
        'company_id': companyId,
        'from_status': null,
        'to_status': status,
        'acted_by':
        _supabase.auth.currentUser?.id,
        'note': 'ایجاد دوره مالی',
      },
    );

    await load();

    return periodId;
  }

  Future<void> updatePeriod({
    required String id,
    required String title,
  }) async {
    final companyId = await _getCompanyId();

    final period = state.periods
        .where(
          (item) => item.id == id,
    )
        .firstOrNull;

    if (period == null) {
      throw Exception(
        'دوره مالی پیدا نشد.',
      );
    }

    if (period.status != 'open') {
      throw Exception(
        'فقط دوره باز قابل ویرایش است.',
      );
    }

    await _supabase
        .from('cash_fiscal_periods')
        .update(
      {
        'title': title,
        'updated_at':
        DateTime.now().toIso8601String(),
      },
    )
        .eq(
      'id',
      id,
    )
        .eq(
      'company_id',
      companyId,
    );

    await load();
  }

  Future<void> deletePeriod(
      String id,
      ) async {
    final companyId = await _getCompanyId();

    final period = state.periods
        .where(
          (item) => item.id == id,
    )
        .firstOrNull;

    if (period == null) {
      throw Exception(
        'دوره مالی پیدا نشد.',
      );
    }

    if (period.status != 'open') {
      throw Exception(
        'فقط دوره باز قابل حذف است.',
      );
    }

    final bankCount = await _supabase
        .from('bank_account_periods')
        .select('id')
        .eq(
      'company_id',
      companyId,
    )
        .eq(
      'period_id',
      id,
    )
        .count(
      CountOption.exact,
    );

    if ((bankCount.count ?? 0) > 0) {
      throw Exception(
        'این دوره دارای اطلاعات حساب بانکی است و قابل حذف نیست.',
      );
    }

    final cashBoxCount = await _supabase
        .from('cash_box_periods')
        .select('id')
        .eq(
      'company_id',
      companyId,
    )
        .eq(
      'period_id',
      id,
    )
        .count(
      CountOption.exact,
    );

    if ((cashBoxCount.count ?? 0) > 0) {
      throw Exception(
        'این دوره دارای اطلاعات صندوق است و قابل حذف نیست.',
      );
    }

    final pettyCashCount = await _supabase
        .from('petty_cash_periods')
        .select('id')
        .eq(
      'company_id',
      companyId,
    )
        .eq(
      'period_id',
      id,
    )
        .count(
      CountOption.exact,
    );

    if ((pettyCashCount.count ?? 0) > 0) {
      throw Exception(
        'این دوره دارای اطلاعات تنخواه است و قابل حذف نیست.',
      );
    }

    await _supabase
        .from(
      'cash_fiscal_period_workflow',
    )
        .delete()
        .eq(
      'period_id',
      id,
    )
        .eq(
      'company_id',
      companyId,
    );

    await _supabase
        .from('cash_fiscal_periods')
        .delete()
        .eq(
      'id',
      id,
    )
        .eq(
      'company_id',
      companyId,
    );

    await load();
  }

  // ==========================================================================
  // CREATE MISSING MONTHS
  // ==========================================================================

  Future<void> createMissingPeriods(
      String fiscalYearId,
      ) async {
    final companyId = await _getCompanyId();

    final year = state.fiscalYears
        .where(
          (item) => item.id == fiscalYearId,
    )
        .firstOrNull;

    if (year == null) {
      throw Exception(
        'سال مالی پیدا نشد.',
      );
    }

    final existingMonths = state.periods
        .where(
          (period) =>
      period.fiscalYearId ==
          fiscalYearId,
    )
        .map(
          (period) => period.month,
    )
        .toSet();

    final missingMonths = <int>[];

    for (var month = 1; month <= 12; month++) {
      if (!existingMonths.contains(month)) {
        missingMonths.add(month);
      }
    }

    if (missingMonths.isEmpty) {
      await load();
      return;
    }

    final rows = missingMonths.map(
          (month) {
        return {
          'company_id': companyId,
          'fiscal_year_id': fiscalYearId,
          'year': year.year,
          'month': month,
          'title':
          '${monthName(month)} ${year.year}',
          'status': 'open',
        };
      },
    ).toList();

    final inserted = await _supabase
        .from('cash_fiscal_periods')
        .insert(rows)
        .select(
      'id, status',
    );

    if (inserted is List &&
        inserted.isNotEmpty) {
      final workflowRows = inserted.map(
            (row) {
          return {
            'period_id': row['id'],
            'company_id': companyId,
            'from_status': null,
            'to_status':
            row['status'] ?? 'open',
            'acted_by':
            _supabase.auth.currentUser?.id,
            'note': 'ایجاد دوره مالی',
          };
        },
      ).toList();

      await _supabase
          .from(
        'cash_fiscal_period_workflow',
      )
          .insert(workflowRows);
    }

    await load();
  }

  // ==========================================================================
  // PERIODS FOR YEAR
  // ==========================================================================

  List<CompanyAdminCashFiscalPeriod> periodsForYear(
      String fiscalYearId,
      ) {
    final result = state.periods
        .where(
          (period) =>
      period.fiscalYearId ==
          fiscalYearId,
    )
        .toList();

    result.sort(
          (a, b) =>
          a.month.compareTo(b.month),
    );

    return result;
  }

  // ==========================================================================
  // WORKFLOW
  // ==========================================================================

  List<CompanyAdminCashFiscalPeriodWorkflow>
  workflowsForPeriod(
      String periodId,
      ) {
    final result = state.workflows
        .where(
          (workflow) =>
      workflow.periodId ==
          periodId,
    )
        .toList();

    result.sort(
          (a, b) {
        final aDate = a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(
              0,
            );

        final bDate = b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(
              0,
            );

        return aDate.compareTo(bDate);
      },
    );

    return result;
  }

  // ==========================================================================
  // CEO APPROVE
  // ==========================================================================

  Future<void> approveAndSendToConsultant({
    required String id,
    String? note,
  }) async {
    final period = state.periods
        .where(
          (item) => item.id == id,
    )
        .firstOrNull;

    if (period == null) {
      throw Exception(
        'دوره مالی موردنظر پیدا نشد.',
      );
    }

    if (period.status !=
        'submitted_to_company_admin') {
      throw Exception(
        'این دوره در وضعیت «در انتظار بررسی مدیرعامل» نیست.',
      );
    }

    try {
      await _supabase.rpc(
        'submit_cash_fiscal_period',
        params: {
          'p_period_id': id,
          'p_target_status':
          'submitted_to_consultant',
          'p_note': note,
        },
      );

      await load();
    } catch (e) {
      throw Exception(
        'خطا در تأیید و ارسال دوره برای مشاور: $e',
      );
    }
  }

  // ==========================================================================
  // CEO REJECT
  // ==========================================================================

  Future<void> rejectPeriodByCompanyAdmin({
    required String id,
    String? note,
  }) async {
    final period = state.periods
        .where(
          (item) => item.id == id,
    )
        .firstOrNull;

    if (period == null) {
      throw Exception(
        'دوره مالی موردنظر پیدا نشد.',
      );
    }

    if (period.status !=
        'submitted_to_company_admin') {
      throw Exception(
        'این دوره در وضعیت «در انتظار بررسی مدیرعامل» نیست.',
      );
    }

    try {
      await _supabase.rpc(
        'submit_cash_fiscal_period',
        params: {
          'p_period_id': id,
          'p_target_status': 'open',
          'p_note': note,
        },
      );

      await load();
    } catch (e) {
      throw Exception(
        'خطا در برگشت دوره به حسابدار: $e',
      );
    }
  }

  // ==========================================================================
  // PERIOD REVIEW
  // ==========================================================================

  Future<CompanyAdminCashFiscalPeriodReviewData>
  loadPeriodReview(
      String periodId,
      ) async {
    final companyId =
    await _getCompanyId();

    // ------------------------------------------------------------------------
    // PERIOD
    // ------------------------------------------------------------------------

    final periodResponse = await _supabase
        .from('cash_fiscal_periods')
        .select(
      '''
          id,
          fiscal_year_id,
          company_id,
          year,
          month,
          title,
          status,
          created_at,
          updated_at
          ''',
    )
        .eq(
      'id',
      periodId,
    )
        .eq(
      'company_id',
      companyId,
    )
        .maybeSingle();

    if (periodResponse == null) {
      throw Exception(
        'دوره مالی پیدا نشد.',
      );
    }

    final period =
    CompanyAdminCashFiscalPeriod.fromMap(
      Map<String, dynamic>.from(
        periodResponse,
      ),
    );

    // ------------------------------------------------------------------------
    // BANK ACCOUNTS
    // ------------------------------------------------------------------------
    //
    // مهم:
    // فیلدهای opening_balance و debit_turnover و ...
    // در bank_accounts نیستند.
    //
    // اطلاعات پایه:
    // bank_accounts
    //
    // اطلاعات دوره:
    // bank_account_periods
    //
    // ------------------------------------------------------------------------

    final bankResponse = await _supabase
        .from('bank_accounts')
        .select(
      '''
          id,
          company_id,
          bank_name,
          account_number,
          bank_account_periods (
            id,
            period_id,
            opening_balance,
            debit_turnover,
            credit_turnover,
            closing_balance,
            ledger_balance,
            discrepancy
          )
          ''',
    )
        .eq(
      'company_id',
      companyId,
    )
        .order(
      'bank_name',
      ascending: true,
    );

    final bankAccounts =
    <Map<String, dynamic>>[];

    for (final raw in (bankResponse as List)) {
      final bank =
      Map<String, dynamic>.from(raw);

      final periodRows =
      bank['bank_account_periods'];

      Map<String, dynamic>? periodData;

      if (periodRows is List) {
        for (final rawPeriod in periodRows) {
          final row =
          Map<String, dynamic>.from(
            rawPeriod,
          );

          if (row['period_id']?.toString() ==
              periodId) {
            periodData = row;
            break;
          }
        }
      }

      bank['period_data'] =
          periodData;

      bankAccounts.add(bank);
    }

    // ------------------------------------------------------------------------
    // CASH BOXES
    // ------------------------------------------------------------------------

    final cashBoxResponse = await _supabase
        .from('cash_boxes')
        .select(
      '''
          id,
          company_id,
          box_name,
          cash_box_periods (
            id,
            period_id,
            opening_balance,
            total_receipts,
            total_payments,
            closing_balance,
            ledger_balance,
            discrepancy
          )
          ''',
    )
        .eq(
      'company_id',
      companyId,
    )
        .order(
      'box_name',
      ascending: true,
    );

    final cashBoxes =
    <Map<String, dynamic>>[];

    for (final raw in (cashBoxResponse as List)) {
      final box =
      Map<String, dynamic>.from(raw);

      final periodRows =
      box['cash_box_periods'];

      Map<String, dynamic>? periodData;

      if (periodRows is List) {
        for (final rawPeriod in periodRows) {
          final row =
          Map<String, dynamic>.from(
            rawPeriod,
          );

          if (row['period_id']?.toString() ==
              periodId) {
            periodData = row;
            break;
          }
        }
      }

      box['period_data'] =
          periodData;

      cashBoxes.add(box);
    }

    // ------------------------------------------------------------------------
    // PETTY CASH
    // ------------------------------------------------------------------------

    final pettyCashResponse =
    await _supabase
        .from('petty_cash_accounts')
        .select(
      '''
              id,
              company_id,
              name,
              responsible_user_id,
              petty_cash_periods (
                id,
                period_id,
                opening_balance,
                total_receipts,
                total_payments,
                closing_balance,
                ledger_balance,
                discrepancy
              )
              ''',
    )
        .eq(
      'company_id',
      companyId,
    )
        .order(
      'name',
      ascending: true,
    );

    final pettyCashAccounts =
    <Map<String, dynamic>>[];

    for (final raw
    in (pettyCashResponse as List)) {
      final account =
      Map<String, dynamic>.from(raw);

      final periodRows =
      account['petty_cash_periods'];

      Map<String, dynamic>? periodData;

      if (periodRows is List) {
        for (final rawPeriod in periodRows) {
          final row =
          Map<String, dynamic>.from(
            rawPeriod,
          );

          if (row['period_id']?.toString() ==
              periodId) {
            periodData = row;
            break;
          }
        }
      }

      account['period_data'] =
          periodData;

      pettyCashAccounts.add(account);
    }

    // ------------------------------------------------------------------------
    // WORKFLOW
    // ------------------------------------------------------------------------

    final workflowResponse = await _supabase
        .from(
      'cash_fiscal_period_workflow',
    )
        .select(
      '''
          id,
          period_id,
          company_id,
          from_status,
          to_status,
          acted_by,
          note,
          created_at
          ''',
    )
        .eq(
      'company_id',
      companyId,
    )
        .eq(
      'period_id',
      periodId,
    )
        .order(
      'created_at',
      ascending: true,
    );

    final workflows =
    (workflowResponse as List)
        .map(
          (row) =>
          CompanyAdminCashFiscalPeriodWorkflow.fromMap(
            Map<String, dynamic>.from(row),
          ),
    )
        .toList();

    return CompanyAdminCashFiscalPeriodReviewData(
      period: period,
      bankAccounts: bankAccounts,
      cashBoxes: cashBoxes,
      pettyCashAccounts:
      pettyCashAccounts,
      workflows: workflows,
    );
  }

  // ==========================================================================
  // STATUS TITLE
  // ==========================================================================

  String statusTitle(
      String status,
      ) {
    switch (status) {
      case 'open':
        return 'باز';

      case 'submitted_to_company_admin':
        return 'در انتظار بررسی مدیرعامل';

      case 'submitted_to_consultant':
        return 'در انتظار بررسی مشاور';

      case 'approved':
        return 'تأیید نهایی';

      case 'closed':
        return 'بسته شده';

      default:
        return 'وضعیت نامشخص';
    }
  }

  // ==========================================================================
  // MONTH NAME
  // ==========================================================================

  String monthName(
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

    if (month < 1 || month > 12) {
      return 'ماه';
    }

    return months[month - 1];
  }

  // ==========================================================================
  // CHANGE PERIOD STATUS
  // ==========================================================================

  Future<void> changePeriodStatus({
    required String id,
    required String status,
    String? note,
  }) async {
    if (status == 'submitted_to_consultant' ||
        status == 'open') {
      final period = state.periods
          .where(
            (item) => item.id == id,
      )
          .firstOrNull;

      if (period == null) {
        throw Exception(
          'دوره مالی پیدا نشد.',
        );
      }

      if (period.status !=
          'submitted_to_company_admin') {
        throw Exception(
          'تغییر این وضعیت از مرحله فعلی مجاز نیست.',
        );
      }

      await _supabase.rpc(
        'submit_cash_fiscal_period',
        params: {
          'p_period_id': id,
          'p_target_status': status,
          'p_note': note,
        },
      );

      await load();
      return;
    }

    throw Exception(
      'تغییر مستقیم وضعیت دوره مجاز نیست. از Workflow استفاده کنید.',
    );
  }
}

// ============================================================================
// STATE
// ============================================================================

class CompanyAdminCashFiscalPeriodsState {
  final bool isLoading;
  final String? error;

  final List<CompanyAdminCashFiscalYear>
  fiscalYears;

  final List<CompanyAdminCashFiscalPeriod>
  periods;

  final List<CompanyAdminCashFiscalPeriodWorkflow>
  workflows;

  const CompanyAdminCashFiscalPeriodsState({
    this.isLoading = false,
    this.error,
    this.fiscalYears = const [],
    this.periods = const [],
    this.workflows = const [],
  });

  CompanyAdminCashFiscalPeriodsState copyWith({
    bool? isLoading,
    String? error,
    List<CompanyAdminCashFiscalYear>?
    fiscalYears,
    List<CompanyAdminCashFiscalPeriod>?
    periods,
    List<CompanyAdminCashFiscalPeriodWorkflow>?
    workflows,
  }) {
    return CompanyAdminCashFiscalPeriodsState(
      isLoading:
      isLoading ?? this.isLoading,
      error: error,
      fiscalYears:
      fiscalYears ?? this.fiscalYears,
      periods:
      periods ?? this.periods,
      workflows:
      workflows ?? this.workflows,
    );
  }
}

// ============================================================================
// FISCAL YEAR
// ============================================================================

class CompanyAdminCashFiscalYear {
  final String id;
  final String companyId;
  final int year;
  final String title;
  final String status;

  const CompanyAdminCashFiscalYear({
    required this.id,
    required this.companyId,
    required this.year,
    required this.title,
    required this.status,
  });

  factory CompanyAdminCashFiscalYear.fromMap(
      Map<String, dynamic> map,
      ) {
    return CompanyAdminCashFiscalYear(
      id: map['id'].toString(),
      companyId:
      map['company_id'].toString(),
      year: _parseInt(
        map['year'],
      ),
      title:
      map['title']?.toString() ?? '',
      status:
      map['status']?.toString() ??
          'open',
    );
  }
}

// ============================================================================
// FISCAL PERIOD
// ============================================================================

class CompanyAdminCashFiscalPeriod {
  final String id;
  final String fiscalYearId;
  final String companyId;
  final int year;
  final int month;
  final String title;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompanyAdminCashFiscalPeriod({
    required this.id,
    required this.fiscalYearId,
    required this.companyId,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory CompanyAdminCashFiscalPeriod.fromMap(
      Map<String, dynamic> map,
      ) {
    return CompanyAdminCashFiscalPeriod(
      id: map['id'].toString(),
      fiscalYearId:
      map['fiscal_year_id'].toString(),
      companyId:
      map['company_id'].toString(),
      year: _parseInt(
        map['year'],
      ),
      month: _parseInt(
        map['month'],
      ),
      title:
      map['title']?.toString() ?? '',
      status:
      map['status']?.toString() ??
          'open',
      createdAt:
      _parseDateTime(
        map['created_at'],
      ),
      updatedAt:
      _parseDateTime(
        map['updated_at'],
      ),
    );
  }
}

// ============================================================================
// WORKFLOW
// ============================================================================

class CompanyAdminCashFiscalPeriodWorkflow {
  final String id;
  final String periodId;
  final String companyId;
  final String? fromStatus;
  final String toStatus;
  final String? actedBy;
  final String? note;
  final DateTime? createdAt;

  const CompanyAdminCashFiscalPeriodWorkflow({
    required this.id,
    required this.periodId,
    required this.companyId,
    required this.fromStatus,
    required this.toStatus,
    required this.actedBy,
    required this.note,
    required this.createdAt,
  });

  factory CompanyAdminCashFiscalPeriodWorkflow.fromMap(
      Map<String, dynamic> map,
      ) {
    return CompanyAdminCashFiscalPeriodWorkflow(
      id: map['id'].toString(),
      periodId:
      map['period_id'].toString(),
      companyId:
      map['company_id'].toString(),
      fromStatus:
      map['from_status']?.toString(),
      toStatus:
      map['to_status']?.toString() ?? '',
      actedBy:
      map['acted_by']?.toString(),
      note:
      map['note']?.toString(),
      createdAt:
      _parseDateTime(
        map['created_at'],
      ),
    );
  }
}

// ============================================================================
// REVIEW DATA
// ============================================================================

class CompanyAdminCashFiscalPeriodReviewData {
  final CompanyAdminCashFiscalPeriod period;

  final List<Map<String, dynamic>>
  bankAccounts;

  final List<Map<String, dynamic>>
  cashBoxes;

  final List<Map<String, dynamic>>
  pettyCashAccounts;

  final List<
      CompanyAdminCashFiscalPeriodWorkflow>
  workflows;

  const CompanyAdminCashFiscalPeriodReviewData({
    required this.period,
    required this.bankAccounts,
    required this.cashBoxes,
    required this.pettyCashAccounts,
    required this.workflows,
  });
}

// ============================================================================
// HELPERS
// ============================================================================

int _parseInt(
    dynamic value,
    ) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    value.toString(),
  ) ??
      0;
}

DateTime? _parseDateTime(
    dynamic value,
    ) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(
    value.toString(),
  );
}