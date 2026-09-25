import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tarazyar/consultant/companies/banking/data/models/banking_models.dart';

// ============================================================
// PROVIDER
// ============================================================

final bankingDashboardDataProvider =
FutureProvider.family<BankingSnapshot, String>(
      (ref, companyId) async {
    final repository = BankingRepository(
      Supabase.instance.client,
    );

    return repository.load(companyId);
  },
);

// سازگاری با فایل‌های قدیمی پروژه
final bankingProvider = bankingDashboardDataProvider;
final bankingDashboardProvider = bankingDashboardDataProvider;

// ============================================================
// REPOSITORY
// ============================================================

class BankingRepository {
  final SupabaseClient supabase;

  BankingRepository(this.supabase);

  // ==========================================================
  // LOAD DASHBOARD
  // ==========================================================

  Future<BankingSnapshot> load(
      String companyId,
      ) async {
    final periods = await _loadPeriods(companyId);

    final bankAccounts = await _loadBankAccounts(companyId);

    final cashBoxes = await _loadCashBoxes(companyId);

    final pettyCashAccounts =
    await _loadPettyCashAccounts(companyId);

    CashFiscalPeriod? latestPeriod;

    if (periods.isNotEmpty) {
      final sorted = [...periods]
        ..sort(
              (a, b) {
            final year = a.year.compareTo(b.year);

            if (year != 0) {
              return year;
            }

            return a.month.compareTo(b.month);
          },
        );

      latestPeriod = sorted.last;
    }

    List<BankAccountPeriod> bankPeriods = [];
    List<CashBoxPeriod> cashPeriods = [];
    List<PettyCashPeriod> pettyCashPeriods = [];

    if (latestPeriod != null) {
      bankPeriods = await _loadBankPeriods(
        latestPeriod.id,
      );

      cashPeriods = await _loadCashPeriods(
        latestPeriod.id,
      );

      pettyCashPeriods = await _loadPettyCashPeriods(
        latestPeriod.id,
      );
    }

    final trend = await _loadTrend(
      companyId,
      periods,
    );

    final alerts = _buildAlerts(
      periods: periods,
      trend: trend,
      bankPeriods: bankPeriods,
      cashPeriods: cashPeriods,
      pettyCashPeriods: pettyCashPeriods,
    );

    return BankingSnapshot(
      latestPeriod: latestPeriod,
      periods: periods,
      bankAccounts: bankAccounts,
      cashBoxes: cashBoxes,
      pettyCashAccounts: pettyCashAccounts,
      bankPeriods: bankPeriods,
      cashPeriods: cashPeriods,
      pettyCashPeriods: pettyCashPeriods,
      trend: trend,
      alerts: alerts,
    );
  }

  // ==========================================================
  // FISCAL PERIODS
  // ==========================================================

  Future<List<CashFiscalPeriod>> _loadPeriods(
      String companyId,
      ) async {
    final response = await supabase
        .from('cash_fiscal_periods')
        .select(
      'id,'
          'fiscal_year_id,'
          'company_id,'
          'year,'
          'month,'
          'title,'
          'status',
    )
        .eq(
      'company_id',
      companyId,
    )
        .order('year')
        .order('month');

    return (response as List)
        .map(
          (row) => CashFiscalPeriod.fromMap(
        Map<String, dynamic>.from(
          row as Map,
        ),
      ),
    )
        .toList();
  }

  // ==========================================================
  // BANK ACCOUNTS
  // ==========================================================

  Future<List<BankAccount>> _loadBankAccounts(
      String companyId,
      ) async {
    final response = await supabase
        .from('bank_accounts')
        .select(
      'id,'
          'company_id,'
          'bank_name,'
          'account_number,'
          'created_by,'
          'created_at',
    )
        .eq(
      'company_id',
      companyId,
    )
        .order('bank_name');

    return (response as List)
        .map(
          (row) => BankAccount.fromMap(
        Map<String, dynamic>.from(
          row as Map,
        ),
      ),
    )
        .toList();
  }

  // ==========================================================
  // CASH BOXES
  // ==========================================================

