import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final companyAdminCashBoxesProvider =
    FutureProvider.autoDispose<List<CompanyAdminCashBox>>((ref) async {
      final client = Supabase.instance.client;

      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('کاربر وارد نشده است.');
      }

      final companyUser =
          await client
              .from('company_users')
              .select('company_id')
              .eq('user_id', user.id)
              .eq('role', 'company_admin')
              .eq('is_active', true)
              .maybeSingle();

      if (companyUser == null) {
        throw Exception('شرکت فعال برای این مدیرعامل پیدا نشد.');
      }

      final companyId = companyUser['company_id'].toString();

      final boxes = await client
          .from('cash_boxes')
          .select('id, company_id, box_name, created_by, created_at')
          .eq('company_id', companyId)
          .order('box_name');

      if (boxes.isEmpty) {
        return [];
      }

      final latestPeriod =
          await client
              .from('cash_fiscal_periods')
              .select('id, year, month, status')
              .eq('company_id', companyId)
              .eq('status', 'approved')
              .order('year', ascending: false)
              .order('month', ascending: false)
              .limit(1)
              .maybeSingle();

      final Map<String, Map<String, dynamic>> periodRows = {};

      if (latestPeriod != null) {
        final periodId = latestPeriod['id'].toString();

        final rows = await client
            .from('cash_box_periods')
            .select(
              'cash_box_id, opening_balance, total_receipts, '
              'total_payments, closing_balance, ledger_balance, discrepancy',
            )
            .eq('company_id', companyId)
            .eq('period_id', periodId);

        for (final row in rows) {
          final cashBoxId = row['cash_box_id'];

          if (cashBoxId != null) {
            periodRows[cashBoxId.toString()] = Map<String, dynamic>.from(row);
          }
        }
      }

      return boxes.map<CompanyAdminCashBox>((row) {
        final id = row['id'].toString();

        final period = periodRows[id];

        return CompanyAdminCashBox(
          id: id,
          companyId: row['company_id'].toString(),
          boxName: row['box_name']?.toString() ?? '',
          createdBy: row['created_by']?.toString(),
          createdAt: row['created_at']?.toString(),
          openingBalance: _toDouble(period?['opening_balance']),
          totalReceipts: _toDouble(period?['total_receipts']),
          totalPayments: _toDouble(period?['total_payments']),
          closingBalance: _toDouble(period?['closing_balance']),
          ledgerBalance: _toDouble(period?['ledger_balance']),
          discrepancy: _toDouble(period?['discrepancy']),
          hasPeriodData: period != null,
        );
      }).toList();
    });

final companyAdminCashBoxesControllerProvider =
    AsyncNotifierProvider<CompanyAdminCashBoxesController, void>(
      CompanyAdminCashBoxesController.new,
    );

class CompanyAdminCashBoxesController extends AsyncNotifier<void> {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<void> build() async {}

  Future<String> _getCompanyId() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد نشده است.');
    }

    final companyUser =
        await _client
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

  Future<void> addCashBox({required String boxName}) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final companyId = await _getCompanyId();
      final user = _client.auth.currentUser;

      await _client.from('cash_boxes').insert({
        'company_id': companyId,
        'box_name': boxName.trim(),
        'created_by': user?.id,
      });

      ref.invalidate(companyAdminCashBoxesProvider);
    });
  }

  Future<void> updateCashBox({
    required String cashBoxId,
    required String boxName,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final companyId = await _getCompanyId();

      await _client
          .from('cash_boxes')
          .update({'box_name': boxName.trim()})
          .eq('id', cashBoxId)
          .eq('company_id', companyId);

      ref.invalidate(companyAdminCashBoxesProvider);
    });
  }

  Future<void> deleteCashBox({required String cashBoxId}) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final companyId = await _getCompanyId();

      await _client
          .from('cash_boxes')
          .delete()
          .eq('id', cashBoxId)
          .eq('company_id', companyId);

      ref.invalidate(companyAdminCashBoxesProvider);
    });
  }
}

class CompanyAdminCashBox {
  final String id;
  final String companyId;
  final String boxName;
  final String? createdBy;
  final String? createdAt;

  final double openingBalance;
  final double totalReceipts;
  final double totalPayments;
  final double closingBalance;
  final double ledgerBalance;
  final double discrepancy;

  final bool hasPeriodData;

  const CompanyAdminCashBox({
    required this.id,
    required this.companyId,
    required this.boxName,
    required this.createdBy,
    required this.createdAt,
    required this.openingBalance,
    required this.totalReceipts,
    required this.totalPayments,
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
