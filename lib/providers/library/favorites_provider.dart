import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:v2/models/song.dart';

class FavoritesNotifier extends Notifier<List<Song>> {
  static const String _storageKey =
      'melody_favorite_songs';

  SharedPreferences? _preferences;
  Future<void>? _loadFuture;

  // =========================================================
  // BUILD
  // =========================================================

  @override
  List<Song> build() {
    _loadFuture = _loadFavorites();

    return <Song>[];
  }

  // =========================================================
  // LOAD FAVORITES
  // =========================================================

  Future<void> _loadFavorites() async {
    try {
      final SharedPreferences prefs =
      await SharedPreferences.getInstance();

      _preferences = prefs;

      final String? storedData =
      prefs.getString(
        _storageKey,
      );

      if (storedData == null ||
          storedData.isEmpty) {
        return;
      }

      final dynamic decoded =
      jsonDecode(
        storedData,
      );

      if (decoded is! List) {
        return;
      }

      state = decoded
          .map(
            (item) => Song.fromJson(
          Map<String, dynamic>.from(
            item as Map,
          ),
        ),
      )
          .toList();
    } catch (_) {
      state = <Song>[];
    }
  }

  Future<void> _ensureLoaded() async {
    await (_loadFuture ??=
        _loadFavorites());
  }

  // =========================================================
  // SAVE FAVORITES
  // =========================================================

  Future<void> _saveFavorites() async {
    final SharedPreferences prefs =
        _preferences ??
            await SharedPreferences.getInstance();

    _preferences = prefs;

    final String encoded =
    jsonEncode(
      state
          .map(
            (song) => song.toJson(),
      )
          .toList(),
    );

    await prefs.setString(
      _storageKey,
      encoded,
    );
  }

  // =========================================================
  // CHECK FAVORITE
  // =========================================================

  bool isFavorite(
      String songId,
      ) {
    return state.any(
          (song) => song.id == songId,
    );
  }

  // =========================================================
  // TOGGLE FAVORITE
  // =========================================================

  Future<void> toggleFavorite(
      Song song,
      ) async {
    await _ensureLoaded();

    final bool alreadyFavorite =
    isFavorite(
      song.id,
    );

    if (alreadyFavorite) {
      state = state
          .where(
            (favoriteSong) =>
        favoriteSong.id != song.id,
      )
          .toList();
    } else {
      state = <Song>[
        ...state,
        song,
      ];
    }

    await _saveFavorites();
  }

  // =========================================================
  // REMOVE FAVORITE
  // =========================================================

  Future<void> removeFavorite(
      String songId,
      ) async {
    await _ensureLoaded();

    state = state
        .where(
          (song) => song.id != songId,
    )
        .toList();

    await _saveFavorites();
  }

  // =========================================================
  // CLEAR FAVORITES
  // =========================================================

  Future<void> clearFavorites() async {
    await _ensureLoaded();

    state = <Song>[];

    await _saveFavorites();
  }
}

final favoritesProvider =
NotifierProvider<
    FavoritesNotifier,
    List<Song>>(
  FavoritesNotifier.new,
);