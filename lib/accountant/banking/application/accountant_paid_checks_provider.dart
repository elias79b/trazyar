import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantPaidChecksProvider =
    FutureProvider.family<List<AccountantPaidCheck>, String>((
      ref,
      companyId,
    ) async {
      return AccountantPaidChecksRepository.fetch(companyId);
    });

class AccountantPaidCheck {
  final String id;
  final String companyId;
  final String checkNumber;
  final String bankName;
  final double amount;
  final String? dueDate;
  final String status;
  final DateTime? createdAt;

  const AccountantPaidCheck({
    required this.id,
    required this.companyId,
    required this.checkNumber,
    required this.bankName,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.createdAt,
  });

  factory AccountantPaidCheck.fromMap(Map<String, dynamic> map) {
    return AccountantPaidCheck(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      checkNumber: map['check_number']?.toString() ?? '',
      bankName: map['bank_name']?.toString() ?? '',
      amount: _toDouble(map['amount']),
      dueDate: map['due_date']?.toString(),
      status: map['status']?.toString() ?? 'pending',
      createdAt:
          map['created_at'] == null
              ? null
              : DateTime.tryParse(map['created_at'].toString()),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '')) ?? 0;
  }
}

class AccountantPaidChecksRepository {
  AccountantPaidChecksRepository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<List<AccountantPaidCheck>> fetch(String companyId) async {
    final response = await _supabase
        .from('paid_checks')
        .select(
          'id, company_id, check_number, bank_name, amount, due_date, status, created_at',
        )
        .eq('company_id', companyId)
        .order('due_date', ascending: true);

    return (response as List)
        .map(
          (row) => AccountantPaidCheck.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  static Future<void> create({
    required String companyId,
    required String checkNumber,
    required String bankName,
    required double amount,
    required String dueDate,
    required String status,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    await _supabase.from('paid_checks').insert({
      'company_id': companyId,
      'check_number': checkNumber,
      'bank_name': bankName,
      'amount': amount,
      'due_date': dueDate,
      'status': status,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> update({
    required String id,
    required String checkNumber,
    required String bankName,
    required double amount,
    required String dueDate,
    required String status,
  }) async {
    await _supabase
        .from('paid_checks')
        .update({
          'check_number': checkNumber,
          'bank_name': bankName,
          'amount': amount,
          'due_date': dueDate,
          'status': status,
        })
        .eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _supabase.from('paid_checks').delete().eq('id', id);
  }
}
