class PayrollPeriodModel {
  const PayrollPeriodModel({
    required this.id,
    required this.companyId,
    required this.periodYear,
    required this.periodMonth,
    required this.status,
    this.notes,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // FIELDS
  // ============================================================

  final String id;

  final String companyId;

  final int periodYear;

  final int periodMonth;

  final String status;

  final String? notes;

  final String? createdBy;

  final DateTime createdAt;

  final DateTime updatedAt;

  // ============================================================
  // VALID STATUSES
  // ============================================================

  static const Set<String> validStatuses = {
    'draft',
    'pending_ceo',
    'ceo_approved',
    'pending_consultant',
    'consultant_approved',
    'rejected',
    'paid',
    'cancelled',
  };

  // ============================================================
  // FROM MAP
  // ============================================================

  factory PayrollPeriodModel.fromMap(Map<String, dynamic> map) {
    final rawStatus = map['status']?.toString() ?? 'draft';

    return PayrollPeriodModel(
      id: map['id']?.toString() ?? '',
      companyId: map['company_id']?.toString() ?? '',
      periodYear: _toInt(map['period_year']),
      periodMonth: _toInt(map['period_month']),

      // اگر Status ناشناخته بود، آن را تغییر نمی‌دهیم
      // تا بتوانیم مشکل دیتابیس را ببینیم.
      status: rawStatus,

      notes: map['notes']?.toString(),
      createdBy: map['created_by']?.toString(),
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_id': companyId,
      'period_year': periodYear,
      'period_month': periodMonth,
      'status': status,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  PayrollPeriodModel copyWith({
    String? id,
    String? companyId,
    int? periodYear,
    int? periodMonth,
    String? status,
    String? notes,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PayrollPeriodModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      periodYear: periodYear ?? this.periodYear,
      periodMonth: periodMonth ?? this.periodMonth,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================
  // MONTH NAME
  // ============================================================

  String get monthName {
    const months = [
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

    if (periodMonth < 1 || periodMonth > 12) {
      return 'نامشخص';
    }

    return months[periodMonth - 1];
  }

  // ============================================================
  // TITLE
  // ============================================================

  String get title {
    return '$monthName $periodYear';
  }

  // ============================================================
  // STATUS TITLE
  // ============================================================

  String get statusTitle {
    switch (status) {
      case 'draft':
        return 'پیش‌نویس';

      case 'pending_ceo':
        return 'در انتظار تأیید مدیرعامل';

      case 'ceo_approved':
        return 'تأیید مدیرعامل';

      case 'pending_consultant':
        return 'در انتظار بررسی مشاور';

      case 'consultant_approved':
        return 'تأیید مشاور';

      case 'rejected':
        return 'ردشده';

      case 'paid':
        return 'پرداخت‌شده';

      case 'cancelled':
        return 'لغوشده';

      default:
        return 'وضعیت نامشخص';
    }
  }

  // ============================================================
  // STATUS CHECKS
  // ============================================================

  bool get isDraft {
    return status == 'draft';
  }

  bool get isPendingCeo {
    return status == 'pending_ceo';
  }

  bool get isCeoApproved {
    return status == 'ceo_approved';
  }

  bool get isPendingConsultant {
    return status == 'pending_consultant';
  }

  bool get isConsultantApproved {
    return status == 'consultant_approved';
  }

  bool get isRejected {
    return status == 'rejected';
  }

  bool get isPaid {
    return status == 'paid';
  }

  bool get isCancelled {
    return status == 'cancelled';
  }

  // ============================================================
  // LOCK
  // ============================================================

  bool get isLocked {
    return status == 'ceo_approved' ||
        status == 'pending_consultant' ||
        status == 'consultant_approved' ||
        status == 'paid';
  }

  // ============================================================
  // CAN EDIT
  // ============================================================

  bool get canEdit {
    return status == 'draft' || status == 'rejected';
  }

  // ============================================================
  // CAN CHANGE STATUS
  // ============================================================

  bool get canChangeStatus {
    switch (status) {
      case 'draft':
      case 'pending_ceo':
      case 'ceo_approved':
      case 'pending_consultant':
      case 'consultant_approved':
      case 'rejected':
      case 'cancelled':
        return true;

      case 'paid':
        return false;

      default:
        return false;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    final parsed = DateTime.tryParse(value?.toString() ?? '');

    return parsed ?? DateTime.now();
  }

  // ============================================================
  // EQUALITY
  // ============================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is PayrollPeriodModel &&
        other.id == id &&
        other.companyId == companyId &&
        other.periodYear == periodYear &&
        other.periodMonth == periodMonth &&
        other.status == status &&
        other.notes == notes &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      companyId,
      periodYear,
      periodMonth,
      status,
      notes,
      createdBy,
      createdAt,
      updatedAt,
    );
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'PayrollPeriodModel('
        'id: $id, '
        'companyId: $companyId, '
        'periodYear: $periodYear, '
        'periodMonth: $periodMonth, '
        'status: $status, '
        'notes: $notes, '
        'createdBy: $createdBy, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
