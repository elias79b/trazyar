import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/owner/companies/data/companies_repository.dart';

import '../domain/models/company_model.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository();
});

final companiesProvider =
FutureProvider.autoDispose<List<CompanyModel>>((ref) async {
  return ref.read(companyRepositoryProvider).getCompanies();
});

final activeCompaniesProvider =
Provider<List<CompanyModel>>((ref) {
  final companies = ref.watch(companiesProvider);

  return companies.maybeWhen(
    data: (data) =>
        data.where((company) => company.isActive).toList(),
    orElse: () => [],
  );
});

final inactiveCompaniesProvider =
Provider<List<CompanyModel>>((ref) {
  final companies = ref.watch(companiesProvider);

  return companies.maybeWhen(
    data: (data) =>
        data.where((company) => !company.isActive).toList(),
    orElse: () => [],
  );
});