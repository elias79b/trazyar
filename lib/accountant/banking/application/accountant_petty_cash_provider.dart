import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantPettyCashProvider = FutureProvider.family<
  List<AccountantPettyCash>,
  String
>((ref, companyId) async {
  final client = Supabase.instance.client;

  final response = await client
      .from('petty_cash_accounts')
      .select(
        'id, company_id, name, responsible_user_id, created_by, created_at',
      )
      .eq('company_id', companyId)
      .order('created_at', ascending: false);

  return (response as List)
      .map(
        (row) =>
            AccountantPettyCash.fromMap(Map<String, dynamic>.from(row as Map)),
      )
      .toList();
});

class AccountantPettyCash {
  final String id;
  final String companyId;
  final String name;
  final String? responsibleUserId;
  final String? createdBy;
  final DateTime? createdAt;

  const AccountantPettyCash({
    required this.id,
    required this.companyId,
    required this.name,
    this.responsibleUserId,
    this.createdBy,
    this.createdAt,
  });

  factory AccountantPettyCash.fromMap(Map<String, dynamic> map) {
    return AccountantPettyCash(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      responsibleUserId: map['responsible_user_id']?.toString(),
      createdBy: map['created_by']?.toString(),
      createdAt:
          map['created_at'] == null
              ? null
              : DateTime.tryParse(map['created_at'].toString()),
    );
  }
}

class AccountantPettyCashRepository {
  AccountantPettyCashRepository._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> create({
    required String companyId,
    required String name,
    String? responsibleUserId,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    await _client.from('petty_cash_accounts').insert({
      'company_id': companyId,
      'name': name.trim(),
      'responsible_user_id': responsibleUserId,
      'created_by': user.id,
    });
  }

  static Future<void> update({
    required String id,
    required String name,
    String? responsibleUserId,
  }) async {
    await _client
        .from('petty_cash_accounts')
        .update({'name': name.trim(), 'responsible_user_id': responsibleUserId})
        .eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _client.from('petty_cash_accounts').delete().eq('id', id);
  }
}
