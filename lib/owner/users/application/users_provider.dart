import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/users_repository.dart';

final usersRepositoryProvider =
Provider<UsersRepository>(
      (ref) => UsersRepository(),
);

final ownerUsersProvider =
FutureProvider<List<OwnerUser>>((ref) async {
  return ref
      .read(usersRepositoryProvider)
      .fetchUsers();
});

final ownerCompaniesForUserProvider =
FutureProvider<List<CompanyOption>>((ref) async {
  return ref
      .read(usersRepositoryProvider)
      .fetchCompanies();
});