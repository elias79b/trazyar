import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final incomeDashboardProvider =
FutureProvider.family<IncomeDashboardData, String>(
      (ref, companyId) async {
    final client = Supabase.instance.client;

    final currentJalali = _gregorianToJalali(DateTime.now());

    final fiscalYearsResponse = await client
        .from('income_fiscal_years')
        .select('''
          id,
          company_id,
          year,
          title,
          status
        ''')
        .eq('company_id', companyId)
        .order('year', ascending: false);

    final fiscalYears =
    List<Map<String, dynamic>>.from(
      fiscalYearsResponse,
    );

    if (fiscalYears.isEmpty) {
      return const IncomeDashboardData.empty();
    }

    // سال مالی جاری باید بر اساس سال شمسی فعلی انتخاب شود،
    // نه صرفاً بزرگ‌ترین سال موجود در دیتابیس.
    Map<String, dynamic>? selectedYear;

    for (final year in fiscalYears) {
      final value = _toInt(year['year']);

      if (value == currentJalali.year) {
        selectedYear = year;
        break;
      }
    }

    // اگر سال جاری وجود نداشت، نزدیک‌ترین سال قبل از سال جاری.
    if (selectedYear == null) {
      for (final year in fiscalYears) {
        final value = _toInt(year['year']);

        if (value <= currentJalali.year) {
          selectedYear = year;
          break;
        }
      }
    }

    // فقط اگر هیچ سال قبلی/جاری نبود، اولین سال موجود.
    selectedYear ??= fiscalYears.first;

    final fiscalYearId =
    selectedYear['id'].toString();

    final fiscalYear =
    _toInt(selectedYear['year']);

    final fiscalYearStatus =
        selectedYear['status']?.toString() ?? 'open';

    final periodResponse = await client
        .from('income_fiscal_periods')
        .select('''
          id,
          fiscal_year_id,
          company_id,
          year,
          month,
          title,
          status
        ''')
        .eq('fiscal_year_id', fiscalYearId)
        .order('month', ascending: true);

    final periodRows =
    List<Map<String, dynamic>>.from(
      periodResponse,
    );

    final periodByMonth =
    <int, Map<String, dynamic>>{};

    for (final row in periodRows) {
      final month = _toInt(row['month']);

      if (month >= 1 && month <= 12) {
        periodByMonth[month] = row;
      }
    }

    final periodIds = periodRows
        .map((e) => e['id']?.toString())
        .whereType<String>()
        .toList();

    List<Map<String, dynamic>> recognitionRows = [];

    if (periodIds.isNotEmpty) {
      final response = await client
          .from('income_recognitions')
          .select('''
            id,
            fiscal_period_id,
            category_id,
            amount
          ''')
          .inFilter(
        'fiscal_period_id',
        periodIds,
      );

      recognitionRows =
      List<Map<String, dynamic>>.from(
        response,
      );
    }

    List<Map<String, dynamic>> receivableRows = [];

    if (periodIds.isNotEmpty) {
      final response = await client
          .from('income_receivables')
          .select('''
            id,
            fiscal_period_id,
            amount,
            received_documents_amount
          ''')
          .inFilter(
        'fiscal_period_id',
        periodIds,
      );

      receivableRows =
      List<Map<String, dynamic>>.from(
        response,
      );
    }

    final categoryIds = recognitionRows
        .map(
          (row) => row['category_id']?.toString(),
    )
        .whereType<String>()
        .toSet()
        .toList();

    final categoryById =
    <String, Map<String, dynamic>>{};

    if (categoryIds.isNotEmpty) {
      final categoryResponse = await client
          .from('income_categories')
          .select('''
            id,
            name,
            category_type
          ''')
          .inFilter(
        'id',
        categoryIds,
      );

      final categories =
      List<Map<String, dynamic>>.from(
        categoryResponse,
      );

      for (final category in categories) {
        final id = category['id']?.toString();

        if (id != null) {
          categoryById[id] = category;
        }
      }
    }

    final incomeByMonth =
    <int, double>{};

    final operationalByMonth =
    <int, double>{};

    final nonOperationalByMonth =
    <int, double>{};

    final receivablesByMonth =
    <int, double>{};

    final receivedByMonth =
    <int, double>{};

    final categoryTotals =
    <String, double>{};

    final categoryTypes =
    <String, String>{};

    final categoryNames =
    <String, String>{};

    for (final row in recognitionRows) {
      final periodId =
      row['fiscal_period_id']?.toString();

      if (periodId == null) {
        continue;
      }

      final period = periodRows.firstWhere(
            (item) =>
        item['id']?.toString() == periodId,
        orElse: () => <String, dynamic>{},
      );

      if (period.isEmpty) {
        continue;
      }

      final month = _toInt(period['month']);

      final amount =
      _toDouble(row['amount']);

      if (month < 1 || month > 12) {
        continue;
      }

      incomeByMonth[month] =
          (incomeByMonth[month] ?? 0) + amount;

      final categoryId =
      row['category_id']?.toString();

      if (categoryId == null) {
        continue;
      }

      final category =
      categoryById[categoryId];

      final name =
          category?['name']?.toString() ??
              'سایر';

      final type =
          category?['category_type']
              ?.toString() ??
              'operational';

      categoryNames[categoryId] = name;
      categoryTypes[categoryId] = type;

      categoryTotals[categoryId] =
          (categoryTotals[categoryId] ?? 0) +
              amount;

      if (type == 'non_operational') {
        nonOperationalByMonth[month] =
            (nonOperationalByMonth[month] ?? 0) +
                amount;
      } else {
        operationalByMonth[month] =
            (operationalByMonth[month] ?? 0) +
                amount;
      }
    }

    for (final row in receivableRows) {
      final periodId =
      row['fiscal_period_id']?.toString();

      if (periodId == null) {
        continue;
      }

      final period = periodRows.firstWhere(
            (item) =>
        item['id']?.toString() == periodId,
        orElse: () => <String, dynamic>{},
      );

      if (period.isEmpty) {
        continue;
      }

      final month =
      _toInt(period['month']);

      if (month < 1 || month > 12) {
        continue;
      }

      final amount =
      _toDouble(row['amount']);

      final received =
      _toDouble(
        row['received_documents_amount'],
      );

      receivablesByMonth[month] =
          (receivablesByMonth[month] ?? 0) +
              amount;

      receivedByMonth[month] =
          (receivedByMonth[month] ?? 0) +
              received;
    }

    final months =
    <IncomeDashboardMonth>[];

    for (int month = 1; month <= 12; month++) {
      final period =
      periodByMonth[month];

      final title =
          period?['title']?.toString() ??
              '${_monthName(month)} ${_toFa(fiscalYear.toString())}';

      final totalIncome =
          incomeByMonth[month] ?? 0;

      final operational =
          operationalByMonth[month] ?? 0;

      final nonOperational =
          nonOperationalByMonth[month] ?? 0;

      final receivables =
          receivablesByMonth[month] ?? 0;

      final received =
          receivedByMonth[month] ?? 0;

      final remaining =
      (receivables - received)
          .clamp(0.0, double.infinity)
          .toDouble();

      final status =
          period?['status']?.toString() ??
              'open';

      months.add(
        IncomeDashboardMonth(
          month: month,
          year: fiscalYear,
          title: title,
          totalIncome: totalIncome,
          operationalIncome: operational,
          nonOperationalIncome:
          nonOperational,
          receivables: receivables,
          receivedDocuments: received,
          remainingReceivables:
          remaining,
          isClosed: status == 'closed',
        ),
      );
    }

    final totalIncome = months.fold<double>(
      0.0,
          (sum, month) =>
      sum + month.totalIncome,
    );

    final operationalIncome =
    months.fold<double>(
      0.0,
          (sum, month) =>
      sum + month.operationalIncome,
    );

    final nonOperationalIncome =
    months.fold<double>(
      0.0,
          (sum, month) =>
      sum + month.nonOperationalIncome,
    );

    final totalReceivables =
    months.fold<double>(
      0.0,
          (sum, month) =>
      sum + month.receivables,
    );

    final totalReceivedDocuments =
    months.fold<double>(
      0.0,
          (sum, month) =>
      sum + month.receivedDocuments,
    );

    final remainingReceivables =
    months.fold<double>(
      0.0,
          (sum, month) =>
      sum + month.remainingReceivables,
    );

    final completedMonths =
        months.where(
              (month) =>
          month.totalIncome > 0 ||
              month.receivables > 0,
        ).length;

    final categoryList =
    categoryTotals.entries
        .map(
          (entry) => IncomeCategoryTotal(
        categoryId: entry.key,
        name:
        categoryNames[entry.key] ??
            'سایر',
        categoryType:
        categoryTypes[entry.key] ??
            'operational',
        amount: entry.value,
      ),
    )
        .where(
          (item) => item.amount > 0,
    )
        .toList()
      ..sort(
            (a, b) =>
            b.amount.compareTo(
              a.amount,
            ),
      );

    IncomeDashboardMonth? currentMonth;
    IncomeDashboardMonth? previousMonth;

    if (fiscalYear ==
        currentJalali.year) {
      final currentIndex =
          currentJalali.month - 1;

      currentMonth =
      months[currentIndex];

      if (currentIndex > 0) {
        previousMonth =
        months[currentIndex - 1];
      }
    } else if (fiscalYear <
        currentJalali.year) {
      currentMonth = months[11];
      previousMonth = months[10];
    } else {
      currentMonth = months[0];
      previousMonth = months[11];
    }

    return IncomeDashboardData(
      fiscalYearId: fiscalYearId,
      fiscalYear: fiscalYear,
      fiscalYearStatus:
      fiscalYearStatus,
      hasFiscalYear: true,
      months: months,
      currentMonth: currentMonth,
      previousMonth: previousMonth,
      categoryTotals: categoryList,
      totalIncome: totalIncome,
      operationalIncome:
      operationalIncome,
      nonOperationalIncome:
      nonOperationalIncome,
      totalReceivables:
      totalReceivables,
      totalReceivedDocuments:
      totalReceivedDocuments,
      remainingReceivables:
      remainingReceivables,
      completedMonths:
      completedMonths,
    );
  },
);

