import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final companyAdminReceivedChecksProvider =
    FutureProvider.autoDispose<List<CompanyAdminReceivedCheck>>((ref) async {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('کاربر وارد نشده است.');
      }

      final companyUser =
          await supabase
              .from('company_users')
              .select('company_id')
              .eq('user_id', user.id)
              .eq('role', 'company_admin')
              .eq('is_active', true)
              .limit(1)
              .maybeSingle();

      if (companyUser == null) {
        throw Exception('شرکت فعال برای کاربر پیدا نشد.');
      }

      final companyId = companyUser['company_id'] as String;

      final response = await supabase
          .from('received_checks')
          .select('''
        id,
        company_id,
        check_number,
        bank_name,
        amount,
        due_date,
        status,
        created_at
        ''')
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (item) => CompanyAdminReceivedCheck.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    });

class CompanyAdminReceivedCheck {
  final String id;
  final String companyId;
  final String? checkNumber;
  final String? bankName;
  final double amount;
  final DateTime? dueDate;
  final String? status;
  final DateTime? createdAt;

  const CompanyAdminReceivedCheck({
    required this.id,
    required this.companyId,
    this.checkNumber,
    this.bankName,
    required this.amount,
    this.dueDate,
    this.status,
    this.createdAt,
  });

  factory CompanyAdminReceivedCheck.fromMap(Map<String, dynamic> map) {
    double number(dynamic value) {
      if (value == null) return 0;

      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value.toString()) ?? 0;
    }

    DateTime? date(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return CompanyAdminReceivedCheck(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      checkNumber: map['check_number'] as String?,
      bankName: map['bank_name'] as String?,
      amount: number(map['amount']),
      dueDate: date(map['due_date']),
      status: map['status'] as String?,
      createdAt: date(map['created_at']),
    );
  }
}

class CompanyAdminReceivedChecksController {
  final Ref ref;
  final SupabaseClient supabase;

  CompanyAdminReceivedChecksController(this.ref, this.supabase);

  Future<String> _getCompanyId() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد نشده است.');
    }

    final response =
        await supabase
            .from('company_users')
            .select('company_id')
            .eq('user_id', user.id)
            .eq('role', 'company_admin')
            .eq('is_active', true)
            .limit(1)
            .maybeSingle();

    if (response == null) {
      throw Exception('شرکت فعال برای کاربر پیدا نشد.');
    }

    return response['company_id'] as String;
  }

  Future<void> addCheck({
    String? checkNumber,
    String? bankName,
    required double amount,
    DateTime? dueDate,
    String? status,
  }) async {
    final companyId = await _getCompanyId();

    await supabase.from('received_checks').insert({
      'company_id': companyId,
      'check_number':
          checkNumber == null || checkNumber.trim().isEmpty
              ? null
              : checkNumber.trim(),
      'bank_name':
          bankName == null || bankName.trim().isEmpty ? null : bankName.trim(),
      'amount': amount,
      'due_date': dueDate == null ? null : _dateOnly(dueDate),
      'status': status == null || status.trim().isEmpty ? null : status.trim(),
    });

    ref.invalidate(companyAdminReceivedChecksProvider);
  }

  Future<void> updateCheck({
    required String id,
    String? checkNumber,
    String? bankName,
    required double amount,
    DateTime? dueDate,
    String? status,
  }) async {
    final companyId = await _getCompanyId();

    await supabase
        .from('received_checks')
        .update({
          'check_number':
              checkNumber == null || checkNumber.trim().isEmpty
                  ? null
                  : checkNumber.trim(),
          'bank_name':
              bankName == null || bankName.trim().isEmpty
                  ? null
                  : bankName.trim(),
          'amount': amount,
          'due_date': dueDate == null ? null : _dateOnly(dueDate),
          'status':
              status == null || status.trim().isEmpty ? null : status.trim(),
        })
        .eq('id', id)
        .eq('company_id', companyId);

    ref.invalidate(companyAdminReceivedChecksProvider);
  }

  Future<void> deleteCheck(String id) async {
    final companyId = await _getCompanyId();

    await supabase
        .from('received_checks')
        .delete()
        .eq('id', id)
        .eq('company_id', companyId);

    ref.invalidate(companyAdminReceivedChecksProvider);
  }

  String _dateOnly(DateTime date) {
    final local = date.toLocal();

    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}

final companyAdminReceivedChecksControllerProvider =
    Provider<CompanyAdminReceivedChecksController>((ref) {
      return CompanyAdminReceivedChecksController(
        ref,
        Supabase.instance.client,
      );
    });
