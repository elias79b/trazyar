import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final incomeDashboardProvider =
    FutureProvider.family<IncomeDashboardData, String>((ref, companyId) async {
      final client = Supabase.instance.client;

      final response = await client
          .from('income_records')
          .select('''
          id,
          company_id,
          category_id,
          title,
          amount,
          income_date,
          status,
          income_categories (
            id,
            name,
            code
          )
        ''')
          .eq('company_id', companyId)
          .order('income_date', ascending: true)
          .order('created_at', ascending: true);

      final records = List<Map<String, dynamic>>.from(response);

      return IncomeDashboardData.fromRecords(records);
    });

class IncomeDashboardData {
  final List<Map<String, dynamic>> records;

  final double totalIncome;
  final double receivedIncome;
  final double pendingIncome;
  final double cancelledIncome;

  final int totalCount;
  final int receivedCount;
  final int pendingCount;
  final int cancelledCount;

  final double todayIncome;

  final double currentMonthIncome;
  final double previousMonthIncome;

  final double currentMonthReceived;
  final double previousMonthReceived;

  final List<IncomeMonthData> monthlyData;
  final List<IncomeCategoryData> categoryData;

  const IncomeDashboardData({
    required this.records,
    required this.totalIncome,
    required this.receivedIncome,
    required this.pendingIncome,
    required this.cancelledIncome,
    required this.totalCount,
    required this.receivedCount,
    required this.pendingCount,
    required this.cancelledCount,
    required this.todayIncome,
    required this.currentMonthIncome,
    required this.previousMonthIncome,
    required this.currentMonthReceived,
    required this.previousMonthReceived,
    required this.monthlyData,
    required this.categoryData,
  });