  Future<List<CashBox>> _loadCashBoxes(
      String companyId,
      ) async {
    final response = await supabase
        .from('cash_boxes')
        .select('*')
        .eq(
      'company_id',
      companyId,
    )
        .order('box_name');

    return (response as List)
        .map(
          (row) => CashBox.fromMap(
        Map<String, dynamic>.from(
          row as Map,
        ),
      ),
    )
        .toList();
  }

  // ==========================================================
  // PETTY CASH ACCOUNTS
  // ==========================================================

  Future<List<PettyCashAccount>> _loadPettyCashAccounts(
      String companyId,
      ) async {
    final response = await supabase
        .from('petty_cash_accounts')
        .select('*')
        .eq(
      'company_id',
      companyId,
    )
        .order('name');

    return (response as List)
        .map(
          (row) => PettyCashAccount.fromMap(
        Map<String, dynamic>.from(
          row as Map,
        ),
      ),
    )
        .toList();
  }

  // ==========================================================
  // BANK ACCOUNT PERIODS
  // ==========================================================

  Future<List<BankAccountPeriod>> _loadBankPeriods(
      String periodId,
      ) async {
    final response = await supabase
        .from('bank_account_periods')
        .select(
      'id,'
          'company_id,'
          'period_id,'
          'bank_account_id,'
          'opening_balance,'
          'debit_turnover,'
          'credit_turnover,'
          'closing_balance,'
          'ledger_balance,'
          'discrepancy',
    )
        .eq(
      'period_id',
      periodId,
    );

    return (response as List)
        .map(
          (row) => BankAccountPeriod.fromMap(
        Map<String, dynamic>.from(
          row as Map,
        ),
      ),
    )
        .toList();
  }

  // ==========================================================
  // CASH BOX PERIODS
  // ==========================================================

  Future<List<CashBoxPeriod>> _loadCashPeriods(
      String periodId,
      ) async {
    final response = await supabase
        .from('cash_box_periods')
        .select(
      'id,'
          'company_id,'
          'period_id,'
          'cash_box_id,'
          'opening_balance,'
          'total_receipts,'
          'total_payments,'
          'closing_balance,'
          'ledger_balance,'
          'discrepancy',
    )
        .eq(
      'period_id',
      periodId,
    );

    return (response as List)
        .map(
          (row) => CashBoxPeriod.fromMap(
        Map<String, dynamic>.from(
          row as Map,
        ),
      ),
    )
        .toList();
  }

  // ==========================================================
  // PETTY CASH PERIODS
  // ==========================================================

  Future<List<PettyCashPeriod>> _loadPettyCashPeriods(
      String periodId,
      ) async {
    final response = await supabase
        .from('petty_cash_periods')
        .select(
      'id,'
          'company_id,'
          'period_id,'
          'petty_cash_id,'
          'opening_balance,'
          'total_receipts,'
          'total_payments,'
          'closing_balance,'
          'ledger_balance,'
          'discrepancy',
    )
        .eq(
      'period_id',
      periodId,
    );

    return (response as List)
        .map(
          (row) => PettyCashPeriod.fromMap(
        Map<String, dynamic>.from(
          row as Map,
        ),
      ),
    )
        .toList();
  }

  // ==========================================================
  // TREND
  // ==========================================================

