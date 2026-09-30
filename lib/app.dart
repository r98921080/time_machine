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
    const seed = Color(0xFFC99742); // Amber Gold
    final scaffoldBg = isDark ? const Color(0xFF0F1E24) : const Color(0xFFF7F5F0); // Deep Teal night / Ivory day
    final cardBg = isDark ? const Color(0xFF16252C) : const Color(0xFFFFFFFF);
    final borderColor = isDark ? const Color(0xFF8B6B3E).withOpacity(0.45) : const Color(0xFFE2D7C3);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
        primary: const Color(0xFFC99742), // Antique Amber Gold
        secondary: const Color(0xFF2B4D58), // Deep Teal
        surface: cardBg,
      ),
      fontFamily: 'NotoSansTC',
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: isDark ? const Color(0xFFF3EEE6) : const Color(0xFF2C241E),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: isDark ? Colors.black45 : const Color(0xFF8B6B3E).withOpacity(0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        color: cardBg,
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: cardBg,
        indicatorColor: const Color(0xFFC99742).withOpacity(isDark ? 0.28 : 0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF0D181D) : const Color(0xFFF4F0E8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC99742), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFC99742),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
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
