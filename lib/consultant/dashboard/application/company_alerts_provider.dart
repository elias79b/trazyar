import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../companies/banking/application/banking_provider.dart';
import '../../companies/banking/data/banking_repository.dart';

// ============================================================
// PROVIDER
// ============================================================

final companyAlertsProvider = FutureProvider.family<List<CompanyAlert>, String>(
  (ref, companyId) async {
    // ----------------------------------------------------------
    // BANKING
    // ----------------------------------------------------------

    final bankingData = await ref.watch(
      bankingDashboardProvider(companyId).future,
    );

    // ----------------------------------------------------------
    // PAYROLL
    // ----------------------------------------------------------

    final payrollAlerts = await PayrollAlertsRepository(
      Supabase.instance.client,
    ).getAlerts(companyId);

    // ----------------------------------------------------------
    // BUILD BANKING ALERTS
    // ----------------------------------------------------------

    final alerts = CompanyAlertsBuilder.build(bankingData);

    // ----------------------------------------------------------
    // ADD PAYROLL ALERTS
    // ----------------------------------------------------------

    alerts.addAll(payrollAlerts);

    // ----------------------------------------------------------
    // SORT ALL ALERTS
    // ----------------------------------------------------------

    alerts.sort((a, b) {
      final severityCompare = _severityWeight(
        a.severity,
      ).compareTo(_severityWeight(b.severity));

      if (severityCompare != 0) {
        return severityCompare;
      }

      return a.title.compareTo(b.title);
    });

    return alerts;
  },
);

// ============================================================
// ALERT ENUMS
// ============================================================

enum CompanyAlertSeverity { danger, warning, info }

enum CompanyAlertType {
  // Banking
  bankDiscrepancy,
  cashDiscrepancy,
  overdueCheck,
  upcomingCheck,
  loan,

  // Payroll
  payrollPendingCeo,
  payrollCeoApproved,
  payrollPendingConsultant,
  payrollRejected,
  payrollDraft,
}

// ============================================================
// ALERT MODEL
// ============================================================

class CompanyAlert {
  const CompanyAlert({
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.route,
    this.amount,
  });

  final CompanyAlertType type;

  final CompanyAlertSeverity severity;

  final String title;

  final String description;

  final String route;

  final double? amount;
}

// ============================================================
// ALERT SORT HELPER
// ============================================================

int _severityWeight(CompanyAlertSeverity severity) {
  switch (severity) {
    case CompanyAlertSeverity.danger:
      return 0;

    case CompanyAlertSeverity.warning:
      return 1;

    case CompanyAlertSeverity.info:
      return 2;
  }
}

// ============================================================
// BANKING ALERT BUILDER
// ============================================================

class CompanyAlertsBuilder {
  static List<CompanyAlert> build(BankingDashboardData data) {
    final alerts = <CompanyAlert>[];

    // ----------------------------------------------------------
    // BANK
    // ----------------------------------------------------------

    _addBankDiscrepancies(alerts, data);

    // ----------------------------------------------------------
    // CASH
    // ----------------------------------------------------------

    _addCashDiscrepancies(alerts, data);

    // ----------------------------------------------------------
    // CHECKS
    // ----------------------------------------------------------

    _addCheckAlerts(alerts, data);

    // ----------------------------------------------------------
    // LOANS
    // ----------------------------------------------------------

    _addLoanAlerts(alerts, data);

    return alerts;
  }

  // ==========================================================
  // BANK DISCREPANCIES
  // ==========================================================

  static void _addBankDiscrepancies(
    List<CompanyAlert> alerts,
    BankingDashboardData data,
  ) {
    for (final account in data.bankAccounts) {
      if (account.discrepancy == 0) {
        continue;
      }

      final amount = account.discrepancy;

      alerts.add(
        CompanyAlert(
          type: CompanyAlertType.bankDiscrepancy,
          severity: CompanyAlertSeverity.danger,
          title: 'مغایرت حساب بانکی',
          description:
              '${account.bankName} '
              'با شماره ${account.accountNumber} '
              'دارای مغایرت ${_money(amount)} است.',
          route: '/consultant/companies/${account.companyId}/banking/accounts',
          amount: amount,
        ),
      );
    }
  }

  // ==========================================================
  // CASH DISCREPANCIES
  // ==========================================================

  static void _addCashDiscrepancies(
    List<CompanyAlert> alerts,
    BankingDashboardData data,
  ) {
    for (final box in data.cashBoxes) {
      if (box.discrepancy == 0) {
        continue;
      }

      final amount = box.discrepancy;

      alerts.add(
        CompanyAlert(
          type: CompanyAlertType.cashDiscrepancy,
          severity: CompanyAlertSeverity.warning,
          title: 'مغایرت صندوق',
          description:
              'صندوق ${box.boxName} '
              'دارای مغایرت ${_money(amount)} است.',
          route: '/consultant/companies/${box.companyId}/banking/cash-boxes',
          amount: amount,
        ),
      );
    }
  }