  factory IncomeDashboardData.fromRecords(List<Map<String, dynamic>> records) {
    double totalIncome = 0;
    double receivedIncome = 0;
    double pendingIncome = 0;
    double cancelledIncome = 0;

    int receivedCount = 0;
    int pendingCount = 0;
    int cancelledCount = 0;

    double todayIncome = 0;

    final now = DateTime.now();
    final todayYear = now.year;
    final todayMonth = now.month;
    final todayDay = now.day;

    final currentJalali = Jalali.fromDateTime(now);

    double currentMonthIncome = 0;
    double previousMonthIncome = 0;

    double currentMonthReceived = 0;
    double previousMonthReceived = 0;

    final Map<String, double> categoryTotals = {};
    final Map<String, String> categoryNames = {};

    for (final record in records) {
      final amount =
          num.tryParse(record['amount']?.toString() ?? '0')?.toDouble() ?? 0;

      final status = record['status']?.toString() ?? 'received';

      totalIncome += amount;

      switch (status) {
        case 'received':
          receivedIncome += amount;
          receivedCount++;
          break;

        case 'pending':
          pendingIncome += amount;
          pendingCount++;
          break;

        case 'cancelled':
          cancelledIncome += amount;
          cancelledCount++;
          break;
      }

      final rawDate = record['income_date']?.toString();

      if (rawDate != null) {
        final date = DateTime.tryParse(rawDate);

        if (date != null) {
          // درآمد امروز
          if (date.year == todayYear &&
              date.month == todayMonth &&
              date.day == todayDay) {
            todayIncome += amount;
          }

          final jalali = Jalali.fromDateTime(date);

          // ماه جاری
          if (jalali.year == currentJalali.year &&
              jalali.month == currentJalali.month) {
            currentMonthIncome += amount;

            if (status == 'received') {
              currentMonthReceived += amount;
            }
          }

          // ماه قبل
          final previousMonth = _previousJalaliMonth(currentJalali);

          if (jalali.year == previousMonth.year &&
              jalali.month == previousMonth.month) {
            previousMonthIncome += amount;

            if (status == 'received') {
              previousMonthReceived += amount;
            }
          }
        }
      }

      // دسته‌بندی
      final category = record['income_categories'];

      if (category is Map) {
        final categoryId = category['id']?.toString();

        final categoryName = category['name']?.toString() ?? 'بدون نام';

        if (categoryId != null) {
          categoryNames[categoryId] = categoryName;

          categoryTotals[categoryId] =
              (categoryTotals[categoryId] ?? 0) + amount;
        }
      }
    }

    final monthlyData = _buildMonthlyData(records);

    final categoryData =
        categoryTotals.entries
            .map(
              (entry) => IncomeCategoryData(
                categoryId: entry.key,
                name: categoryNames[entry.key] ?? 'بدون نام',
                amount: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    return IncomeDashboardData(
      records: records,
      totalIncome: totalIncome,
      receivedIncome: receivedIncome,
      pendingIncome: pendingIncome,
      cancelledIncome: cancelledIncome,
      totalCount: records.length,
      receivedCount: receivedCount,
      pendingCount: pendingCount,
      cancelledCount: cancelledCount,
      todayIncome: todayIncome,
      currentMonthIncome: currentMonthIncome,
      previousMonthIncome: previousMonthIncome,
      currentMonthReceived: currentMonthReceived,
      previousMonthReceived: previousMonthReceived,
      monthlyData: monthlyData,
      categoryData: categoryData,
    );
  }

  // -----------------------------
  // درصد دریافت شده
  // -----------------------------

  double get receivedPercentage {
    if (totalIncome <= 0) {
      return 0;
    }

    return (receivedIncome / totalIncome) * 100;
  }

  // -----------------------------
  // درصد در انتظار
  // -----------------------------

  double get pendingPercentage {
    if (totalIncome <= 0) {
      return 0;
    }

    return (pendingIncome / totalIncome) * 100;
  }

  // -----------------------------
  // درصد لغو شده
  // -----------------------------

  double get cancelledPercentage {
    if (totalIncome <= 0) {
      return 0;
    }

    return (cancelledIncome / totalIncome) * 100;
  }

  // -----------------------------
  // رشد ماه جاری نسبت به ماه قبل
  // -----------------------------

  double get monthGrowthPercentage {
    if (previousMonthIncome == 0) {
      if (currentMonthIncome > 0) {
        return 100;
      }

      return 0;
    }

    return ((currentMonthIncome - previousMonthIncome) / previousMonthIncome) *
        100;
  }

  // -----------------------------
  // رشد دریافتی ماه جاری
  // -----------------------------

  double get receivedGrowthPercentage {
    if (previousMonthReceived == 0) {
      if (currentMonthReceived > 0) {
        return 100;
      }

      return 0;
    }

    return ((currentMonthReceived - previousMonthReceived) /
            previousMonthReceived) *
        100;
  }

  // -----------------------------
  // نام ماه جاری
  // -----------------------------

  String get currentMonthName {
    return _monthName(Jalali.fromDateTime(DateTime.now()).month);
  }

  // -----------------------------
  // نام ماه قبل
  // -----------------------------

  String get previousMonthName {
    final current = Jalali.fromDateTime(DateTime.now());

    final previous = _previousJalaliMonth(current);

    return _monthName(previous.month);
  }

  // -----------------------------
  // ماه قبل
  // -----------------------------

  static Jalali _previousJalaliMonth(Jalali date) {
    if (date.month == 1) {
      return Jalali(date.year - 1, 12, 1);
    }

    return Jalali(date.year, date.month - 1, 1);
  }

  // -----------------------------
  // ساخت ۶ ماه اخیر
  // -----------------------------

  static List<IncomeMonthData> _buildMonthlyData(
    List<Map<String, dynamic>> records,
  ) {
    final now = DateTime.now();

    final current = Jalali.fromDateTime(now);

    final Map<String, IncomeMonthData> months = {};

    // دقیقاً ۶ ماه:
    //
    // current - 5
    // current - 4
    // current - 3
    // current - 2
    // current - 1
    // current
    //
    // بنابراین هیچ ماه آینده‌ای وارد نمی‌شود.

    for (int offset = 5; offset >= 0; offset--) {
      final monthDate = _subtractMonths(current, offset);

      final key = '${monthDate.year}-${monthDate.month}';

      months[key] = IncomeMonthData(
        year: monthDate.year,
        month: monthDate.month,
        label: _monthName(monthDate.month),
        amount: 0,
        receivedAmount: 0,
        pendingAmount: 0,
        cancelledAmount: 0,
      );
    }

    for (final record in records) {
      final rawDate = record['income_date']?.toString();

      if (rawDate == null) {
        continue;
      }

      final date = DateTime.tryParse(rawDate);

      if (date == null) {
        continue;
      }

      final jalali = Jalali.fromDateTime(date);

      final key = '${jalali.year}-${jalali.month}';

      final existing = months[key];

      if (existing == null) {
        continue;
      }

      final amount =
          num.tryParse(record['amount']?.toString() ?? '0')?.toDouble() ?? 0;

      final status = record['status']?.toString() ?? 'received';

      months[key] = existing.copyWith(
        amount: existing.amount + amount,
        receivedAmount:
            existing.receivedAmount + (status == 'received' ? amount : 0),
        pendingAmount:
            existing.pendingAmount + (status == 'pending' ? amount : 0),
        cancelledAmount:
            existing.cancelledAmount + (status == 'cancelled' ? amount : 0),
      );
    }

    return months.values.toList();
  }

  static Jalali _subtractMonths(Jalali current, int months) {
    int year = current.year;
    int month = current.month - months;

    while (month <= 0) {
      month += 12;
      year--;
    }

    return Jalali(year, month, 1);
  }

  static String _monthName(int month) {
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
}

// =====================================================
// مدل ماه
// =====================================================

class IncomeMonthData {
  final int year;
  final int month;
  final String label;

  final double amount;
  final double receivedAmount;
  final double pendingAmount;
  final double cancelledAmount;

  const IncomeMonthData({
    required this.year,
    required this.month,
    required this.label,
    required this.amount,
    required this.receivedAmount,
    required this.pendingAmount,
    required this.cancelledAmount,
  });

  IncomeMonthData copyWith({
    int? year,
    int? month,
    String? label,
    double? amount,
    double? receivedAmount,
    double? pendingAmount,
    double? cancelledAmount,
  }) {
    return IncomeMonthData(
      year: year ?? this.year,
      month: month ?? this.month,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      cancelledAmount: cancelledAmount ?? this.cancelledAmount,
    );
  }
}

// =====================================================
// مدل دسته‌بندی
// =====================================================

class IncomeCategoryData {
  final String categoryId;
  final String name;
  final double amount;

  const IncomeCategoryData({
    required this.categoryId,
    required this.name,
    required this.amount,
  });

  double percentage(double total) {
    if (total <= 0) {
      return 0;
    }

    return (amount / total) * 100;
  }
}