  Future<List<BankingTrendPoint>> _loadTrend(
      String companyId,
      List<CashFiscalPeriod> periods,
      ) async {
    if (periods.isEmpty) {
      return [];
    }

    final ids = periods
        .map(
          (e) => e.id,
    )
        .toList();

    final results = await Future.wait([
      supabase
          .from('bank_account_periods')
          .select(
        'period_id,closing_balance',
      )
          .eq(
        'company_id',
        companyId,
      )
          .inFilter(
        'period_id',
        ids,
      ),
      supabase
          .from('cash_box_periods')
          .select(
        'period_id,closing_balance',
      )
          .eq(
        'company_id',
        companyId,
      )
          .inFilter(
        'period_id',
        ids,
      ),
      supabase
          .from('petty_cash_periods')
          .select(
        'period_id,closing_balance',
      )
          .eq(
        'company_id',
        companyId,
      )
          .inFilter(
        'period_id',
        ids,
      ),
    ]);

    final bank = <String, double>{};
    final cash = <String, double>{};
    final petty = <String, double>{};

    // ----------------------------------------------------------
    // BANK
    // ----------------------------------------------------------

    for (final row in results[0] as List) {
      final map = Map<String, dynamic>.from(
        row as Map,
      );

      final id = map['period_id']?.toString() ?? '';

      bank[id] = (bank[id] ?? 0) +
          _number(
            map['closing_balance'],
          );
    }

    // ----------------------------------------------------------
    // CASH
    // ----------------------------------------------------------

    for (final row in results[1] as List) {
      final map = Map<String, dynamic>.from(
        row as Map,
      );

      final id = map['period_id']?.toString() ?? '';

      cash[id] = (cash[id] ?? 0) +
          _number(
            map['closing_balance'],
          );
    }

    // ----------------------------------------------------------
    // PETTY CASH
    // ----------------------------------------------------------

    for (final row in results[2] as List) {
      final map = Map<String, dynamic>.from(
        row as Map,
      );

      final id = map['period_id']?.toString() ?? '';

      petty[id] = (petty[id] ?? 0) +
          _number(
            map['closing_balance'],
          );
    }

    final sorted = [...periods]
      ..sort(
            (a, b) {
          final year = a.year.compareTo(b.year);

          if (year != 0) {
            return year;
          }

          return a.month.compareTo(b.month);
        },
      );

    return sorted
        .map(
          (period) {
        return BankingTrendPoint(
          year: period.year,
          month: period.month,
          bank: bank[period.id] ?? 0,
          cash: cash[period.id] ?? 0,
          pettyCash: petty[period.id] ?? 0,
        );
      },
    )
        .toList();
  }

  // ==========================================================
  // BANKING ALERTS
  // ==========================================================

