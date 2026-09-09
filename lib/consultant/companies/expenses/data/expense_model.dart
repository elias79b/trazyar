class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.companyId,
    required this.categoryId,
    required this.title,
    this.description,
    required this.amount,
    required this.expenseDate,
    this.referenceNumber,
    required this.expenseType,
    required this.sourceType,
    this.payrollPeriodId,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.categoryName,
    this.payrollPeriodYear,
    this.payrollPeriodMonth,
    this.payrollPeriodStatus,
  });

  final String id;
  final String companyId;
  final String categoryId;
  final String title;
  final String? description;
  final num amount;
  final DateTime expenseDate;
  final String? referenceNumber;
  final String expenseType;
  final String sourceType;
  final String? payrollPeriodId;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined/display fields
  final String? categoryName;
  final int? payrollPeriodYear;
  final int? payrollPeriodMonth;
  final String? payrollPeriodStatus;

  bool get isManual => sourceType == 'manual';

  bool get isPayroll => sourceType == 'payroll';

  bool get isOperational => expenseType == 'operational';

  bool get isNonOperational => expenseType == 'non_operational';

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    final category = map['expense_categories'];

    final payrollPeriod = map['payroll_periods'];

    return ExpenseModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      categoryId: map['category_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      amount: _parseNum(map['amount']),
      expenseDate: DateTime.parse(map['expense_date'].toString()),
      referenceNumber: map['reference_number'] as String?,
      expenseType: map['expense_type'] as String? ?? 'operational',
      sourceType: map['source_type'] as String? ?? 'manual',
      payrollPeriodId: map['payroll_period_id'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
      categoryName: category is Map ? category['name'] as String? : null,
      payrollPeriodYear:
          payrollPeriod is Map ? _parseInt(payrollPeriod['period_year']) : null,
      payrollPeriodMonth:
          payrollPeriod is Map
              ? _parseInt(payrollPeriod['period_month'])
              : null,
      payrollPeriodStatus:
          payrollPeriod is Map ? payrollPeriod['status'] as String? : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'amount': amount,
      'expense_date': _dateOnly(expenseDate),
      'reference_number': referenceNumber,
      'expense_type': expenseType,
      'source_type': sourceType,
      'payroll_period_id': payrollPeriodId,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? companyId,
    String? categoryId,
    String? title,
    String? description,
    num? amount,
    DateTime? expenseDate,
    String? referenceNumber,
    String? expenseType,
    String? sourceType,
    String? payrollPeriodId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    int? payrollPeriodYear,
    int? payrollPeriodMonth,
    String? payrollPeriodStatus,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      expenseType: expenseType ?? this.expenseType,
      sourceType: sourceType ?? this.sourceType,
      payrollPeriodId: payrollPeriodId ?? this.payrollPeriodId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      payrollPeriodYear: payrollPeriodYear ?? this.payrollPeriodYear,
      payrollPeriodMonth: payrollPeriodMonth ?? this.payrollPeriodMonth,
      payrollPeriodStatus: payrollPeriodStatus ?? this.payrollPeriodStatus,
    );
  }

  static num _parseNum(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    return num.tryParse(value.toString()) ?? 0;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
