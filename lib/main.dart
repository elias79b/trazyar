import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tarazyar/core/config/app_config.dart';
import 'package:tarazyar/core/router/app_router.dart';

Future<void> main() async {
  // ============================================================
  // Flutter initialization
  // ============================================================

  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // IMPORTANT FOR FLUTTER WEB + SUPABASE INVITE LINKS
  //
  // Flutter Web به صورت پیش‌فرض از # برای مسیر استفاده می‌کند.
  // Supabase Invite هم اطلاعات توکن را داخل Fragment یعنی # قرار
  // می‌دهد.
  //
  // با Path URL Strategy، مسیر Flutter دیگر # ندارد.
  //
  // قبل از runApp باید اجرا شود.
  // ============================================================

  usePathUrlStrategy();

  // ============================================================
  // Supabase
  // ============================================================

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  debugPrint(
    'Supabase initialized successfully.',
  );

  // ============================================================
  // Application
  // ============================================================

  runApp(
    const ProviderScope(
      child: TrazyarApp(),
    ),
  );
}

// ================================================================
// APP
// ================================================================

class TrazyarApp extends ConsumerWidget {
  const TrazyarApp({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    // ==========================================================
    // Router
    // ==========================================================

    final router =
    ref.watch(appRouterProvider);

    // ==========================================================
    // Material App
    // ==========================================================

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,

      routerConfig: router,

      // ========================================================
      // Locale
      // ========================================================

      locale: const Locale(
        'fa',
        'IR',
      ),

      supportedLocales: const [
        Locale(
          'fa',
          'IR',
        ),
      ],

      // ========================================================
      // Localization
      // ========================================================

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ========================================================
      // RTL
      // ========================================================

      builder: (
          context,
          child,
          ) {
        return Directionality(
          textDirection:
          TextDirection.rtl,
          child:
          child ??
              const SizedBox.shrink(),
        );
      },

      // ========================================================
      // Theme
      // ========================================================

      theme: ThemeData(
        useMaterial3: true,

        fontFamily:
        'Vazirmatn',

        colorScheme:
        ColorScheme.fromSeed(
          seedColor:
          const Color(
            0xFF1B4332,
          ),
          brightness:
          Brightness.light,
        ),
      ),
    );
  }
}