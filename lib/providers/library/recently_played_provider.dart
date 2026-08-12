import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:v2/models/song.dart';

class RecentlyPlayedNotifier extends Notifier<List<Song>> {
  static const String _storageKey =
      'melody_recently_played';

  static const int _maxItems = 12;

  SharedPreferences? _preferences;
  Future<void>? _loadFuture;

  // =========================================================
  // BUILD
  // =========================================================

  @override
  List<Song> build() {
    _loadFuture = _loadRecentlyPlayed();

    return <Song>[];
  }

  // =========================================================
  // LOAD
  // =========================================================

  Future<void> _loadRecentlyPlayed() async {
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

  // =========================================================
  // ENSURE LOADED
  // =========================================================

  Future<void> _ensureLoaded() async {
    await (_loadFuture ??=
        _loadRecentlyPlayed());
  }

  // =========================================================
  // SAVE
  // =========================================================

  Future<void> _save() async {
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
  // ADD SONG
  // =========================================================

  Future<void> addSong(
      Song song,
      ) async {
    await _ensureLoaded();

    // Remove previous occurrence so there
    // will never be duplicates.
    final List<Song> updated =
    state
        .where(
          (item) =>
      item.id != song.id,
    )
        .toList();

    // Newest song goes first.
    updated.insert(
      0,
      song,
    );

    // Keep only latest 12.
    state = updated
        .take(
      _maxItems,
    )
        .toList();

    await _save();
  }

  // =========================================================
  // REMOVE SONG
  // =========================================================

  Future<void> removeSong(
      String songId,
      ) async {
    await _ensureLoaded();

    state = state
        .where(
          (song) =>
      song.id != songId,
    )
        .toList();

    await _save();
  }
  Future<void> removeUnavailableSongs(
      Set<String> validSongIds,
      ) async {
    await _ensureLoaded();

    state = state
        .where(
          (song) => validSongIds.contains(song.id),
    )
        .toList();

    await _save();
  }

  // =========================================================
  // CLEAR HISTORY
  // =========================================================

  Future<void> clearHistory() async {
    await _ensureLoaded();

    state = <Song>[];

    await _save();
  }
}


// ===========================================================
// PROVIDER
// ===========================================================

final recentlyPlayedProvider =
NotifierProvider<
    RecentlyPlayedNotifier,
    List<Song>>(
  RecentlyPlayedNotifier.new,
);
