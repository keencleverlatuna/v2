import 'dart:async';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v2/models/song.dart';
import 'package:v2/providers/library/recently_played_provider.dart';
import 'package:v2/services/audio/melody_audio_handler.dart';

// ===========================================================
// REPEAT MODE
// ===========================================================

enum PlayerRepeatMode {
  off,
  all,
  one,
}

// ===========================================================
// PLAYER STATE
// ===========================================================

class MelodyPlayerState {
  final Song? currentSong;

  final bool isPlaying;
  final bool isLoading;

  final Duration position;
  final Duration duration;

  final List<Song> queue;
  final int currentIndex;

  final bool isShuffleEnabled;
  final PlayerRepeatMode repeatMode;

  final String? errorMessage;

  const MelodyPlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const <Song>[],
    this.currentIndex = -1,
    this.isShuffleEnabled = false,
    this.repeatMode = PlayerRepeatMode.off,
    this.errorMessage,
  });

  MelodyPlayerState copyWith({
    Song? currentSong,
    bool clearCurrentSong = false,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    List<Song>? queue,
    int? currentIndex,
    bool? isShuffleEnabled,
    PlayerRepeatMode? repeatMode,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MelodyPlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffleEnabled:
      isShuffleEnabled ?? this.isShuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      errorMessage: clearError
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

// ===========================================================
// PLAYER NOTIFIER
// ===========================================================

class PlayerNotifier extends Notifier<MelodyPlayerState> {
  late final MelodyAudioHandler _audioHandler;

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<void>? _completionSubscription;

  List<Song> _originalQueue = <Song>[];

  bool _handlingCompletion = false;
  Future<void> removeSongFromQueue(
      String songId,
      ) async {
    final int removedIndex =
    state.queue.indexWhere(
          (song) => song.id == songId,
    );

    // Remove it from the original shuffle queue too.
    _originalQueue = _originalQueue
        .where(
          (song) => song.id != songId,
    )
        .toList();

    if (removedIndex < 0) {
      return;
    }

    final List<Song> updatedQueue =
    state.queue
        .where(
          (song) => song.id != songId,
    )
        .toList();

    final bool removedCurrentSong =
        state.currentSong?.id == songId;

    // =======================================================
    // CURRENT SONG WAS DELETED
    // =======================================================

    if (removedCurrentSong) {
      await _audioHandler.stop();

      // Clear notification / lock-screen queue.
      await _audioHandler.setSongQueue(
        updatedQueue,
        currentIndex: -1,
      );

      state = state.copyWith(
        clearCurrentSong: true,
        queue: updatedQueue,
        currentIndex: -1,
        isPlaying: false,
        isLoading: false,
        position: Duration.zero,
        duration: Duration.zero,
        clearError: true,
      );

      return;
    }

    // =======================================================
    // NON-CURRENT SONG WAS DELETED
    // =======================================================

    int newIndex =
        state.currentIndex;

    // If a song before the current song was removed,
    // move the current index one step backward.
    if (removedIndex < newIndex) {
      newIndex--;
    }

    if (updatedQueue.isEmpty) {
      newIndex = -1;
    } else if (newIndex >=
        updatedQueue.length) {
      newIndex =
          updatedQueue.length - 1;
    }

    // Keep Android notification Next/Previous queue synced.
    await _audioHandler.setSongQueue(
      updatedQueue,
      currentIndex: newIndex,
    );

    state = state.copyWith(
      queue: updatedQueue,
      currentIndex: newIndex,
      clearError: true,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  MelodyPlayerState build() {
    _audioHandler = ref.read(
      melodyAudioHandlerProvider,
    );

    _audioHandler.attachControlCallbacks(
      onNext: next,
      onPrevious: previous,
      onQueueItem: _playQueueItemFromSystem,
    );

    // ---------------------------------------------------------
    // PLAYING STATE
    // ---------------------------------------------------------

    _playingSubscription =
        _audioHandler.playingStream.listen(
              (playing) {
            state = state.copyWith(
              isPlaying: playing,
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint(
              'Playing stream error: $error',
            );
          },
        );

    // ---------------------------------------------------------
    // POSITION
    // ---------------------------------------------------------

    _positionSubscription =
        _audioHandler.positionStream.listen(
              (position) {
            state = state.copyWith(
              position: position,
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint(
              'Position stream error: $error',
            );
          },
        );

    // ---------------------------------------------------------
    // DURATION
    // ---------------------------------------------------------

    _durationSubscription =
        _audioHandler.durationStream.listen(
              (duration) {
            state = state.copyWith(
              duration: duration ?? Duration.zero,
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint(
              'Duration stream error: $error',
            );
          },
        );

    // ---------------------------------------------------------
    // SONG COMPLETE
    // ---------------------------------------------------------

    _completionSubscription =
        _audioHandler.completedStream.listen(
              (_) {
            if (_handlingCompletion) {
              return;
            }

            unawaited(
              _handleSongCompleted(),
            );
          },
          onError: (Object error, StackTrace stackTrace) {
            debugPrint(
              'Completion stream error: $error',
            );
          },
        );

    // ---------------------------------------------------------
    // CLEANUP
    // ---------------------------------------------------------

    ref.onDispose(() {
      _playingSubscription?.cancel();
      _positionSubscription?.cancel();
      _durationSubscription?.cancel();
      _completionSubscription?.cancel();

      // IMPORTANT:
      // Do NOT dispose MelodyAudioHandler here.
      // AudioService owns it so background playback can continue.
      _audioHandler.clearControlCallbacks();
    });

    return const MelodyPlayerState();
  }

  // =========================================================
  // PLAY SONG
  // =========================================================

  Future<void> playSong(
      Song song, {
        List<Song>? queue,
        int? index,
      }) async {
    if (state.isLoading &&
        state.currentSong?.id == song.id) {
      return;
    }

    try {
      final List<Song> nextQueue =
          queue ?? state.queue;

      int nextIndex =
          index ?? state.currentIndex;

      // If a queue was supplied without an index,
      // locate the selected song automatically.
      if (queue != null && index == null) {
        nextIndex = queue.indexWhere(
              (item) => item.id == song.id,
        );
      }

      // If there is no queue yet, make a one-song queue.
      final List<Song> effectiveQueue =
      nextQueue.isEmpty
          ? <Song>[song]
          : List<Song>.from(nextQueue);

      if (nextIndex < 0 ||
          nextIndex >= effectiveQueue.length) {
        nextIndex = effectiveQueue.indexWhere(
              (item) => item.id == song.id,
        );

        if (nextIndex < 0) {
          nextIndex = 0;
        }
      }

      state = state.copyWith(
        currentSong: song,
        isLoading: true,
        isPlaying: false,
        queue: effectiveQueue,
        currentIndex: nextIndex,
        position: Duration.zero,
        duration: Duration.zero,
        clearError: true,
      );

      debugPrint(
        'PlayerProvider: playing ${song.title}',
      );

      // Sync Android notification / lock-screen queue.
      await _audioHandler.setSongQueue(
        effectiveQueue,
        currentIndex: nextIndex,
      );

      // IMPORTANT:
      // This reaches the SAME working AudioPlayerService.
      //
      // AudioPlayerService.loadAndPlaySong() still performs:
      //
      // setSource()
      //   -> resume()
      //
      // We do NOT call play() a second time.
      await _audioHandler.loadAndPlaySong(
        song,
        queueIndex: nextIndex,
      );

      state = state.copyWith(
        currentSong: song,
        isLoading: false,
        clearError: true,
      );

      unawaited(
        ref
            .read(
          recentlyPlayedProvider.notifier,
        )
            .addSong(song),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Playback error: $error',
      );

      debugPrint(
        'Playback stack trace: $stackTrace',
      );

      state = state.copyWith(
        isLoading: false,
        isPlaying: false,
        errorMessage: error.toString(),
      );
    }
  }

  // =========================================================
  // PLAY QUEUE
  // =========================================================

  Future<void> playQueue(
      List<Song> songs, {
        int startIndex = 0,
      }) async {
    if (songs.isEmpty) {
      return;
    }

    if (startIndex < 0 ||
        startIndex >= songs.length) {
      return;
    }

    _originalQueue =
    List<Song>.from(songs);

    // ---------------------------------------------------------
    // SHUFFLE ENABLED
    // ---------------------------------------------------------

    if (state.isShuffleEnabled) {
      final Song selectedSong =
      songs[startIndex];

      final List<Song> remainingSongs =
      List<Song>.from(songs)
        ..removeAt(startIndex);

      remainingSongs.shuffle(
        Random(),
      );

      final List<Song> shuffledQueue =
      <Song>[
        selectedSong,
        ...remainingSongs,
      ];

      await playSong(
        selectedSong,
        queue: shuffledQueue,
        index: 0,
      );

      return;
    }

    // ---------------------------------------------------------
    // NORMAL QUEUE
    // ---------------------------------------------------------

    await playSong(
      songs[startIndex],
      queue: List<Song>.from(songs),
      index: startIndex,
    );
  }

  // =========================================================
  // TOGGLE PLAY / PAUSE
  // =========================================================

  Future<void> togglePlayPause() async {
    if (state.currentSong == null ||
        state.isLoading) {
      return;
    }

    try {
      if (state.isPlaying) {
        await _audioHandler.pause();
      } else {
        await _audioHandler.play();
      }

      state = state.copyWith(
        clearError: true,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Play/pause error: $error',
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
  // PLAY
  // =========================================================

  Future<void> play() async {
    if (state.currentSong == null ||
        state.isLoading) {
      return;
    }

    try {
      await _audioHandler.play();

      state = state.copyWith(
        clearError: true,
      );
    } catch (error) {
      debugPrint(
        'Resume error: $error',
      );

      state = state.copyWith(
        errorMessage: error.toString(),
      );
    }
  }

  // =========================================================
  // PAUSE
  // =========================================================

  Future<void> pause() async {
    if (state.currentSong == null) {
      return;
    }

    try {
      await _audioHandler.pause();
    } catch (error) {
      debugPrint(
        'Pause error: $error',
      );

      state = state.copyWith(
        errorMessage: error.toString(),
      );
    }
  }

  // =========================================================
  // STOP
  // =========================================================

  Future<void> stop() async {
    try {
      await _audioHandler.stop();

      state = state.copyWith(
        isPlaying: false,
        isLoading: false,
        position: Duration.zero,
        clearError: true,
      );
    } catch (error) {
      debugPrint(
        'Stop error: $error',
      );

      state = state.copyWith(
        errorMessage: error.toString(),
      );
    }
  }

  // =========================================================
  // SEEK
  // =========================================================

  Future<void> seek(
      Duration position,
      ) async {
    if (state.currentSong == null) {
      return;
    }

    Duration safePosition =
        position;

    if (safePosition < Duration.zero) {
      safePosition = Duration.zero;
    }

    if (state.duration > Duration.zero &&
        safePosition > state.duration) {
      safePosition = state.duration;
    }

    try {
      await _audioHandler.seek(
        safePosition,
      );

      state = state.copyWith(
        position: safePosition,
        clearError: true,
      );
    } catch (error) {
      debugPrint(
        'Seek error: $error',
      );

      state = state.copyWith(
        errorMessage: error.toString(),
      );
    }
  }

  // =========================================================
  // NEXT
  // =========================================================

  Future<void> next() async {
    if (state.queue.isEmpty ||
        state.isLoading) {
      return;
    }

    int nextIndex =
        state.currentIndex + 1;

    // ---------------------------------------------------------
    // END OF QUEUE
    // ---------------------------------------------------------

    if (nextIndex >= state.queue.length) {
      if (state.repeatMode ==
          PlayerRepeatMode.all) {
        nextIndex = 0;
      } else {
        await _audioHandler.stop();

        state = state.copyWith(
          isPlaying: false,
          position: Duration.zero,
        );

        return;
      }
    }

    await playSong(
      state.queue[nextIndex],
      queue: state.queue,
      index: nextIndex,
    );
  }

  // =========================================================
  // PREVIOUS
  // =========================================================

  Future<void> previous() async {
    if (state.currentSong == null ||
        state.isLoading) {
      return;
    }

    // Apple Music-style:
    // past 3 seconds -> restart current track.
    if (state.position.inSeconds > 3) {
      await seek(
        Duration.zero,
      );

      return;
    }

    if (state.queue.isEmpty) {
      await seek(
        Duration.zero,
      );

      return;
    }

    int previousIndex =
        state.currentIndex - 1;

    // ---------------------------------------------------------
    // START OF QUEUE
    // ---------------------------------------------------------

    if (previousIndex < 0) {
      if (state.repeatMode ==
          PlayerRepeatMode.all) {
        previousIndex =
            state.queue.length - 1;
      } else {
        await seek(
          Duration.zero,
        );

        return;
      }
    }

    await playSong(
      state.queue[previousIndex],
      queue: state.queue,
      index: previousIndex,
    );
  }

  // =========================================================
  // SYSTEM QUEUE SELECTION
  // =========================================================

  Future<void> _playQueueItemFromSystem(
      int index,
      ) async {
    if (state.isLoading ||
        index < 0 ||
        index >= state.queue.length) {
      return;
    }

    await playSong(
      state.queue[index],
      queue: state.queue,
      index: index,
    );
  }

  // =========================================================
  // TOGGLE SHUFFLE
  // =========================================================

  void toggleShuffle() {
    final bool enableShuffle =
    !state.isShuffleEnabled;

    // ---------------------------------------------------------
    // EMPTY QUEUE
    // ---------------------------------------------------------

    if (state.queue.isEmpty) {
      state = state.copyWith(
        isShuffleEnabled: enableShuffle,
      );

      unawaited(
        _audioHandler.setShuffleMode(
          enableShuffle
              ? AudioServiceShuffleMode.all
              : AudioServiceShuffleMode.none,
        ),
      );

      return;
    }

    final Song? currentSong =
        state.currentSong;

    // ---------------------------------------------------------
    // ENABLE SHUFFLE
    // ---------------------------------------------------------

    if (enableShuffle) {
      if (_originalQueue.isEmpty) {
        _originalQueue =
        List<Song>.from(state.queue);
      }

      if (currentSong == null) {
        final List<Song> shuffledQueue =
        List<Song>.from(state.queue)
          ..shuffle(
            Random(),
          );

        final int shuffledIndex =
        shuffledQueue.isEmpty ? -1 : 0;

        state = state.copyWith(
          queue: shuffledQueue,
          currentIndex: shuffledIndex,
          isShuffleEnabled: true,
        );

        unawaited(
          _audioHandler.setSongQueue(
            shuffledQueue,
            currentIndex: shuffledIndex,
          ),
        );

        unawaited(
          _audioHandler.setShuffleMode(
            AudioServiceShuffleMode.all,
          ),
        );

        return;
      }

      final List<Song> otherSongs =
      state.queue
          .where(
            (song) =>
        song.id != currentSong.id,
      )
          .toList();

      otherSongs.shuffle(
        Random(),
      );

      final List<Song> shuffledQueue =
      <Song>[
        currentSong,
        ...otherSongs,
      ];

      state = state.copyWith(
        queue: shuffledQueue,
        currentIndex: 0,
        isShuffleEnabled: true,
      );

      unawaited(
        _audioHandler.setSongQueue(
          shuffledQueue,
          currentIndex: 0,
        ),
      );

      unawaited(
        _audioHandler.setShuffleMode(
          AudioServiceShuffleMode.all,
        ),
      );

      return;
    }

    // ---------------------------------------------------------
    // DISABLE SHUFFLE
    // ---------------------------------------------------------

    if (_originalQueue.isNotEmpty) {
      final List<Song> restoredQueue =
      List<Song>.from(
        _originalQueue,
      );

      int restoredIndex = -1;

      if (currentSong != null) {
        restoredIndex =
            restoredQueue.indexWhere(
                  (song) =>
              song.id == currentSong.id,
            );
      }

      final int safeIndex =
      restoredIndex >= 0
          ? restoredIndex
          : restoredQueue.isEmpty
          ? -1
          : 0;

      state = state.copyWith(
        queue: restoredQueue,
        currentIndex: safeIndex,
        isShuffleEnabled: false,
      );

      unawaited(
        _audioHandler.setSongQueue(
          restoredQueue,
          currentIndex: safeIndex,
        ),
      );

      unawaited(
        _audioHandler.setShuffleMode(
          AudioServiceShuffleMode.none,
        ),
      );

      return;
    }

    state = state.copyWith(
      isShuffleEnabled: false,
    );

    unawaited(
      _audioHandler.setShuffleMode(
        AudioServiceShuffleMode.none,
      ),
    );
  }

  // =========================================================
  // TOGGLE REPEAT
  // =========================================================

  void toggleRepeat() {
    switch (state.repeatMode) {
      case PlayerRepeatMode.off:
        state = state.copyWith(
          repeatMode: PlayerRepeatMode.all,
        );

        unawaited(
          _audioHandler.setRepeatMode(
            AudioServiceRepeatMode.all,
          ),
        );

        break;

      case PlayerRepeatMode.all:
        state = state.copyWith(
          repeatMode: PlayerRepeatMode.one,
        );

        unawaited(
          _audioHandler.setRepeatMode(
            AudioServiceRepeatMode.one,
          ),
        );

        break;

      case PlayerRepeatMode.one:
        state = state.copyWith(
          repeatMode: PlayerRepeatMode.off,
        );

        unawaited(
          _audioHandler.setRepeatMode(
            AudioServiceRepeatMode.none,
          ),
        );

        break;
    }
  }

  // =========================================================
  // AUTOMATIC SONG COMPLETION
  // =========================================================

  Future<void> _handleSongCompleted() async {
    // Ignore completion while another song is switching.
    if (state.isLoading) {
      debugPrint(
        'Ignoring completion event while switching tracks.',
      );

      return;
    }

    if (_handlingCompletion) {
      return;
    }

    if (state.currentSong == null) {
      return;
    }

    _handlingCompletion = true;

    try {
      // -------------------------------------------------------
      // REPEAT ONE
      // -------------------------------------------------------

      if (state.repeatMode ==
          PlayerRepeatMode.one) {
        await _audioHandler.seek(
          Duration.zero,
        );

        await _audioHandler.play();

        return;
      }

      // -------------------------------------------------------
      // NO QUEUE
      // -------------------------------------------------------

      if (state.queue.isEmpty) {
        state = state.copyWith(
          isPlaying: false,
          position: Duration.zero,
        );

        return;
      }

      final int nextIndex =
          state.currentIndex + 1;

      // -------------------------------------------------------
      // PLAY NEXT
      // -------------------------------------------------------

      if (nextIndex < state.queue.length) {
        await playSong(
          state.queue[nextIndex],
          queue: state.queue,
          index: nextIndex,
        );

        return;
      }

      // -------------------------------------------------------
      // REPEAT ALL
      // -------------------------------------------------------

      if (state.repeatMode ==
          PlayerRepeatMode.all) {
        await playSong(
          state.queue.first,
          queue: state.queue,
          index: 0,
        );

        return;
      }

      // -------------------------------------------------------
      // END OF QUEUE
      // -------------------------------------------------------

      await _audioHandler.stop();

      state = state.copyWith(
        isPlaying: false,
        position: Duration.zero,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Song completion error: $error',
      );

      debugPrint(
        'Song completion stack trace: $stackTrace',
      );

      state = state.copyWith(
        isPlaying: false,
        isLoading: false,
        errorMessage: error.toString(),
      );
    } finally {
      _handlingCompletion = false;
    }
  }
}

// ===========================================================
// PROVIDER
// ===========================================================

final playerProvider =
NotifierProvider<
    PlayerNotifier,
    MelodyPlayerState>(
  PlayerNotifier.new,
);
