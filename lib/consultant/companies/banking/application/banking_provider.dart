import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/banking_repository.dart';

final bankingRepositoryProvider =
Provider<BankingRepository>(
      (ref) => BankingRepository(),
);

final bankingDashboardProvider =
FutureProvider.family<
    BankingDashboardData,
    String>(
      (ref, companyId) async {
    return ref
        .read(bankingRepositoryProvider)
        .fetchDashboard(companyId);
  },
);

final createBankAccountProvider =
Provider<
    Future<void> Function({
    required String companyId,
    required String bankName,
    required String accountNumber,
    required double openingBalance,
    required double debitTurnover,
    required double creditTurnover,
    required double closingBalance,
    required double ledgerBalance,
    required double discrepancy,
    int? fiscalYear,
    int? fiscalMonth,
    })>((ref) {
  return ({
    required String companyId,
    required String bankName,
    required String accountNumber,
    required double openingBalance,
    required double debitTurnover,
    required double creditTurnover,
    required double closingBalance,
    required double ledgerBalance,
    required double discrepancy,
    int? fiscalYear,
    int? fiscalMonth,
  }) {
    return ref
        .read(bankingRepositoryProvider)
        .createBankAccount(
      companyId: companyId,
      bankName: bankName,
      accountNumber: accountNumber,
      openingBalance: openingBalance,
      debitTurnover: debitTurnover,
      creditTurnover: creditTurnover,
      closingBalance: closingBalance,
      ledgerBalance: ledgerBalance,
      discrepancy: discrepancy,
      fiscalYear: fiscalYear,
      fiscalMonth: fiscalMonth,
    );
  };
});