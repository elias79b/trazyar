// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../data/consultant_dashboard_repository.dart';
//
// final consultantDashboardRepositoryProvider =
// Provider<ConsultantDashboardRepository>(
//       (ref) {
//     return ConsultantDashboardRepository();
//   },
// );
//
// final consultantCompaniesProvider =
// FutureProvider<List<ConsultantCompany>>(
//       (ref) async {
//     final repository =
//     ref.read(
//       consultantDashboardRepositoryProvider,
//     );
//
//     return repository.fetchMyCompanies();
//   },
// );
//
// final consultantProfileProvider =
// FutureProvider<Map<String, dynamic>?>(
//       (ref) async {
//     final repository =
//     ref.read(
//       consultantDashboardRepositoryProvider,
//     );
//
//     return repository.fetchMyProfile();
//   },
// );
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tarazyar/consultant/dashboard/data/models/consultant_event_model.dart';
import 'package:tarazyar/consultant/dashboard/data/models/consultant_note_model.dart';



final consultantDashboardProvider =
FutureProvider<ConsultantDashboardData>(
      (ref) async {
    final client =
        Supabase.instance.client;

    final userId =
        client.auth.currentUser?.id;

    if (userId == null) {
      throw Exception(
        'کاربر وارد سیستم نشده است.',
      );
    }

    final companies =
    await client
        .from('consultant_company_assignments')
        .select(
      'company_id, companies(id,name,is_active)',
    )
        .eq(
      'consultant_user_id',
      userId,
    )
        .eq(
      'is_active',
      true,
    );

    final notes =
    await client
        .from('consultant_notes')
        .select()
        .eq(
      'consultant_user_id',
      userId,
    )
        .eq(
      'is_archived',
      false,
    )
        .order(
      'is_pinned',
      ascending: false,
    )
        .order(
      'updated_at',
      ascending: false,
    );

    final events =
    await client
        .from('consultant_events')
        .select(
      '*, companies(id,name)',
    )
        .eq(
      'consultant_user_id',
      userId,
    )
        .order(
      'event_date',
      ascending: true,
    )
        .order(
      'start_time',
      ascending: true,
    );

    final companyRows =
    List<Map<String, dynamic>>.from(
      companies,
    );

    final noteRows =
    List<Map<String, dynamic>>.from(
      notes,
    );

    final eventRows =
    List<Map<String, dynamic>>.from(
      events,
    );

    final companyList =
    <ConsultantCompany>[];

    for (final row in companyRows) {
      final company =
      row['companies'];

      if (company is Map) {
        companyList.add(
          ConsultantCompany(
            id:
            company['id'].toString(),
            name:
            company['name']
                ?.toString() ??
                '',
          ),
        );
      }
    }

    return ConsultantDashboardData(
      companies: companyList,
      notes: noteRows
          .map(
        ConsultantNote.fromMap,
      )
          .toList(),
      events: eventRows
          .map(
        ConsultantEvent.fromMap,
      )
          .toList(),
    );
  },
);

class ConsultantDashboardData {
  final List<ConsultantCompany> companies;
  final List<ConsultantNote> notes;
  final List<ConsultantEvent> events;

  const ConsultantDashboardData({
    required this.companies,
    required this.notes,
    required this.events,
  });

  int get pendingEvents =>
      events
          .where(
            (event) =>
        event.status ==
            'pending',
      )
          .length;

  int get todayEvents {
    final now = DateTime.now();

    return events.where((event) {
      return event.eventDate.year ==
          now.year &&
          event.eventDate.month ==
              now.month &&
          event.eventDate.day ==
              now.day;
    }).length;
  }

  int get highPriorityEvents =>
      events
          .where(
            (event) =>
        event.priority ==
            'high' &&
            event.status ==
                'pending',
      )
          .length;
}

class ConsultantCompany {
  final String id;
  final String name;

  const ConsultantCompany({
    required this.id,
    required this.name,
  });
}