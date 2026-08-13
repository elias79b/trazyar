import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authServiceProvider = Provider<AuthService>(
      (ref) => AuthService(
    Supabase.instance.client,
  ),
);

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  // ============================================================
  // SESSION
  // ============================================================

  Session? get currentSession {
    return _client.auth.currentSession;
  }

  User? get currentUser {
    return _client.auth.currentUser;
  }

  bool get isAuthenticated {
    return currentSession != null;
  }

  // ============================================================
  // SIGN IN
  // ============================================================

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      throw Exception(
        'ایمیل را وارد کنید.',
      );
    }

    if (password.isEmpty) {
      throw Exception(
        'رمز عبور را وارد کنید.',
      );
    }

    final response =
    await _client.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );

    print('==============================');
    print('LOGIN SUCCESS');
    print('USER ID: ${response.user?.id}');
    print('EMAIL: ${response.user?.email}');
    print(
      'SESSION EXISTS: ${response.session != null}',
    );
    print('==============================');

    if (response.user == null ||
        response.session == null) {
      throw Exception(
        'ورود به حساب کاربری انجام نشد.',
      );
    }
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ============================================================
  // FETCH USER ROLE
  // ============================================================

  Future<String?> fetchRole(
      String userId,
      ) async {
    print(
      '========================================',
    );
    print('FETCH ROLE START');
    print('USER ID: $userId');

    try {
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

      print(
        'PUBLIC USERS ROW: $row',
      );

      if (row == null) {
        print(
          'USER PROFILE NOT FOUND',
        );

        return null;
      }

      final role =
      row['role']
          ?.toString()
          .trim()
          .toLowerCase();

      final isActive =
          row['is_active'] == true;

      print(
        'ROLE: $role',
      );

      print(
        'IS ACTIVE: $isActive',
      );

      // کاربر غیرفعال اجازه ورود به داشبورد ندارد.
      if (!isActive) {
        print(
          'USER ACCOUNT IS INACTIVE',
        );

        return null;
      }

      print(
        'FETCH ROLE SUCCESS: $role',
      );

      print(
        '========================================',
      );

      return role;
    } catch (e, stackTrace) {
      print(
        'FETCH ROLE ERROR: $e',
      );

      print(
        stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // FETCH CURRENT USER ROLE
  // ============================================================

  Future<String?> fetchCurrentUserRole() async {
    final user = currentUser;

    if (user == null) {
      print(
        'FETCH CURRENT ROLE: NO AUTH USER',
      );

      return null;
    }

    return fetchRole(
      user.id,
    );
  }

  // ============================================================
  // ROUTE FOR ROLE
  // ============================================================

  static String routeForRole(
      String? role,
      ) {
    final normalizedRole =
    role?.trim().toLowerCase();

    print(
      'ROUTE FOR ROLE: $normalizedRole',
    );

    switch (normalizedRole) {
      case 'owner':
        return '/owner';

      case 'consultant':
        return '/consultant';

      case 'company':
      case 'company_admin':
      case 'admin':
      case 'accountant':
      case 'member':
        return '/company';

      default:
        return '/login';
    }
  }

  // ============================================================
  // GET CURRENT USER ROUTE
  // ============================================================

  Future<String> currentUserRoute() async {
    final user = currentUser;

    if (user == null) {
      print(
        'CURRENT USER ROUTE: NO USER',
      );

      return '/login';
    }

    final role =
    await fetchRole(
      user.id,
    );

    return routeForRole(
      role,
    );
  }
}