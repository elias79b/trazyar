
import 'package:tarazyar/authentication/domain/entities/user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  AppUser? get currentUser;

  Future<AppUser> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
