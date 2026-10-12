import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final companyAdminPettyCashProvider =
    FutureProvider.autoDispose<List<CompanyAdminPettyCash>>((ref) async {
      final supabase = Supabase.instance.client;

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('کاربر وارد نشده است.');
      }

      final companyUserResponse =
          await supabase
              .from('company_users')
              .select('company_id')
              .eq('user_id', currentUser.id)
              .eq('role', 'company_admin')
              .eq('is_active', true)
              .limit(1)
              .maybeSingle();

      if (companyUserResponse == null) {
        throw Exception('شرکت فعال برای کاربر پیدا نشد.');
      }

      final companyId = companyUserResponse['company_id'] as String;

      final accountsResponse = await supabase
          .from('petty_cash_accounts')
          .select(
            'id, company_id, name, responsible_user_id, created_by, created_at',
          )
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      final accounts =
          (accountsResponse as List)
              .map(
                (item) => CompanyAdminPettyCash.fromMap(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList();

      if (accounts.isEmpty) {
        return [];
      }

      String? latestPeriodId;

      final periodsResponse =
          await supabase
              .from('cash_fiscal_periods')
              .select('id')
              .eq('company_id', companyId)
              .eq('status', 'approved')
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      if (periodsResponse != null) {
        latestPeriodId = periodsResponse['id'] as String?;
      }

      if (latestPeriodId == null) {
        return accounts;
      }

      final pettyCashIds = accounts.map((e) => e.id).toList();

      final pettyPeriodsResponse = await supabase
          .from('petty_cash_periods')
          .select('''
        id,
        company_id,
        period_id,
        petty_cash_id,
        opening_balance,
        total_receipts,
        total_payments,
        closing_balance,
        ledger_balance,
        discrepancy,
        created_by,
        created_at,
        updated_at
        ''')
          .eq('company_id', companyId)
          .eq('period_id', latestPeriodId)
          .inFilter('petty_cash_id', pettyCashIds);

      final periodMap = <String, PettyCashPeriodData>{};

      for (final item in pettyPeriodsResponse as List) {
        final map = Map<String, dynamic>.from(item as Map);
        final pettyCashId = map['petty_cash_id'] as String?;

        if (pettyCashId == null) {
          continue;
        }

        periodMap[pettyCashId] = PettyCashPeriodData.fromMap(map);
      }

      return accounts
          .map((account) => account.copyWith(periodData: periodMap[account.id]))
          .toList();
    });

class CompanyAdminPettyCash {
  final String id;
  final String companyId;
  final String name;
  final String? responsibleUserId;
  final String? createdBy;
  final DateTime? createdAt;
  final PettyCashPeriodData? periodData;

  const CompanyAdminPettyCash({
    required this.id,
    required this.companyId,
    required this.name,
    this.responsibleUserId,
    this.createdBy,
    this.createdAt,
    this.periodData,
  });

  factory CompanyAdminPettyCash.fromMap(Map<String, dynamic> map) {
    return CompanyAdminPettyCash(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      name: map['name'] as String,
      responsibleUserId: map['responsible_user_id'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt:
          map['created_at'] == null
              ? null
              : DateTime.tryParse(map['created_at'].toString()),
    );
  }

  CompanyAdminPettyCash copyWith({PettyCashPeriodData? periodData}) {
    return CompanyAdminPettyCash(
      id: id,
      companyId: companyId,
      name: name,
      responsibleUserId: responsibleUserId,
      createdBy: createdBy,
      createdAt: createdAt,
      periodData: periodData ?? this.periodData,
    );
  }
}

class PettyCashPeriodData {
  final String id;
  final String companyId;
  final String periodId;
  final String pettyCashId;
  final double openingBalance;
  final double totalReceipts;
  final double totalPayments;
  final double closingBalance;
  final double ledgerBalance;
  final double discrepancy;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PettyCashPeriodData({
    required this.id,
    required this.companyId,
    required this.periodId,
    required this.pettyCashId,
    required this.openingBalance,
    required this.totalReceipts,
    required this.totalPayments,
    required this.closingBalance,
    required this.ledgerBalance,
    required this.discrepancy,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory PettyCashPeriodData.fromMap(Map<String, dynamic> map) {
    double number(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    return PettyCashPeriodData(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      periodId: map['period_id'] as String,
      pettyCashId: map['petty_cash_id'] as String,
      openingBalance: number(map['opening_balance']),
      totalReceipts: number(map['total_receipts']),
      totalPayments: number(map['total_payments']),
      closingBalance: number(map['closing_balance']),
      ledgerBalance: number(map['ledger_balance']),
      discrepancy: number(map['discrepancy']),
      createdBy: map['created_by'] as String?,
      createdAt:
          map['created_at'] == null
              ? null
              : DateTime.tryParse(map['created_at'].toString()),
      updatedAt:
          map['updated_at'] == null
              ? null
              : DateTime.tryParse(map['updated_at'].toString()),
    );
  }
}

class CompanyAdminPettyCashController {
  final Ref ref;
  final SupabaseClient supabase;

  CompanyAdminPettyCashController(this.ref, this.supabase);

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

  Future<void> addPettyCash({
    required String name,
    String? responsibleUserId,
  }) async {
    final companyId = await _getCompanyId();
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد نشده است.');
    }

    await supabase.from('petty_cash_accounts').insert({
      'company_id': companyId,
      'name': name.trim(),
      'responsible_user_id':
          responsibleUserId == null || responsibleUserId.trim().isEmpty
              ? null
              : responsibleUserId.trim(),
      'created_by': user.id,
    });

    ref.invalidate(companyAdminPettyCashProvider);
  }

  Future<void> updatePettyCash({
    required String id,
    required String name,
    String? responsibleUserId,
  }) async {
    final companyId = await _getCompanyId();

    await supabase
        .from('petty_cash_accounts')
        .update({
          'name': name.trim(),
          'responsible_user_id':
              responsibleUserId == null || responsibleUserId.trim().isEmpty
                  ? null
                  : responsibleUserId.trim(),
        })
        .eq('id', id)
        .eq('company_id', companyId);

    ref.invalidate(companyAdminPettyCashProvider);
  }

  Future<void> deletePettyCash(String id) async {
    final companyId = await _getCompanyId();

    await supabase
        .from('petty_cash_accounts')
        .delete()
        .eq('id', id)
        .eq('company_id', companyId);

    ref.invalidate(companyAdminPettyCashProvider);
  }
}

final companyAdminPettyCashControllerProvider =
    Provider<CompanyAdminPettyCashController>((ref) {
      return CompanyAdminPettyCashController(ref, Supabase.instance.client);
    });
