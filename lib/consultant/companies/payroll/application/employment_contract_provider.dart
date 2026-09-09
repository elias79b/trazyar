import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/employment_contract_model.dart';
import '../data/employment_contract_repository.dart';

final employmentContractRepositoryProvider =
    Provider<EmploymentContractRepository>((ref) {
      return EmploymentContractRepository();
    });

final employmentContractsProvider =
    FutureProvider.family<List<EmploymentContractModel>, String>((
      ref,
      companyId,
    ) async {
      final repository = ref.watch(employmentContractRepositoryProvider);

      return repository.getContracts(companyId);
    });

final employmentContractProvider =
    FutureProvider.family<EmploymentContractModel?, String>((
      ref,
      contractId,
    ) async {
      final repository = ref.watch(employmentContractRepositoryProvider);

      return repository.getContractById(contractId);
    });
