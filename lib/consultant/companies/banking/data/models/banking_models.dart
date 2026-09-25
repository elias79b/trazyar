class CashFiscalYear {
  final String id;
  final String companyId;
  final int year;
  final String title;
  final String status;

  const CashFiscalYear({
    required this.id,
    required this.companyId,
    required this.year,
    required this.title,
    required this.status,
  });

  factory CashFiscalYear.fromMap(Map<String, dynamic> map) {
    return CashFiscalYear(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      year: _toInt(map['year']),
      title: map['title']?.toString() ?? '',
      status: map['status']?.toString() ?? 'open',
    );
  }
}

class CashFiscalPeriod {
  final String id;
  final String fiscalYearId;
  final String companyId;
  final int year;
  final int month;
  final String title;
  final String status;
  final String? rejectionReason;

  const CashFiscalPeriod({
    required this.id,
    required this.fiscalYearId,
    required this.companyId,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
    this.rejectionReason,
  });

  factory CashFiscalPeriod.fromMap(Map<String, dynamic> map) {
    return CashFiscalPeriod(
      id: map['id']?.toString() ?? '',
      fiscalYearId: map['fiscal_year_id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      year: _toInt(map['year']),
      month: _toInt(map['month']),
      title: map['title']?.toString() ?? '',
      status: map['status']?.toString() ?? 'draft',
      rejectionReason: map['rejection_reason']?.toString(),
    );
  }

  String get statusTitle {
    switch (status) {
      case 'draft':
        return 'پیش‌نویس';
      case 'pending_ceo':
        return 'در انتظار تأیید مدیرعامل';
      case 'ceo_approved':
        return 'تأیید مدیرعامل';
      case 'pending_consultant':
        return 'در انتظار تأیید مشاور';
      case 'consultant_approved':
        return 'تأیید نهایی';
      case 'rejected':
        return 'برگشت داده شده';
      default:
        return status;
    }
  }

  bool get isLocked => status == 'consultant_approved';

  static const List<String> monthNames = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];

  String get monthTitle {
    if (month >= 1 && month <= 12) {
      return monthNames[month - 1];
    }
    return 'ماه $month';
  }
}

class BankAccount {
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

  const BankAccount({
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
  });

  factory BankAccount.fromMap(Map<String, dynamic> map) {
    return BankAccount(
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
    );
  }
}

class CashBox {
  final String id;
  final String companyId;
  final String boxName;
  final double openingBalance;
  final double totalReceipts;
  final double totalPayments;
  final double closingBalance;
  final double ledgerBalance;
  final double discrepancy;

  const CashBox({
    required this.id,
    required this.companyId,
    required this.boxName,
    required this.openingBalance,
    required this.totalReceipts,
    required this.totalPayments,
    required this.closingBalance,
    required this.ledgerBalance,
    required this.discrepancy,
  });

  factory CashBox.fromMap(Map<String, dynamic> map) {
    return CashBox(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      boxName: map['box_name']?.toString() ?? '',
      openingBalance: _toDouble(map['opening_balance']),
      totalReceipts: _toDouble(map['total_receipts']),
      totalPayments: _toDouble(map['total_payments']),
      closingBalance: _toDouble(map['closing_balance']),
      ledgerBalance: _toDouble(map['ledger_balance']),
      discrepancy: _toDouble(map['discrepancy']),
    );
  }
}

class PettyCashAccount {
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

  const PettyCashAccount({
    required this.id,
    required this.companyId,
    required this.name,
    this.responsibleUserId,
    required this.openingBalance,
    required this.totalReceipts,
    required this.totalPayments,
    required this.closingBalance,
    required this.ledgerBalance,
    required this.discrepancy,
  });

  factory PettyCashAccount.fromMap(Map<String, dynamic> map) {
    return PettyCashAccount(
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
    );
  }
}

class BankAccountPeriod {
  final String id;
  final String companyId;
  final String periodId;
  final String bankAccountId;
  final double openingBalance;
  final double debitTurnover;
  final double creditTurnover;
  final double closingBalance;
  final double ledgerBalance;
  final double discrepancy;
  final String? notes;

  const BankAccountPeriod({
    required this.id,
    required this.companyId,
    required this.periodId,
    required this.bankAccountId,
    required this.openingBalance,
    required this.debitTurnover,
    required this.creditTurnover,
    required this.closingBalance,
    required this.ledgerBalance,
    required this.discrepancy,
    this.notes,
  });

  factory BankAccountPeriod.fromMap(Map<String, dynamic> map) {
    return BankAccountPeriod(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      periodId: map['period_id']?.toString() ?? '',
      bankAccountId: map['bank_account_id']?.toString() ?? '',
      openingBalance: _toDouble(map['opening_balance']),
      debitTurnover: _toDouble(map['debit_turnover']),
      creditTurnover: _toDouble(map['credit_turnover']),
      closingBalance: _toDouble(map['closing_balance']),
      ledgerBalance: _toDouble(map['ledger_balance']),
      discrepancy: _toDouble(map['discrepancy']),
      notes: map['notes']?.toString(),
    );
  }
}

