import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:v2/models/song.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  late final Future<void> _initializationFuture =
  _initializePlayer();

  int _latestRequestId = 0;

  // =========================================================
  // STREAMS
  // =========================================================

  Stream<bool> get playingStream {
    return _player.onPlayerStateChanged
        .map(
          (state) => state == PlayerState.playing,
    )
        .distinct();
  }

  Stream<Duration> get positionStream {
    return _player.onPositionChanged;
  }

  Stream<Duration?> get durationStream {
    return _player.onDurationChanged.map<Duration?>(
          (duration) => duration,
    );
  }

  Stream<void> get completedStream {
    return _player.onPlayerComplete;
  }

  // =========================================================
  // INITIALIZE
  // =========================================================

  Future<void> initialize() {
    return _initializationFuture;
  }

  Future<void> _initializePlayer() async {
    await _player.setPlayerMode(
      PlayerMode.mediaPlayer,
    );

    await _player.setReleaseMode(
      ReleaseMode.stop,
    );

    await _player.setVolume(1.0);

    await _player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
        ),
      ),
    );

    // Extra debugging.
    _player.onPlayerStateChanged.listen(
          (state) {
        debugPrint(
          'Native player state: $state',
        );
      },
    );

    _player.onPositionChanged.listen(
          (position) {
        // Print every ~5 seconds only.
        if (position.inSeconds > 0 &&
            position.inSeconds % 5 == 0 &&
            position.inMilliseconds % 1000 < 250) {
          debugPrint(
            'Audio position: ${position.inSeconds}s',
          );
        }
      },
    );

    debugPrint(
      'AudioPlayerService initialized.',
    );
  }

  // =========================================================
  // LOAD + PLAY SONG
  // =========================================================

  Future<void> loadAndPlaySong(
      Song song,
      ) async {
    await _initializationFuture;

    final int requestId =
    ++_latestRequestId;

    try {
      debugPrint(
        '========================================',
      );

      debugPrint(
        'Preparing song: ${song.title}',
      );

      debugPrint(
        'Request ID: $requestId',
      );

      debugPrint(
        'Original audio path: ${song.audioUrl}',
      );

      final Source source =
      await _resolveSource(
        song.audioUrl,
      );

      if (requestId != _latestRequestId) {
        debugPrint(
          'Stale request ignored: ${song.title}',
        );

        return;
      }

      debugPrint(
        'Resolved audio source: $source',
      );

      // =====================================================
      // IMPORTANT FIX
      // =====================================================
      //
      // HUWAG mag-stop() dito.
      //
      // Changing the source replaces the current source.
      // Then resume() starts the new song from the beginning.
      //
      // =====================================================

      debugPrint(
        'Changing source to: ${song.title}',
      );

      await _player.setSource(
        source,
      );

      if (requestId != _latestRequestId) {
        debugPrint(
          'Request cancelled after setSource: ${song.title}',
        );

        return;
      }

      debugPrint(
        'Source changed successfully.',
      );

      await _player.setVolume(
        1.0,
      );

      debugPrint(
        'Starting playback: ${song.title}',
      );

      await _player.resume();

      if (requestId != _latestRequestId) {
        debugPrint(
          'A newer song was selected.',
        );

        return;
      }

      debugPrint(
        'Resume completed.',
      );

      debugPrint(
        'Current player state: ${_player.state}',
      );

      final Duration? duration =
      await _player.getDuration();

      debugPrint(
        'Loaded duration: $duration',
      );

      // Give native player a short moment,
      // then inspect whether position is actually moving.
      await Future<void>.delayed(
        const Duration(milliseconds: 600),
      );

      if (requestId != _latestRequestId) {
        return;
      }

      final Duration? position =
      await _player.getCurrentPosition();

      debugPrint(
        'Position after 600ms: $position',
      );

      debugPrint(
        'Playback setup finished: ${song.title}',
      );

      debugPrint(
        '========================================',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Playback error for ${song.title}: $error',
      );

      debugPrint(
        'Playback stack trace: $stackTrace',
      );

      rethrow;
    }
  }

  // =========================================================
  // PLAY / RESUME
  // =========================================================

  Future<void> play() async {
    await _initializationFuture;

    final PlayerState currentState =
        _player.state;

    if (currentState == PlayerState.paused) {
      await _player.resume();
      return;
    }

    if (currentState == PlayerState.completed) {
      await _player.seek(
        Duration.zero,
      );

      await _player.resume();
    }
  }

  // =========================================================
  // PAUSE
  // =========================================================

  Future<void> pause() async {
    await _initializationFuture;

    if (_player.state == PlayerState.playing) {
      await _player.pause();
    }
  }

  // =========================================================
  // SEEK
  // =========================================================

  Future<void> seek(
      Duration position,
      ) async {
    await _initializationFuture;

    final PlayerState currentState =
        _player.state;

    if (currentState == PlayerState.playing ||
        currentState == PlayerState.paused ||
        currentState == PlayerState.completed) {
      await _player.seek(
        position,
      );
    }
  }

  // =========================================================
  // STOP
  // =========================================================

  Future<void> stop() async {
    await _initializationFuture;

    ++_latestRequestId;

    final PlayerState currentState =
        _player.state;

    if (currentState == PlayerState.playing ||
        currentState == PlayerState.paused ||
        currentState == PlayerState.completed) {
      await _player.stop();
    }
  }

  // =========================================================
  // RESOLVE SOURCE
  // =========================================================

  Future<Source> _resolveSource(
      String value,
      ) async {
    final String source =
    value.trim();

    // Flutter bundled asset.
    if (source.startsWith('assets/')) {
      final File file =
      await _copyAssetToTempFile(
        source,
      );

      return DeviceFileSource(
        file.path,
        mimeType: 'audio/mpeg',
      );
    }

    // asset:// URI.
    if (source.startsWith('asset://')) {
      final String relativePath =
      source.substring(
        'asset://'.length,
      );

      final String assetPath =
      relativePath.startsWith('assets/')
          ? relativePath
          : 'assets/$relativePath';

      final File file =
      await _copyAssetToTempFile(
        assetPath,
      );

      return DeviceFileSource(
        file.path,
        mimeType: 'audio/mpeg',
      );
    }

    // file:// URI.
    if (source.startsWith('file://')) {
      final Uri uri =
      Uri.parse(source);

      return DeviceFileSource(
        uri.toFilePath(),
        mimeType: 'audio/mpeg',
      );
    }

    // Android/iOS absolute path.
    if (source.startsWith('/')) {
      return DeviceFileSource(
        source,
        mimeType: 'audio/mpeg',
      );
    }

    // Windows absolute path.
    final RegExp windowsPath =
    RegExp(
      r'^[a-zA-Z]:[\\/]',
    );

    if (windowsPath.hasMatch(source)) {
      return DeviceFileSource(
        source,
        mimeType: 'audio/mpeg',
      );
    }

    // Network stream.
    return UrlSource(
      source,
    );
  }

  // =========================================================
  // COPY ASSET TO TEMP FILE
  // =========================================================

  Future<File> _copyAssetToTempFile(
      String assetPath,
      ) async {
    debugPrint(
      'Loading Flutter asset: $assetPath',
    );

    final ByteData data =
    await rootBundle.load(
      assetPath,
    );

    debugPrint(
      'ByteData length: ${data.lengthInBytes}',
    );

    final Uint8List bytes =
    data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    debugPrint(
      'Asset bytes loaded: ${bytes.length}',
    );

    if (bytes.isEmpty) {
      throw Exception(
        'Flutter asset is empty: $assetPath',
      );
    }

    final Directory tempDirectory =
    await getTemporaryDirectory();

    final Directory audioDirectory =
    Directory(
      '${tempDirectory.path}/melody_audio',
    );

    if (!await audioDirectory.exists()) {
      await audioDirectory.create(
        recursive: true,
      );
    }

    final String fileName =
        assetPath.split('/').last;

    final File tempFile =
    File(
      '${audioDirectory.path}/$fileName',
    );

    debugPrint(
      'Temporary audio path: ${tempFile.path}',
    );

    // Reuse correct existing copy.
    if (await tempFile.exists()) {
      final int existingSize =
      await tempFile.length();

      if (existingSize > 0 &&
          existingSize == bytes.length) {
        debugPrint(
          'Using existing temporary audio file.',
        );

        debugPrint(
          'Temporary audio size: $existingSize bytes',
        );

        return tempFile;
      }

      await tempFile.delete();
    }

    await tempFile.writeAsBytes(
      bytes,
      flush: true,
    );

    final int tempFileSize =
    await tempFile.length();

    debugPrint(
      'Temporary audio size: $tempFileSize bytes',
    );

    if (tempFileSize <= 0) {
      throw Exception(
        'Temporary audio file is empty: $assetPath',
      );
    }

    if (tempFileSize != bytes.length) {
      throw Exception(
        'Audio file size mismatch. '
            'Asset: ${bytes.length}, '
            'Temporary: $tempFileSize',
      );
    }

    debugPrint(
      'Asset copied successfully.',
    );

    return tempFile;
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  Future<void> dispose() async {
    ++_latestRequestId;

    await _player.dispose();
  }
}