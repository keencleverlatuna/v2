import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'package:v2/providers/player/player_provider.dart';

class MiniPlayer extends ConsumerWidget {
  final bool compact;

  const MiniPlayer({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final playerState =
    ref.watch(playerProvider);

    final playerNotifier =
    ref.read(playerProvider.notifier);

    final song =
        playerState.currentSong;

    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final int durationMs =
        playerState.duration.inMilliseconds;

    final int positionMs =
        playerState.position.inMilliseconds;

    double progress = 0;

    if (durationMs > 0) {
      progress =
          positionMs / durationMs;

      progress =
          progress.clamp(
            0.0,
            1.0,
          );
    }

    final double radius =
    compact ? 29 : 24;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal:
        compact ? 0 : 14,

        // Important:
        // no extra vertical padding
        // while compact.
        vertical:
        compact ? 0 : 5,
      ),
      child: GestureDetector(
        behavior:
        HitTestBehavior.opaque,

        onTap: song == null
            ? null
            : () {
          context.push(
            '/now-playing',
          );
        },

        child: ClipRRect(
          borderRadius:
          BorderRadius.circular(
            radius,
          ),
          child: GlassContainer(
            child: AnimatedContainer(
              duration:
              const Duration(
                milliseconds: 280,
              ),
              curve:
              Curves.easeOutCubic,

              height:
              compact ? 58 : 68,

              decoration:
              BoxDecoration(
                borderRadius:
                BorderRadius.circular(
                  radius,
                ),

                // Very light internal tint.
                // Premium glass stays visible.
                gradient:
                LinearGradient(
                  begin:
                  Alignment.topLeft,
                  end:
                  Alignment.bottomRight,
                  colors: isDark
                      ? <Color>[
                    Colors.white
                        .withValues(
                      alpha: 0.085,
                    ),
                    Colors.white
                        .withValues(
                      alpha: 0.025,
                    ),
                  ]
                      : <Color>[
                    Colors.white
                        .withValues(
                      alpha: 0.30,
                    ),
                    Colors.white
                        .withValues(
                      alpha: 0.10,
                    ),
                  ],
                ),

                border:
                Border.all(
                  color: colors.onSurface
                      .withValues(
                    alpha:
                    isDark
                        ? 0.11
                        : 0.08,
                  ),
                  width: 0.8,
                ),
              ),

              child: Stack(
                children: <Widget>[
                  Padding(
                    padding:
                    EdgeInsets.fromLTRB(
                      compact ? 7 : 10,
                      compact ? 5 : 8,
                      compact ? 7 : 6,
                      compact ? 5 : 8,
                    ),

                    child: compact
                        ? _buildCompactPlayer(
                      context:
                      context,
                      playerState:
                      playerState,
                      playerNotifier:
                      playerNotifier,
                      song:
                      song,
                    )
                        : _buildFullPlayer(
                      context:
                      context,
                      playerState:
                      playerState,
                      playerNotifier:
                      playerNotifier,
                      song:
                      song,
                    ),
                  ),

                  // ===========================================
                  // PROGRESS BAR
                  // ===========================================

                  Positioned(
                    left:
                    compact ? 13 : 10,
                    right:
                    compact ? 13 : 10,
                    bottom: 2,

                    child:
                    ClipRRect(
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),

                      child:
                      LinearProgressIndicator(
                        value:
                        song == null
                            ? 0
                            : progress,

                        minHeight:
                        compact
                            ? 1.3
                            : 1.8,

                        backgroundColor:
                        colors.onSurface
                            .withValues(
                          alpha: 0.08,
                        ),

                        valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                          song == null
                              ? colors.onSurface
                              .withValues(
                            alpha:
                            0.18,
                          )
                              : const Color(
                            0xFFFF2D55,
                          ).withValues(
                            alpha:
                            0.85,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // FULL PLAYER
  // =========================================================

  Widget _buildFullPlayer({
    required BuildContext context,
    required MelodyPlayerState
    playerState,
    required PlayerNotifier
    playerNotifier,
    required dynamic song,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        // =====================================================
        // ARTWORK
        // =====================================================

        ClipRRect(
          borderRadius:
          BorderRadius.circular(
            10,
          ),
          child: song?.artworkUrl != null &&
              song!.artworkUrl!.isNotEmpty
              ? Image.network(
            song.artworkUrl!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (
                context,
                error,
                stackTrace,
                ) {
              return _placeholder(
                context,
              );
            },
          )
              : _placeholder(
            context,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        // =====================================================
        // DETAILS
        // =====================================================

        Expanded(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      song?.title ??
                          'Nothing Playing',
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                        colors.onSurface,
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w600,
                        letterSpacing:
                        -0.2,
                      ),
                    ),
                  ),

                  if (song != null &&
                      playerState.isPlaying)
                    const Padding(
                      padding:
                      EdgeInsets.only(
                        left: 6,
                      ),
                      child: Icon(
                        CupertinoIcons
                            .waveform,
                        color:
                        Color(
                          0xFFFF2D55,
                        ),
                        size: 15,
                      ),
                    ),
                ],
              ),

              if (song != null) ...[
                const SizedBox(
                  height: 3,
                ),

                Text(
                  song.artist,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                    colors.onSurface
                        .withValues(
                      alpha: 0.55,
                    ),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(
          width: 4,
        ),

        // =====================================================
        // PLAY / PAUSE
        // =====================================================

        if (playerState.isLoading)
          SizedBox(
            width: 44,
            height: 44,
            child: Padding(
              padding:
              const EdgeInsets.all(
                12,
              ),
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color:
                colors.onSurface,
              ),
            ),
          )
        else
          IconButton(
            onPressed: song == null
                ? null
                : () {
              playerNotifier
                  .togglePlayPause();
            },

            icon: Icon(
              playerState.isPlaying
                  ? CupertinoIcons
                  .pause_fill
                  : CupertinoIcons
                  .play_fill,

              color: song == null
                  ? colors.onSurface
                  .withValues(
                alpha: 0.22,
              )
                  : colors.onSurface,

              size: 25,
            ),
          ),

        // =====================================================
        // NEXT
        // =====================================================

        IconButton(
          onPressed: song == null
              ? null
              : () {
            playerNotifier.next();
          },

          icon: Icon(
            CupertinoIcons
                .forward_end_fill,

            color: song == null
                ? colors.onSurface
                .withValues(
              alpha: 0.22,
            )
                : colors.onSurface,

            size: 21,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PREMIUM COMPACT PLAYER
  // =========================================================

  Widget _buildCompactPlayer({
    required BuildContext context,
    required MelodyPlayerState
    playerState,
    required PlayerNotifier
    playerNotifier,
    required dynamic song,
  }) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Row(
      children: <Widget>[
        // =====================================================
        // PLAY / PAUSE GLASS CIRCLE
        // =====================================================

        GestureDetector(
          behavior:
          HitTestBehavior.opaque,

          onTap: song == null
              ? null
              : () {
            playerNotifier
                .togglePlayPause();
          },

          child: Container(
            width: 39,
            height: 39,
            alignment:
            Alignment.center,

            decoration:
            BoxDecoration(
              shape:
              BoxShape.circle,

              color: colors.onSurface
                  .withValues(
                alpha:
                isDark
                    ? 0.10
                    : 0.07,
              ),

              border:
              Border.all(
                color:
                colors.onSurface
                    .withValues(
                  alpha: 0.10,
                ),
                width: 0.7,
              ),
            ),

            child: playerState.isLoading
                ? SizedBox(
              width: 17,
              height: 17,
              child:
              CircularProgressIndicator(
                strokeWidth: 1.8,
                color:
                colors.onSurface,
              ),
            )
                : Icon(
              playerState.isPlaying
                  ? CupertinoIcons
                  .pause_fill
                  : CupertinoIcons
                  .play_fill,

              size: 18,

              color: song == null
                  ? colors.onSurface
                  .withValues(
                alpha:
                0.28,
              )
                  : colors.onSurface,
            ),
          ),
        ),

        const SizedBox(
          width: 9,
        ),

        // =====================================================
        // SONG INFO
        // =====================================================

        Expanded(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                song?.title ??
                    'Nothing Playing',

                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,

                style: TextStyle(
                  color:
                  colors.onSurface,
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w600,
                  letterSpacing:
                  -0.25,
                ),
              ),

              if (song != null) ...[
                const SizedBox(
                  height: 1,
                ),

                Text(
                  song.artist,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,

                  style: TextStyle(
                    color:
                    colors.onSurface
                        .withValues(
                      alpha: 0.48,
                    ),
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),

        if (song != null &&
            playerState.isPlaying)
          Padding(
            padding:
            const EdgeInsets.only(
              left: 4,
              right: 2,
            ),
            child:
            const Icon(
              CupertinoIcons.waveform,
              color:
              Color(
                0xFFFF2D55,
              ),
              size: 14,
            ),
          ),
      ],
    );
  }

  // =========================================================
  // PLACEHOLDER
  // =========================================================

  Widget _placeholder(
      BuildContext context,
      ) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    return Container(
      width: 48,
      height: 48,
      alignment:
      Alignment.center,

      decoration:
      BoxDecoration(
        color:
        colors.onSurface
            .withValues(
          alpha: 0.07,
        ),

        borderRadius:
        BorderRadius.circular(
          10,
        ),
      ),

      child: Icon(
        CupertinoIcons
            .music_note_2,
        color:
        colors.onSurface
            .withValues(
          alpha: 0.38,
        ),
        size: 23,
      ),
    );
  }
}