import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ============================================================
// BANK ACCOUNT MODEL
// ============================================================

class BankAccountModel {
  const BankAccountModel({
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
    this.fiscalYear,
    this.fiscalMonth,
  });

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

  final int? fiscalYear;
  final int? fiscalMonth;

  factory BankAccountModel.fromMap(Map<String, dynamic> map) {
    return BankAccountModel(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      bankName: map['bank_name']?.toString() ?? '',
      accountNumber: map['account_number']?.toString() ?? '',
      openingBalance: _toDouble(map['opening_balance']),
      debitTurnover: _toDouble(map['debit_turnover']),
      creditTurnover: _toDouble(map['credit_turnover']),
      closingBalance: _toDouble(map['closing_balance']),
      ledgerBalance: _toDouble(map['ledger_balance']),
      discrepancy: _toDouble(map['discrepancy']),
      fiscalYear: _toInt(map['fiscal_year']),
      fiscalMonth: _toInt(map['fiscal_month']),
    );
  }
}

// ============================================================
// CASH BOX MODEL
// ============================================================

class CashBoxModel {
  const CashBoxModel({
    required this.id,
    required this.companyId,
    required this.boxName,
    required this.openingBalance,
    required this.totalReceipts,
    required this.totalPayments,
    required this.closingBalance,
    required this.ledgerBalance,
    required this.discrepancy,
    this.fiscalYear,
    this.fiscalMonth,
  });

  final String id;
  final String companyId;
  final String boxName;

  final double openingBalance;
  final double totalReceipts;
  final double totalPayments;
  final double closingBalance;
  final double ledgerBalance;
  final double discrepancy;

  final int? fiscalYear;
  final int? fiscalMonth;

  factory CashBoxModel.fromMap(Map<String, dynamic> map) {
    return CashBoxModel(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      boxName: map['box_name']?.toString() ?? '',
      openingBalance: _toDouble(map['opening_balance']),
      totalReceipts: _toDouble(map['total_receipts']),
      totalPayments: _toDouble(map['total_payments']),
      closingBalance: _toDouble(map['closing_balance']),
      ledgerBalance: _toDouble(map['ledger_balance']),
      discrepancy: _toDouble(map['discrepancy']),
      fiscalYear: _toInt(map['fiscal_year']),
      fiscalMonth: _toInt(map['fiscal_month']),
    );
  }
}

// ============================================================
// BANK LOAN MODEL
// ============================================================

class BankLoanModel {
  const BankLoanModel({
    required this.id,
    required this.companyId,
    required this.bankName,
    required this.loanType,
    required this.principalAmount,
    required this.remainingAmount,
    required this.interestRate,
    required this.startDate,
    required this.endDate,
    required this.monthlyInstallment,
  });

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

  factory BankLoanModel.fromMap(Map<String, dynamic> map) {
    return BankLoanModel(
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
    );
  }
}

// ============================================================
// PETTY CASH MODEL
// ============================================================

class PettyCashModel {
  const PettyCashModel({
    required this.id,
    required this.companyId,
    required this.name,
    required this.responsibleUserId,
    required this.openingBalance,
    required this.totalReceipts,
    required this.totalPayments,
    required this.closingBalance,
    required this.ledgerBalance,
    required this.discrepancy,
    this.fiscalYear,
    this.fiscalMonth,
  });

  final String id;
  final String companyId;
  final String name;
  final String? responsibleUserId;

  final double openingBalance;
  final double totalReceipts;
  final double totalPayments;
  final double closingBalance;
  final double ledgerBalance;
  final double discrepancy;

  final int? fiscalYear;
  final int? fiscalMonth;

  factory PettyCashModel.fromMap(Map<String, dynamic> map) {
    return PettyCashModel(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      responsibleUserId: map['responsible_user_id']?.toString(),
      openingBalance: _toDouble(map['opening_balance']),
      totalReceipts: _toDouble(map['total_receipts']),
      totalPayments: _toDouble(map['total_payments']),
      closingBalance: _toDouble(map['closing_balance']),
      ledgerBalance: _toDouble(map['ledger_balance']),
      discrepancy: _toDouble(map['discrepancy']),
      fiscalYear: _toInt(map['fiscal_year']),
      fiscalMonth: _toInt(map['fiscal_month']),
    );
  }
}

