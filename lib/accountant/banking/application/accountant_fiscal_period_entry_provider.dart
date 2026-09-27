import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantFiscalPeriodEntryProvider =
    FutureProvider.family<AccountantFiscalPeriodEntryData, String>((
      ref,
      periodId,
    ) async {
      return AccountantFiscalPeriodEntryRepository.load(periodId);
    });

class AccountantFiscalPeriodEntryData {
  final AccountantFiscalPeriodInfo period;
  final List<BankAccountPeriodEntry> bankAccounts;
  final List<CashBoxPeriodEntry> cashBoxes;
  final List<PettyCashPeriodEntry> pettyCashAccounts;

  const AccountantFiscalPeriodEntryData({
    required this.period,
    required this.bankAccounts,
    required this.cashBoxes,
    required this.pettyCashAccounts,
  });
}

class AccountantFiscalPeriodInfo {
  final String id;
  final String companyId;
  final String yearId;
  final int year;
  final int month;
  final String title;
  final String status;

  const AccountantFiscalPeriodInfo({
    required this.id,
    required this.companyId,
    required this.yearId,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
  });

  bool get isOpen => status == 'open';

  bool get isSubmittedToCompanyAdmin => status == 'submitted_to_company_admin';

  bool get isSubmittedToConsultant => status == 'submitted_to_consultant';

  bool get isApproved => status == 'approved';

  bool get isClosed => status == 'closed';

  bool get canEdit => isOpen;
}

class BankAccountPeriodEntry {
  final String bankAccountId;
  final String bankName;
  final String accountNumber;
  final String? periodRecordId;

  final double openingBalance;
  final double debitTurnover;
  final double creditTurnover;
  final double closingBalance;
  final double ledgerBalance;
  final double discrepancy;

  const BankAccountPeriodEntry({
    required this.bankAccountId,
    required this.bankName,
    required this.accountNumber,
    required this.periodRecordId,
    required this.openingBalance,
    required this.debitTurnover,
    required this.creditTurnover,
    required this.closingBalance,
    required this.ledgerBalance,
    required this.discrepancy,
  });

  BankAccountPeriodEntry copyWith({
    String? periodRecordId,
    double? openingBalance,
    double? debitTurnover,
    double? creditTurnover,
    double? closingBalance,
    double? ledgerBalance,
    double? discrepancy,
  }) {
    return BankAccountPeriodEntry(
      bankAccountId: bankAccountId,
      bankName: bankName,
      accountNumber: accountNumber,
      periodRecordId: periodRecordId ?? this.periodRecordId,
      openingBalance: openingBalance ?? this.openingBalance,
      debitTurnover: debitTurnover ?? this.debitTurnover,
      creditTurnover: creditTurnover ?? this.creditTurnover,
      closingBalance: closingBalance ?? this.closingBalance,
      ledgerBalance: ledgerBalance ?? this.ledgerBalance,
      discrepancy: discrepancy ?? this.discrepancy,
    );
  }
}

class CashBoxPeriodEntry {
  final String cashBoxId;
  final String boxName;
  final String? periodRecordId;

  final double openingBalance;
  final double totalReceipts;
  final double totalPayments;
  final double closingBalance;
  final double ledgerBalance;
  final double discrepancy;

  const CashBoxPeriodEntry({
    required this.cashBoxId,
    required this.boxName,
    required this.periodRecordId,
    required this.openingBalance,
    required this.totalReceipts,
    required this.totalPayments,
    required this.closingBalance,
    required this.ledgerBalance,
    required this.discrepancy,
  });

