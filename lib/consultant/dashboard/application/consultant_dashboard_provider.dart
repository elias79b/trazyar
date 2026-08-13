import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/consultant_dashboard_repository.dart';

final consultantDashboardRepositoryProvider =
Provider<ConsultantDashboardRepository>(
      (ref) {
    return ConsultantDashboardRepository();
  },
);

final consultantCompaniesProvider =
FutureProvider<List<ConsultantCompany>>(
      (ref) async {
    final repository =
    ref.read(
      consultantDashboardRepositoryProvider,
    );

    return repository.fetchMyCompanies();
  },
);

final consultantProfileProvider =
FutureProvider<Map<String, dynamic>?>(
      (ref) async {
    final repository =
    ref.read(
      consultantDashboardRepositoryProvider,
    );

    return repository.fetchMyProfile();
  },
);