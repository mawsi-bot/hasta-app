import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design/hasta_theme.dart';
import 'core/providers.dart';
import 'features/auth/domain/auth_controller.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'features/home/presentation/home_shell.dart';

class HastaApp extends ConsumerWidget {
  const HastaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale locale = ref.watch(localeProvider).valueOrNull ?? const Locale('my');
    return MaterialApp(
      onGenerateTitle: (BuildContext c) => AppLocalizations.of(c).appTitle,
      debugShowCheckedModeBanner: false,
      theme: HastaTheme.light(),
      darkTheme: HastaTheme.dark(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _Root(),
    );
  }
}

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthPhase phase = ref.watch(authControllerProvider.select((AuthState s) => s.phase));
    return switch (phase) {
      AuthPhase.booting => const Scaffold(key: Key('boot'), body: Center(child: CircularProgressIndicator())),
      AuthPhase.signedOut || AuthPhase.signingIn => const WelcomeScreen(),
      AuthPhase.signedIn => const HomeShell(),
    };
  }
}
