import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:v2/app.dart';
import 'package:v2/services/audio/audio_player_service.dart';
import 'package:v2/services/audio/melody_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('BOOT 1: Flutter initialized');

  // =========================================================
  // LIQUID GLASS
  // =========================================================

  await LiquidGlassWidgets.initialize(
    enablePerformanceMonitor: false,
  );

  debugPrint(
    'BOOT 2: Liquid Glass initialized',
  );

  // =========================================================
  // AUDIO SERVICE
  // =========================================================

  debugPrint(
    'BOOT 3: Starting AudioService',
  );

  final MelodyAudioHandler audioHandler =
  await AudioService.init<
      MelodyAudioHandler>(
    builder: () {
      return MelodyAudioHandler(
        AudioPlayerService(),
      );
    },
    config: AudioServiceConfig(
      androidNotificationChannelId:
      'com.example.v2.channel.audio',

      androidNotificationChannelName:
      'V2 Playback',

      androidNotificationChannelDescription:
      'Music playback controls for V2',

      androidNotificationOngoing: true,

      androidStopForegroundOnPause: true,

      androidShowNotificationBadge: false,

      androidNotificationIcon:
      'mipmap/ic_launcher',

      fastForwardInterval:
      const Duration(
        seconds: 10,
      ),

      rewindInterval:
      const Duration(
        seconds: 10,
      ),
    ),
  );

  debugPrint(
    'BOOT 4: AudioService initialized',
  );

  // =========================================================
  // APP
  // =========================================================

  runApp(
    LiquidGlassWidgets.wrap(
      // Force Premium quality instead of
      // automatically lowering the quality.
      adaptiveQuality: false,

      theme: GlassThemeData.simple(
        blur: 12,
        thickness: 34,

        // PREMIUM LIQUID GLASS
        quality:
        GlassQuality.premium,
      ),

      child: ProviderScope(
        overrides: [
          melodyAudioHandlerProvider
              .overrideWithValue(
            audioHandler,
          ),
        ],
        child: const MelodyApp(),
      ),
    ),
  );

  debugPrint(
    'BOOT 5: runApp called',
  );
}