class IncomeDashboardData {
  final String? fiscalYearId;
  final int? fiscalYear;
  final String fiscalYearStatus;
  final bool hasFiscalYear;

  final List<IncomeDashboardMonth> months;

  final IncomeDashboardMonth? currentMonth;
  final IncomeDashboardMonth? previousMonth;

  final List<IncomeCategoryTotal> categoryTotals;

  final double totalIncome;
  final double operationalIncome;
  final double nonOperationalIncome;

  final double totalReceivables;
  final double totalReceivedDocuments;
  final double remainingReceivables;

  final int completedMonths;

  const IncomeDashboardData({
    required this.fiscalYearId,
    required this.fiscalYear,
    required this.fiscalYearStatus,
    required this.hasFiscalYear,
    required this.months,
    required this.currentMonth,
    required this.previousMonth,
    required this.categoryTotals,
    required this.totalIncome,
    required this.operationalIncome,
    required this.nonOperationalIncome,
    required this.totalReceivables,
    required this.totalReceivedDocuments,
    required this.remainingReceivables,
    required this.completedMonths,
  });

  const IncomeDashboardData.empty()
      : fiscalYearId = null,
        fiscalYear = null,
        fiscalYearStatus = 'open',
        hasFiscalYear = false,
        months = const [],
        currentMonth = null,
        previousMonth = null,
        categoryTotals = const [],
        totalIncome = 0,
        operationalIncome = 0,
        nonOperationalIncome = 0,
        totalReceivables = 0,
        totalReceivedDocuments = 0,
        remainingReceivables = 0,
        completedMonths = 0;
}

