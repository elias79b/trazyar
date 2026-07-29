import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tarazyar/authentication/domain/entities/user.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  Stream<AppUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((authState) {
      return _mapUser(authState.session?.user);
    });
  }

  AppUser? get currentUser => _mapUser(_client.auth.currentUser);

  Future<AppUser> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = _mapUser(response.user);

    if (user == null) {
      throw const AuthException('Unable to sign in with these credentials.');
    }

    return user;
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }

  AppUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }

    final metadata = <String, dynamic>{
      ...?user.userMetadata,
      ...user.appMetadata,
    };
    final role = AppRole.fromValue(metadata['role']?.toString());
    final fullName =
        metadata['full_name']?.toString() ??
        metadata['name']?.toString() ??
        metadata['display_name']?.toString();

    return AppUser(
      id: user.id,
      email: user.email ?? '',
      role: role,
      fullName: fullName,
    );
  }
}
