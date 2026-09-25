import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/consultant/companies/banking/data/models/banking_models.dart';
import '../../companies/banking/application/banking_provider.dart';

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
    // INCOME
    // ----------------------------------------------------------

    final incomeAlerts = await IncomeAlertsRepository(
      Supabase.instance.client,
    ).getAlerts(companyId);

    // ----------------------------------------------------------
    // BANKING ALERTS
    // ----------------------------------------------------------

    final alerts = CompanyAlertsBuilder.build(bankingData);

    // ----------------------------------------------------------
    // PAYROLL ALERTS
    // ----------------------------------------------------------

    alerts.addAll(payrollAlerts);

    // ----------------------------------------------------------
    // INCOME ALERTS
    // ----------------------------------------------------------

    alerts.addAll(incomeAlerts);

    // ----------------------------------------------------------
    // SORT
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
// ALERT SEVERITY
// ============================================================

enum CompanyAlertSeverity { danger, warning, info }

// ============================================================
// ALERT TYPE
// ============================================================

enum CompanyAlertType {
  // Banking
  bankDiscrepancy,
  cashDiscrepancy,
  pettyCashDiscrepancy,

  // Payroll
  payrollPendingCeo,
  payrollCeoApproved,
  payrollPendingConsultant,
  payrollRejected,
  payrollDraft,

  // Banking checks / loans
  upcomingCheck,
  overdueCheck,
  loan,

  // Income
  incomeNoRecognition,
  incomeReceivableWithoutRecognition,
  incomeReceivableExceededRecognition,
  incomeUnreceivedReceivable,
  incomeOpenPeriod,
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
// SEVERITY WEIGHT
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
  static List<CompanyAlert> build(BankingSnapshot data) {
    final alerts = <CompanyAlert>[];

    _addBankDiscrepancies(alerts, data);

    _addCashDiscrepancies(alerts, data);

    _addPettyCashDiscrepancies(alerts, data);

    return alerts;
  }

  // ==========================================================
  // BANK DISCREPANCIES
  // ==========================================================

  static void _addBankDiscrepancies(
    List<CompanyAlert> alerts,
    BankingSnapshot data,
  ) {
    for (final account in data.bankAccounts) {
      final discrepancy = account.discrepancy;

      if (discrepancy == 0) {
        continue;
      }

      alerts.add(
        CompanyAlert(
          type: CompanyAlertType.bankDiscrepancy,
          severity: CompanyAlertSeverity.danger,
          title: 'مغایرت حساب بانکی',
          description:
              '${account.bankName} '
              'با شماره ${account.accountNumber} '
              'دارای مغایرت ${_money(discrepancy)} است.',
          route: '/consultant/companies/${account.companyId}/banking/accounts',
          amount: discrepancy,
        ),
      );
    }
  }

  // ==========================================================
  // CASH DISCREPANCIES
  // ==========================================================

  static void _addCashDiscrepancies(
    List<CompanyAlert> alerts,
    BankingSnapshot data,
  ) {
    for (final box in data.cashBoxes) {
      final discrepancy = box.discrepancy;

      if (discrepancy == 0) {
        continue;
      }

      alerts.add(
        CompanyAlert(
          type: CompanyAlertType.cashDiscrepancy,
          severity: CompanyAlertSeverity.warning,
          title: 'مغایرت صندوق',
          description:
              'صندوق ${box.boxName} '
              'دارای مغایرت ${_money(discrepancy)} است.',
          route: '/consultant/companies/${box.companyId}/banking/cash-boxes',
          amount: discrepancy,
        ),
      );
    }
  }

  // ==========================================================
  // PETTY CASH DISCREPANCIES
  // ==========================================================

