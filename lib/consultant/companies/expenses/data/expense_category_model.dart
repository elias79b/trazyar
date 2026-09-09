class ExpenseCategoryModel {
  const ExpenseCategoryModel({
    required this.id,
    required this.companyId,
    required this.name,
    this.code,
    this.description,
    required this.expenseType,
    required this.isActive,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String companyId;
  final String name;
  final String? code;
  final String? description;
  final String expenseType;
  final bool isActive;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOperational => expenseType == 'operational';

  bool get isNonOperational => expenseType == 'non_operational';

  factory ExpenseCategoryModel.fromMap(Map<String, dynamic> map) {
    return ExpenseCategoryModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      name: map['name'] as String,
      code: map['code'] as String?,
      description: map['description'] as String?,
      expenseType: map['expense_type'] as String? ?? 'operational',
      isActive: map['is_active'] as bool? ?? true,
      createdBy: map['created_by'] as String?,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'name': name,
      'code': code,
      'description': description,
      'expense_type': expenseType,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ExpenseCategoryModel copyWith({
    String? id,
    String? companyId,
    String? name,
    String? code,
    String? description,
    String? expenseType,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseCategoryModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      expenseType: expenseType ?? this.expenseType,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
