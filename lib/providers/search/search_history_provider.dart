import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryNotifier extends Notifier<List<String>> {
  static const String _storageKey =
      'melody_recent_searches';

  static const int _maxSearches = 8;

  SharedPreferences? _preferences;
  Future<void>? _loadFuture;

  @override
  List<String> build() {
    _loadFuture = _loadHistory();
    return [];
  }

  // =========================================================
  // LOAD
  // =========================================================
  Future<void> _loadHistory() async {
    try {
      final prefs =
      await SharedPreferences.getInstance();

      _preferences = prefs;

      final history =
      prefs.getStringList(_storageKey);

      if (history == null) {
        return;
      }

      state = history;
    } catch (_) {
      state = [];
    }
  }

  Future<void> _ensureLoaded() async {
    await (_loadFuture ??= _loadHistory());
  }

  // =========================================================
  // SAVE
  // =========================================================
  Future<void> _save() async {
    final prefs =
        _preferences ??
            await SharedPreferences.getInstance();

    _preferences = prefs;

    await prefs.setStringList(
      _storageKey,
      state,
    );
  }

  // =========================================================
  // ADD SEARCH
  // =========================================================
  Future<void> addQuery(
      String query,
      ) async {
    await _ensureLoaded();

    final cleanQuery = query.trim();

    if (cleanQuery.isEmpty) {
      return;
    }

    final updated = state
        .where(
          (item) =>
      item.toLowerCase() !=
          cleanQuery.toLowerCase(),
    )
        .toList();

    updated.insert(
      0,
      cleanQuery,
    );

    state = updated
        .take(_maxSearches)
        .toList();

    await _save();
  }

  // =========================================================
  // REMOVE ONE
  // =========================================================
  Future<void> removeQuery(
      String query,
      ) async {
    await _ensureLoaded();

    state = state
        .where(
          (item) => item != query,
    )
        .toList();

    await _save();
  }

  // =========================================================
  // CLEAR ALL
  // =========================================================
  Future<void> clearHistory() async {
    await _ensureLoaded();

    state = [];

    await _save();
  }
}

final searchHistoryProvider =
NotifierProvider<
    SearchHistoryNotifier,
    List<String>>(
  SearchHistoryNotifier.new,
);