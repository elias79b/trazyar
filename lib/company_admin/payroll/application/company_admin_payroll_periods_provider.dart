import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shamsi_date/shamsi_date.dart';

final companyAdminPayrollPeriodsProvider =
FutureProvider.autoDispose<CompanyAdminPayrollPeriodsData>(
      (ref) async {
    final client = Supabase.instance.client;

    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception(
        'کاربر وارد سیستم نشده است.',
      );
    }

    final membership = await client
        .from('company_users')
        .select(
      'company_id, user_id, role, is_active',
    )
        .eq('user_id', user.id)
        .eq('role', 'company_admin')
        .eq('is_active', true)
        .maybeSingle();

    if (membership == null) {
      throw Exception(
        'شرکت فعالی برای این مدیرعامل پیدا نشد.',
      );
    }

    final companyId =
    membership['company_id']?.toString();

    if (companyId == null ||
        companyId.isEmpty) {
      throw Exception(
        'شناسه شرکت مدیرعامل پیدا نشد.',
      );
    }

    final rows = await client
        .from('payroll_periods')
        .select(
      '''
          id,
          company_id,
          period_year,
          period_month,
          status,
          notes,
          created_by,
          created_at,
          updated_at,
          cost_center_id
          ''',
    )
        .eq('company_id', companyId)
        .order(
      'period_year',
      ascending: false,
    )
        .order(
      'period_month',
      ascending: true,
    );

    final periods = (rows as List)
        .map(
          (row) =>
          CompanyAdminPayrollPeriod.fromMap(
            Map<String, dynamic>.from(row),
          ),
    )
        .toList();

    return CompanyAdminPayrollPeriodsData(
      companyId: companyId,
      periods: periods,
    );
  },
);

class CompanyAdminPayrollPeriodsData {
  final String companyId;
  final List<CompanyAdminPayrollPeriod> periods;

  const CompanyAdminPayrollPeriodsData({
    required this.companyId,
    required this.periods,
  });

  /// سال‌هایی که واقعاً در دیتابیس وجود دارند
  /// به همراه سال جاری شمسی.
  List<int> get years {
    final currentYear =
        Jalali.now().year;

    final result = periods
        .map(
          (e) => e.periodYear,
    )
        .toSet();

    result.add(currentYear);

    final years = result.toList();

    years.sort(
          (a, b) => b.compareTo(a),
    );

    return years;
  }

  List<CompanyAdminPayrollPeriod>
  periodsForYear(
      int year,
      ) {
    final result = periods
        .where(
          (period) =>
      period.periodYear == year,
    )
        .toList();

    result.sort(
          (a, b) =>
          a.periodMonth.compareTo(
            b.periodMonth,
          ),
    );

    return result;
  }

  /// برای نمایش همیشه ۱۲ ماه سال را برمی‌گرداند.
  ///
  /// اگر رکورد واقعی payroll_periods وجود داشته باشد،
  /// همان رکورد برگردانده می‌شود.
  ///
  /// اگر وجود نداشته باشد، یک ماه مجازی با وضعیت
  /// "not_created" ساخته می‌شود تا ماه در UI نمایش داده شود.
  List<CompanyAdminPayrollMonthItem>
  monthItemsForYear(
      int year,
      ) {
    final yearPeriods =
    periodsForYear(year);

    final Map<int, CompanyAdminPayrollPeriod>
    periodByMonth = {};

    for (final period in yearPeriods) {
      periodByMonth[period.periodMonth] =
          period;
    }

    return List.generate(
      12,
          (index) {
        final month = index + 1;

        final existing =
        periodByMonth[month];

        if (existing != null) {
          return CompanyAdminPayrollMonthItem
              .existing(
            period: existing,
          );
        }

        return CompanyAdminPayrollMonthItem
            .missing(
          year: year,
          month: month,
        );
      },
    );
  }

  int get currentJalaliYear {
    return Jalali.now().year;
  }

  int get pendingCeoCount {
    return periods
        .where(
          (period) =>
      period.isPendingCeo,
    )
        .length;
  }

  int get approvedCount {
    return periods
        .where(
          (period) =>
      period.isCeoApproved,
    )
        .length;
  }

  int get consultantApprovedCount {
    return periods
        .where(
          (period) =>
      period.isConsultantApproved,
    )
        .length;
  }

  int get rejectedCount {
    return periods
        .where(
          (period) =>
      period.isRejected,
    )
        .length;
  }

  int get createdPeriodsCount {
    return periods.length;
  }

