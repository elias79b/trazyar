import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantBankingDashboardProvider =
    FutureProvider.family<AccountantBankingDashboardData, String>((
      ref,
      companyId,
    ) async {
      final client = Supabase.instance.client;

      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('کاربر وارد سیستم نشده است.');
      }

      // ============================================================
      // آخرین دوره مالی شرکت
      // ============================================================

      final periodResponse =
          await client
              .from('cash_fiscal_periods')
              .select('id, company_id, year, month, title, status')
              .eq('company_id', companyId)
              .order('year', ascending: false)
              .order('month', ascending: false)
              .limit(1)
              .maybeSingle();

      final period = periodResponse;

      final String? periodId = period?['id']?.toString();

      final String periodTitle =
          period?['title']?.toString() ??
          (period != null
              ? '${period['year']}/${period['month']}'
              : 'بدون دوره مالی');

      // ============================================================
      // بانک‌ها
      // ============================================================

      final List<Map<String, dynamic>> bankRows = [];

      if (periodId != null) {
        final response = await client
            .from('bank_account_periods')
            .select('''
              id,
              bank_account_id,
              opening_balance,
              closing_balance,
              ledger_balance,
              discrepancy,
              bank_accounts (
                id,
                bank_name,
                account_number
              )
              ''')
            .eq('company_id', companyId)
            .eq('period_id', periodId);

        for (final row in response) {
          final bank = row['bank_accounts'];

          if (bank is Map) {
            bankRows.add({
              'name': bank['bank_name']?.toString() ?? 'بانک',
              'closingBalance': _toDouble(row['closing_balance']),
              'ledgerBalance': _toDouble(row['ledger_balance']),
              'discrepancy': _toDouble(row['discrepancy']),
            });
          }
        }
      }

      bankRows.sort(
        (a, b) => (b['closingBalance'] as double).compareTo(
          a['closingBalance'] as double,
        ),
      );

      // ============================================================
      // صندوق‌ها
      // ============================================================

      final List<Map<String, dynamic>> cashBoxRows = [];

      if (periodId != null) {
        final response = await client
            .from('cash_box_periods')
            .select('''
              id,
              cash_box_id,
              closing_balance,
              ledger_balance,
              discrepancy,
              cash_boxes (
                id,
                box_name
              )
              ''')
            .eq('company_id', companyId)
            .eq('period_id', periodId);

        for (final row in response) {
          final cashBox = row['cash_boxes'];

          if (cashBox is Map) {
            cashBoxRows.add({
              'name': cashBox['box_name']?.toString() ?? 'صندوق',
              'closingBalance': _toDouble(row['closing_balance']),
              'ledgerBalance': _toDouble(row['ledger_balance']),
              'discrepancy': _toDouble(row['discrepancy']),
            });
          }
        }
      }

      // ============================================================
      // تنخواه‌ها
      // ============================================================

      final List<Map<String, dynamic>> pettyCashRows = [];

      if (periodId != null) {
        final response = await client
            .from('petty_cash_periods')
            .select('''
              id,
              petty_cash_id,
              closing_balance,
              ledger_balance,
              discrepancy,
              petty_cash_accounts (
                id,
                name
              )
              ''')
            .eq('company_id', companyId)
            .eq('period_id', periodId);

        for (final row in response) {
          final pettyCash = row['petty_cash_accounts'];

          if (pettyCash is Map) {
            pettyCashRows.add({
              'name': pettyCash['name']?.toString() ?? 'تنخواه',
              'closingBalance': _toDouble(row['closing_balance']),
              'ledgerBalance': _toDouble(row['ledger_balance']),
              'discrepancy': _toDouble(row['discrepancy']),
            });
          }
        }
      }

      // ============================================================
      // مغایرت بانک‌ها
      // ============================================================

      final bankDiscrepancies =
          bankRows
              .map(
                (row) => BankingDiscrepancy(
                  name: row['name'] as String,
                  amount: row['discrepancy'] as double,
                ),
              )
              .toList();

      // ============================================================
      // چک‌های دریافتی
      // ============================================================

      final receivedChecks = await client
          .from('received_checks')
          .select('amount')
          .eq('company_id', companyId);

      final double receivedChecksTotal = receivedChecks.fold<double>(
        0,
        (sum, row) => sum + _toDouble(row['amount']),
      );

      // ============================================================
      // چک‌های پرداختی
      // ============================================================

      final paidChecks = await client
          .from('paid_checks')
          .select('amount')
          .eq('company_id', companyId);

      final double paidChecksTotal = paidChecks.fold<double>(
        0,
        (sum, row) => sum + _toDouble(row['amount']),
      );

      // ============================================================
      // تسهیلات / بدهی بانکی
      // ============================================================

      final loans = await client
          .from('bank_loans')
          .select('id, bank_name, loan_type, remaining_amount')
          .eq('company_id', companyId);

      final List<BankDebtItem> debtItems = [];

      for (final row in loans) {
        debtItems.add(
          BankDebtItem(
            bankName: row['bank_name']?.toString() ?? 'بانک',
            loanType: row['loan_type']?.toString(),
            remainingAmount: _toDouble(row['remaining_amount']),
          ),
        );
      }

      debtItems.sort((a, b) => b.remainingAmount.compareTo(a.remainingAmount));

      // ============================================================
      // مجموع‌ها
      // ============================================================

      final double totalBankBalance = bankRows.fold<double>(
        0,
        (sum, row) => sum + (row['closingBalance'] as double),
      );

      final double totalCashBalance = cashBoxRows.fold<double>(
        0,
        (sum, row) => sum + (row['closingBalance'] as double),
      );

      final double totalPettyCashBalance = pettyCashRows.fold<double>(
        0,
        (sum, row) => sum + (row['closingBalance'] as double),
      );

      final double totalBankDebt = debtItems.fold<double>(
        0,
        (sum, item) => sum + item.remainingAmount,
      );

      return AccountantBankingDashboardData(
        companyId: companyId,
        periodId: periodId,
        periodTitle: periodTitle,
        periodStatus: period?['status']?.toString(),
        banks:
            bankRows
                .map(
                  (row) => BankBalanceItem(
                    bankName: row['name'] as String,
                    balance: row['closingBalance'] as double,
                  ),
                )
                .toList(),
        cashBoxes:
            cashBoxRows
                .map(
                  (row) => CashBalanceItem(
                    name: row['name'] as String,
                    balance: row['closingBalance'] as double,
                  ),
                )
                .toList(),
        pettyCash:
            pettyCashRows
                .map(
                  (row) => CashBalanceItem(
                    name: row['name'] as String,
                    balance: row['closingBalance'] as double,
                  ),
                )
                .toList(),
        discrepancies: bankDiscrepancies,
        receivedChecksTotal: receivedChecksTotal,
        paidChecksTotal: paidChecksTotal,
        bankDebts: debtItems,
        totalBankBalance: totalBankBalance,
        totalCashBalance: totalCashBalance,
        totalPettyCashBalance: totalPettyCashBalance,
        totalBankDebt: totalBankDebt,
      );
    });

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}

