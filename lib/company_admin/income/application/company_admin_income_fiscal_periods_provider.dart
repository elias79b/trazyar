
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IncomeFiscalYear {
final String id;
final String companyId;
final int year;
final String title;
final String status;

const IncomeFiscalYear({
required this.id,
required this.companyId,
required this.year,
required this.title,
required this.status,
});

factory IncomeFiscalYear.fromMap(Map<String, dynamic> map) {
return IncomeFiscalYear(
id: map['id'].toString(),
companyId: map['company_id'].toString(),
year: (map['year'] as num).toInt(),
title: map['title'] as String,
status: map['status'] as String,
);
}
}

class IncomeFiscalPeriod {
final String id;
final String fiscalYearId;
final String companyId;
final int year;
final int month;
final String title;
final String status;

const IncomeFiscalPeriod({
required this.id,
required this.fiscalYearId,
required this.companyId,
required this.year,
required this.month,
required this.title,
required this.status,
});

factory IncomeFiscalPeriod.fromMap(Map<String, dynamic> map) {
return IncomeFiscalPeriod(
id: map['id'].toString(),
fiscalYearId: map['fiscal_year_id'].toString(),
companyId: map['company_id'].toString(),
year: (map['year'] as num).toInt(),
month: (map['month'] as num).toInt(),
title: map['title'] as String,
status: map['status'] as String,
);
}
}

class IncomeFiscalPeriodsState {
final bool loading;
final String? error;
final String? companyId;
final List<IncomeFiscalYear> years;
final List<IncomeFiscalPeriod> periods;

const IncomeFiscalPeriodsState({
this.loading = false,
this.error,
this.companyId,
this.years = const [],
this.periods = const [],
});

IncomeFiscalPeriodsState copyWith({
bool? loading,
String? error,
String? companyId,
List<IncomeFiscalYear>? years,
List<IncomeFiscalPeriod>? periods,
bool clearError = false,
}) {
return IncomeFiscalPeriodsState(
loading: loading ?? this.loading,
error: clearError ? null : (error ?? this.error),
companyId: companyId ?? this.companyId,
years: years ?? this.years,
periods: periods ?? this.periods,
);
}
}

final companyAdminIncomeFiscalPeriodsProvider =
StateNotifierProvider<
IncomeFiscalPeriodsNotifier,
IncomeFiscalPeriodsState>(
(ref) => IncomeFiscalPeriodsNotifier(),
);

class IncomeFiscalPeriodsNotifier
extends StateNotifier<IncomeFiscalPeriodsState> {
IncomeFiscalPeriodsNotifier()
    : super(const IncomeFiscalPeriodsState());

final SupabaseClient _db = Supabase.instance.client;

Future<String> _companyId() async {
final userId = _db.auth.currentUser?.id;
if (userId == null) {
throw Exception('ابتدا وارد حساب کاربری شوید.');
}

final membership = await _db
    .from('company_users')
    .select('company_id')
    .eq('user_id', userId)
    .eq('role', 'company_admin')
    .eq('is_active', true)
    .maybeSingle();

if (membership == null) {
throw Exception('شرکت فعالی برای حساب شما پیدا نشد.');
}

return membership['company_id'].toString();
}

Future<void> load() async {
state = state.copyWith(loading: true, clearError: true);

try {
final companyId = await _companyId();

final yearRows = await _db
    .from('income_fiscal_years')
    .select('id, company_id, year, title, status')
    .eq('company_id', companyId)
    .order('year', ascending: false);

final periodRows = await _db
    .from('income_fiscal_periods')
    .select(
'id, fiscal_year_id, company_id, year, month, title, status',
)
    .eq('company_id', companyId)
    .order('year', ascending: false)
    .order('month');

state = state.copyWith(
loading: false,
companyId: companyId,
years: (yearRows as List)
    .map((e) => IncomeFiscalYear.fromMap(
Map<String, dynamic>.from(e as Map),
))
    .toList(),
periods: (periodRows as List)
    .map((e) => IncomeFiscalPeriod.fromMap(
Map<String, dynamic>.from(e as Map),
))
    .toList(),
);
} catch (e) {
state = state.copyWith(
loading: false,
error: e.toString(),
);
}
}

Future<void> saveYear({
String? id,
required int year,
required String title,
required String status,
}) async {
final companyId = state.companyId ?? await _companyId();
final userId = _db.auth.currentUser?.id;

if (userId == null) {
throw Exception('ابتدا وارد حساب کاربری شوید.');
}

if (id == null) {
await _db.from('income_fiscal_years').insert({
'company_id': companyId,
'year': year,
'title': title.trim(),
'status': status,
'created_by': userId,
});
} else {
await _db
    .from('income_fiscal_years')
    .update({
'year': year,
'title': title.trim(),
'status': status,
'updated_at': DateTime.now().toUtc().toIso8601String(),
})
    .eq('id', id)
    .eq('company_id', companyId);
}

await load();
}

Future<void> generateMonths(IncomeFiscalYear fiscalYear) async {
final existingMonths = state.periods
    .where((p) => p.fiscalYearId == fiscalYear.id)
    .map((p) => p.month)
    .toSet();

final missing = <Map<String, dynamic>>[];

const monthNames = [
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

for (var month = 1; month <= 12; month++) {
if (existingMonths.contains(month)) continue;

missing.add({
'fiscal_year_id': fiscalYear.id,
'company_id': fiscalYear.companyId,
'year': fiscalYear.year,
'month': month,
'title': '${monthNames[month - 1]} ${fiscalYear.year}',
'status': 'open',
});
}

if (missing.isNotEmpty) {
await _db.from('income_fiscal_periods').insert(missing);
}

await load();
}

Future<void> updatePeriodStatus({
required IncomeFiscalPeriod period,
required String status,
}) async {
await _db
    .from('income_fiscal_periods')
    .update({
'status': status,
'updated_at': DateTime.now().toUtc().toIso8601String(),
})
    .eq('id', period.id)
    .eq('company_id', period.companyId);

await load();
}
}

