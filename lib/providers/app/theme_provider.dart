import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  static const String _themeKey = 'melody_dark_mode';

  SharedPreferences? _preferences;
  Future<void>? _loadFuture;

  @override
  ThemeMode build() {
    _loadFuture = _loadTheme();

    // Melody currently starts in Dark Mode by default.
    return ThemeMode.dark;
  }

  Future<void> _loadTheme() async {
    try {
      final SharedPreferences prefs =
      await SharedPreferences.getInstance();

      _preferences = prefs;

      final bool isDark =
          prefs.getBool(_themeKey) ?? true;

      state = isDark
          ? ThemeMode.dark
          : ThemeMode.light;
    } catch (_) {
      // Keep Dark Mode as the default if loading fails.
    }
  }

  Future<void> _ensureLoaded() async {
    await (_loadFuture ??= _loadTheme());
  }

  Future<void> setDarkMode(
      bool enabled,
      ) async {
    await _ensureLoaded();

    state = enabled
        ? ThemeMode.dark
        : ThemeMode.light;

    final SharedPreferences prefs =
        _preferences ??
            await SharedPreferences.getInstance();

    _preferences = prefs;

    await prefs.setBool(
      _themeKey,
      enabled,
    );
  }

  Future<void> toggleTheme() async {
    await _ensureLoaded();

    final bool isCurrentlyDark =
        state == ThemeMode.dark;

    await setDarkMode(
      !isCurrentlyDark,
    );
  }

  Future<void> setTheme(
      ThemeMode mode,
      ) async {
    await setDarkMode(
      mode == ThemeMode.dark,
    );
  }
}

final themeProvider =
NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);