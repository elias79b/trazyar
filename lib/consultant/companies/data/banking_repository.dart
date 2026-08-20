import 'package:supabase_flutter/supabase_flutter.dart';

class BankAccountModel {
  const BankAccountModel({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.openingBalance,
    required this.debitTurnover,
    required this.creditTurnover,
    required this.closingBalance,
    required this.ledgerBalance,
    required this.discrepancy,
  });

  final String id;
  final String bankName;
  final String accountNumber;

  final double openingBalance;
  final double debitTurnover;
  final double creditTurnover;
  final double closingBalance;
  final double ledgerBalance;
  final double discrepancy;

  factory BankAccountModel.fromMap(
      Map<String, dynamic> map,
      ) {
    return BankAccountModel(
      id: map['id'].toString(),
      bankName: (map['bank_name'] ?? '').toString(),
      accountNumber: (map['account_number'] ?? '').toString(),
      openingBalance:
      (map['opening_balance'] ?? 0).toDouble(),
      debitTurnover:
      (map['debit_turnover'] ?? 0).toDouble(),
      creditTurnover:
      (map['credit_turnover'] ?? 0).toDouble(),
      closingBalance:
      (map['closing_balance'] ?? 0).toDouble(),
      ledgerBalance:
      (map['ledger_balance'] ?? 0).toDouble(),
      discrepancy:
      (map['discrepancy'] ?? 0).toDouble(),
    );
  }
}

class BankingRepository {
  BankingRepository()
      : _client = Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<BankAccountModel>> fetchBankAccounts(
      String companyId,
      ) async {
    final data = await _client
        .from('bank_accounts')
        .select()
        .eq('company_id', companyId)
        .order('bank_name');

    return (data as List)
        .map(
          (e) => BankAccountModel.fromMap(
        Map<String, dynamic>.from(e),
      ),
    )
        .toList();
  }
}