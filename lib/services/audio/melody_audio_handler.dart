import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v2/models/song.dart';
import 'package:v2/services/audio/audio_player_service.dart';

// ===========================================================
// CALLBACK TYPES
// ===========================================================

typedef MelodyNextCallback = Future<void> Function();
typedef MelodyPreviousCallback = Future<void> Function();
typedef MelodyQueueItemCallback = Future<void> Function(int index);

// ===========================================================
// MELODY AUDIO HANDLER
// ===========================================================

class MelodyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayerService _audioService;

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<void>? _completionSubscription;

  MelodyNextCallback? _onNext;
  MelodyPreviousCallback? _onPrevious;
  MelodyQueueItemCallback? _onQueueItem;

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  AudioProcessingState _processingState = AudioProcessingState.idle;

  int _queueIndex = -1;
  int _lastBroadcastSecond = -1;

  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;
  AudioServiceShuffleMode _shuffleMode = AudioServiceShuffleMode.none;

  MediaItem? _currentMediaItem;

  MelodyAudioHandler(this._audioService) {
    // PlaybackState is NOT a const constructor in audio_service 0.18.19.
    playbackState.add(
      PlaybackState(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );

    _bindPlayerStreams();

    unawaited(
      _audioService.initialize(),
    );
  }

  // =========================================================
  // STREAMS FOR PLAYER PROVIDER
  // =========================================================

  Stream<bool> get playingStream => _audioService.playingStream;

  Stream<Duration> get positionStream => _audioService.positionStream;

  Stream<Duration?> get durationStream => _audioService.durationStream;

  Stream<void> get completedStream => _audioService.completedStream;

  // =========================================================
  // SYSTEM CONTROL CALLBACKS
  // =========================================================

  void attachControlCallbacks({
    required MelodyNextCallback onNext,
    required MelodyPreviousCallback onPrevious,
    required MelodyQueueItemCallback onQueueItem,
  }) {
    _onNext = onNext;
    _onPrevious = onPrevious;
    _onQueueItem = onQueueItem;
  }

  void clearControlCallbacks() {
    _onNext = null;
    _onPrevious = null;
    _onQueueItem = null;
  }

  // =========================================================
  // PLAYER STREAM BINDINGS
  // =========================================================

  void _bindPlayerStreams() {
    _playingSubscription = _audioService.playingStream.listen(
          (playing) {
        _isPlaying = playing;

        if (_currentMediaItem != null &&
            _processingState == AudioProcessingState.idle) {
          _processingState = AudioProcessingState.ready;
        }

        _broadcastPlaybackState();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          'Audio handler playing stream error: $error',
        );
      },
    );

    _positionSubscription = _audioService.positionStream.listen(
          (position) {
        _position = position;

        final int second = position.inSeconds;

        // Avoid updating notification hundreds of times per second.
        if (second != _lastBroadcastSecond) {
          _lastBroadcastSecond = second;
          _broadcastPlaybackState();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          'Audio handler position stream error: $error',
        );
      },
    );

    _durationSubscription = _audioService.durationStream.listen(
          (duration) {
        if (duration == null || _currentMediaItem == null) {
          return;
        }

        _currentMediaItem = _currentMediaItem!.copyWith(
          duration: duration,
        );

        mediaItem.add(
          _currentMediaItem,
        );

        final List<MediaItem> currentQueue =
        List<MediaItem>.from(queue.value);

        if (_queueIndex >= 0 && _queueIndex < currentQueue.length) {
          currentQueue[_queueIndex] = _currentMediaItem!;

          queue.add(
            currentQueue,
          );
        }

        _broadcastPlaybackState();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          'Audio handler duration stream error: $error',
        );
      },
    );

    _completionSubscription = _audioService.completedStream.listen(
          (_) {
        _isPlaying = false;
        _processingState = AudioProcessingState.completed;

        _broadcastPlaybackState();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          'Audio handler completion stream error: $error',
        );
      },
    );
  }

  // =========================================================
  // QUEUE
  // =========================================================

  Future<void> setSongQueue(
      List<Song> songs, {
        required int currentIndex,
      }) async {
    final List<MediaItem> mediaItems =
    songs.map(_songToMediaItem).toList();

    queue.add(
      mediaItems,
    );

    _queueIndex = currentIndex;

    if (currentIndex >= 0 && currentIndex < mediaItems.length) {
      _currentMediaItem = mediaItems[currentIndex];

      mediaItem.add(
        _currentMediaItem,
      );
    }

    _broadcastPlaybackState();
  }

  // =========================================================
  // LOAD + PLAY
  // =========================================================

  Future<void> loadAndPlaySong(
      Song song, {
        required int queueIndex,
      }) async {
    _queueIndex = queueIndex;
    _position = Duration.zero;
    _lastBroadcastSecond = -1;
    _isPlaying = false;
    _processingState = AudioProcessingState.loading;

    _currentMediaItem = _songToMediaItem(song);

    mediaItem.add(
      _currentMediaItem,
    );

    _broadcastPlaybackState();

    try {
      // Keep using the existing working AudioPlayerService:
      // setSource() -> resume()
      await _audioService.loadAndPlaySong(
        song,
      );

      _processingState = AudioProcessingState.ready;

      _broadcastPlaybackState();
    } catch (error, stackTrace) {
      debugPrint(
        'Background audio load error: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      _isPlaying = false;
      _processingState = AudioProcessingState.error;

      _broadcastPlaybackState(
        errorMessage: error.toString(),
      );

      rethrow;
    }
  }

  // =========================================================
  // PLAY
  // =========================================================

  @override
  Future<void> play() async {
    if (_currentMediaItem == null) {
      return;
    }

    try {
      await _audioService.play();

      if (_processingState == AudioProcessingState.completed) {
        _processingState = AudioProcessingState.ready;
      }

      _broadcastPlaybackState();
    } catch (error) {
      _processingState = AudioProcessingState.error;

      _broadcastPlaybackState(
        errorMessage: error.toString(),
      );

      rethrow;
    }
  }

  // =========================================================
  // PAUSE
  // =========================================================

  @override
  Future<void> pause() async {
    if (_currentMediaItem == null) {
      return;
    }

    await _audioService.pause();

    _broadcastPlaybackState();
  }

  // =========================================================
  // STOP
  // =========================================================

  @override
  Future<void> stop() async {
    await _audioService.stop();

    _isPlaying = false;
    _position = Duration.zero;
    _lastBroadcastSecond = -1;
    _processingState = AudioProcessingState.idle;

    _broadcastPlaybackState();
  }

  // =========================================================
  // SEEK
  // =========================================================

  @override
  Future<void> seek(
      Duration position,
      ) async {
    if (_currentMediaItem == null) {
      return;
    }

    Duration safePosition = position;

    if (safePosition < Duration.zero) {
      safePosition = Duration.zero;
    }

    await _audioService.seek(
      safePosition,
    );

    _position = safePosition;
    _lastBroadcastSecond = safePosition.inSeconds;

    _broadcastPlaybackState();
  }

  // =========================================================
  // NEXT
  // =========================================================

  @override
  Future<void> skipToNext() async {
    debugPrint('NOTIFICATION: skipToNext');

    final List<MediaItem> currentQueue =
    List<MediaItem>.from(queue.value);

    final int currentIndex =
        playbackState.value.queueIndex ?? _queueIndex;

    final int nextIndex = currentIndex + 1;

    // Prefer the AudioService queue itself. This makes
    // notification/lock-screen next independent from UI state.
    if (currentQueue.isNotEmpty &&
        currentIndex >= 0 &&
        nextIndex < currentQueue.length) {
      await skipToQueueItem(nextIndex);
      return;
    }

    // Let PlayerProvider handle end-of-queue / repeat-all logic.
    final MelodyNextCallback? callback = _onNext;

    if (callback != null) {
      await callback();
    }
  }

  // =========================================================
  // PREVIOUS
  // =========================================================

  @override
  Future<void> skipToPrevious() async {
    debugPrint('NOTIFICATION: skipToPrevious');

    final List<MediaItem> currentQueue =
    List<MediaItem>.from(queue.value);

    final int currentIndex =
        playbackState.value.queueIndex ?? _queueIndex;

    final int previousIndex = currentIndex - 1;

    // Prefer direct queue navigation when a previous item exists.
    if (currentQueue.isNotEmpty &&
        currentIndex >= 0 &&
        previousIndex >= 0 &&
        previousIndex < currentQueue.length) {
      await skipToQueueItem(previousIndex);
      return;
    }

    // Let PlayerProvider preserve the Apple Music-style
    // restart/repeat-all behaviour at the beginning of the queue.
    final MelodyPreviousCallback? callback = _onPrevious;

    if (callback != null) {
      await callback();
    }
  }

  // =========================================================
  // SELECT QUEUE ITEM
  // =========================================================

  @override
  Future<void> skipToQueueItem(
      int index,
      ) async {
    debugPrint(
      'NOTIFICATION: skipToQueueItem index=$index',
    );

    final MelodyQueueItemCallback? callback = _onQueueItem;

    if (callback == null) {
      debugPrint(
        'NOTIFICATION: queue callback is not attached.',
      );
      return;
    }

    await callback(
      index,
    );
  }

  // =========================================================
  // REPEAT MODE
  // =========================================================

  @override
  Future<void> setRepeatMode(
      AudioServiceRepeatMode repeatMode,
      ) async {
    _repeatMode = repeatMode;

    _broadcastPlaybackState();
  }

  // =========================================================
  // SHUFFLE MODE
  // =========================================================

  @override
  Future<void> setShuffleMode(
      AudioServiceShuffleMode shuffleMode,
      ) async {
    _shuffleMode = shuffleMode;

    _broadcastPlaybackState();
  }

  // =========================================================
  // SONG -> MEDIA ITEM
  // =========================================================

  MediaItem _songToMediaItem(
      Song song,
      ) {
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      artUri: _artUriFromValue(
        song.artworkUrl,
      ),
      playable: true,
      extras: <String, dynamic>{
        'audioUrl': song.audioUrl,
      },
    );
  }

  // =========================================================
  // ARTWORK URI
  // =========================================================

  Uri? _artUriFromValue(
      String? value,
      ) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final String source = value.trim();

    try {
      if (source.startsWith('http://') ||
          source.startsWith('https://') ||
          source.startsWith('content://') ||
          source.startsWith('file://')) {
        return Uri.parse(
          source,
        );
      }

      if (source.startsWith('/')) {
        return Uri.file(
          source,
        );
      }

      if (RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(source)) {
        return Uri.file(
          source,
          windows: Platform.isWindows,
        );
      }
    } catch (error) {
      debugPrint(
        'Could not create artwork URI: $error',
      );
    }

    return null;
  }

  // =========================================================
  // ANDROID NOTIFICATION / LOCK SCREEN STATE
  // =========================================================

  void _broadcastPlaybackState({
    String? errorMessage,
  }) {
    if (_currentMediaItem == null) {
      playbackState.add(
        PlaybackState(
          processingState: _processingState,
          playing: false,
          updatePosition: _position,
          repeatMode: _repeatMode,
          shuffleMode: _shuffleMode,
          errorMessage: errorMessage,
        ),
      );

      return;
    }

    // Use the same control layout recommended by audio_service:
    // Previous | Play/Pause | Stop | Next.
    //
    // Android compact view shows Previous, Play/Pause and Next.
    final List<MediaControl> controls = <MediaControl>[
      MediaControl.skipToPrevious,
      _isPlaying ? MediaControl.pause : MediaControl.play,
      MediaControl.stop,
      MediaControl.skipToNext,
    ];

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const <MediaAction>{
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const <int>[
          0,
          1,
          3,
        ],
        processingState: _processingState,
        playing: _isPlaying,
        updatePosition: _position,
        bufferedPosition: _position,
        speed: 1.0,
        queueIndex: _queueIndex >= 0 ? _queueIndex : null,
        repeatMode: _repeatMode,
        shuffleMode: _shuffleMode,
        errorMessage: errorMessage,
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  Future<void> disposeHandler() async {
    await _playingSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _completionSubscription?.cancel();

    await _audioService.dispose();
  }
}

// ===========================================================
// RIVERPOD PROVIDER
// ===========================================================

final melodyAudioHandlerProvider =
Provider<MelodyAudioHandler>(
      (ref) {
    throw StateError(
      'MelodyAudioHandler has not been initialized.',
    );
  },
);
