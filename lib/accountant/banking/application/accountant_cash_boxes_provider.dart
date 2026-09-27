import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantCashBoxesProvider = FutureProvider.family<
  List<AccountantCashBox>,
  String
>((ref, companyId) async {
  final client = Supabase.instance.client;

  final response = await client
      .from('cash_boxes')
      .select('id, company_id, box_name, created_by, created_at')
      .eq('company_id', companyId)
      .order('created_at', ascending: false);

  return (response as List)
      .map(
        (row) =>
            AccountantCashBox.fromMap(Map<String, dynamic>.from(row as Map)),
      )
      .toList();
});

class AccountantCashBox {
  final String id;
  final String companyId;
  final String boxName;
  final String? createdBy;
  final DateTime? createdAt;

  const AccountantCashBox({
    required this.id,
    required this.companyId,
    required this.boxName,
    this.createdBy,
    this.createdAt,
  });

  factory AccountantCashBox.fromMap(Map<String, dynamic> map) {
    return AccountantCashBox(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      boxName: map['box_name']?.toString() ?? '',
      createdBy: map['created_by']?.toString(),
      createdAt:
          map['created_at'] == null
              ? null
              : DateTime.tryParse(map['created_at'].toString()),
    );
  }
}

class AccountantCashBoxesRepository {
  AccountantCashBoxesRepository._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> create({
    required String companyId,
    required String boxName,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    await _client.from('cash_boxes').insert({
      'company_id': companyId,
      'box_name': boxName.trim(),
      'created_by': user.id,
    });
  }

  static Future<void> update({
    required String id,
    required String boxName,
  }) async {
    await _client
        .from('cash_boxes')
        .update({'box_name': boxName.trim()})
        .eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _client.from('cash_boxes').delete().eq('id', id);
  }
}