class IncomeDashboardMonth {
  final int month;
  final int year;
  final String title;

  final double totalIncome;
  final double operationalIncome;
  final double nonOperationalIncome;

  final double receivables;
  final double receivedDocuments;
  final double remainingReceivables;

  final bool isClosed;

  const IncomeDashboardMonth({
    required this.month,
    required this.year,
    required this.title,
    required this.totalIncome,
    required this.operationalIncome,
    required this.nonOperationalIncome,
    required this.receivables,
    required this.receivedDocuments,
    required this.remainingReceivables,
    required this.isClosed,
  });

  bool get isEmpty =>
      totalIncome <= 0 &&
          receivables <= 0;
}

class IncomeCategoryTotal {
  final String categoryId;
  final String name;
  final String categoryType;
  final double amount;

  const IncomeCategoryTotal({
    required this.categoryId,
    required this.name,
    required this.categoryType,
    required this.amount,
  });
}

class _JalaliDate {
  final int year;
  final int month;
  final int day;

  const _JalaliDate({
    required this.year,
    required this.month,
    required this.day,
  });
}

_JalaliDate _gregorianToJalali(
    DateTime date,
    ) {
  final gDayMonth = <int>[
    0,
    31,
    59,
    90,
    120,
    151,
    181,
    212,
    243,
    273,
    304,
    334,
  ];

  int gy = date.year;
  int gm = date.month;
  final gd = date.day;

  int jy;

  if (gy > 1600) {
    jy = 979;
    gy -= 1600;
  } else {
    jy = 0;
    gy -= 621;
  }

  final gy2 =
  gm > 2 ? gy + 1 : gy;

  int days =
      (365 * gy) +
          ((gy2 + 3) ~/ 4) -
          ((gy2 + 99) ~/ 100) +
          ((gy2 + 399) ~/ 400) -
          80 +
          gd +
          gDayMonth[gm - 1];

  jy += 33 * (days ~/ 12053);

  days %= 12053;

  jy += 4 * (days ~/ 1461);

  days %= 1461;

  if (days > 365) {
    jy += (days - 1) ~/ 365;
    days = (days - 1) % 365;
  }

  final jm = days < 186
      ? 1 + (days ~/ 31)
      : 7 + ((days - 186) ~/ 30);

  final jd = 1 +
      (days < 186
          ? days % 31
          : (days - 186) % 30);

  return _JalaliDate(
    year: jy,
    month: jm,
    day: jd,
  );
}

String _monthName(int month) {
  const names = [
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

  if (month < 1 || month > 12) {
    return '';
  }

  return names[month - 1];
}

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value.toString(),
  ) ??
      0;
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

String _toFa(String value) {
  const en = '0123456789';
  const fa = '۰۱۲۳۴۵۶۷۸۹';

  var result = value;

  for (int i = 0; i < en.length; i++) {
    result = result.replaceAll(
      en[i],
      fa[i],
    );
  }

  return result;
}