// ============================================================
// CHECK MODEL
// ============================================================

class CheckModel {
  const CheckModel({
    required this.id,
    required this.companyId,
    required this.checkNumber,
    required this.bankName,
    required this.amount,
    required this.dueDate,
    required this.status,
  });

  final String id;
  final String companyId;
  final String checkNumber;
  final String bankName;
  final double amount;
  final DateTime? dueDate;
  final String status;

  factory CheckModel.fromMap(Map<String, dynamic> map) {
    return CheckModel(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      checkNumber: map['check_number']?.toString() ?? '',
      bankName: map['bank_name']?.toString() ?? '',
      amount: _toDouble(map['amount']),
      dueDate: _toDate(map['due_date']),
      status: map['status']?.toString() ?? '',
    );
  }
}

// ============================================================
// CHECK SUMMARY
// ============================================================

class CheckSummary {
  const CheckSummary({
    required this.count,
    required this.totalAmount,
    required this.checks,
  });

  final int count;
  final double totalAmount;
  final List<CheckModel> checks;
}

// ============================================================
// BANKING DASHBOARD DATA
// ============================================================

class BankingDashboardData {
  const BankingDashboardData({
    required this.bankAccounts,
    required this.cashBoxes,
    required this.bankLoans,
    required this.pettyCashAccounts,
    required this.receivedChecks,
    required this.paidChecks,
  });

  final List<BankAccountModel> bankAccounts;
  final List<CashBoxModel> cashBoxes;
  final List<BankLoanModel> bankLoans;
  final List<PettyCashModel> pettyCashAccounts;

  final CheckSummary receivedChecks;
  final CheckSummary paidChecks;

  // ==========================================================
  // BANK
  // ==========================================================

  double get totalBankBalance {
    return bankAccounts.fold(0, (sum, item) => sum + item.closingBalance);
  }

  // ==========================================================
  // CASH BOX
  // ==========================================================

  double get totalCashBalance {
    return cashBoxes.fold(0, (sum, item) => sum + item.closingBalance);
  }

  // ==========================================================
  // PETTY CASH
  // ==========================================================

  double get totalPettyCashBalance {
    return pettyCashAccounts.fold(0, (sum, item) => sum + item.closingBalance);
  }

  double get totalPettyCashReceipts {
    return pettyCashAccounts.fold(0, (sum, item) => sum + item.totalReceipts);
  }

  double get totalPettyCashPayments {
    return pettyCashAccounts.fold(0, (sum, item) => sum + item.totalPayments);
  }

  double get totalPettyCashDiscrepancy {
    return pettyCashAccounts.fold(0, (sum, item) => sum + item.discrepancy);
  }

  int get pettyCashDiscrepancyCount {
    return pettyCashAccounts.where((item) => item.discrepancy != 0).length;
  }

  // ==========================================================
  // TOTAL LIQUIDITY
  // ==========================================================

  double get totalLiquidity {
    return totalBankBalance + totalCashBalance + totalPettyCashBalance;
  }

  // ==========================================================
  // BANK DISCREPANCY
  // ==========================================================

  double get totalBankDiscrepancy {
    return bankAccounts.fold(0, (sum, item) => sum + item.discrepancy);
  }

  int get bankDiscrepancyCount {
    return bankAccounts.where((item) => item.discrepancy != 0).length;
  }

  // ==========================================================
  // CASH DISCREPANCY
  // ==========================================================

  double get totalCashDiscrepancy {
    return cashBoxes.fold(0, (sum, item) => sum + item.discrepancy);
  }

  int get cashDiscrepancyCount {
    return cashBoxes.where((item) => item.discrepancy != 0).length;
  }

  // ==========================================================
  // LOANS
  // ==========================================================

  double get totalLoanPrincipal {
    return bankLoans.fold(0, (sum, item) => sum + item.principalAmount);
  }

  double get totalLoanRemaining {
    return bankLoans.fold(0, (sum, item) => sum + item.remainingAmount);
  }

