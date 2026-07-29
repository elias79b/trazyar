import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authServiceProvider = Provider<AuthService>(
      (ref) => AuthService(Supabase.instance.client),
);

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    print("==============");
    print(response.user?.id);
    print(response.user?.email);
    print(response.session);
    print("==============");
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<String?> fetchRole(String userId) async {
    print("Fetching role for: $userId");

    final row = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    print("User Row => $row");

    if (row == null) {
      return null;
    }

    return row['role'] as String?;
  }

  static String routeForRole(String? role) {
    if (role == 'owner') return '/owner';
    return '/login';
  }
}