// ================================================================
// DATA
// ================================================================

class AccountantBankingDashboardData {
  final String companyId;

  final String? periodId;
  final String periodTitle;
  final String? periodStatus;

  final List<BankBalanceItem> banks;

  final List<CashBalanceItem> cashBoxes;

  final List<CashBalanceItem> pettyCash;

  final List<BankingDiscrepancy> discrepancies;

  final double receivedChecksTotal;
  final double paidChecksTotal;

  final List<BankDebtItem> bankDebts;

  final double totalBankBalance;
  final double totalCashBalance;
  final double totalPettyCashBalance;

  final double totalBankDebt;

  const AccountantBankingDashboardData({
    required this.companyId,
    required this.periodId,
    required this.periodTitle,
    required this.periodStatus,
    required this.banks,
    required this.cashBoxes,
    required this.pettyCash,
    required this.discrepancies,
    required this.receivedChecksTotal,
    required this.paidChecksTotal,
    required this.bankDebts,
    required this.totalBankBalance,
    required this.totalCashBalance,
    required this.totalPettyCashBalance,
    required this.totalBankDebt,
  });

  double get totalChecks => receivedChecksTotal + paidChecksTotal;

  double get receivedChecksPercent {
    if (totalChecks == 0) {
      return 0;
    }

    return receivedChecksTotal / totalChecks;
  }

  double get paidChecksPercent {
    if (totalChecks == 0) {
      return 0;
    }

    return paidChecksTotal / totalChecks;
  }

  double get totalCashAndBank =>
      totalBankBalance + totalCashBalance + totalPettyCashBalance;
}

class BankBalanceItem {
  final String bankName;
  final double balance;

  const BankBalanceItem({required this.bankName, required this.balance});
}

class CashBalanceItem {
  final String name;
  final double balance;

  const CashBalanceItem({required this.name, required this.balance});
}

class BankingDiscrepancy {
  final String name;
  final double amount;

  const BankingDiscrepancy({required this.name, required this.amount});
}

class BankDebtItem {
  final String bankName;
  final String? loanType;
  final double remainingAmount;

  const BankDebtItem({
    required this.bankName,
    required this.loanType,
    required this.remainingAmount,
  });
}