  static void _addPettyCashDiscrepancies(
    List<CompanyAlert> alerts,
    BankingSnapshot data,
  ) {
    for (final pettyCash in data.pettyCashAccounts) {
      final discrepancy = pettyCash.discrepancy;

      if (discrepancy == 0) {
        continue;
      }

      alerts.add(
        CompanyAlert(
          type: CompanyAlertType.pettyCashDiscrepancy,
          severity: CompanyAlertSeverity.warning,
          title: 'مغایرت تنخواه',
          description:
              'تنخواه ${pettyCash.name} '
              'دارای مغایرت ${_money(discrepancy)} است.',
          route:
              '/consultant/companies/${pettyCash.companyId}/banking/petty-cash',
          amount: discrepancy,
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

        if (periodId.isEmpty) {
          continue;
        }

        final year = _toInt(row['period_year']);

        final month = _toInt(row['period_month']);

        final status = row['status']?.toString().trim() ?? '';

        final periodTitle = _periodTitle(year, month);

        final route = '/consultant/companies/$companyId/payroll/periods';

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
        }
      }

      return alerts;
    } catch (error, stackTrace) {
      debugPrint('PAYROLL ALERTS ERROR: $error');

      debugPrint('$stackTrace');

      return [];
    }
  }
}

// ============================================================
// INCOME ALERT REPOSITORY
// ============================================================

class IncomeAlertsRepository {
  IncomeAlertsRepository(this._client);

  final SupabaseClient _client;