  // ==========================================================
  // CHECK ALERTS
  // ==========================================================

  static void _addCheckAlerts(
    List<CompanyAlert> alerts,
    BankingDashboardData data,
  ) {
    final today = _dateOnly(DateTime.now());

    final upcomingLimit = today.add(const Duration(days: 3));

    // --------------------------------------------------------
    // RECEIVED
    // --------------------------------------------------------

    for (final check in data.receivedChecks.checks) {
      _evaluateCheck(
        alerts: alerts,
        check: check,
        today: today,
        upcomingLimit: upcomingLimit,
        typeTitle: 'دریافتی',
        route:
            '/consultant/companies/${check.companyId}/banking/received-checks',
      );
    }

    // --------------------------------------------------------
    // PAID
    // --------------------------------------------------------

    for (final check in data.paidChecks.checks) {
      _evaluateCheck(
        alerts: alerts,
        check: check,
        today: today,
        upcomingLimit: upcomingLimit,
        typeTitle: 'پرداختی',
        route: '/consultant/companies/${check.companyId}/banking/paid-checks',
      );
    }
  }

  // ==========================================================
  // EVALUATE CHECK
  // ==========================================================

  static void _evaluateCheck({
    required List<CompanyAlert> alerts,
    required CheckModel check,
    required DateTime today,
    required DateTime upcomingLimit,
    required String typeTitle,
    required String route,
  }) {
    final dueDate = check.dueDate;

    if (dueDate == null) {
      return;
    }

    final status = check.status.trim().toLowerCase();

    const closedStatuses = <String>{
      'paid',
      'cleared',
      'settled',
      'cancelled',
      'canceled',
      'پرداخت شده',
      'وصول شده',
      'تسویه شده',
      'باطل شده',
    };

    if (closedStatuses.contains(status)) {
      return;
    }

    final date = _dateOnly(dueDate);

    // --------------------------------------------------------
    // OVERDUE
    // --------------------------------------------------------

    if (date.isBefore(today)) {
      final numberText =
          check.checkNumber.trim().isEmpty
              ? ''
              : 'شماره ${check.checkNumber.trim()} ';

      alerts.add(
        CompanyAlert(
          type: CompanyAlertType.overdueCheck,
          severity: CompanyAlertSeverity.danger,
          title: 'چک سررسید شده',
          description:
              'چک $typeTitle '
              '$numberText'
              'به مبلغ ${_money(check.amount)} '
              'از سررسید گذشته است.',
          route: route,
          amount: check.amount,
        ),
      );

      return;
    }

    // --------------------------------------------------------
    // UPCOMING
    // --------------------------------------------------------

    if (!date.isAfter(upcomingLimit)) {
      final numberText =
          check.checkNumber.trim().isEmpty
              ? ''
              : 'شماره ${check.checkNumber.trim()} ';

      alerts.add(
        CompanyAlert(
          type: CompanyAlertType.upcomingCheck,
          severity: CompanyAlertSeverity.warning,
          title: 'چک نزدیک سررسید',
          description:
              'چک $typeTitle '
              '$numberText'
              'به مبلغ ${_money(check.amount)} '
              'در تاریخ ${_dateText(date)} سررسید می‌شود.',
          route: route,
          amount: check.amount,
        ),
      );
    }
  }

  // ==========================================================
  // LOAN ALERTS
  // ==========================================================

  static void _addLoanAlerts(
    List<CompanyAlert> alerts,
    BankingDashboardData data,
  ) {
    for (final loan in data.bankLoans) {
      if (loan.remainingAmount <= 0) {
        continue;
      }

      alerts.add(
        CompanyAlert(
          type: CompanyAlertType.loan,
          severity: CompanyAlertSeverity.info,
          title: 'تسهیلات دارای مانده',
          description:
              '${loan.bankName} '
              'دارای مانده تسهیلات '
              '${_money(loan.remainingAmount)} است.',
          route: '/consultant/companies/${loan.companyId}/banking/loans',
          amount: loan.remainingAmount,
        ),
      );
    }
  }
}

// ============================================================
// PAYROLL ALERT REPOSITORY
// ============================================================

class PayrollAlertsRepository {
  PayrollAlertsRepository(this._client);

  final SupabaseClient _client;

  // ==========================================================
  // GET PAYROLL ALERTS
  // ==========================================================

