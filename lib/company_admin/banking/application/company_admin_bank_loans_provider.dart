import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final companyAdminBankLoansProvider =
    FutureProvider.autoDispose<List<CompanyAdminBankLoan>>((ref) async {
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
            (item) => CompanyAdminBankLoan.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    });

class CompanyAdminBankLoan {
  final String id;
  final String companyId;
  final String bankName;
  final String? loanType;
  final double principalAmount;
  final double remainingAmount;
  final double interestRate;
  final DateTime? startDate;
  final DateTime? endDate;
  final double monthlyInstallment;
  final String? createdBy;
  final DateTime? createdAt;

  const CompanyAdminBankLoan({
    required this.id,
    required this.companyId,
    required this.bankName,
    this.loanType,
    required this.principalAmount,
    required this.remainingAmount,
    required this.interestRate,
    this.startDate,
    this.endDate,
    required this.monthlyInstallment,
    this.createdBy,
    this.createdAt,
  });

  factory CompanyAdminBankLoan.fromMap(Map<String, dynamic> map) {
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

    return CompanyAdminBankLoan(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      bankName: map['bank_name'] as String? ?? '',
      loanType: map['loan_type'] as String?,
      principalAmount: number(map['principal_amount']),
      remainingAmount: number(map['remaining_amount']),
      interestRate: number(map['interest_rate']),
      startDate: date(map['start_date']),
      endDate: date(map['end_date']),
      monthlyInstallment: number(map['monthly_installment']),
      createdBy: map['created_by'] as String?,
      createdAt: date(map['created_at']),
    );
  }
}

class CompanyAdminBankLoansController {
  final Ref ref;
  final SupabaseClient supabase;

  CompanyAdminBankLoansController(this.ref, this.supabase);

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

  Future<void> addLoan({
    required String bankName,
    required String loanType,
    required double principalAmount,
    required double remainingAmount,
    required double interestRate,
    DateTime? startDate,
    DateTime? endDate,
    required double monthlyInstallment,
  }) async {
    final companyId = await _getCompanyId();
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد نشده است.');
    }

    await supabase.from('bank_loans').insert({
      'company_id': companyId,
      'bank_name': bankName.trim(),
      'loan_type': loanType.trim().isEmpty ? null : loanType.trim(),
      'principal_amount': principalAmount,
      'remaining_amount': remainingAmount,
      'interest_rate': interestRate,
      'start_date': startDate == null ? null : _dateOnly(startDate),
      'end_date': endDate == null ? null : _dateOnly(endDate),
      'monthly_installment': monthlyInstallment,
      'created_by': user.id,
    });

    ref.invalidate(companyAdminBankLoansProvider);
  }

  Future<void> updateLoan({
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
    final companyId = await _getCompanyId();

    await supabase
        .from('bank_loans')
        .update({
          'bank_name': bankName.trim(),
          'loan_type': loanType.trim().isEmpty ? null : loanType.trim(),
          'principal_amount': principalAmount,
          'remaining_amount': remainingAmount,
          'interest_rate': interestRate,
          'start_date': startDate == null ? null : _dateOnly(startDate),
          'end_date': endDate == null ? null : _dateOnly(endDate),
          'monthly_installment': monthlyInstallment,
        })
        .eq('id', id)
        .eq('company_id', companyId);

    ref.invalidate(companyAdminBankLoansProvider);
  }

  Future<void> deleteLoan(String id) async {
    final companyId = await _getCompanyId();

    await supabase
        .from('bank_loans')
        .delete()
        .eq('id', id)
        .eq('company_id', companyId);

    ref.invalidate(companyAdminBankLoansProvider);
  }

  String _dateOnly(DateTime date) {
    final local = date.toLocal();

    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}

final companyAdminBankLoansControllerProvider =
    Provider<CompanyAdminBankLoansController>((ref) {
      return CompanyAdminBankLoansController(ref, Supabase.instance.client);
    });