  int get missingPeriodsCount {
    final currentYear =
        Jalali.now().year;

    return monthItemsForYear(
      currentYear,
    ).where(
          (item) => item.isMissing,
    ).length;
  }
}

class CompanyAdminPayrollMonthItem {
  final int year;
  final int month;
  final CompanyAdminPayrollPeriod? period;
  final bool isMissing;

  const CompanyAdminPayrollMonthItem({
    required this.year,
    required this.month,
    required this.period,
    required this.isMissing,
  });

  factory CompanyAdminPayrollMonthItem.existing({
    required CompanyAdminPayrollPeriod period,
  }) {
    return CompanyAdminPayrollMonthItem(
      year: period.periodYear,
      month: period.periodMonth,
      period: period,
      isMissing: false,
    );
  }

  factory CompanyAdminPayrollMonthItem.missing({
    required int year,
    required int month,
  }) {
    return CompanyAdminPayrollMonthItem(
      year: year,
      month: month,
      period: null,
      isMissing: true,
    );
  }

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

    return months[month - 1];
  }

  String get title {
    return '$monthName $year';
  }

  String get statusTitle {
    if (isMissing) {
      return 'دوره ثبت نشده';
    }

    return period!.statusTitle;
  }

  String get statusDescription {
    if (isMissing) {
      return 'برای این ماه هنوز دوره حقوق در سیستم ایجاد نشده است.';
    }

    return period!.statusDescription;
  }

  bool get isPendingCeo {
    return period?.isPendingCeo ?? false;
  }
}

class CompanyAdminPayrollPeriod {
  final String id;
  final String companyId;

  final int periodYear;
  final int periodMonth;

  final String status;
  final String? notes;

  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? costCenterId;

  const CompanyAdminPayrollPeriod({
    required this.id,
    required this.companyId,
    required this.periodYear,
    required this.periodMonth,
    required this.status,
    required this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.costCenterId,
  });

  factory CompanyAdminPayrollPeriod.fromMap(
      Map<String, dynamic> map,
      ) {
    return CompanyAdminPayrollPeriod(
      id: map['id'].toString(),
      companyId:
      map['company_id'].toString(),
      periodYear: _toInt(
        map['period_year'],
      ),
      periodMonth: _toInt(
        map['period_month'],
      ),
      status:
      map['status']?.toString() ??
          'draft',
      notes:
      map['notes']?.toString(),
      createdBy:
      map['created_by']?.toString(),
      createdAt:
      _toDateTime(
        map['created_at'],
      ),
      updatedAt:
      _toDateTime(
        map['updated_at'],
      ),
      costCenterId:
      map['cost_center_id']?.toString(),
    );
  }

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
    return status ==
        'consultant_approved';
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

    if (periodMonth < 1 ||
        periodMonth > 12) {
      return 'ماه $periodMonth';
    }

    return months[periodMonth - 1];
  }

  String get title {
    return '$monthName $periodYear';
  }

  String get statusTitle {
    switch (status) {
      case 'draft':
        return 'پیش‌نویس';

      case 'pending_ceo':
        return 'در انتظار بررسی مدیرعامل';

      case 'ceo_approved':
        return 'تأیید مدیرعامل';

      case 'pending_consultant':
        return 'در انتظار بررسی مشاور';

      case 'consultant_approved':
        return 'تأیید نهایی';

      case 'rejected':
        return 'رد شده';

      case 'paid':
        return 'پرداخت شده';

      case 'cancelled':
        return 'لغو شده';

      default:
        return status;
    }
  }

  String get statusDescription {
    switch (status) {
      case 'draft':
        return 'دوره هنوز برای بررسی ارسال نشده است.';

      case 'pending_ceo':
        return 'این دوره منتظر بررسی و تصمیم مدیرعامل است.';

      case 'ceo_approved':
        return 'دوره توسط مدیرعامل تأیید شده است.';

      case 'pending_consultant':
        return 'دوره برای بررسی مشاور ارسال شده است.';

      case 'consultant_approved':
        return 'دوره تأیید نهایی شده است.';

      case 'rejected':
        return 'این دوره رد شده و نیاز به بررسی مجدد دارد.';

      case 'paid':
        return 'پرداخت حقوق این دوره ثبت شده است.';

      case 'cancelled':
        return 'این دوره لغو شده است.';

      default:
        return '';
    }
  }
}

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    value.toString(),
  ) ??
      0;
}

DateTime? _toDateTime(
    dynamic value,
    ) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(
    value.toString(),
  );
}