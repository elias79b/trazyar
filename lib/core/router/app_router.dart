import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tarazyar/authentication/application/auth_service.dart';
import 'package:tarazyar/authentication/presentation/pages/login_page.dart';
import 'package:tarazyar/authentication/presentation/pages/splash_page.dart';
import 'package:tarazyar/owner/companies/presentation/pages/companies_page.dart';
import 'package:tarazyar/owner/dashboard/presentation/pages/owner_page.dart';
import 'package:tarazyar/owner/reports/presentation/pages/reportspage.dart';
import 'package:tarazyar/owner/settings/presentation/pages/settings_page.dart';
import 'package:tarazyar/owner/users/presentation/pages/users_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final client = Supabase.instance.client;

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(client.auth.onAuthStateChange),
    redirect: (context, state) async {
      final session = client.auth.currentSession;
      final location = state.matchedLocation;

      if (session == null) {
        if (location == '/login') return null;
        return '/login';
      }

      final role = await AuthService(client).fetchRole(session.user.id);
      final target = AuthService.routeForRole(role);

      if (location == '/login' || location == '/splash' || location == '/') {
        return target;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => '/splash',
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/owner',
        builder: (context, state) => const OwnerPage(),
      ),
      GoRoute(
        path: '/owner/companies',
        builder: (context, state) => const CompaniesPage(),
      ),
      GoRoute(
        path: '/owner/users',
        builder: (context, state) => const UsersPage(),
      ),
      GoRoute(
        path: '/owner/reports',
        builder: (context, state) => const ReportsPage(),
      ),
      GoRoute(
        path: '/owner/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text('صفحه $title'),
      ),
    );
  }
}