  double get totalMonthlyInstallments {
    return bankLoans.fold(0, (sum, item) => sum + item.monthlyInstallment);
  }

  int get loanCount {
    return bankLoans.length;
  }
}

// ============================================================
// BANKING REPOSITORY
// ============================================================

class BankingRepository {
  BankingRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // ==========================================================
  // BANK ACCOUNT CRUD
  // ==========================================================

  Future<void> createBankAccount({
    required String companyId,
    required String bankName,
    required String accountNumber,
    required double openingBalance,
    required double debitTurnover,
    required double creditTurnover,
    required double closingBalance,
    required double ledgerBalance,
    required double discrepancy,
    int? fiscalYear,
    int? fiscalMonth,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد نشده است.');
    }

    await _client.from('bank_accounts').insert({
      'company_id': companyId,
      'bank_name': bankName.trim(),
      'account_number': accountNumber.trim(),
      'opening_balance': openingBalance,
      'debit_turnover': debitTurnover,
      'credit_turnover': creditTurnover,
      'closing_balance': closingBalance,
      'ledger_balance': ledgerBalance,
      'discrepancy': discrepancy,
      'fiscal_year': fiscalYear,
      'fiscal_month': fiscalMonth,
      'created_by': user.id,
    });
  }

  Future<void> updateBankAccount({
    required String id,
    required String bankName,
    required String accountNumber,
    required double openingBalance,
    required double debitTurnover,
    required double creditTurnover,
    required double closingBalance,
    required double ledgerBalance,
    required double discrepancy,
    int? fiscalYear,
    int? fiscalMonth,
  }) async {
    await _client
        .from('bank_accounts')
        .update({
          'bank_name': bankName.trim(),
          'account_number': accountNumber.trim(),
          'opening_balance': openingBalance,
          'debit_turnover': debitTurnover,
          'credit_turnover': creditTurnover,
          'closing_balance': closingBalance,
          'ledger_balance': ledgerBalance,
          'discrepancy': discrepancy,
          'fiscal_year': fiscalYear,
          'fiscal_month': fiscalMonth,
        })
        .eq('id', id);
  }

  Future<void> deleteBankAccount(String id) async {
    await _client.from('bank_accounts').delete().eq('id', id);
  }

  // ==========================================================
  // CASH BOX CRUD
  // ==========================================================

  Future<void> createCashBox({
    required String companyId,
    required String boxName,
    required double openingBalance,
    required double totalReceipts,
    required double totalPayments,
    required double closingBalance,
    required double ledgerBalance,
    required double discrepancy,
    int? fiscalYear,
    int? fiscalMonth,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد نشده است.');
    }

    await _client.from('cash_boxes').insert({
      'company_id': companyId,
      'box_name': boxName.trim(),
      'opening_balance': openingBalance,
      'total_receipts': totalReceipts,
      'total_payments': totalPayments,
      'closing_balance': closingBalance,
      'ledger_balance': ledgerBalance,
      'discrepancy': discrepancy,
      'fiscal_year': fiscalYear,
      'fiscal_month': fiscalMonth,
      'created_by': user.id,
    });
  }

  Future<void> updateCashBox({
    required String id,
    required String boxName,
    required double openingBalance,
    required double totalReceipts,
    required double totalPayments,
    required double closingBalance,
    required double ledgerBalance,
    required double discrepancy,
    int? fiscalYear,
    int? fiscalMonth,
  }) async {
    await _client
        .from('cash_boxes')
        .update({
          'box_name': boxName.trim(),
          'opening_balance': openingBalance,
          'total_receipts': totalReceipts,
          'total_payments': totalPayments,
          'closing_balance': closingBalance,
          'ledger_balance': ledgerBalance,
          'discrepancy': discrepancy,
          'fiscal_year': fiscalYear,
          'fiscal_month': fiscalMonth,
        })
        .eq('id', id);
  }

  Future<void> deleteCashBox(String id) async {
    await _client.from('cash_boxes').delete().eq('id', id);
  }

  // ==========================================================
  // BANK LOAN CRUD
  // ==========================================================

