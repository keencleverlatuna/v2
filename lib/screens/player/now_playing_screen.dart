import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:v2/providers/library/favorites_provider.dart';
import 'package:v2/providers/player/player_provider.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({
    super.key,
  });

  static const Color _accentColor =
  Color(0xFFFF2D55);

  String _formatDuration(
      Duration duration,
      ) {
    final Duration safeDuration =
    duration.isNegative
        ? Duration.zero
        : duration;

    final int minutes =
        safeDuration.inMinutes;

    final int seconds =
    safeDuration.inSeconds.remainder(
      60,
    );

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final bool isDarkMode =
        Theme.of(context).brightness ==
            Brightness.dark;

    final playerState =
    ref.watch(
      playerProvider,
    );

    final playerNotifier =
    ref.read(
      playerProvider.notifier,
    );

    final favorites =
    ref.watch(
      favoritesProvider,
    );

    final favoritesNotifier =
    ref.read(
      favoritesProvider.notifier,
    );

    final song =
        playerState.currentSong;

    // =========================================================
    // NOTHING PLAYING
    // =========================================================

    if (song == null) {
      return Scaffold(
        backgroundColor:
        colors.surface,

        body:
        SafeArea(
          child:
          Column(
            children:
            <Widget>[
              Align(
                alignment:
                Alignment.centerLeft,

                child:
                IconButton(
                  onPressed:
                      () {
                    Navigator.of(
                      context,
                    ).pop();
                  },

                  icon:
                  Icon(
                    CupertinoIcons
                        .chevron_down,

                    color:
                    colors.onSurface,

                    size: 27,
                  ),
                ),
              ),

              Expanded(
                child:
                Center(
                  child:
                  Text(
                    'Nothing Playing',

                    style:
                    TextStyle(
                      color:
                      colors.onSurface
                          .withValues(
                        alpha: 0.70,
                      ),

                      fontSize: 18,

                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // =========================================================
    // FAVORITE STATUS
    // =========================================================

    final bool isFavorite =
    favorites.any(
          (favoriteSong) =>
      favoriteSong.id ==
          song.id,
    );

    // =========================================================
    // SAFE DURATION
    // =========================================================

    final int durationMs =
    playerState.duration
        .inMilliseconds <=
        0
        ? 1
        : playerState.duration
        .inMilliseconds;

    final int positionMs =
    playerState.position
        .inMilliseconds
        .clamp(
      0,
      durationMs,
    );

    Duration remainingDuration =
        playerState.duration -
            playerState.position;

    if (remainingDuration.isNegative) {
      remainingDuration =
          Duration.zero;
    }

    final bool hasLyrics =
        song.lyrics != null &&
            song.lyrics!
                .trim()
                .isNotEmpty;

    // =========================================================
    // THEME COLORS
    // =========================================================

    final Color primaryText =
        colors.onSurface;

    final Color secondaryText =
    colors.onSurface.withValues(
      alpha: 0.60,
    );

    final Color tertiaryText =
    colors.onSurface.withValues(
      alpha: 0.42,
    );

    final Color disabledColor =
    colors.onSurface.withValues(
      alpha: 0.25,
    );

    return Scaffold(
      backgroundColor:
      colors.surface,

      body:
      Stack(
        children:
        <Widget>[
          // =====================================================
          // BACKGROUND ARTWORK
          // =====================================================

          Positioned.fill(
            child:
            song.artworkUrl !=
                null &&
                song.artworkUrl!
                    .isNotEmpty
                ? Image.network(
              song.artworkUrl!,
              fit:
              BoxFit.cover,

              errorBuilder:
                  (
                  BuildContext context,
                  Object error,
                  StackTrace?
                  stackTrace,
                  ) {
                return ColoredBox(
                  color:
                  colors.surface,
                );
              },
            )
                : ColoredBox(
              color:
              colors.surface,
            ),
          ),

          // =====================================================
          // BLUR + THEME OVERLAY
          // =====================================================

          Positioned.fill(
            child:
            BackdropFilter(
              filter:
              ImageFilter.blur(
                sigmaX: 45,
                sigmaY: 45,
              ),

              child:
              AnimatedContainer(
                duration:
                const Duration(
                  milliseconds: 300,
                ),

                color:
                isDarkMode
                    ? Colors.black
                    .withValues(
                  alpha: 0.60,
                )
                    : Colors.white
                    .withValues(
                  alpha: 0.76,
                ),
              ),
            ),
          ),

          // =====================================================
          // EXTRA GRADIENT FOR READABILITY
          // =====================================================

          Positioned.fill(
            child:
            IgnorePointer(
              child:
              DecoratedBox(
                decoration:
                BoxDecoration(
                  gradient:
                  LinearGradient(
                    begin:
                    Alignment.topCenter,

                    end:
                    Alignment.bottomCenter,

                    colors:
                    isDarkMode
                        ? <Color>[
                      Colors.black
                          .withValues(
                        alpha: 0.06,
                      ),
                      Colors.black
                          .withValues(
                        alpha: 0.22,
                      ),
                    ]
                        : <Color>[
                      Colors.white
                          .withValues(
                        alpha: 0.05,
                      ),
                      Colors.white
                          .withValues(
                        alpha: 0.28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // =====================================================
          // CONTENT
          // =====================================================

          SafeArea(
            child:
            Padding(
              padding:
              const EdgeInsets
                  .fromLTRB(
                24,
                8,
                24,
                20,
              ),

              child:
              Column(
                children:
                <Widget>[
                  // =================================================
                  // TOP BAR
                  // =================================================

                  Row(
                    children:
                    <Widget>[
                      IconButton(
                        onPressed:
                            () {
                          Navigator.of(
                            context,
                          ).pop();
                        },

                        icon:
                        Icon(
                          CupertinoIcons
                              .chevron_down,

                          color:
                          primaryText,

                          size: 27,
                        ),
                      ),

                      const Spacer(),

                      Text(
                        'Now Playing',

                        style:
                        TextStyle(
                          color:
                          secondaryText,

                          fontSize: 14,

                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),

                      const Spacer(),

                      IconButton(
                        onPressed:
                            () {
                          debugPrint(
                            'More options tapped',
                          );
                        },

                        icon:
                        Icon(
                          CupertinoIcons
                              .ellipsis_circle,

                          color:
                          primaryText,

                          size: 26,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // =================================================
                  // ALBUM ARTWORK
                  // =================================================

                  Expanded(
                    child:
                    Center(
                      child:
                      AspectRatio(
                        aspectRatio: 1,

                        child:
                        Container(
                          constraints:
                          const BoxConstraints(
                            maxWidth: 340,
                            maxHeight: 340,
                          ),

                          decoration:
                          BoxDecoration(
                            borderRadius:
                            BorderRadius
                                .circular(
                              24,
                            ),

                            boxShadow:
                            <BoxShadow>[
                              BoxShadow(
                                color:
                                Colors.black
                                    .withValues(
                                  alpha:
                                  isDarkMode
                                      ? 0.35
                                      : 0.18,
                                ),

                                blurRadius:
                                35,

                                offset:
                                const Offset(
                                  0,
                                  18,
                                ),
                              ),
                            ],
                          ),

                          child:
                          ClipRRect(
                            borderRadius:
                            BorderRadius
                                .circular(
                              24,
                            ),

                            child:
                            song.artworkUrl !=
                                null &&
                                song
                                    .artworkUrl!
                                    .isNotEmpty
                                ? Image.network(
                              song
                                  .artworkUrl!,

                              fit:
                              BoxFit
                                  .cover,

                              errorBuilder:
                                  (
                                  BuildContext
                                  context,
                                  Object
                                  error,
                                  StackTrace?
                                  stackTrace,
                                  ) {
                                return _artworkPlaceholder(
                                  context,
                                );
                              },
                            )
                                : _artworkPlaceholder(
                              context,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 26,
                  ),

                  // =================================================
                  // SONG + ARTIST
                  // =================================================

                  Row(
                    children:
                    <Widget>[
                      Expanded(
                        child:
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children:
                          <Widget>[
                            Text(
                              song.title,

                              maxLines: 1,

                              overflow:
                              TextOverflow
                                  .ellipsis,

                              style:
                              TextStyle(
                                color:
                                primaryText,

                                fontSize:
                                24,

                                fontWeight:
                                FontWeight
                                    .w700,

                                letterSpacing:
                                -0.5,
                              ),
                            ),

                            const SizedBox(
                              height: 5,
                            ),

                            Text(
                              song.artist,

                              maxLines: 1,

                              overflow:
                              TextOverflow
                                  .ellipsis,

                              style:
                              TextStyle(
                                color:
                                secondaryText,

                                fontSize:
                                17,

                                fontWeight:
                                FontWeight
                                    .w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // =============================================
                      // FAVORITE
                      // =============================================

                      IconButton(
                        onPressed:
                            () {
                          favoritesNotifier
                              .toggleFavorite(
                            song,
                          );
                        },

                        icon:
                        Icon(
                          isFavorite
                              ? CupertinoIcons
                              .heart_fill
                              : CupertinoIcons
                              .heart,

                          color:
                          isFavorite
                              ? _accentColor
                              : primaryText,

                          size: 27,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  // =================================================
                  // SEEK BAR
                  // =================================================

                  SliderTheme(
                    data:
                    SliderTheme.of(
                      context,
                    ).copyWith(
                      trackHeight: 4,

                      activeTrackColor:
                      primaryText,

                      inactiveTrackColor:
                      primaryText
                          .withValues(
                        alpha: 0.20,
                      ),

                      thumbColor:
                      primaryText,

                      overlayColor:
                      primaryText
                          .withValues(
                        alpha: 0.10,
                      ),

                      thumbShape:
                      const RoundSliderThumbShape(
                        enabledThumbRadius:
                        6,
                      ),

                      overlayShape:
                      const RoundSliderOverlayShape(
                        overlayRadius:
                        14,
                      ),
                    ),

                    child:
                    Slider(
                      min: 0,

                      max:
                      durationMs
                          .toDouble(),

                      value:
                      positionMs
                          .toDouble(),

                      onChanged:
                          (
                          double value,
                          ) {
                        playerNotifier
                            .seek(
                          Duration(
                            milliseconds:
                            value
                                .toInt(),
                          ),
                        );
                      },
                    ),
                  ),

                  // =================================================
                  // TIME
                  // =================================================

                  Padding(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 4,
                    ),

                    child:
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                      children:
                      <Widget>[
                        Text(
                          _formatDuration(
                            playerState
                                .position,
                          ),

                          style:
                          TextStyle(
                            color:
                            tertiaryText,

                            fontSize:
                            12,
                          ),
                        ),

                        Text(
                          '-${_formatDuration(
                            remainingDuration,
                          )}',

                          style:
                          TextStyle(
                            color:
                            tertiaryText,

                            fontSize:
                            12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // =================================================
                  // PLAYER CONTROLS
                  // =================================================

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceEvenly,

                    children:
                    <Widget>[
                      // =============================================
                      // SHUFFLE
                      // =============================================

                      IconButton(
                        onPressed:
                            () {
                          playerNotifier
                              .toggleShuffle();
                        },

                        icon:
                        Icon(
                          CupertinoIcons
                              .shuffle,

                          color:
                          playerState
                              .isShuffleEnabled
                              ? _accentColor
                              : secondaryText,

                          size: 23,
                        ),
                      ),

                      // =============================================
                      // PREVIOUS
                      // =============================================

                      IconButton(
                        onPressed:
                        playerState
                            .isLoading
                            ? null
                            : () {
                          playerNotifier
                              .previous();
                        },

                        icon:
                        Icon(
                          CupertinoIcons
                              .backward_end_fill,

                          color:
                          playerState
                              .isLoading
                              ? disabledColor
                              : primaryText,

                          size: 38,
                        ),
                      ),

                      // =============================================
                      // PLAY / PAUSE
                      // =============================================

                      SizedBox(
                        width: 74,
                        height: 74,

                        child:
                        playerState
                            .isLoading
                            ? Padding(
                          padding:
                          const EdgeInsets
                              .all(
                            22,
                          ),

                          child:
                          CircularProgressIndicator(
                            strokeWidth:
                            3,

                            color:
                            primaryText,
                          ),
                        )
                            : IconButton(
                          onPressed:
                              () {
                            playerNotifier
                                .togglePlayPause();
                          },

                          icon:
                          Icon(
                            playerState
                                .isPlaying
                                ? CupertinoIcons
                                .pause_fill
                                : CupertinoIcons
                                .play_fill,

                            color:
                            primaryText,

                            size:
                            48,
                          ),
                        ),
                      ),

                      // =============================================
                      // NEXT
                      // =============================================

                      IconButton(
                        onPressed:
                        playerState
                            .isLoading
                            ? null
                            : () {
                          playerNotifier
                              .next();
                        },

                        icon:
                        Icon(
                          CupertinoIcons
                              .forward_end_fill,

                          color:
                          playerState
                              .isLoading
                              ? disabledColor
                              : primaryText,

                          size: 38,
                        ),
                      ),

                      // =============================================
                      // REPEAT
                      // =============================================

                      IconButton(
                        onPressed:
                            () {
                          playerNotifier
                              .toggleRepeat();
                        },

                        icon:
                        Stack(
                          clipBehavior:
                          Clip.none,

                          children:
                          <Widget>[
                            Icon(
                              CupertinoIcons
                                  .repeat,

                              color:
                              playerState
                                  .repeatMode ==
                                  PlayerRepeatMode
                                      .off
                                  ? secondaryText
                                  : _accentColor,

                              size: 23,
                            ),

                            if (playerState
                                .repeatMode ==
                                PlayerRepeatMode
                                    .one)
                              const Positioned(
                                right: -4,
                                top: -6,

                                child:
                                Text(
                                  '1',

                                  style:
                                  TextStyle(
                                    color:
                                    _accentColor,

                                    fontSize:
                                    10,

                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // =================================================
                  // LOWER CONTROLS
                  // =================================================

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,

                    children:
                    <Widget>[
                      // =============================================
                      // LYRICS
                      // =============================================

                      IconButton(
                        onPressed:
                            () {
                          _showLyrics(
                            context,
                            song.title,
                            song.artist,
                            song.lyrics,
                          );
                        },

                        icon:
                        Icon(
                          CupertinoIcons
                              .quote_bubble,

                          color:
                          hasLyrics
                              ? primaryText
                              : disabledColor,

                          size: 24,
                        ),
                      ),

                      // =============================================
                      // QUEUE
                      // =============================================

                      IconButton(
                        onPressed:
                            () {
                          _showQueue(
                            context,
                            ref,
                          );
                        },

                        icon:
                        Icon(
                          CupertinoIcons
                              .list_bullet,

                          color:
                          secondaryText,

                          size: 25,
                        ),
                      ),
                    ],
                  ),

                  // =================================================
                  // ERROR
                  // =================================================

                  if (playerState
                      .errorMessage !=
                      null) ...[
                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      playerState
                          .errorMessage!,

                      maxLines: 1,

                      overflow:
                      TextOverflow
                          .ellipsis,

                      textAlign:
                      TextAlign.center,

                      style:
                      const TextStyle(
                        color:
                        Colors.redAccent,

                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================
  // ARTWORK PLACEHOLDER
  // ===========================================================

  Widget _artworkPlaceholder(
      BuildContext context,
      ) {
    final ColorScheme colors =
        Theme.of(context).colorScheme;

    final bool isDarkMode =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Container(
      color:
      isDarkMode
          ? const Color(
        0xFF2C2C2E,
      )
          : const Color(
        0xFFE9E9EE,
      ),

      alignment:
      Alignment.center,

      child:
      Icon(
        CupertinoIcons
            .music_note_2,

        color:
        colors.onSurface
            .withValues(
          alpha: 0.38,
        ),

        size: 90,
      ),
    );
  }

  // ===========================================================
  // LYRICS
  // ===========================================================

  void _showLyrics(
      BuildContext context,
      String title,
      String artist,
      String? lyrics,
      ) {
    final bool hasLyrics =
        lyrics != null &&
            lyrics.trim().isNotEmpty;

    showModalBottomSheet<void>(
      context: context,

      backgroundColor:
      Colors.transparent,

      showDragHandle: false,

      isScrollControlled: true,

      builder:
          (
          BuildContext sheetContext,
          ) {
        final ColorScheme colors =
            Theme.of(
              sheetContext,
            ).colorScheme;

        final bool isDarkMode =
            Theme.of(
              sheetContext,
            ).brightness ==
                Brightness.dark;

        final Color sheetColor =
        isDarkMode
            ? const Color(
          0xFF1C1C1E,
        )
            : const Color(
          0xFFF2F2F7,
        );

        return Container(
          decoration:
          BoxDecoration(
            color:
            sheetColor,

            borderRadius:
            const BorderRadius
                .vertical(
              top:
              Radius.circular(
                28,
              ),
            ),
          ),

          child:
          SafeArea(
            top: false,

            child:
            SizedBox(
              height:
              MediaQuery.sizeOf(
                sheetContext,
              ).height *
                  0.78,

              child:
              Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children:
                <Widget>[
                  // ===============================================
                  // HANDLE
                  // ===============================================

                  Center(
                    child:
                    Container(
                      width: 38,
                      height: 5,

                      margin:
                      const EdgeInsets
                          .only(
                        top: 10,
                        bottom: 16,
                      ),

                      decoration:
                      BoxDecoration(
                        color:
                        colors.onSurface
                            .withValues(
                          alpha: 0.20,
                        ),

                        borderRadius:
                        BorderRadius
                            .circular(
                          20,
                        ),
                      ),
                    ),
                  ),

                  // ===============================================
                  // HEADER
                  // ===============================================

                  Padding(
                    padding:
                    const EdgeInsets
                        .fromLTRB(
                      24,
                      2,
                      24,
                      18,
                    ),

                    child:
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children:
                      <Widget>[
                        Text(
                          'Lyrics',

                          style:
                          TextStyle(
                            color:
                            colors.onSurface,

                            fontSize:
                            26,

                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          title,

                          maxLines: 1,

                          overflow:
                          TextOverflow
                              .ellipsis,

                          style:
                          TextStyle(
                            color:
                            colors.onSurface,

                            fontSize:
                            16,

                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),

                        const SizedBox(
                          height: 3,
                        ),

                        Text(
                          artist,

                          maxLines: 1,

                          overflow:
                          TextOverflow
                              .ellipsis,

                          style:
                          TextStyle(
                            color:
                            colors.onSurface
                                .withValues(
                              alpha:
                              0.54,
                            ),

                            fontSize:
                            14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,

                    color:
                    colors.onSurface
                        .withValues(
                      alpha: 0.10,
                    ),
                  ),

                  // ===============================================
                  // LYRICS CONTENT
                  // ===============================================

                  Expanded(
                    child:
                    hasLyrics
                        ? SingleChildScrollView(
                      padding:
                      const EdgeInsets
                          .fromLTRB(
                        24,
                        26,
                        24,
                        60,
                      ),

                      child:
                      Text(
                        lyrics,

                        style:
                        TextStyle(
                          color:
                          colors.onSurface,

                          fontSize:
                          21,

                          height:
                          1.65,

                          fontWeight:
                          FontWeight
                              .w600,

                          letterSpacing:
                          -0.2,
                        ),
                      ),
                    )
                        : Center(
                      child:
                      Column(
                        mainAxisSize:
                        MainAxisSize
                            .min,

                        children:
                        <Widget>[
                          Icon(
                            CupertinoIcons
                                .quote_bubble,

                            color:
                            colors.onSurface
                                .withValues(
                              alpha:
                              0.24,
                            ),

                            size:
                            52,
                          ),

                          const SizedBox(
                            height:
                            16,
                          ),

                          Text(
                            'Lyrics Not Available',

                            style:
                            TextStyle(
                              color:
                              colors.onSurface,

                              fontSize:
                              19,

                              fontWeight:
                              FontWeight
                                  .w600,
                            ),
                          ),

                          const SizedBox(
                            height:
                            7,
                          ),

                          Text(
                            'No lyrics were added for this song.',

                            textAlign:
                            TextAlign
                                .center,

                            style:
                            TextStyle(
                              color:
                              colors.onSurface
                                  .withValues(
                                alpha:
                                0.54,
                              ),

                              fontSize:
                              14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================
  // QUEUE
  // ===========================================================

  void _showQueue(
      BuildContext context,
      WidgetRef ref,
      ) {
    showModalBottomSheet<void>(
      context: context,

      backgroundColor:
      Colors.transparent,

      showDragHandle: false,

      isScrollControlled: true,

      builder:
          (
          BuildContext sheetContext,
          ) {
        return Consumer(
          builder:
              (
              BuildContext context,
              WidgetRef ref,
              Widget? child,
              ) {
            final ColorScheme colors =
                Theme.of(
                  context,
                ).colorScheme;

            final bool isDarkMode =
                Theme.of(
                  context,
                ).brightness ==
                    Brightness.dark;

            final Color sheetColor =
            isDarkMode
                ? const Color(
              0xFF1C1C1E,
            )
                : const Color(
              0xFFF2F2F7,
            );

            final state =
            ref.watch(
              playerProvider,
            );

            final notifier =
            ref.read(
              playerProvider.notifier,
            );

            return Container(
              decoration:
              BoxDecoration(
                color:
                sheetColor,

                borderRadius:
                const BorderRadius
                    .vertical(
                  top:
                  Radius.circular(
                    28,
                  ),
                ),
              ),

              child:
              SafeArea(
                top: false,

                child:
                Column(
                  mainAxisSize:
                  MainAxisSize.min,

                  children:
                  <Widget>[
                    // =============================================
                    // HANDLE
                    // =============================================

                    Container(
                      width: 38,
                      height: 5,

                      margin:
                      const EdgeInsets
                          .only(
                        top: 10,
                        bottom: 14,
                      ),

                      decoration:
                      BoxDecoration(
                        color:
                        colors.onSurface
                            .withValues(
                          alpha: 0.20,
                        ),

                        borderRadius:
                        BorderRadius
                            .circular(
                          20,
                        ),
                      ),
                    ),

                    if (state.queue.isEmpty)
                      SizedBox(
                        height: 200,

                        child:
                        Center(
                          child:
                          Text(
                            'Queue is empty',

                            style:
                            TextStyle(
                              color:
                              colors.onSurface
                                  .withValues(
                                alpha:
                                0.70,
                              ),

                              fontSize:
                              16,
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height:
                        MediaQuery.sizeOf(
                          context,
                        ).height *
                            0.55,

                        child:
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children:
                          <Widget>[
                            Padding(
                              padding:
                              const EdgeInsets
                                  .fromLTRB(
                                20,
                                5,
                                20,
                                14,
                              ),

                              child:
                              Text(
                                'Up Next',

                                style:
                                TextStyle(
                                  color:
                                  colors.onSurface,

                                  fontSize:
                                  22,

                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                            ),

                            Expanded(
                              child:
                              ListView.separated(
                                itemCount:
                                state
                                    .queue
                                    .length,

                                separatorBuilder:
                                    (
                                    BuildContext
                                    context,
                                    int index,
                                    ) {
                                  return Divider(
                                    height:
                                    1,

                                    indent:
                                    65,

                                    color:
                                    colors.onSurface
                                        .withValues(
                                      alpha:
                                      0.10,
                                    ),
                                  );
                                },

                                itemBuilder:
                                    (
                                    BuildContext
                                    context,
                                    int index,
                                    ) {
                                  final queueSong =
                                  state.queue[
                                  index];

                                  final bool
                                  isCurrent =
                                      index ==
                                          state
                                              .currentIndex;

                                  return ListTile(
                                    contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                      horizontal:
                                      20,
                                    ),

                                    leading:
                                    SizedBox(
                                      width:
                                      28,

                                      child:
                                      Center(
                                        child:
                                        isCurrent
                                            ? const Icon(
                                          CupertinoIcons
                                              .waveform,

                                          color:
                                          _accentColor,

                                          size:
                                          21,
                                        )
                                            : Text(
                                          '${index + 1}',

                                          style:
                                          TextStyle(
                                            color:
                                            colors.onSurface.withValues(
                                              alpha: 0.54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    title:
                                    Text(
                                      queueSong
                                          .title,

                                      maxLines:
                                      1,

                                      overflow:
                                      TextOverflow
                                          .ellipsis,

                                      style:
                                      TextStyle(
                                        color:
                                        isCurrent
                                            ? _accentColor
                                            : colors.onSurface,

                                        fontWeight:
                                        isCurrent
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),

                                    subtitle:
                                    Text(
                                      queueSong
                                          .artist,

                                      maxLines:
                                      1,

                                      overflow:
                                      TextOverflow
                                          .ellipsis,

                                      style:
                                      TextStyle(
                                        color:
                                        colors.onSurface
                                            .withValues(
                                          alpha:
                                          0.54,
                                        ),
                                      ),
                                    ),

                                    trailing:
                                    isCurrent
                                        ? const Icon(
                                      CupertinoIcons
                                          .speaker_2_fill,

                                      color:
                                      _accentColor,

                                      size:
                                      18,
                                    )
                                        : null,

                                    onTap:
                                        () {
                                      notifier
                                          .playQueue(
                                        state
                                            .queue,

                                        startIndex:
                                        index,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}