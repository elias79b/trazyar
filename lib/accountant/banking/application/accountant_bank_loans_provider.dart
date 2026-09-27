import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantBankLoansProvider = FutureProvider.family<
  List<AccountantBankLoan>,
  String
>((ref, companyId) async {
  final client = Supabase.instance.client;

  final response = await client
      .from('bank_loans')
      .select('''
          id,
          company_id,
          bank_name,
          loan_type,
          principal_amount,
          remaining_amount,
          interest_rate,
          start_date,
          end_date,
          monthly_installment,
          created_by,
          created_at
          ''')
      .eq('company_id', companyId)
      .order('created_at', ascending: false);

  return (response as List)
      .map(
        (row) =>
            AccountantBankLoan.fromMap(Map<String, dynamic>.from(row as Map)),
      )
      .toList();
});

class AccountantBankLoan {
  final String id;
  final String companyId;
  final String bankName;
  final String loanType;
  final double principalAmount;
  final double remainingAmount;
  final double interestRate;
  final DateTime? startDate;
  final DateTime? endDate;
  final double monthlyInstallment;
  final String? createdBy;
  final DateTime? createdAt;

  const AccountantBankLoan({
    required this.id,
    required this.companyId,
    required this.bankName,
    required this.loanType,
    required this.principalAmount,
    required this.remainingAmount,
    required this.interestRate,
    this.startDate,
    this.endDate,
    required this.monthlyInstallment,
    this.createdBy,
    this.createdAt,
  });

  factory AccountantBankLoan.fromMap(Map<String, dynamic> map) {
    return AccountantBankLoan(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      bankName: map['bank_name']?.toString() ?? '',
      loanType: map['loan_type']?.toString() ?? '',
      principalAmount: _toDouble(map['principal_amount']),
      remainingAmount: _toDouble(map['remaining_amount']),
      interestRate: _toDouble(map['interest_rate']),
      startDate: _toDate(map['start_date']),
      endDate: _toDate(map['end_date']),
      monthlyInstallment: _toDouble(map['monthly_installment']),
      createdBy: map['created_by']?.toString(),
      createdAt: _toDateTime(map['created_at']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '')) ?? 0;
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }
}

class AccountantBankLoansRepository {
  AccountantBankLoansRepository._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> create({
    required String companyId,
    required String bankName,
    required String loanType,
    required double principalAmount,
    required double remainingAmount,
    required double interestRate,
    DateTime? startDate,
    DateTime? endDate,
    required double monthlyInstallment,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد سیستم نشده است.');
    }

    await _client.from('bank_loans').insert({
      'company_id': companyId,
      'bank_name': bankName.trim(),
      'loan_type': loanType.trim(),
      'principal_amount': principalAmount,
      'remaining_amount': remainingAmount,
      'interest_rate': interestRate,
      'start_date': _dateOnly(startDate),
      'end_date': _dateOnly(endDate),
      'monthly_installment': monthlyInstallment,
      'created_by': user.id,
    });
  }

  static Future<void> update({
    required String id,
    required String bankName,
    required String loanType,
    required double principalAmount,
    required double remainingAmount,
    required double interestRate,
    DateTime? startDate,
    DateTime? endDate,
    required double monthlyInstallment,
  }) async {
    await _client
        .from('bank_loans')
        .update({
          'bank_name': bankName.trim(),
          'loan_type': loanType.trim(),
          'principal_amount': principalAmount,
          'remaining_amount': remainingAmount,
          'interest_rate': interestRate,
          'start_date': _dateOnly(startDate),
          'end_date': _dateOnly(endDate),
          'monthly_installment': monthlyInstallment,
        })
        .eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _client.from('bank_loans').delete().eq('id', id);
  }

  static String? _dateOnly(DateTime? date) {
    if (date == null) return null;

    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
