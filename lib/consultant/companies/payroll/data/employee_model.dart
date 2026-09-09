class EmployeeModel {
  const EmployeeModel({
    required this.id,
    required this.companyId,
    required this.personnelCode,
    required this.firstName,
    required this.lastName,
    this.nationalId,
    this.mobile,
    this.jobTitle,
    this.department,
    this.employmentType,
    this.hireDate,
    this.terminationDate,
    required this.status,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String companyId;

  final String personnelCode;

  final String firstName;
  final String lastName;

  final String? nationalId;
  final String? mobile;

  final String? jobTitle;
  final String? department;
  final String? employmentType;

  final DateTime? hireDate;
  final DateTime? terminationDate;

  final String status;

  final String? createdBy;

  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName'.trim();

  bool get isActive => status == 'active';

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] as String,
      companyId: map['company_id'] as String,
      personnelCode: map['personnel_code'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      nationalId: map['national_id'] as String?,
      mobile: map['mobile'] as String?,
      jobTitle: map['job_title'] as String?,
      department: map['department'] as String?,
      employmentType: map['employment_type'] as String?,
      hireDate: _parseDate(map['hire_date']),
      terminationDate: _parseDate(map['termination_date']),
      status: map['status'] as String,
      createdBy: map['created_by'] as String?,
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'personnel_code': personnelCode,
      'first_name': firstName,
      'last_name': lastName,
      'national_id': nationalId,
      'mobile': mobile,
      'job_title': jobTitle,
      'department': department,
      'employment_type': employmentType,
      'hire_date': hireDate?.toIso8601String(),
      'termination_date': terminationDate?.toIso8601String(),
      'status': status,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  EmployeeModel copyWith({
    String? personnelCode,
    String? firstName,
    String? lastName,
    String? nationalId,
    String? mobile,
    String? jobTitle,
    String? department,
    String? employmentType,
    DateTime? hireDate,
    DateTime? terminationDate,
    String? status,
  }) {
    return EmployeeModel(
      id: id,
      companyId: companyId,
      personnelCode: personnelCode ?? this.personnelCode,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nationalId: nationalId ?? this.nationalId,
      mobile: mobile ?? this.mobile,
      jobTitle: jobTitle ?? this.jobTitle,
      department: department ?? this.department,
      employmentType: employmentType ?? this.employmentType,
      hireDate: hireDate ?? this.hireDate,
      terminationDate: terminationDate ?? this.terminationDate,
      status: status ?? this.status,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}
