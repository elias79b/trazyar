

import 'package:tarazyar/authentication/data/datasources/auth_remote_data_source.dart';
import 'package:tarazyar/authentication/domain/entities/user.dart';
import 'package:tarazyar/authentication/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<AppUser?> get authStateChanges => _remoteDataSource.authStateChanges;

  @override
  AppUser? get currentUser => _remoteDataSource.currentUser;

  @override
  Future<AppUser> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _remoteDataSource.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() {
    return _remoteDataSource.signOut();
  }
}
