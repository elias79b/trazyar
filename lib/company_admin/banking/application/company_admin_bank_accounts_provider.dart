import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final companyAdminBankAccountsProvider =
FutureProvider.autoDispose<List<CompanyAdminBankAccount>>((ref) async {
  final client = Supabase.instance.client;

  final user = client.auth.currentUser;

  if (user == null) {
    throw Exception('کاربر وارد نشده است.');
  }

  final companyUser = await client
      .from('company_users')
      .select('company_id, role, is_active')
      .eq('user_id', user.id)
      .eq('role', 'company_admin')
      .eq('is_active', true)
      .maybeSingle();

  if (companyUser == null) {
    throw Exception('شرکت فعال برای این مدیرعامل پیدا نشد.');
  }

  final companyId = companyUser['company_id'] as String;

  final accounts = await client
      .from('bank_accounts')
      .select('id, company_id, bank_name, account_number')
      .eq('company_id', companyId)
      .order('bank_name');

  if (accounts.isEmpty) {
    return [];
  }

  final latestPeriod = await client
      .from('cash_fiscal_periods')
      .select('id, year, month, status')
      .eq('company_id', companyId)
      .eq('status', 'approved')
      .order('year', ascending: false)
      .order('month', ascending: false)
      .limit(1)
      .maybeSingle();

  Map<String, dynamic> periodRowsByAccount = {};

  if (latestPeriod != null) {
    final periodId = latestPeriod['id'] as String;

    final periodRows = await client
        .from('bank_account_periods')
        .select(
      'bank_account_id, opening_balance, debit_turnover, '
          'credit_turnover, closing_balance, ledger_balance, discrepancy',
    )
        .eq('company_id', companyId)
        .eq('period_id', periodId);

    for (final row in periodRows) {
      final bankAccountId = row['bank_account_id'];

      if (bankAccountId != null) {
        periodRowsByAccount[bankAccountId.toString()] = row;
      }
    }
  }

  return accounts.map<CompanyAdminBankAccount>((row) {
    final accountId = row['id'].toString();

    final period = periodRowsByAccount[accountId];

    return CompanyAdminBankAccount(
      id: accountId,
      companyId: row['company_id'].toString(),
      bankName: row['bank_name']?.toString() ?? '',
      accountNumber: row['account_number']?.toString() ?? '',
      openingBalance: _toDouble(period?['opening_balance']),
      debitTurnover: _toDouble(period?['debit_turnover']),
      creditTurnover: _toDouble(period?['credit_turnover']),
      closingBalance: _toDouble(period?['closing_balance']),
      ledgerBalance: _toDouble(period?['ledger_balance']),
      discrepancy: _toDouble(period?['discrepancy']),
      hasPeriodData: period != null,
    );
  }).toList();
});

final companyAdminBankAccountsControllerProvider =
AsyncNotifierProvider<CompanyAdminBankAccountsController, void>(
  CompanyAdminBankAccountsController.new,
);

class CompanyAdminBankAccountsController extends AsyncNotifier<void> {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<void> build() async {}

  Future<String> _getCompanyId() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد نشده است.');
    }

    final companyUser = await _client
        .from('company_users')
        .select('company_id')
        .eq('user_id', user.id)
        .eq('role', 'company_admin')
        .eq('is_active', true)
        .maybeSingle();

    if (companyUser == null) {
      throw Exception('شرکت فعال برای این مدیرعامل پیدا نشد.');
    }

    return companyUser['company_id'].toString();
  }

  Future<void> addAccount({
    required String bankName,
    required String accountNumber,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final companyId = await _getCompanyId();

      await _client.from('bank_accounts').insert({
        'company_id': companyId,
        'bank_name': bankName.trim(),
        'account_number': accountNumber.trim(),
      });

      ref.invalidate(companyAdminBankAccountsProvider);
    });
  }

  Future<void> updateAccount({
    required String accountId,
    required String bankName,
    required String accountNumber,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final companyId = await _getCompanyId();

      await _client
          .from('bank_accounts')
          .update({
        'bank_name': bankName.trim(),
        'account_number': accountNumber.trim(),
      })
          .eq('id', accountId)
          .eq('company_id', companyId);

      ref.invalidate(companyAdminBankAccountsProvider);
    });
  }

  Future<void> deleteAccount({
    required String accountId,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final companyId = await _getCompanyId();

      await _client
          .from('bank_accounts')
          .delete()
          .eq('id', accountId)
          .eq('company_id', companyId);

      ref.invalidate(companyAdminBankAccountsProvider);
    });
  }
}

class CompanyAdminBankAccount {
  final String id;
  final String companyId;
  final String bankName;
  final String accountNumber;

  final double openingBalance;
  final double debitTurnover;
  final double creditTurnover;
  final double closingBalance;
  final double ledgerBalance;
  final double discrepancy;

  final bool hasPeriodData;

  const CompanyAdminBankAccount({
    required this.id,
    required this.companyId,
    required this.bankName,
    required this.accountNumber,
    required this.openingBalance,
    required this.debitTurnover,
    required this.creditTurnover,
    required this.closingBalance,
    required this.ledgerBalance,
    required this.discrepancy,
    required this.hasPeriodData,
  });

  bool get hasDiscrepancy => discrepancy.abs() > 0.01;
}

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}