class CashBoxPeriod {
  final String id;
  final String companyId;
  final String periodId;
  final String cashBoxId;
  final double openingBalance;
  final double totalReceipts;
  final double totalPayments;
  final double closingBalance;
  final double ledgerBalance;
  final double discrepancy;
  final String? notes;

  const CashBoxPeriod({
    required this.id,
    required this.companyId,
    required this.periodId,
    required this.cashBoxId,
    required this.openingBalance,
    required this.totalReceipts,
    required this.totalPayments,
    required this.closingBalance,
    required this.ledgerBalance,
    required this.discrepancy,
    this.notes,
  });

  factory CashBoxPeriod.fromMap(Map<String, dynamic> map) {
    return CashBoxPeriod(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      periodId: map['period_id']?.toString() ?? '',
      cashBoxId: map['cash_box_id']?.toString() ?? '',
      openingBalance: _toDouble(map['opening_balance']),
      totalReceipts: _toDouble(map['total_receipts']),
      totalPayments: _toDouble(map['total_payments']),
      closingBalance: _toDouble(map['closing_balance']),
      ledgerBalance: _toDouble(map['ledger_balance']),
      discrepancy: _toDouble(map['discrepancy']),
      notes: map['notes']?.toString(),
    );
  }
}

class PettyCashPeriod {
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
  final String? notes;

  const PettyCashPeriod({
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
    this.notes,
  });

  factory PettyCashPeriod.fromMap(
      Map<String, dynamic> map,
      ) {
    return PettyCashPeriod(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      periodId: map['period_id']?.toString() ?? '',
      pettyCashId: map['petty_cash_id']?.toString() ?? '',
      openingBalance: _toDouble(
        map['opening_balance'],
      ),
      totalReceipts: _toDouble(
        map['total_receipts'],
      ),
      totalPayments: _toDouble(
        map['total_payments'],
      ),
      closingBalance: _toDouble(
        map['closing_balance'],
      ),
      ledgerBalance: _toDouble(
        map['ledger_balance'],
      ),
      discrepancy: _toDouble(
        map['discrepancy'],
      ),
      notes: map['notes']?.toString(),
    );
  }
}

class BankingTrendPoint {
  final int year;
  final int month;
  final double bank;
  final double cash;
  final double pettyCash;

  const BankingTrendPoint({
    required this.year,
    required this.month,
    required this.bank,
    required this.cash,
    required this.pettyCash,
  });

  double get liquidity => bank + cash + pettyCash;

  String get title {
    if (month >= 1 && month <= 12) {
      return CashFiscalPeriod.monthNames[month - 1];
    }
    return '$month';
  }
}

class BankingAlert {
  final String title;
  final String message;
  final BankingAlertType type;

  const BankingAlert({
    required this.title,
    required this.message,
    required this.type,
  });
}

enum BankingAlertType {
  warning,
  danger,
  info,
}

class BankingSnapshot {
  final CashFiscalPeriod? latestPeriod;
  final List<CashFiscalPeriod> periods;
  final List<BankAccount> bankAccounts;
  final List<CashBox> cashBoxes;
  final List<PettyCashAccount> pettyCashAccounts;
  final List<BankAccountPeriod> bankPeriods;
  final List<CashBoxPeriod> cashPeriods;
  final List<PettyCashPeriod> pettyCashPeriods;
  final List<BankingTrendPoint> trend;
  final List<BankingAlert> alerts;

  const BankingSnapshot({
    required this.latestPeriod,
    required this.periods,
    required this.bankAccounts,
    required this.cashBoxes,
    required this.pettyCashAccounts,
    required this.bankPeriods,
    required this.cashPeriods,
    required this.pettyCashPeriods,
    required this.trend,
    required this.alerts,
  });

  double get bankBalance =>
      bankPeriods.fold(0, (sum, item) => sum + item.closingBalance);

  double get cashBalance =>
      cashPeriods.fold(0, (sum, item) => sum + item.closingBalance);

  double get pettyCashBalance =>
      pettyCashPeriods.fold(0, (sum, item) => sum + item.closingBalance);

  double get totalLiquidity =>
      bankBalance + cashBalance + pettyCashBalance;

  double get bankDiscrepancy =>
      bankPeriods.fold(0, (sum, item) => sum + item.discrepancy.abs());

  double get cashDiscrepancy =>
      cashPeriods.fold(0, (sum, item) => sum + item.discrepancy.abs());

  double get pettyCashDiscrepancy =>
      pettyCashPeriods.fold(0, (sum, item) => sum + item.discrepancy.abs());

  double get totalDiscrepancy =>
      bankDiscrepancy + cashDiscrepancy + pettyCashDiscrepancy;

  bool get hasData =>
      bankAccounts.isNotEmpty ||
          cashBoxes.isNotEmpty ||
          pettyCashAccounts.isNotEmpty ||
          periods.isNotEmpty;

  String get workflowTitle {
    if (latestPeriod == null) return 'دوره‌ای ثبت نشده';
    return latestPeriod!.statusTitle;
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0;

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString().replaceAll(',', '')) ?? 0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
}