  CashBoxPeriodEntry copyWith({
    String? periodRecordId,
    double? openingBalance,
    double? totalReceipts,
    double? totalPayments,
    double? closingBalance,
    double? ledgerBalance,
    double? discrepancy,
  }) {
    return CashBoxPeriodEntry(
      cashBoxId: cashBoxId,
      boxName: boxName,
      periodRecordId: periodRecordId ?? this.periodRecordId,
      openingBalance: openingBalance ?? this.openingBalance,
      totalReceipts: totalReceipts ?? this.totalReceipts,
      totalPayments: totalPayments ?? this.totalPayments,
      closingBalance: closingBalance ?? this.closingBalance,
      ledgerBalance: ledgerBalance ?? this.ledgerBalance,
      discrepancy: discrepancy ?? this.discrepancy,
    );
  }
}

class PettyCashPeriodEntry {
  final String pettyCashId;
  final String name;
  final String? responsibleUserId;
  final String? periodRecordId;

  final double openingBalance;
  final double totalReceipts;
  final double totalPayments;
  final double closingBalance;
  final double ledgerBalance;
  final double discrepancy;

  const PettyCashPeriodEntry({
    required this.pettyCashId,
    required this.name,
    required this.responsibleUserId,
    required this.periodRecordId,
    required this.openingBalance,
    required this.totalReceipts,
    required this.totalPayments,
    required this.closingBalance,
    required this.ledgerBalance,
    required this.discrepancy,
  });

  PettyCashPeriodEntry copyWith({
    String? periodRecordId,
    double? openingBalance,
    double? totalReceipts,
    double? totalPayments,
    double? closingBalance,
    double? ledgerBalance,
    double? discrepancy,
  }) {
    return PettyCashPeriodEntry(
      pettyCashId: pettyCashId,
      name: name,
      responsibleUserId: responsibleUserId,
      periodRecordId: periodRecordId ?? this.periodRecordId,
      openingBalance: openingBalance ?? this.openingBalance,
      totalReceipts: totalReceipts ?? this.totalReceipts,
      totalPayments: totalPayments ?? this.totalPayments,
      closingBalance: closingBalance ?? this.closingBalance,
      ledgerBalance: ledgerBalance ?? this.ledgerBalance,
      discrepancy: discrepancy ?? this.discrepancy,
    );
  }
}