  List<BankingAlert> _buildAlerts({
    required List<CashFiscalPeriod> periods,
    required List<BankingTrendPoint> trend,
    required List<BankAccountPeriod> bankPeriods,
    required List<CashBoxPeriod> cashPeriods,
    required List<PettyCashPeriod> pettyCashPeriods,
  }) {
    final alerts = <BankingAlert>[];

    // --------------------------------------------------------
    // NO PERIOD
    // --------------------------------------------------------

    if (periods.isEmpty) {
      alerts.add(
        const BankingAlert(
          title: 'دوره مالی ایجاد نشده',
          message:
          'برای شروع ثبت اطلاعات نقد و بانک، دوره سال مالی ایجاد کنید.',
          type: BankingAlertType.info,
        ),
      );

      return alerts;
    }

    // --------------------------------------------------------
    // LATEST PERIOD
    // --------------------------------------------------------

    final sortedPeriods = [...periods]
      ..sort(
            (a, b) {
          final year = a.year.compareTo(b.year);

          if (year != 0) {
            return year;
          }

          return a.month.compareTo(b.month);
        },
      );

    final latest = sortedPeriods.last;

    // --------------------------------------------------------
    // REJECTED
    // --------------------------------------------------------

    if (latest.status == 'rejected') {
      alerts.add(
        const BankingAlert(
          title: 'دوره برگشت داده شده',
          message:
          'آخرین دوره نیاز به اصلاح و ارسال مجدد دارد.',
          type: BankingAlertType.danger,
        ),
      );
    }

    // --------------------------------------------------------
    // PENDING CEO
    // --------------------------------------------------------

    if (latest.status == 'pending_ceo') {
      alerts.add(
        const BankingAlert(
          title: 'در انتظار مدیرعامل',
          message:
          'اطلاعات آخرین دوره برای بررسی مدیرعامل ارسال شده است.',
          type: BankingAlertType.info,
        ),
      );
    }

    // --------------------------------------------------------
    // CEO APPROVED
    // --------------------------------------------------------

    if (latest.status == 'ceo_approved') {
      alerts.add(
        const BankingAlert(
          title: 'تأیید مدیرعامل',
          message:
          'آخرین دوره توسط مدیرعامل تأیید شده است.',
          type: BankingAlertType.info,
        ),
      );
    }

    // --------------------------------------------------------
    // PENDING CONSULTANT
    // --------------------------------------------------------

    if (latest.status == 'pending_consultant') {
      alerts.add(
        const BankingAlert(
          title: 'در انتظار مشاور مالی',
          message:
          'دوره توسط مدیرعامل تأیید شده و منتظر تأیید نهایی مشاور است.',
          type: BankingAlertType.info,
        ),
      );
    }

    // --------------------------------------------------------
    // CONSULTANT APPROVED
    // --------------------------------------------------------

    if (latest.status == 'consultant_approved') {
      alerts.add(
        const BankingAlert(
          title: 'دوره قفل شده',
          message:
          'آخرین دوره تأیید نهایی شده و اطلاعات آن قابل ویرایش نیست.',
          type: BankingAlertType.info,
        ),
      );
    }

    // --------------------------------------------------------
    // BANK DISCREPANCY
    // --------------------------------------------------------

    final bankDiscrepancy = bankPeriods.fold<double>(
      0,
          (sum, item) => sum + item.discrepancy.abs(),
    );

    if (bankDiscrepancy > 0) {
      alerts.add(
        BankingAlert(
          title: 'اختلاف بانک و دفتر',
          message:
          'مجموع اختلاف حساب‌های بانکی '
              '${_money(bankDiscrepancy)} ریال است.',
          type: BankingAlertType.warning,
        ),
      );
    }

    // --------------------------------------------------------
    // CASH DISCREPANCY
    // --------------------------------------------------------

    final cashDiscrepancy = cashPeriods.fold<double>(
      0,
          (sum, item) => sum + item.discrepancy.abs(),
    );

    if (cashDiscrepancy > 0) {
      alerts.add(
        BankingAlert(
          title: 'اختلاف صندوق و دفتر',
          message:
          'مجموع اختلاف صندوق‌ها '
              '${_money(cashDiscrepancy)} ریال است.',
          type: BankingAlertType.warning,
        ),
      );
    }

    // --------------------------------------------------------
    // PETTY CASH DISCREPANCY
    // --------------------------------------------------------

    final pettyDiscrepancy = pettyCashPeriods.fold<double>(
      0,
          (sum, item) => sum + item.discrepancy.abs(),
    );

    if (pettyDiscrepancy > 0) {
      alerts.add(
        BankingAlert(
          title: 'اختلاف تنخواه',
          message:
          'مجموع اختلاف تنخواه‌ها '
              '${_money(pettyDiscrepancy)} ریال است.',
          type: BankingAlertType.warning,
        ),
      );
    }

    // --------------------------------------------------------
    // LIQUIDITY DECLINE
    // --------------------------------------------------------

    if (trend.length >= 2) {
      final previous = trend[trend.length - 2];
      final current = trend.last;

      if (previous.liquidity > 0 &&
          current.liquidity < previous.liquidity) {
        final decline =
            (previous.liquidity - current.liquidity) /
                previous.liquidity;

        if (decline >= .20) {
          alerts.add(
            BankingAlert(
              title: 'کاهش غیرعادی نقدینگی',
              message:
              'نقدینگی نسبت به دوره قبل حدود '
                  '${(decline * 100).toStringAsFixed(0)}٪ کاهش داشته است.',
              type: BankingAlertType.danger,
            ),
          );
        }
      }
    }

    return alerts;
  }
}

// ============================================================
// NUMBER
// ============================================================

double _number(
    dynamic value,
    ) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value.toString().replaceAll(',', ''),
  ) ??
      0;
}

// ============================================================
// MONEY
// ============================================================

String _money(
    double value,
    ) {
  final negative = value < 0;

  final text = value.abs().round().toString();

  var result = '';

  for (var i = 0; i < text.length; i++) {
    if (i > 0 &&
        (text.length - i) % 3 == 0) {
      result += '٬';
    }

    result += text[i];
  }

  return '${negative ? '-' : ''}$result';
}