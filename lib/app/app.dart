import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/init/init_provider.dart';
import '../features/init/init_screen.dart';
import 'router.dart';

class MediaDownloaderApp extends ConsumerWidget {
  const MediaDownloaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initState = ref.watch(initProvider);

    if (initState.status == InitStatus.done) {
      return MaterialApp.router(
        title: 'Media Downloader',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        themeMode: ThemeMode.dark,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
      );
    }

    return MaterialApp(
      title: 'Media Downloader',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const InitScreen(),
    );
  }
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6C63FF),
    brightness: brightness,
    surface: isDark ? const Color(0xFF0F0F14) : const Color(0xFFF6F6FB),
    surfaceContainer:
        isDark ? const Color(0xFF1A1A24) : const Color(0xFFFFFFFF),
    surfaceContainerHighest:
        isDark ? const Color(0xFF242432) : const Color(0xFFEEEEF8),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: buildTextTheme(colorScheme),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(
        colorScheme.primary.withValues(alpha: 0.4),
      ),
    ),
  );
}

TextTheme buildTextTheme(ColorScheme colors) {
  return TextTheme(
    headlineMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: colors.onSurface,
      letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: colors.onSurface,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: colors.onSurface,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      color: colors.onSurfaceVariant,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: colors.onSurfaceVariant,
      letterSpacing: 0.8,
    ),
  );
}