class AccountantFiscalPeriodEntryRepository {
  AccountantFiscalPeriodEntryRepository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<AccountantFiscalPeriodEntryData> load(String periodId) async {
    final periodRow =
        await _supabase
            .from('cash_fiscal_periods')
            .select(
              'id, company_id, fiscal_year_id, year, month, title, status',
            )
            .eq('id', periodId)
            .maybeSingle();

    if (periodRow == null) {
      throw Exception('دوره مالی پیدا نشد.');
    }

    final companyId = periodRow['company_id'].toString();

    final bankRows = await _supabase
        .from('bank_accounts')
        .select('''
          id,
          company_id,
          bank_name,
          account_number,
          bank_account_periods(
            id,
            period_id,
            opening_balance,
            debit_turnover,
            credit_turnover,
            closing_balance,
            ledger_balance,
            discrepancy
          )
          ''')
        .eq('company_id', companyId)
        .order('bank_name');

    final cashRows = await _supabase
        .from('cash_boxes')
        .select('''
          id,
          company_id,
          box_name,
          cash_box_periods(
            id,
            period_id,
            opening_balance,
            total_receipts,
            total_payments,
            closing_balance,
            ledger_balance,
            discrepancy
          )
          ''')
        .eq('company_id', companyId)
        .order('box_name');

    final pettyRows = await _supabase
        .from('petty_cash_accounts')
        .select('''
          id,
          company_id,
          name,
          responsible_user_id,
          petty_cash_periods(
            id,
            period_id,
            opening_balance,
            total_receipts,
            total_payments,
            closing_balance,
            ledger_balance,
            discrepancy
          )
          ''')
        .eq('company_id', companyId)
        .order('name');

    final banks = <BankAccountPeriodEntry>[];

    for (final raw in bankRows) {
      final row = Map<String, dynamic>.from(raw);

      final records = _recordsForPeriod(row['bank_account_periods'], periodId);

      final record = records.isEmpty ? null : records.first;

      banks.add(
        BankAccountPeriodEntry(
          bankAccountId: row['id'].toString(),
          bankName: row['bank_name']?.toString() ?? 'بدون نام بانک',
          accountNumber: row['account_number']?.toString() ?? '',
          periodRecordId: record?['id']?.toString(),
          openingBalance: _number(record?['opening_balance']),
          debitTurnover: _number(record?['debit_turnover']),
          creditTurnover: _number(record?['credit_turnover']),
          closingBalance: _number(record?['closing_balance']),
          ledgerBalance: _number(record?['ledger_balance']),
          discrepancy: _number(record?['discrepancy']),
        ),
      );
    }

    final cashBoxes = <CashBoxPeriodEntry>[];

    for (final raw in cashRows) {
      final row = Map<String, dynamic>.from(raw);

      final records = _recordsForPeriod(row['cash_box_periods'], periodId);

      final record = records.isEmpty ? null : records.first;

      cashBoxes.add(
        CashBoxPeriodEntry(
          cashBoxId: row['id'].toString(),
          boxName: row['box_name']?.toString() ?? 'بدون نام صندوق',
          periodRecordId: record?['id']?.toString(),
          openingBalance: _number(record?['opening_balance']),
          totalReceipts: _number(record?['total_receipts']),
          totalPayments: _number(record?['total_payments']),
          closingBalance: _number(record?['closing_balance']),
          ledgerBalance: _number(record?['ledger_balance']),
          discrepancy: _number(record?['discrepancy']),
        ),
      );
    }

    final pettyCash = <PettyCashPeriodEntry>[];

    for (final raw in pettyRows) {
      final row = Map<String, dynamic>.from(raw);

      final records = _recordsForPeriod(row['petty_cash_periods'], periodId);

      final record = records.isEmpty ? null : records.first;

      pettyCash.add(
        PettyCashPeriodEntry(
          pettyCashId: row['id'].toString(),
          name: row['name']?.toString() ?? 'بدون نام تنخواه',
          responsibleUserId: row['responsible_user_id']?.toString(),
          periodRecordId: record?['id']?.toString(),
          openingBalance: _number(record?['opening_balance']),
          totalReceipts: _number(record?['total_receipts']),
          totalPayments: _number(record?['total_payments']),
          closingBalance: _number(record?['closing_balance']),
          ledgerBalance: _number(record?['ledger_balance']),
          discrepancy: _number(record?['discrepancy']),
        ),
      );
    }

    return AccountantFiscalPeriodEntryData(
      period: AccountantFiscalPeriodInfo(
        id: periodRow['id'].toString(),
        companyId: companyId,
        yearId: periodRow['fiscal_year_id'].toString(),
        year: _int(periodRow['year']),
        month: _int(periodRow['month']),
        title: periodRow['title']?.toString() ?? '',
        status: periodRow['status']?.toString() ?? 'open',
      ),
      bankAccounts: banks,
      cashBoxes: cashBoxes,
      pettyCashAccounts: pettyCash,
    );
  }

  static Future<void> saveBankAccount({
    required String periodId,
    required String companyId,
    required BankAccountPeriodEntry entry,
  }) async {
    await _ensureEditable(periodId);

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('کاربر وارد نشده است.');
    }

    final payload = <String, dynamic>{
      'company_id': companyId,
      'period_id': periodId,
      'bank_account_id': entry.bankAccountId,
      'opening_balance': entry.openingBalance,
      'debit_turnover': entry.debitTurnover,
      'credit_turnover': entry.creditTurnover,
      'closing_balance': entry.closingBalance,
      'ledger_balance': entry.ledgerBalance,
      'discrepancy': entry.discrepancy,
      'created_by': userId,
    };