  Future<List<CompanyAlert>> getAlerts(String companyId) async {
    try {
      final response = await _client
          .from('payroll_periods')
          .select('''
            id,
            company_id,
            period_year,
            period_month,
            status,
            notes
            ''')
          .eq('company_id', companyId)
          .order('period_year', ascending: false)
          .order('period_month', ascending: false);

      final rows = response as List;

      final alerts = <CompanyAlert>[];

      for (final rawRow in rows) {
        final row = Map<String, dynamic>.from(rawRow);

        final periodId = row['id']?.toString() ?? '';

        final year = _toInt(row['period_year']);

        final month = _toInt(row['period_month']);

        final status = row['status']?.toString().trim() ?? '';

        if (periodId.isEmpty) {
          continue;
        }

        final periodTitle = _periodTitle(year, month);

        final route = '/consultant/companies/$companyId/payroll/periods';

        // ------------------------------------------------------
        // PENDING CEO
        // ------------------------------------------------------

        if (status == 'pending_ceo') {
          alerts.add(
            CompanyAlert(
              type: CompanyAlertType.payrollPendingCeo,
              severity: CompanyAlertSeverity.warning,
              title: 'دوره حقوق در انتظار تأیید مدیرعامل',
              description:
                  'دوره حقوق $periodTitle '
                  'برای ادامه فرآیند نیاز به تأیید مدیرعامل دارد.',
              route: route,
            ),
          );

          continue;
        }

        // ------------------------------------------------------
        // CEO APPROVED
        // ------------------------------------------------------

        if (status == 'ceo_approved') {
          alerts.add(
            CompanyAlert(
              type: CompanyAlertType.payrollCeoApproved,
              severity: CompanyAlertSeverity.info,
              title: 'دوره حقوق تأیید مدیرعامل شد',
              description:
                  'دوره حقوق $periodTitle '
                  'توسط مدیرعامل تأیید شده و آماده مرحله بعد است.',
              route: route,
            ),
          );

          continue;
        }

        // ------------------------------------------------------
        // PENDING CONSULTANT
        // ------------------------------------------------------

        if (status == 'pending_consultant') {
          alerts.add(
            CompanyAlert(
              type: CompanyAlertType.payrollPendingConsultant,
              severity: CompanyAlertSeverity.warning,
              title: 'دوره حقوق در انتظار تأیید مشاور',
              description:
                  'دوره حقوق $periodTitle '
                  'برای بررسی و تأیید نهایی مشاور آماده است.',
              route: route,
            ),
          );

          continue;
        }

        // ------------------------------------------------------
        // REJECTED
        // ------------------------------------------------------

        if (status == 'rejected') {
          alerts.add(
            CompanyAlert(
              type: CompanyAlertType.payrollRejected,
              severity: CompanyAlertSeverity.danger,
              title: 'دوره حقوق رد شده است',
              description:
                  'دوره حقوق $periodTitle '
                  'رد شده و نیاز به بررسی و اصلاح دارد.',
              route: route,
            ),
          );

          continue;
        }

        // ------------------------------------------------------
        // DRAFT
        // ------------------------------------------------------

        if (status == 'draft') {
          alerts.add(
            CompanyAlert(
              type: CompanyAlertType.payrollDraft,
              severity: CompanyAlertSeverity.info,
              title: 'دوره حقوق در حالت پیش‌نویس',
              description:
                  'دوره حقوق $periodTitle '
                  'هنوز نهایی و برای تأیید ارسال نشده است.',
              route: route,
            ),
          );

          continue;
        }
      }

      return alerts;
    } catch (error, stackTrace) {
      debugPrint('PAYROLL ALERTS ERROR: $error');

      debugPrint('$stackTrace');

      // --------------------------------------------------------
      // IMPORTANT:
      // اگر حقوق خطا داد، هشدارهای بانک از کار نیفتند.
      // --------------------------------------------------------

      return [];
    }
  }
}

// ============================================================
// PAYROLL PERIOD TITLE
// ============================================================

String _periodTitle(int year, int month) {
  final monthName = _jalaliMonthName(month);

  if (year <= 0 || month <= 0) {
    return 'دوره حقوق';
  }

  return '$monthName $year';
}

// ============================================================
// JALALI MONTH NAME
// ============================================================

String _jalaliMonthName(int month) {
  switch (month) {
    case 1:
      return 'فروردین';

    case 2:
      return 'اردیبهشت';

    case 3:
      return 'خرداد';

    case 4:
      return 'تیر';

    case 5:
      return 'مرداد';

    case 6:
      return 'شهریور';

    case 7:
      return 'مهر';

    case 8:
      return 'آبان';

    case 9:
      return 'آذر';

    case 10:
      return 'دی';

    case 11:
      return 'بهمن';

    case 12:
      return 'اسفند';

    default:
      return 'ماه $month';
  }
}

// ============================================================
// DATE ONLY
// ============================================================

DateTime _dateOnly(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

// ============================================================
// DATE TEXT
// ============================================================

String _dateText(DateTime date) {
  return '${date.year}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.day.toString().padLeft(2, '0')}';
}

// ============================================================
// MONEY
// ============================================================

String _money(double value) {
  final rounded = value.round();

  final isNegative = rounded < 0;

  final digits = rounded.abs().toString();

  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(digits[i]);
  }

  final result = buffer.toString();

  return isNegative ? '-$result' : result;
}

// ============================================================
// TO INT
// ============================================================

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
}
