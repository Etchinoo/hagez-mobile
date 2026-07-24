import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: HagezApp()));
}

class HagezApp extends StatelessWidget {
  const HagezApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'حاجز',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
      // Arabic-first, RTL by default. English toggle is handled at the
      // widget level via AppStrings.of(languageCode) (see l10n/app_strings.dart)
      // rather than full MaterialApp locale switching, since only two
      // in-app languages are supported and RTL layout direction should track
      // the user's language preference, not the device locale.
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
