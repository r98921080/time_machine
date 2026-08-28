import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'widgets/main_shell.dart';

class TimeMachineApp extends StatelessWidget {
  const TimeMachineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '時光機',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const _RootRouter(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final seed = const Color(0xFF6366F1); // Indigo
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
      ),
      fontFamily: 'NotoSansTC',
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark
            ? const Color(0xFF1E1E2E)
            : const Color(0xFFF8F8FF),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppProvider>().state;
    return switch (state) {
      AppState.loading => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      AppState.onboarding => const OnboardingScreen(),
      AppState.ready => const MainShell(),
    };
  }
}
