import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cost_center_model.dart';
import '../data/cost_center_repository.dart';

final costCenterRepositoryProvider = Provider<CostCenterRepository>((ref) {
  return CostCenterRepository();
});

final costCentersProvider =
    FutureProvider.family<List<CostCenterModel>, String>((
      ref,
      companyId,
    ) async {
      final repository = ref.watch(costCenterRepositoryProvider);

      return repository.getCostCenters(companyId);
    });

final costCenterProvider = FutureProvider.family<CostCenterModel?, String>((
  ref,
  id,
) async {
  final repository = ref.watch(costCenterRepositoryProvider);

  return repository.getCostCenterById(id);
});
