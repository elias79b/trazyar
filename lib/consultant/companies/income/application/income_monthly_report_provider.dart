import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final incomeMonthlyReportProvider = FutureProvider.family<
  IncomeMonthlyReportData,
  String
>((ref, companyId) async {
  final client = Supabase.instance.client;

  final yearsResponse = await client
      .from('income_fiscal_years')
      .select('id, company_id, year, title, status')
      .eq('company_id', companyId)
      .order('year', ascending: false);

  final years = List<Map<String, dynamic>>.from(yearsResponse);

  if (years.isEmpty) {
    return IncomeMonthlyReportData.empty();
  }

  final yearIds = years.map((e) => e['id'].toString()).toList();

  final periodsResponse = await client
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
      .eq('company_id', companyId)
      .inFilter('fiscal_year_id', yearIds)
      .order('year', ascending: false)
      .order('month', ascending: true);

  final periods = List<Map<String, dynamic>>.from(periodsResponse);

  if (periods.isEmpty) {
    return IncomeMonthlyReportData.fromData(years: years, rows: const []);
  }

  final periodIds = periods.map((e) => e['id'].toString()).toList();

  final recognitionsResponse = await client
      .from('income_recognitions')
      .select('''
          id,
          company_id,
          fiscal_period_id,
          category_id,
          amount,
          description,
          income_categories (
            id,
            name,
            code,
            category_type,
            is_system
          )
        ''')
      .eq('company_id', companyId)
      .inFilter('fiscal_period_id', periodIds);

  final receivablesResponse = await client
      .from('income_receivables')
      .select('''
          id,
          company_id,
          fiscal_period_id,
          title,
          amount,
          received_documents_amount
        ''')
      .eq('company_id', companyId)
      .inFilter('fiscal_period_id', periodIds);

  final recognitions = List<Map<String, dynamic>>.from(recognitionsResponse);

  final receivables = List<Map<String, dynamic>>.from(receivablesResponse);

  final rows = <IncomeMonthlyReportRow>[];

  for (final period in periods) {
    final periodId = period['id'].toString();

    final periodRecognitions =
        recognitions
            .where((item) => item['fiscal_period_id']?.toString() == periodId)
            .toList();

    final periodReceivables =
        receivables
            .where((item) => item['fiscal_period_id']?.toString() == periodId)
            .toList();

    double operational = 0;
    double nonOperational = 0;

    for (final item in periodRecognitions) {
      final amount = _toDouble(item['amount']);
      final category = item['income_categories'];

      final categoryType =
          category is Map<String, dynamic>
              ? category['category_type']?.toString()
              : null;

      if (categoryType == 'non_operational') {
        nonOperational += amount;
      } else {
        operational += amount;
      }
    }

    double receivableTotal = 0;
    double receivedDocuments = 0;

    for (final item in periodReceivables) {
      receivableTotal += _toDouble(item['amount']);
      receivedDocuments += _toDouble(item['received_documents_amount']);
    }

    final total = operational + nonOperational;
    final remainingReceivable = (receivableTotal - receivedDocuments).clamp(
      0,
      double.infinity,
    );

    rows.add(
      IncomeMonthlyReportRow(
        periodId: periodId,
        year: _toInt(period['year']),
        month: _toInt(period['month']),
        title: period['title']?.toString() ?? '',
        status: period['status']?.toString() ?? 'open',
        operational: operational,
        nonOperational: nonOperational,
        total: total,
        receivableTotal: receivableTotal,
        receivedDocuments: receivedDocuments,
        remainingReceivable: remainingReceivable.toDouble(),
      ),
    );
  }

  return IncomeMonthlyReportData.fromData(years: years, rows: rows);
});

class IncomeMonthlyReportData {
  final List<Map<String, dynamic>> years;
  final List<IncomeMonthlyReportRow> rows;

  const IncomeMonthlyReportData({required this.years, required this.rows});

  factory IncomeMonthlyReportData.empty() {
    return const IncomeMonthlyReportData(years: [], rows: []);
  }

  factory IncomeMonthlyReportData.fromData({
    required List<Map<String, dynamic>> years,
    required List<IncomeMonthlyReportRow> rows,
  }) {
    return IncomeMonthlyReportData(years: years, rows: rows);
  }

  double get totalOperational =>
      rows.fold(0, (sum, row) => sum + row.operational);

  double get totalNonOperational =>
      rows.fold(0, (sum, row) => sum + row.nonOperational);

  double get totalIncome => rows.fold(0, (sum, row) => sum + row.total);

  double get totalReceivables =>
      rows.fold(0, (sum, row) => sum + row.receivableTotal);

  double get totalReceivedDocuments =>
      rows.fold(0, (sum, row) => sum + row.receivedDocuments);

  double get totalRemainingReceivables =>
      rows.fold(0, (sum, row) => sum + row.remainingReceivable);
}

class IncomeMonthlyReportRow {
  final String periodId;
  final int year;
  final int month;
  final String title;
  final String status;

  final double operational;
  final double nonOperational;
  final double total;

  final double receivableTotal;
  final double receivedDocuments;
  final double remainingReceivable;

  const IncomeMonthlyReportRow({
    required this.periodId,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
    required this.operational,
    required this.nonOperational,
    required this.total,
    required this.receivableTotal,
    required this.receivedDocuments,
    required this.remainingReceivable,
  });

  bool get isClosed => status == 'closed';
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0;

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}
