import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:v2/models/playlist.dart';
import 'package:v2/models/song.dart';

class PlaylistsNotifier
    extends Notifier<List<MelodyPlaylist>> {
  static const String _storageKey =
      'melody_custom_playlists';

  SharedPreferences? _preferences;
  Future<void>? _loadFuture;

  // =========================================================
  // BUILD
  // =========================================================

  @override
  List<MelodyPlaylist> build() {
    _loadFuture = _loadPlaylists();

    return <MelodyPlaylist>[];
  }

  // =========================================================
  // LOAD PLAYLISTS
  // =========================================================

  Future<void> _loadPlaylists() async {
    try {
      final SharedPreferences prefs =
      await SharedPreferences.getInstance();

      _preferences = prefs;

      final String? data =
      prefs.getString(
        _storageKey,
      );

      if (data == null ||
          data.isEmpty) {
        return;
      }

      final dynamic decoded =
      jsonDecode(
        data,
      );

      if (decoded is! List) {
        return;
      }

      state = decoded
          .map(
            (item) => MelodyPlaylist.fromJson(
          Map<String, dynamic>.from(
            item as Map,
          ),
        ),
      )
          .toList();
    } catch (_) {
      state = <MelodyPlaylist>[];
    }
  }

  Future<void> _ensureLoaded() async {
    await (_loadFuture ??=
        _loadPlaylists());
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
            (playlist) =>
            playlist.toJson(),
      )
          .toList(),
    );

    await prefs.setString(
      _storageKey,
      encoded,
    );
  }

  // =========================================================
  // CREATE PLAYLIST
  // =========================================================

  Future<void> createPlaylist(
      String name,
      ) async {
    await _ensureLoaded();

    final String cleanName =
    name.trim();

    if (cleanName.isEmpty) {
      return;
    }

    final MelodyPlaylist playlist =
    MelodyPlaylist(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      name: cleanName,
    );

    state = <MelodyPlaylist>[
      ...state,
      playlist,
    ];

    await _save();
  }

  // =========================================================
  // RENAME PLAYLIST
  // =========================================================

  Future<void> renamePlaylist(
      String playlistId,
      String newName,
      ) async {
    await _ensureLoaded();

    final String cleanName =
    newName.trim();

    if (cleanName.isEmpty) {
      return;
    }

    state = state.map(
          (playlist) {
        if (playlist.id != playlistId) {
          return playlist;
        }

        return playlist.copyWith(
          name: cleanName,
        );
      },
    ).toList();

    await _save();
  }

  // =========================================================
  // DELETE PLAYLIST
  // =========================================================

  Future<void> deletePlaylist(
      String playlistId,
      ) async {
    await _ensureLoaded();

    state = state
        .where(
          (playlist) =>
      playlist.id != playlistId,
    )
        .toList();

    await _save();
  }

  // =========================================================
  // ADD SONG
  // =========================================================

  Future<void> addSong(
      String playlistId,
      Song song,
      ) async {
    await _ensureLoaded();

    state = state.map(
          (playlist) {
        if (playlist.id != playlistId) {
          return playlist;
        }

        final bool alreadyExists =
        playlist.songs.any(
              (item) => item.id == song.id,
        );

        if (alreadyExists) {
          return playlist;
        }

        return playlist.copyWith(
          songs: <Song>[
            ...playlist.songs,
            song,
          ],
        );
      },
    ).toList();

    await _save();
  }

  // =========================================================
  // REMOVE SONG FROM ONE PLAYLIST
  // =========================================================

  Future<void> removeSong(
      String playlistId,
      String songId,
      ) async {
    await _ensureLoaded();

    state = state.map(
          (playlist) {
        if (playlist.id != playlistId) {
          return playlist;
        }

        return playlist.copyWith(
          songs: playlist.songs
              .where(
                (song) =>
            song.id != songId,
          )
              .toList(),
        );
      },
    ).toList();

    await _save();
  }

  // =========================================================
  // REMOVE SONG FROM ALL PLAYLISTS
  // =========================================================

  Future<void> removeSongFromAllPlaylists(
      String songId,
      ) async {
    await _ensureLoaded();

    state = state.map(
          (playlist) {
        return playlist.copyWith(
          songs: playlist.songs
              .where(
                (song) =>
            song.id != songId,
          )
              .toList(),
        );
      },
    ).toList();

    await _save();
  }
}

final playlistsProvider =
NotifierProvider<
    PlaylistsNotifier,
    List<MelodyPlaylist>>(
  PlaylistsNotifier.new,
);