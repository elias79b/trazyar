import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/authentication/application/auth_service.dart';
import 'package:tarazyar/authentication/presentation/pages/invite_acceptance_page.dart';
import 'package:tarazyar/authentication/presentation/pages/login_page.dart';
import 'package:tarazyar/authentication/presentation/pages/splash_page.dart';

import 'package:tarazyar/consultant/dashboard/presentation/pages/consultant_page.dart';

import 'package:tarazyar/owner/companies/presentation/pages/companies_page.dart';
import 'package:tarazyar/owner/dashboard/presentation/pages/owner_page.dart';
import 'package:tarazyar/owner/reports/presentation/pages/reportspage.dart';
import 'package:tarazyar/owner/settings/presentation/pages/settings_page.dart';
import 'package:tarazyar/owner/users/presentation/pages/users_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final client = Supabase.instance.client;

  // ============================================================
  // مهم:
  //
  // برنامه هنگام اجرای مجدد ابتدا باید Login را نشان بدهد،
  // حتی اگر Session قبلی Supabase هنوز وجود داشته باشد.
  //
  // بعد از اولین Redirect، این مقدار false می‌شود.
  // ============================================================

  bool firstRedirect = true;

  return GoRouter(
    // ============================================================
    // شروع برنامه
    // ============================================================

    initialLocation: '/login',

    // ============================================================
    // AUTH REFRESH
    //
    // بعد از Login یا Logout، Router دوباره بررسی می‌شود.
    // ============================================================

    refreshListenable: GoRouterRefreshStream(
      client.auth.onAuthStateChange,
    ),

    // ============================================================
    // REDIRECT
    // ============================================================

    redirect: (context, state) async {
      final path = state.uri.path;

      debugPrint('====================================');
      debugPrint('ROUTER REDIRECT');
      debugPrint('PATH: $path');
      debugPrint(
        'SESSION: ${client.auth.currentSession != null}',
      );
      debugPrint('FIRST REDIRECT: $firstRedirect');
      debugPrint('====================================');

      // ==========================================================
      // INVITATION
      //
      // این مسیر نباید توسط Role یا Login تغییر کند.
      // ==========================================================

      if (path == '/auth/invite') {
        return null;
      }

      // ==========================================================
      // LOGIN
      // ==========================================================

      if (path == '/login') {
        // --------------------------------------------------------
        // اولین بار که برنامه اجرا می‌شود:
        //
        // حتی اگر Session قبلی وجود داشته باشد،
        // اجازه بده LoginPage نمایش داده شود.
        // --------------------------------------------------------

        if (firstRedirect) {
          firstRedirect = false;

          debugPrint(
            'FIRST APP START -> STAY ON LOGIN',
          );

          return null;
        }

        // --------------------------------------------------------
        // اگر Login انجام شده باشد و Session ایجاد شده باشد،
        // اینجا Role را پیدا می‌کنیم و وارد داشبورد می‌شویم.
        //
        // این قسمت هنگام AuthStateChange بعد از Login اجرا می‌شود.
        // --------------------------------------------------------

        final session =
            client.auth.currentSession;

        if (session == null) {
          debugPrint(
            'NO SESSION -> STAY ON LOGIN',
          );

          return null;
        }

        debugPrint(
          'LOGIN SUCCESS -> FETCH ROLE',
        );

        final authService =
        AuthService(client);

        final role =
        await authService.fetchRole(
          session.user.id,
        );

        debugPrint(
          'FETCHED ROLE: $role',
        );

        if (role == null) {
          debugPrint(
            'INVALID ROLE -> LOGIN',
          );

          return null;
        }

        final target =
        AuthService.routeForRole(
          role,
        );

        debugPrint(
          'LOGIN TARGET: $target',
        );

        return target;
      }

      // ==========================================================
      // SESSION
      // ==========================================================

      final session =
          client.auth.currentSession;

      // ==========================================================
      // کاربر وارد نشده
      // ==========================================================

      if (session == null) {
        debugPrint(
          'NO SESSION -> REDIRECT TO LOGIN',
        );

        if (path == '/splash') {
          return '/login';
        }

        return '/login';
      }

      // ==========================================================
      // کاربر وارد شده
      // ==========================================================

      final authService =
      AuthService(client);

      final role =
      await authService.fetchRole(
        session.user.id,
      );

      debugPrint(
        'FETCHED ROLE: $role',
      );

      // ==========================================================
      // پروفایل نامعتبر
      // ==========================================================

      if (role == null) {
        debugPrint(
          'ROLE NULL -> LOGIN',
        );

        return '/login';
      }

      // ==========================================================
      // TARGET
      // ==========================================================

      final target =
      AuthService.routeForRole(
        role,
      );

      debugPrint(
        'ROLE: $role',
      );

      debugPrint(
        'TARGET: $target',
      );

      // ==========================================================
      // ROOT / SPLASH
      // ==========================================================

      if (path == '/' ||
          path == '/splash') {
        return target;
      }

      // ==========================================================
      // OWNER
      // ==========================================================

      if (role == 'owner') {
        if (path == '/owner' ||
            path.startsWith('/owner/')) {
          return null;
        }

        return '/owner';
      }

      // ==========================================================
      // CONSULTANT
      // ==========================================================

      if (role == 'consultant') {
        if (path == '/consultant' ||
            path.startsWith('/consultant/')) {
          return null;
        }

        return '/consultant';
      }

      // ==========================================================
      // ROLE ناشناخته
      // ==========================================================

      debugPrint(
        'UNKNOWN ROLE -> LOGIN',
      );

      return '/login';
    },

    // ============================================================
    // ROUTES
    // ============================================================

    routes: [
      // ==========================================================
      // ROOT
      // ==========================================================

      GoRoute(
        path: '/',
        redirect: (_, __) => '/login',
      ),

      // ==========================================================
      // SPLASH
      // ==========================================================

      GoRoute(
        path: '/splash',
        builder: (context, state) {
          return const SplashPage();
        },
      ),

      // ==========================================================
      // LOGIN
      // ==========================================================

      GoRoute(
        path: '/login',
        builder: (context, state) {
          return const LoginPage();
        },
      ),

      // ==========================================================
      // INVITE
      // ==========================================================

      GoRoute(
        path: '/auth/invite',
        builder: (context, state) {
          return const InviteAcceptancePage();
        },
      ),

      // ==========================================================
      // CONSULTANT
      // ==========================================================

      GoRoute(
        path: '/consultant',
        builder: (context, state) {
          return const ConsultantPage();
        },
      ),

      // ==========================================================
      // OWNER
      // ==========================================================

      GoRoute(
        path: '/owner',
        builder: (context, state) {
          return const OwnerPage();
        },
      ),

      // ==========================================================
      // OWNER / COMPANIES
      // ==========================================================

      GoRoute(
        path: '/owner/companies',
        builder: (context, state) {
          return const CompaniesPage();
        },
      ),

      // ==========================================================
      // OWNER / USERS
      // ==========================================================

      GoRoute(
        path: '/owner/users',
        builder: (context, state) {
          return const UsersPage();
        },
      ),

      // ==========================================================
      // OWNER / REPORTS
      // ==========================================================

      GoRoute(
        path: '/owner/reports',
        builder: (context, state) {
          return const ReportsPage();
        },
      ),

      // ==========================================================
      // OWNER / SETTINGS
      // ==========================================================

      GoRoute(
        path: '/owner/settings',
        builder: (context, state) {
          return const SettingsPage();
        },
      ),
    ],
  );
});

// ================================================================
// AUTH REFRESH
// ================================================================

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(
      Stream<dynamic> stream,
      ) {
    _subscription = stream
        .asBroadcastStream()
        .listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic>
  _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}