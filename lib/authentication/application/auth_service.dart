
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authServiceProvider = Provider<AuthService>(
      (ref) => AuthService(Supabase.instance.client),
);

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  bool get isAuthenticated => currentSession != null;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      throw Exception('ایمیل را وارد کنید.');
    }

    if (password.isEmpty) {
      throw Exception('رمز عبور را وارد کنید.');
    }

    final response =
    await _client.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );

    if (response.user == null ||
        response.session == null) {
      throw Exception(
        'ورود به حساب کاربری انجام نشد.',
      );
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<String?> fetchRole(
      String userId,
      ) async {
    final row = await _client
        .from('users')
        .select(
      'id, email, full_name, role, is_active',
    )
        .eq(
      'id',
      userId,
    )
        .maybeSingle();

    if (row == null) {
      return null;
    }

    final isActive = row['is_active'] == true;

    if (!isActive) {
      return null;
    }

    final role = row['role']
        ?.toString()
        .trim()
        .toLowerCase();

    if (role == null || role.isEmpty) {
      return null;
    }

    return role;
  }

  Future<String?> fetchCurrentUserRole() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    return fetchRole(user.id);
  }

  static String routeForRole(
      String? role,
      ) {
    final normalizedRole =
    role?.trim().toLowerCase();

    switch (normalizedRole) {
      case 'owner':
        return '/owner';

      case 'consultant':
        return '/consultant';

      case 'accountant':
        return '/accountant';

      case 'company_admin':
        return '/company-admin';

    // این نقش‌ها عمداً مثل قبل
    // رفتار می‌کنند تا Flow قبلی تغییر نکند.
      case 'company':
      case 'admin':
      case 'member':
        return '/company';

      default:
        return '/login';
    }
  }

  Future<String> currentUserRoute() async {
    final user = currentUser;

    if (user == null) {
      return '/login';
    }

    final role =
    await fetchRole(user.id);

    return routeForRole(role);
  }
}