import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/employee_model.dart';
import '../data/employee_repository.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository();
});

final employeesProvider = FutureProvider.family<List<EmployeeModel>, String>((
  ref,
  companyId,
) async {
  final repository = ref.watch(employeeRepositoryProvider);

  return repository.getEmployees(companyId);
});

final employeeProvider = FutureProvider.family<EmployeeModel?, String>((
  ref,
  employeeId,
) async {
  final repository = ref.watch(employeeRepositoryProvider);

  return repository.getEmployeeById(employeeId);
});

final employeeSearchProvider =
    FutureProvider.family<List<EmployeeModel>, EmployeeSearchParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(employeeRepositoryProvider);

      return repository.searchEmployees(
        companyId: params.companyId,
        query: params.query,
      );
    });

class EmployeeSearchParams {
  const EmployeeSearchParams({required this.companyId, required this.query});

  final String companyId;
  final String query;

  @override
  bool operator ==(Object other) {
    return other is EmployeeSearchParams &&
        other.companyId == companyId &&
        other.query == query;
  }

  @override
  int get hashCode => Object.hash(companyId, query);
}
