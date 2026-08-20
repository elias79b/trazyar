import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/consultant/companies/data/banking_repository.dart';


final bankingRepositoryProvider =
Provider<BankingRepository>(
      (ref) => BankingRepository(),
);

final bankAccountsProvider =
FutureProvider.family<
    List<BankAccountModel>,
    String>((ref, companyId) async {
  return ref
      .read(bankingRepositoryProvider)
      .fetchBankAccounts(companyId);
});