import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/company_repository.dart';
import '../data/models/company_model.dart';

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository();
});

final companyProvider = FutureProvider.family<CompanyModel, String>((
  ref,
  companyId,
) async {
  return ref.read(companyRepositoryProvider).fetchCompany(companyId);
});
