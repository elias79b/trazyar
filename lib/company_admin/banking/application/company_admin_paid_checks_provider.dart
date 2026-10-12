import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyAdminPaidCheck {
  final String id;
  final String companyId;
  final String? checkNumber;
  final String? bankName;
  final double amount;
  final DateTime? dueDate;
  final String status;
  final DateTime? createdAt;

  const CompanyAdminPaidCheck({
    required this.id,
    required this.companyId,
    this.checkNumber,
    this.bankName,
    required this.amount,
    this.dueDate,
    required this.status,
    this.createdAt,
  });

  factory CompanyAdminPaidCheck.fromMap(Map<String, dynamic> map) {
    return CompanyAdminPaidCheck(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      checkNumber: map['check_number'] as String?,
      bankName: map['bank_name'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      dueDate:
          map['due_date'] != null
              ? DateTime.tryParse(map['due_date'].toString())
              : null,
      status: (map['status'] as String?) ?? 'pending',
      createdAt:
          map['created_at'] != null
              ? DateTime.tryParse(map['created_at'].toString())
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'check_number': checkNumber,
      'bank_name': bankName,
      'amount': amount,
      'due_date': dueDate?.toIso8601String().split('T').first,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class CompanyAdminPaidChecksState {
  final bool isLoading;
  final String? error;
  final List<CompanyAdminPaidCheck> checks;

  const CompanyAdminPaidChecksState({
    this.isLoading = false,
    this.error,
    this.checks = const [],
  });

  CompanyAdminPaidChecksState copyWith({
    bool? isLoading,
    String? error,
    List<CompanyAdminPaidCheck>? checks,
    bool clearError = false,
  }) {
    return CompanyAdminPaidChecksState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      checks: checks ?? this.checks,
    );
  }
}

final companyAdminPaidChecksProvider = StateNotifierProvider<
  CompanyAdminPaidChecksNotifier,
  CompanyAdminPaidChecksState
>((ref) => CompanyAdminPaidChecksNotifier());

class CompanyAdminPaidChecksNotifier
    extends StateNotifier<CompanyAdminPaidChecksState> {
  CompanyAdminPaidChecksNotifier() : super(const CompanyAdminPaidChecksState());

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> _getCompanyId() async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('کاربر وارد نشده است.');
    }

    final response =
        await _supabase
            .from('company_users')
            .select('company_id')
            .eq('user_id', userId)
            .eq('role', 'company_admin')
            .eq('is_active', true)
            .maybeSingle();

    if (response == null) {
      throw Exception('شرکت فعال برای کاربر پیدا نشد.');
    }

    return response['company_id'] as String;
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final companyId = await _getCompanyId();

      if (companyId == null) {
        throw Exception('شناسه شرکت پیدا نشد.');
      }

      final response = await _supabase
          .from('paid_checks')
          .select(
            'id, company_id, check_number, bank_name, amount, due_date, status, created_at',
          )
          .eq('company_id', companyId)
          .order('due_date', ascending: true);

      final checks =
          (response as List)
              .map(
                (item) => CompanyAdminPaidCheck.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();

      state = state.copyWith(isLoading: false, checks: checks);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createCheck({
    required String checkNumber,
    required String bankName,
    required double amount,
    required DateTime? dueDate,
    required String status,
  }) async {
    final companyId = await _getCompanyId();

    if (companyId == null) {
      throw Exception('شناسه شرکت پیدا نشد.');
    }

    await _supabase.from('paid_checks').insert({
      'company_id': companyId,
      'check_number': checkNumber.trim().isEmpty ? null : checkNumber.trim(),
      'bank_name': bankName.trim().isEmpty ? null : bankName.trim(),
      'amount': amount,
      'due_date':
          dueDate == null ? null : dueDate.toIso8601String().split('T').first,
      'status': status,
    });

    await load();
  }

  Future<void> updateCheck({
    required String id,
    required String checkNumber,
    required String bankName,
    required double amount,
    required DateTime? dueDate,
    required String status,
  }) async {
    await _supabase
        .from('paid_checks')
        .update({
          'check_number':
              checkNumber.trim().isEmpty ? null : checkNumber.trim(),
          'bank_name': bankName.trim().isEmpty ? null : bankName.trim(),
          'amount': amount,
          'due_date':
              dueDate == null
                  ? null
                  : dueDate.toIso8601String().split('T').first,
          'status': status,
        })
        .eq('id', id);

    await load();
  }

  Future<void> deleteCheck(String id) async {
    await _supabase.from('paid_checks').delete().eq('id', id);

    await load();
  }
}
