import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/company_repository.dart';
import '../data/models/company_model.dart';

final companyRepositoryProvider = Provider((ref) => CompanyRepository());

final companyProvider = FutureProvider.family<CompanyModel, String>((
  ref,
  id,
) async {
  return ref.read(companyRepositoryProvider).fetchCompany(id);
});
