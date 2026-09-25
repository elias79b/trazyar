import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final expenseMonthlyReportProvider =
    FutureProvider.family<ExpenseMonthlyReportData, String>((
      ref,
      periodId,
    ) async {
      final client = Supabase.instance.client;

      final periodResponse =
          await client
              .from('expense_fiscal_periods')
              .select('''
          id,
          fiscal_year_id,
          company_id,
          year,
          month,
          title,
          status
        ''')
              .eq('id', periodId)
              .maybeSingle();

      if (periodResponse == null) {
        throw Exception('دوره مالی هزینه پیدا نشد.');
      }

      final period = Map<String, dynamic>.from(periodResponse);

      final response = await client
          .from('expense_recognitions')
          .select('''
          id,
          company_id,
          fiscal_period_id,
          category_id,
          amount,
          description,
          created_by,
          created_at,
          updated_at,
          expense_categories (
            id,
            name,
            code,
            expense_type,
            is_active
          )
        ''')
          .eq('fiscal_period_id', periodId)
          .order('created_at', ascending: true);

      final rows = List<Map<String, dynamic>>.from(response);

      double total = 0;
      double operational = 0;
      double nonOperational = 0;

      final categories = <ExpenseMonthlyReportCategory>[];

      for (final row in rows) {
        final amount = _toDouble(row['amount']);

        final category = row['expense_categories'];

        String categoryId = row['category_id']?.toString() ?? '';

        String categoryName = 'بدون دسته‌بندی';
        String code = '';
        String expenseType = 'operational';

        if (category is Map) {
          categoryId = category['id']?.toString() ?? categoryId;

          categoryName = category['name']?.toString() ?? categoryName;

          code = category['code']?.toString() ?? '';

          expenseType = category['expense_type']?.toString() ?? expenseType;
        }

        total += amount;

        if (expenseType == 'non_operational') {
          nonOperational += amount;
        } else {
          operational += amount;
        }

        categories.add(
          ExpenseMonthlyReportCategory(
            recognitionId: row['id']?.toString() ?? '',
            categoryId: categoryId,
            categoryName: categoryName,
            code: code,
            expenseType: expenseType,
            amount: amount,
            description: row['description']?.toString(),
            createdAt: _parseDate(row['created_at']),
          ),
        );
      }

      categories.sort((a, b) => b.amount.compareTo(a.amount));

      return ExpenseMonthlyReportData(
        periodId: periodId,
        fiscalYearId: period['fiscal_year_id']?.toString() ?? '',
        companyId: period['company_id']?.toString() ?? '',
        year: _toInt(period['year']),
        month: _toInt(period['month']),
        title: period['title']?.toString() ?? '',
        status: period['status']?.toString() ?? 'open',
        total: total,
        operational: operational,
        nonOperational: nonOperational,
        categories: categories,
      );
    });

class ExpenseMonthlyReportData {
  final String periodId;
  final String fiscalYearId;
  final String companyId;

  final int year;
  final int month;
  final String title;
  final String status;

  final double total;
  final double operational;
  final double nonOperational;

  final List<ExpenseMonthlyReportCategory> categories;

  const ExpenseMonthlyReportData({
    required this.periodId,
    required this.fiscalYearId,
    required this.companyId,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
    required this.total,
    required this.operational,
    required this.nonOperational,
    required this.categories,
  });

  bool get isClosed => status == 'closed';

  double get operationalPercent {
    if (total <= 0) return 0;
    return operational / total * 100;
  }

  double get nonOperationalPercent {
    if (total <= 0) return 0;
    return nonOperational / total * 100;
  }

  int get categoryCount => categories.length;
}

class ExpenseMonthlyReportCategory {
  final String recognitionId;
  final String categoryId;
  final String categoryName;
  final String code;
  final String expenseType;

  final double amount;
  final String? description;
  final DateTime? createdAt;

  const ExpenseMonthlyReportCategory({
    required this.recognitionId,
    required this.categoryId,
    required this.categoryName,
    required this.code,
    required this.expenseType,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  bool get isOperational => expenseType != 'non_operational';

  bool get isNonOperational => expenseType == 'non_operational';
}

double _toDouble(dynamic value) {
  if (value == null) return 0;

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value) {
  if (value == null) return 0;

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;

  return DateTime.tryParse(value.toString());
}