  Future<List<CompanyAlert>> getAlerts(String companyId) async {
    try {
      final yearsResponse = await _client
          .from('income_fiscal_years')
          .select('''
            id,
            company_id,
            year,
            title,
            status
          ''')
          .eq('company_id', companyId)
          .order('year', ascending: false);

      final years = List<Map<String, dynamic>>.from(yearsResponse);

      if (years.isEmpty) {
        return [];
      }

      final latestYear = years.first;
      final latestYearId = latestYear['id']?.toString();

      if (latestYearId == null || latestYearId.isEmpty) {
        return [];
      }

      final latestYearValue = _toInt(latestYear['year']);

      final periodsResponse = await _client
          .from('income_fiscal_periods')
          .select('''
            id,
            fiscal_year_id,
            company_id,
            year,
            month,
            title,
            status
          ''')
          .eq('company_id', companyId)
          .eq('fiscal_year_id', latestYearId)
          .order('month', ascending: true);

      final periods = List<Map<String, dynamic>>.from(periodsResponse);

      if (periods.isEmpty) {
        return [
          CompanyAlert(
            type: CompanyAlertType.incomeOpenPeriod,
            severity: CompanyAlertSeverity.info,
            title: 'دوره‌های درآمد ایجاد نشده‌اند',
            description:
                'برای سال مالی $latestYearValue هنوز دوره‌های ماهانه درآمد ایجاد نشده است.',
            route: '/consultant/companies/$companyId/income/periods',
          ),
        ];
      }

      final periodIds = periods.map((item) => item['id'].toString()).toList();

      final recognitionsResponse = await _client
          .from('income_recognitions')
          .select('''
            id,
            fiscal_period_id,
            category_id,
            amount
          ''')
          .eq('company_id', companyId)
          .inFilter('fiscal_period_id', periodIds);

      final receivablesResponse = await _client
          .from('income_receivables')
          .select('''
            id,
            fiscal_period_id,
            amount,
            received_documents_amount
          ''')
          .eq('company_id', companyId)
          .inFilter('fiscal_period_id', periodIds);

      final recognitions = List<Map<String, dynamic>>.from(
        recognitionsResponse,
      );

      final receivables = List<Map<String, dynamic>>.from(receivablesResponse);

      final alerts = <CompanyAlert>[];

      for (final period in periods) {
        final periodId = period['id'].toString();

        final year = _toInt(period['year']);

        final month = _toInt(period['month']);

        final title =
            period['title']?.toString().trim().isNotEmpty == true
                ? period['title'].toString()
                : _periodTitle(year, month);

        final status = period['status']?.toString() ?? 'open';

        final periodRecognitions =
            recognitions
                .where(
                  (item) => item['fiscal_period_id']?.toString() == periodId,
                )
                .toList();

        final periodReceivables =
            receivables
                .where(
                  (item) => item['fiscal_period_id']?.toString() == periodId,
                )
                .toList();

        double recognizedTotal = 0;

        for (final item in periodRecognitions) {
          recognizedTotal += _toDouble(item['amount']);
        }

        double receivableTotal = 0;
        double receivedTotal = 0;

        for (final item in periodReceivables) {
          receivableTotal += _toDouble(item['amount']);

          receivedTotal += _toDouble(item['received_documents_amount']);
        }

        final remainingReceivable =
            (receivableTotal - receivedTotal)
                .clamp(0, double.infinity)
                .toDouble();

        // ------------------------------------------------------
        // NO RECOGNITION
        // ------------------------------------------------------

        if (recognizedTotal <= 0 && status == 'open') {
          alerts.add(
            CompanyAlert(
              type: CompanyAlertType.incomeNoRecognition,
              severity: CompanyAlertSeverity.warning,
              title: 'درآمد $title ثبت نشده است',
              description:
                  'برای دوره $title هنوز درآمد ماهانه شناسایی نشده است.',
              route:
                  '/consultant/companies/$companyId/income/recognition/$periodId',
            ),
          );
        }

        // ------------------------------------------------------
        // RECEIVABLE WITHOUT RECOGNITION
        // ------------------------------------------------------

        if (receivableTotal > 0 && recognizedTotal <= 0) {
          alerts.add(
            CompanyAlert(
              type: CompanyAlertType.incomeReceivableWithoutRecognition,
              severity: CompanyAlertSeverity.danger,
              title: 'دریافتنی بدون شناسایی درآمد',
              description:
                  'در دوره $title مبلغ '
                  '${_money(receivableTotal)} '
                  'به‌عنوان دریافتنی ثبت شده ولی درآمدی برای دوره شناسایی نشده است.',
              route:
                  '/consultant/companies/$companyId/income/receivables/$periodId',
              amount: receivableTotal,
            ),
          );
        }

        // ------------------------------------------------------
        // RECEIVABLE EXCEEDS RECOGNIZED
        // ------------------------------------------------------

        if (recognizedTotal > 0 && receivableTotal > recognizedTotal) {
          final difference = receivableTotal - recognizedTotal;

          alerts.add(
            CompanyAlert(
              type: CompanyAlertType.incomeReceivableExceededRecognition,
              severity: CompanyAlertSeverity.warning,
              title: 'دریافتنی بیشتر از درآمد شناسایی‌شده',
              description:
                  'در دوره $title مبلغ دریافتنی '
                  '${_money(receivableTotal)} '
                  'است که ${_money(difference)} '
                  'بیشتر از درآمد شناسایی‌شده است.',
              route:
                  '/consultant/companies/$companyId/income/receivables/$periodId',
              amount: difference,
            ),
          );
        }

        // ------------------------------------------------------
        // UNRECEIVED
        // ------------------------------------------------------

        if (remainingReceivable > 0) {
          alerts.add(
            CompanyAlert(
              type: CompanyAlertType.incomeUnreceivedReceivable,
              severity: CompanyAlertSeverity.info,
              title: 'مانده دریافتنی درآمد',
              description:
                  'در دوره $title مبلغ '
                  '${_money(remainingReceivable)} '
                  'از دریافتنی‌ها هنوز دریافت نشده است.',
              route:
                  '/consultant/companies/$companyId/income/receivables/$periodId',
              amount: remainingReceivable,
            ),
          );
        }
      }

      return alerts;
    } catch (error, stackTrace) {
      debugPrint('INCOME ALERTS ERROR: $error');

      debugPrint('$stackTrace');

      return [];
    }
  }
}

// ============================================================
// PERIOD TITLE
// ============================================================

String _periodTitle(int year, int month) {
  if (year <= 0 || month <= 0) {
    return 'دوره';
  }

  return '${_jalaliMonthName(month)} $year';
}

// ============================================================
// JALALI MONTH
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

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
}

// ============================================================
// TO DOUBLE
// ============================================================

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}
