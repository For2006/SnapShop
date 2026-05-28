import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/app_theme.dart';
import 'config/app_router.dart';
import 'config/l10n/app_localizations.dart';
import 'features/settings/settings_provider.dart';

class SnapShopApp extends ConsumerWidget {
  const SnapShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settingsState = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'SnapShop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: settingsState.localeOption.locale,
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
