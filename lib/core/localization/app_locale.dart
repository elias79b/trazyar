import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

abstract final class AppLocale {
  static const Locale defaultLocale = Locale('fa');
  static const TextDirection defaultTextDirection = TextDirection.rtl;

  static const List<Locale> supportedLocales = [defaultLocale];

  static const List<LocalizationsDelegate<dynamic>> localizationDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
}