    if (entry.periodRecordId != null) {
      await _supabase
          .from('bank_account_periods')
          .update({
            'opening_balance': entry.openingBalance,
            'debit_turnover': entry.debitTurnover,
            'credit_turnover': entry.creditTurnover,
            'closing_balance': entry.closingBalance,
            'ledger_balance': entry.ledgerBalance,
            'discrepancy': entry.discrepancy,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', entry.periodRecordId!);
    } else {
      await _supabase.from('bank_account_periods').insert(payload);
    }
  }

  static Future<void> saveCashBox({
    required String periodId,
    required String companyId,
    required CashBoxPeriodEntry entry,
  }) async {
    await _ensureEditable(periodId);

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('کاربر وارد نشده است.');
    }

    final payload = <String, dynamic>{
      'company_id': companyId,
      'period_id': periodId,
      'cash_box_id': entry.cashBoxId,
      'opening_balance': entry.openingBalance,
      'total_receipts': entry.totalReceipts,
      'total_payments': entry.totalPayments,
      'closing_balance': entry.closingBalance,
      'ledger_balance': entry.ledgerBalance,
      'discrepancy': entry.discrepancy,
      'created_by': userId,
    };

    if (entry.periodRecordId != null) {
      await _supabase
          .from('cash_box_periods')
          .update({
            'opening_balance': entry.openingBalance,
            'total_receipts': entry.totalReceipts,
            'total_payments': entry.totalPayments,
            'closing_balance': entry.closingBalance,
            'ledger_balance': entry.ledgerBalance,
            'discrepancy': entry.discrepancy,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', entry.periodRecordId!);
    } else {
      await _supabase.from('cash_box_periods').insert(payload);
    }
  }

  static Future<void> savePettyCash({
    required String periodId,
    required String companyId,
    required PettyCashPeriodEntry entry,
  }) async {
    await _ensureEditable(periodId);

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('کاربر وارد نشده است.');
    }

    final payload = <String, dynamic>{
      'company_id': companyId,
      'period_id': periodId,
      'petty_cash_id': entry.pettyCashId,
      'opening_balance': entry.openingBalance,
      'total_receipts': entry.totalReceipts,
      'total_payments': entry.totalPayments,
      'closing_balance': entry.closingBalance,
      'ledger_balance': entry.ledgerBalance,
      'discrepancy': entry.discrepancy,
      'created_by': userId,
    };

    if (entry.periodRecordId != null) {
      await _supabase
          .from('petty_cash_periods')
          .update({
            'opening_balance': entry.openingBalance,
            'total_receipts': entry.totalReceipts,
            'total_payments': entry.totalPayments,
            'closing_balance': entry.closingBalance,
            'ledger_balance': entry.ledgerBalance,
            'discrepancy': entry.discrepancy,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', entry.periodRecordId!);
    } else {
      await _supabase.from('petty_cash_periods').insert(payload);
    }
  }

  static Future<void> submitToCompanyAdmin({
    required String periodId,
    String? note,
  }) async {
    await _supabase.rpc(
      'submit_cash_fiscal_period',
      params: {
        'p_period_id': periodId,
        'p_target_status': 'submitted_to_company_admin',
        'p_note': note,
      },
    );
  }

  static Future<void> _ensureEditable(String periodId) async {
    final row =
        await _supabase
            .from('cash_fiscal_periods')
            .select('status')
            .eq('id', periodId)
            .maybeSingle();

    if (row == null) {
      throw Exception('دوره مالی پیدا نشد.');
    }

    final status = row['status']?.toString();

    if (status != 'open') {
      throw Exception(
        'این دوره دیگر در وضعیت ثبت اولیه نیست و امکان ویرایش ندارد.',
      );
    }
  }

  static List<Map<String, dynamic>> _recordsForPeriod(
    dynamic value,
    String periodId,
  ) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['period_id']?.toString() == periodId)
        .toList();
  }

  static double _number(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0;
  }

  static int _int(dynamic value) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }
}
