import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantBankingAccountsProvider = FutureProvider.family<
  List<AccountantBankAccount>,
  String
>((ref, companyId) async {
  final client = Supabase.instance.client;

  final response = await client
      .from('bank_accounts')
      .select('id, company_id, bank_name, account_number, created_at')
      .eq('company_id', companyId)
      .order('created_at', ascending: false);

  return (response as List)
      .map(
        (row) => AccountantBankAccount.fromMap(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
});

class AccountantBankAccount {
  final String id;
  final String companyId;
  final String bankName;
  final String accountNumber;
  final DateTime? createdAt;

  const AccountantBankAccount({
    required this.id,
    required this.companyId,
    required this.bankName,
    required this.accountNumber,
    this.createdAt,
  });

  factory AccountantBankAccount.fromMap(Map<String, dynamic> map) {
    return AccountantBankAccount(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      bankName: map['bank_name']?.toString() ?? '',
      accountNumber: map['account_number']?.toString() ?? '',
      createdAt:
          map['created_at'] == null
              ? null
              : DateTime.tryParse(map['created_at'].toString()),
    );
  }
}

class AccountantBankingAccountsRepository {
  AccountantBankingAccountsRepository._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> create({
    required String companyId,
    required String bankName,
    required String accountNumber,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    await _client.from('bank_accounts').insert({
      'company_id': companyId,
      'bank_name': bankName.trim(),
      'account_number': accountNumber.trim(),
      'created_by': user.id,
    });
  }

  static Future<void> update({
    required String id,
    required String bankName,
    required String accountNumber,
  }) async {
    await _client
        .from('bank_accounts')
        .update({
          'bank_name': bankName.trim(),
          'account_number': accountNumber.trim(),
        })
        .eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _client.from('bank_accounts').delete().eq('id', id);
  }
}