  Future<void> createBankLoan({
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
      throw Exception('کاربر وارد نشده است.');
    }

    await _client.from('bank_loans').insert({
      'company_id': companyId,
      'bank_name': bankName.trim(),
      'loan_type': loanType.trim(),
      'principal_amount': principalAmount,
      'remaining_amount': remainingAmount,
      'interest_rate': interestRate,
      'start_date': _dateToString(startDate),
      'end_date': _dateToString(endDate),
      'monthly_installment': monthlyInstallment,
      'created_by': user.id,
    });
  }

  Future<void> updateBankLoan({
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
          'start_date': _dateToString(startDate),
          'end_date': _dateToString(endDate),
          'monthly_installment': monthlyInstallment,
        })
        .eq('id', id);
  }

  Future<void> deleteBankLoan(String id) async {
    await _client.from('bank_loans').delete().eq('id', id);
  }

  // ==========================================================
  // PETTY CASH CRUD
  // ==========================================================

  Future<void> createPettyCash({
    required String companyId,
    required String name,
    String? responsibleUserId,
    required double openingBalance,
    required double totalReceipts,
    required double totalPayments,
    required double closingBalance,
    required double ledgerBalance,
    required double discrepancy,
    int? fiscalYear,
    int? fiscalMonth,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد نشده است.');
    }

    await _client.from('petty_cash_accounts').insert({
      'company_id': companyId,
      'name': name.trim(),
      'responsible_user_id': responsibleUserId,
      'opening_balance': openingBalance,
      'total_receipts': totalReceipts,
      'total_payments': totalPayments,
      'closing_balance': closingBalance,
      'ledger_balance': ledgerBalance,
      'discrepancy': discrepancy,
      'fiscal_year': fiscalYear,
      'fiscal_month': fiscalMonth,
      'created_by': user.id,
    });
  }

  Future<void> updatePettyCash({
    required String id,
    required String name,
    String? responsibleUserId,
    required double openingBalance,
    required double totalReceipts,
    required double totalPayments,
    required double closingBalance,
    required double ledgerBalance,
    required double discrepancy,
    int? fiscalYear,
    int? fiscalMonth,
  }) async {
    await _client
        .from('petty_cash_accounts')
        .update({
          'name': name.trim(),
          'responsible_user_id': responsibleUserId,
          'opening_balance': openingBalance,
          'total_receipts': totalReceipts,
          'total_payments': totalPayments,
          'closing_balance': closingBalance,
          'ledger_balance': ledgerBalance,
          'discrepancy': discrepancy,
          'fiscal_year': fiscalYear,
          'fiscal_month': fiscalMonth,
        })
        .eq('id', id);
  }

  Future<void> deletePettyCash(String id) async {
    await _client.from('petty_cash_accounts').delete().eq('id', id);
  }

  // ==========================================================
  // RECEIVED CHECK CRUD
  // ==========================================================

  Future<void> createReceivedCheck({
    required String companyId,
    required String checkNumber,
    required String bankName,
    required double amount,
    DateTime? dueDate,
    required String status,
  }) async {
    await _createCheck(
      tableName: 'received_checks',
      companyId: companyId,
      checkNumber: checkNumber,
      bankName: bankName,
      amount: amount,
      dueDate: dueDate,
      status: status,
    );
  }

  Future<void> updateReceivedCheck({
    required String id,
    required String checkNumber,
    required String bankName,
    required double amount,
    DateTime? dueDate,
    required String status,
  }) async {
    await _updateCheck(
      tableName: 'received_checks',
      id: id,
      checkNumber: checkNumber,
      bankName: bankName,
      amount: amount,
      dueDate: dueDate,
      status: status,
    );
  }

  Future<void> deleteReceivedCheck(String id) async {
    await _client.from('received_checks').delete().eq('id', id);
  }

  // ==========================================================
  // PAID CHECK CRUD
  // ==========================================================

  Future<void> createPaidCheck({
    required String companyId,
    required String checkNumber,
    required String bankName,
    required double amount,
    DateTime? dueDate,
    required String status,
  }) async {
    await _createCheck(
      tableName: 'paid_checks',
      companyId: companyId,
      checkNumber: checkNumber,
      bankName: bankName,
      amount: amount,
      dueDate: dueDate,
      status: status,
    );
  }

  Future<void> updatePaidCheck({
    required String id,
    required String checkNumber,
    required String bankName,
    required double amount,
    DateTime? dueDate,
    required String status,
  }) async {
    await _updateCheck(
      tableName: 'paid_checks',
      id: id,
      checkNumber: checkNumber,
      bankName: bankName,
      amount: amount,
      dueDate: dueDate,
      status: status,
    );
  }

  Future<void> deletePaidCheck(String id) async {
    await _client.from('paid_checks').delete().eq('id', id);
  }

  // ==========================================================
  // GENERIC CHECK CREATE
  // ==========================================================

  Future<void> _createCheck({
    required String tableName,
    required String companyId,
    required String checkNumber,
    required String bankName,
    required double amount,
    DateTime? dueDate,
    required String status,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('کاربر وارد نشده است.');
    }

    await _client.from(tableName).insert({
      'company_id': companyId,
      'check_number': checkNumber.trim(),
      'bank_name': bankName.trim(),
      'amount': amount,
      'due_date': _dateToString(dueDate),
      'status': status.trim(),
    });
  }

  // ==========================================================
  // GENERIC CHECK UPDATE
  // ==========================================================

  Future<void> _updateCheck({
    required String tableName,
    required String id,
    required String checkNumber,
    required String bankName,
    required double amount,
    DateTime? dueDate,
    required String status,
  }) async {
    await _client
        .from(tableName)
        .update({
          'check_number': checkNumber.trim(),
          'bank_name': bankName.trim(),
          'amount': amount,
          'due_date': _dateToString(dueDate),
          'status': status.trim(),
        })
        .eq('id', id);
  }

  // ==========================================================
  // FETCH DASHBOARD
  // ==========================================================

  Future<BankingDashboardData> fetchDashboard(String companyId) async {
    final user = _client.auth.currentUser;

    final session = _client.auth.currentSession;

    debugPrint('==============================================');
    debugPrint('BANKING REPOSITORY');
    debugPrint('USER ID: ${user?.id}');
    debugPrint('USER EMAIL: ${user?.email}');
    debugPrint('SESSION EXISTS: ${session != null}');
    debugPrint(
      'ACCESS TOKEN EXISTS: '
      '${session?.accessToken.isNotEmpty == true}',
    );
    debugPrint('COMPANY ID: $companyId');
    debugPrint('==============================================');

    if (user == null || session == null) {
      throw Exception('Session کاربر در زمان خواندن اطلاعات بانک وجود ندارد.');
    }

    if (companyId.trim().isEmpty) {
      throw Exception('شناسه شرکت خالی است.');
    }

    final bankAccounts = await _fetchBankAccounts(companyId);

    final cashBoxes = await _fetchCashBoxes(companyId);

    final bankLoans = await _fetchBankLoans(companyId);

    final pettyCashAccounts = await _fetchPettyCashAccounts(companyId);

    final receivedChecks = await _fetchReceivedChecks(companyId);

    final paidChecks = await _fetchPaidChecks(companyId);

    return BankingDashboardData(
      bankAccounts: bankAccounts,
      cashBoxes: cashBoxes,
      bankLoans: bankLoans,
      pettyCashAccounts: pettyCashAccounts,
      receivedChecks: receivedChecks,
      paidChecks: paidChecks,
    );
  }

  // ==========================================================
  // FETCH BANK ACCOUNTS
  // ==========================================================

  Future<List<BankAccountModel>> _fetchBankAccounts(String companyId) async {
    try {
      final data = await _client
          .from('bank_accounts')
          .select()
          .eq('company_id', companyId)
          .order('bank_name');

      final rows = data as List;

      return rows
          .map(
            (row) => BankAccountModel.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList();
    } catch (error, stackTrace) {
      debugPrint('BANK ACCOUNTS ERROR: $error');
      debugPrint('$stackTrace');

      throw Exception('خطا در دریافت حساب‌های بانکی: $error');
    }
  }

  // ==========================================================
  // FETCH CASH BOXES
  // ==========================================================

  Future<List<CashBoxModel>> _fetchCashBoxes(String companyId) async {
    try {
      final data = await _client
          .from('cash_boxes')
          .select()
          .eq('company_id', companyId)
          .order('box_name');

      final rows = data as List;

      return rows
          .map((row) => CashBoxModel.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error, stackTrace) {
      debugPrint('CASH BOXES ERROR: $error');
      debugPrint('$stackTrace');

      throw Exception('خطا در دریافت صندوق‌ها: $error');
    }
  }

  // ==========================================================
  // FETCH BANK LOANS
  // ==========================================================

  Future<List<BankLoanModel>> _fetchBankLoans(String companyId) async {
    try {
      final data = await _client
          .from('bank_loans')
          .select()
          .eq('company_id', companyId)
          .order('start_date', ascending: false);

      final rows = data as List;

      return rows
          .map((row) => BankLoanModel.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error, stackTrace) {
      debugPrint('BANK LOANS ERROR: $error');
      debugPrint('$stackTrace');

      throw Exception('خطا در دریافت تسهیلات بانکی: $error');
    }
  }

  // ==========================================================
  // FETCH PETTY CASH
  // ==========================================================

  Future<List<PettyCashModel>> _fetchPettyCashAccounts(String companyId) async {
    try {
      debugPrint('PETTY CASH -> START');

      final data = await _client
          .from('petty_cash_accounts')
          .select()
          .eq('company_id', companyId)
          .order('name');

      final rows = data as List;

      debugPrint(
        'PETTY CASH -> '
        '${rows.length} ROWS',
      );

      return rows
          .map((row) => PettyCashModel.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error, stackTrace) {
      debugPrint('PETTY CASH ERROR: $error');
      debugPrint('$stackTrace');

      throw Exception('خطا در دریافت تنخواه‌ها: $error');
    }
  }

  // ==========================================================
  // FETCH RECEIVED CHECKS
  // ==========================================================

  Future<CheckSummary> _fetchReceivedChecks(String companyId) async {
    try {
      final data = await _client
          .from('received_checks')
          .select()
          .eq('company_id', companyId)
          .order('due_date');

      final rows = data as List;

      final checks =
          rows
              .map((row) => CheckModel.fromMap(Map<String, dynamic>.from(row)))
              .toList();

      final total = checks.fold<double>(0, (sum, item) => sum + item.amount);

      return CheckSummary(
        count: checks.length,
        totalAmount: total,
        checks: checks,
      );
    } catch (error, stackTrace) {
      debugPrint('RECEIVED CHECKS ERROR: $error');
      debugPrint('$stackTrace');

      throw Exception('خطا در دریافت چک‌های دریافتی: $error');
    }
  }

  // ==========================================================
  // FETCH PAID CHECKS
  // ==========================================================

  Future<CheckSummary> _fetchPaidChecks(String companyId) async {
    try {
      final data = await _client
          .from('paid_checks')
          .select()
          .eq('company_id', companyId)
          .order('due_date');

      final rows = data as List;

      final checks =
          rows
              .map((row) => CheckModel.fromMap(Map<String, dynamic>.from(row)))
              .toList();

      final total = checks.fold<double>(0, (sum, item) => sum + item.amount);

      return CheckSummary(
        count: checks.length,
        totalAmount: total,
        checks: checks,
      );
    } catch (error, stackTrace) {
      debugPrint('PAID CHECKS ERROR: $error');
      debugPrint('$stackTrace');

      throw Exception('خطا در دریافت چک‌های پرداختی: $error');
    }
  }
}

// ============================================================
// HELPERS
// ============================================================

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0;
}

int? _toInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  return int.tryParse(value.toString().trim());
}

DateTime? _toDate(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(value.toString());
}

String? _dateToString(DateTime? value) {
  if (value == null) {
    return null;
  }

  final month = value.month.toString().padLeft(2, '0');

  final day = value.day.toString().padLeft(2, '0');

  return '${value.year}-$month-$day';
}
