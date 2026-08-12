import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:v2/models/song.dart';
import 'package:v2/services/music/music_import_service.dart';

// ===========================================================
// STATE
// ===========================================================

class ImportedMusicState {
  final List<Song> songs;
  final bool isLoading;
  final String? errorMessage;

  const ImportedMusicState({
    this.songs = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ImportedMusicState copyWith({
    List<Song>? songs,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ImportedMusicState(
      songs: songs ?? this.songs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

// ===========================================================
// NOTIFIER
// ===========================================================

class ImportedMusicNotifier
    extends Notifier<ImportedMusicState> {
  static const String _storageKey =
      'melody_imported_music';

  final MusicImportService _importService =
  const MusicImportService();

  @override
  ImportedMusicState build() {
    unawaited(
      _loadSavedSongs(),
    );

    return const ImportedMusicState(
      isLoading: true,
    );
  }

  // =========================================================
  // LOAD SAVED SONGS
  // =========================================================

  Future<void> _loadSavedSongs() async {
    try {
      final SharedPreferences prefs =
      await SharedPreferences.getInstance();

      final List<String> saved =
          prefs.getStringList(
            _storageKey,
          ) ??
              const [];

      final List<Song> restoredSongs =
      <Song>[];

      for (final String rawSong in saved) {
        try {
          final dynamic decoded =
          jsonDecode(
            rawSong,
          );

          final Song song =
          Song.fromJson(
            Map<String, dynamic>.from(
              decoded as Map,
            ),
          );

          if (_isLocalFile(
            song.audioUrl,
          )) {
            final File file =
            File(
              _normalizePath(
                song.audioUrl,
              ),
            );

            if (!await file.exists()) {
              debugPrint(
                'Imported song missing: ${song.title}',
              );
              continue;
            }

            final int fileSize =
            await file.length();

            if (fileSize <= 0) {
              continue;
            }
          }

          restoredSongs.add(
            song,
          );
        } catch (error) {
          debugPrint(
            'Failed to restore imported song: $error',
          );
        }
      }

      state = state.copyWith(
        songs: restoredSongs,
        isLoading: false,
        clearError: true,
      );

      await _saveSongs();
    } catch (error, stackTrace) {
      debugPrint(
        'Imported music load error: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  // =========================================================
  // IMPORT MUSIC
  // =========================================================

  Future<int> importMusic() async {
    if (state.isLoading) {
      return 0;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final List<Song> imported =
      await _importService
          .pickAndImportSongs();

      if (imported.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          clearError: true,
        );

        return 0;
      }

      final List<Song> updatedSongs =
      <Song>[
        ...state.songs,
        ...imported,
      ];

      state = state.copyWith(
        songs: updatedSongs,
        isLoading: false,
        clearError: true,
      );

      await _saveSongs();

      return imported.length;
    } catch (error, stackTrace) {
      debugPrint(
        'Import music error: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );

      return 0;
    }
  }

  // =========================================================
  // REMOVE SONG
  // =========================================================

  Future<void> removeSong(
      Song song,
      ) async {
    try {
      final List<Song> updated =
      state.songs
          .where(
            (item) =>
        item.id != song.id,
      )
          .toList();

      await _deleteLocalFile(
        song.audioUrl,
      );

      if (song.artworkUrl != null) {
        await _deleteLocalFile(
          song.artworkUrl!,
        );
      }

      state = state.copyWith(
        songs: updated,
        clearError: true,
      );

      await _saveSongs();
    } catch (error, stackTrace) {
      debugPrint(
        'Remove imported song error: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      state = state.copyWith(
        errorMessage: error.toString(),
      );
    }
  }

  // =========================================================
  // CLEAR ALL
  // =========================================================

  Future<void> clearAll() async {
    try {
      for (final Song song in state.songs) {
        await _deleteLocalFile(
          song.audioUrl,
        );

        if (song.artworkUrl != null) {
          await _deleteLocalFile(
            song.artworkUrl!,
          );
        }
      }

      state = state.copyWith(
        songs: const <Song>[],
        clearError: true,
      );

      await _saveSongs();
    } catch (error) {
      state = state.copyWith(
        errorMessage: error.toString(),
      );
    }
  }

  // =========================================================
  // SAVE
  // =========================================================

  Future<void> _saveSongs() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    final List<String> encoded =
    state.songs
        .map(
          (song) => jsonEncode(
        song.toJson(),
      ),
    )
        .toList();

    await prefs.setStringList(
      _storageKey,
      encoded,
    );
  }

  // =========================================================
  // DELETE LOCAL FILE
  // =========================================================

  Future<void> _deleteLocalFile(
      String value,
      ) async {
    if (!_isLocalFile(value)) {
      return;
    }

    final File file =
    File(
      _normalizePath(
        value,
      ),
    );

    if (await file.exists()) {
      await file.delete();
    }
  }

  // =========================================================
  // LOCAL FILE CHECK
  // =========================================================

  bool _isLocalFile(
      String value,
      ) {
    if (value.startsWith('/')) {
      return true;
    }

    if (value.startsWith(
      'file://',
    )) {
      return true;
    }

    return RegExp(
      r'^[a-zA-Z]:[\\/]',
    ).hasMatch(
      value,
    );
  }

  // =========================================================
  // NORMALIZE PATH
  // =========================================================

  String _normalizePath(
      String value,
      ) {
    if (value.startsWith(
      'file://',
    )) {
      return Uri.parse(
        value,
      ).toFilePath();
    }

    return value;
  }
}

// ===========================================================
// PROVIDER
// ===========================================================

final importedMusicProvider =
NotifierProvider<
    ImportedMusicNotifier,
    ImportedMusicState>(
  ImportedMusicNotifier.new,
);
