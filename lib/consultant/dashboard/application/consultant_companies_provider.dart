import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/consultant_companies_repository.dart';
import '../data/models/consultant_company.dart';

final consultantCompaniesRepositoryProvider =
Provider<ConsultantCompaniesRepository>(
      (ref) => ConsultantCompaniesRepository(),
);

final consultantCompaniesProvider =
FutureProvider<List<ConsultantCompany>>((ref) async {
  return ref
      .read(consultantCompaniesRepositoryProvider)
      .fetchMyCompanies();
});