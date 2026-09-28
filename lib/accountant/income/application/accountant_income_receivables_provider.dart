import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountantIncomeReceivablesProvider =
FutureProvider.family<AccountantIncomeReceivablesData, String>((
    ref,
    periodId,
    ) async {
  return AccountantIncomeReceivablesRepository.fetch(periodId);
});

class AccountantIncomeReceivablesData {
  final AccountantIncomeReceivablePeriod period;
  final List<AccountantIncomeReceivable> receivables;

  const AccountantIncomeReceivablesData({
    required this.period,
    required this.receivables,
  });

  double get totalAmount =>
      receivables.fold<double>(0, (sum, item) => sum + item.amount);

  double get totalReceivedDocuments => receivables.fold<double>(
    0,
        (sum, item) => sum + item.receivedDocumentsAmount,
  );

  double get totalRemaining =>
      receivables.fold<double>(0, (sum, item) => sum + item.remainingAmount);

  int get totalCount => receivables.length;

  int get outstandingCount =>
      receivables.where((item) => item.remainingAmount > 0).length;
}

class AccountantIncomeReceivablePeriod {
  final String id;
  final String fiscalYearId;
  final String companyId;
  final int year;
  final int month;
  final String title;
  final String status;

  const AccountantIncomeReceivablePeriod({
    required this.id,
    required this.fiscalYearId,
    required this.companyId,
    required this.year,
    required this.month,
    required this.title,
    required this.status,
  });

  bool get isOpen => status == 'open';

  bool get isLocked => !isOpen;

  String get statusTitle {
    switch (status) {
      case 'open':
        return 'باز';

      case 'submitted_to_company_admin':
        return 'ارسال‌شده به مدیرعامل';

      case 'submitted_to_consultant':
        return 'در انتظار تأیید مشاور';

      case 'approved':
        return 'تأیید نهایی شده';

      case 'closed':
        return 'بسته';

      default:
        return status;
    }
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

    if (month < 1 || month > 12) {
      return 'ماه';
    }

    return months[month - 1];
  }

  String get displayTitle {
    if (title.trim().isNotEmpty) {
      return title;
    }

    return monthName;
  }
}

class AccountantIncomeReceivable {
  final String id;
  final String companyId;
  final String fiscalPeriodId;
  final String title;
  final double amount;
  final double receivedDocumentsAmount;
  final String? description;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AccountantIncomeReceivable({
    required this.id,
    required this.companyId,
    required this.fiscalPeriodId,
    required this.title,
    required this.amount,
    required this.receivedDocumentsAmount,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remainingAmount {
    final remaining = amount - receivedDocumentsAmount;

    if (remaining < 0) {
      return 0;
    }

    return remaining;
  }

  bool get isFullyReceived => remainingAmount <= 0;

  bool get hasReceivedDocuments => receivedDocumentsAmount > 0;
}

class AccountantIncomeReceivablesRepository {
  AccountantIncomeReceivablesRepository._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<AccountantIncomeReceivablesData> fetch(
      String periodId,
      ) async {
    if (periodId.trim().isEmpty) {
      throw Exception('شناسه ماه مطالبات مشخص نیست.');
    }

    final periodResponse = await _supabase
        .from('income_receivable_fiscal_periods')
        .select(
      'id, '
          'fiscal_year_id, '
          'company_id, '
          'year, '
          'month, '
          'title, '
          'status',
    )
        .eq('id', periodId)
        .maybeSingle();

    if (periodResponse == null) {
      throw Exception('ماه مطالبات پیدا نشد.');
    }

    final period = AccountantIncomeReceivablePeriod(
      id: periodResponse['id']?.toString() ?? periodId,
      fiscalYearId: periodResponse['fiscal_year_id']?.toString() ?? '',
      companyId: periodResponse['company_id']?.toString() ?? '',
      year: _toInt(periodResponse['year']),
      month: _toInt(periodResponse['month']),
      title: periodResponse['title']?.toString() ?? '',
      status: periodResponse['status']?.toString() ?? 'open',
    );

    if (period.companyId.isEmpty) {
      throw Exception('شرکت ماه مطالبات مشخص نیست.');
    }

    final response = await _supabase
        .from('income_receivables')
        .select(
      'id, '
          'company_id, '
          'fiscal_period_id, '
          'title, '
          'amount, '
          'received_documents_amount, '
          'description, '
          'created_by, '
          'created_at, '
          'updated_at',
    )
        .eq('fiscal_period_id', periodId)
        .order('created_at', ascending: false);

    final receivables = <AccountantIncomeReceivable>[];

    for (final rawRow in response as List) {
      final row = Map<String, dynamic>.from(rawRow);

      receivables.add(
        AccountantIncomeReceivable(
          id: row['id']?.toString() ?? '',
          companyId:
          row['company_id']?.toString() ?? period.companyId,
          fiscalPeriodId:
          row['fiscal_period_id']?.toString() ?? periodId,
          title: row['title']?.toString() ?? '',
          amount: _toDouble(row['amount']),
          receivedDocumentsAmount:
          _toDouble(row['received_documents_amount']),
          description: row['description']?.toString(),
          createdBy: row['created_by']?.toString(),
          createdAt: _toDateTime(row['created_at']),
          updatedAt: _toDateTime(row['updated_at']),
        ),
      );
    }

    return AccountantIncomeReceivablesData(
      period: period,
      receivables: receivables,
    );
  }

  static Future<void> create({
    required String periodId,
    required String title,
    required double amount,
    required double receivedDocumentsAmount,
    String? description,
  }) async {
    await _ensureEditable(periodId);

    final normalizedTitle = title.trim();

    if (normalizedTitle.isEmpty) {
      throw Exception('عنوان مطالبه را وارد کنید.');
    }

    if (amount <= 0) {
      throw Exception('مبلغ مطالبه باید بیشتر از صفر باشد.');
    }

    if (receivedDocumentsAmount < 0) {
      throw Exception('مبلغ اسناد دریافتی نمی‌تواند منفی باشد.');
    }

    if (receivedDocumentsAmount > amount) {
      throw Exception(
        'مبلغ اسناد دریافتی نمی‌تواند بیشتر از مبلغ مطالبه باشد.',
      );
    }

    final period = await _getPeriod(periodId);
    final user = _supabase.auth.currentUser;

    await _supabase.from('income_receivables').insert({
      'company_id': period['company_id'],
      'fiscal_period_id': periodId,
      'title': normalizedTitle,
      'amount': amount,
      'received_documents_amount': receivedDocumentsAmount,
      'description': _nullableText(description),
      'created_by': user?.id,
    });
  }

  static Future<void> update({
    required String id,
    required String periodId,
    required String title,
    required double amount,
    required double receivedDocumentsAmount,
    String? description,
  }) async {
    await _ensureEditable(periodId);

    final normalizedTitle = title.trim();

    if (normalizedTitle.isEmpty) {
      throw Exception('عنوان مطالبه را وارد کنید.');
    }

    if (amount <= 0) {
      throw Exception('مبلغ مطالبه باید بیشتر از صفر باشد.');
    }

    if (receivedDocumentsAmount < 0) {
      throw Exception('مبلغ اسناد دریافتی نمی‌تواند منفی باشد.');
    }

    if (receivedDocumentsAmount > amount) {
      throw Exception(
        'مبلغ اسناد دریافتی نمی‌تواند بیشتر از مبلغ مطالبه باشد.',
      );
    }

    await _supabase
        .from('income_receivables')
        .update({
      'title': normalizedTitle,
      'amount': amount,
      'received_documents_amount': receivedDocumentsAmount,
      'description': _nullableText(description),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    })
        .eq('id', id)
        .eq('fiscal_period_id', periodId);
  }

  static Future<void> delete({
    required String id,
    required String periodId,
  }) async {
    await _ensureEditable(periodId);

    await _supabase
        .from('income_receivables')
        .delete()
        .eq('id', id)
        .eq('fiscal_period_id', periodId);
  }

  static Future<void> processPeriodWorkflow({
    required String periodId,
    required String action,
    String? note,
  }) async {
    if (periodId.trim().isEmpty) {
      throw Exception('شناسه ماه مطالبات مشخص نیست.');
    }

    await _supabase.rpc(
      'process_income_receivable_fiscal_period',
      params: {
        'p_period_id': periodId,
        'p_action': action,
        'p_note': _nullableText(note),
      },
    );
  }

  static Future<Map<String, dynamic>> _getPeriod(
      String periodId,
      ) async {
    final result = await _supabase
        .from('income_receivable_fiscal_periods')
        .select(
      'id, '
          'fiscal_year_id, '
          'company_id, '
          'year, '
          'month, '
          'title, '
          'status',
    )
        .eq('id', periodId)
        .maybeSingle();

    if (result == null) {
      throw Exception('ماه مطالبات پیدا نشد.');
    }

    return Map<String, dynamic>.from(result);
  }

  static Future<void> _ensureEditable(String periodId) async {
    final period = await _getPeriod(periodId);
    final status = period['status']?.toString() ?? '';

    if (status != 'open') {
      throw Exception(
        'این ماه مطالبات در وضعیت «${_statusTitle(status)}» قرار دارد و امکان ویرایش مطالبات وجود ندارد.',
      );
    }
  }

  static String _statusTitle(String status) {
    switch (status) {
      case 'open':
        return 'باز';

      case 'submitted_to_company_admin':
        return 'ارسال‌شده به مدیرعامل';

      case 'submitted_to_consultant':
        return 'در انتظار تأیید مشاور';

      case 'approved':
        return 'تأیید نهایی شده';

      case 'closed':
        return 'بسته';

      default:
        return status;
    }
  }

  static String? _nullableText(String? value) {
    final text = value?.trim();

    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

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

  static double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}