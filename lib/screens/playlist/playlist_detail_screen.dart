import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:v2/models/album.dart';
import 'package:v2/models/playlist.dart';
import 'package:v2/models/song.dart';

import 'package:v2/providers/library/playlists_provider.dart';
import 'package:v2/providers/player/player_provider.dart';

import 'package:v2/screens/home/home_screen.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
  });

  static const List<Album> _albums = [
    HomeScreen.myHumps,
    HomeScreen.afterHours,
    HomeScreen.thatsTheWay,
  ];

  List<Song> get _allSongs {
    return _albums
        .expand(
          (album) => album.songs,
    )
        .toList();
  }

  MelodyPlaylist? _findPlaylist(
      List<MelodyPlaylist> playlists,
      ) {
    for (final playlist in playlists) {
      if (playlist.id == playlistId) {
        return playlist;
      }
    }

    return null;
  }

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref,
      ) {
    final playlists =
    ref.watch(playlistsProvider);

    final playlistsNotifier =
    ref.read(playlistsProvider.notifier);

    final playerState =
    ref.watch(playerProvider);

    final playerNotifier =
    ref.read(playerProvider.notifier);

    final playlist =
    _findPlaylist(playlists);

    // =========================================================
    // PLAYLIST NOT FOUND
    // =========================================================
    if (playlist == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment:
                Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    CupertinoIcons.chevron_left,
                    color: Colors.white,
                  ),
                ),
              ),

              const Expanded(
                child: Center(
                  child: Text(
                    'Playlist not found.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // =================================================
            // TOP BAR
            // =================================================
            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  8,
                  4,
                  8,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        CupertinoIcons.chevron_left,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),

                    const Spacer(),

                    IconButton(
                      onPressed: () {
                        _showPlaylistOptions(
                          context,
                          ref,
                          playlist,
                        );
                      },
                      icon: const Icon(
                        CupertinoIcons
                            .ellipsis_circle,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =================================================
            // PLAYLIST HEADER
            // =================================================
            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  20,
                  14,
                  20,
                  0,
                ),
                child: Column(
                  children: [
                    // =========================================
                    // ARTWORK
                    // =========================================
                    Container(
                      width: 230,
                      height: 230,
                      alignment:
                      Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(
                          22,
                        ),
                        gradient:
                        const LinearGradient(
                          begin:
                          Alignment.topLeft,
                          end:
                          Alignment.bottomRight,
                          colors: [
                            Color(0xFF5856D6),
                            Color(0xFFAF52DE),
                            Color(0xFFFF2D55),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 28,
                            offset:
                            const Offset(
                              0,
                              15,
                            ),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons
                            .music_note_2,
                        color: Colors.white,
                        size: 82,
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // =========================================
                    // NAME
                    // =========================================
                    Text(
                      playlist.name,
                      textAlign:
                      TextAlign.center,
                      style:
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight:
                        FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      '${playlist.songs.length} ${playlist.songs.length == 1 ? 'song' : 'songs'}',
                      style:
                      const TextStyle(
                        color:
                        Colors.white54,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // =========================================
                    // PLAY + SHUFFLE
                    // =========================================
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon:
                            CupertinoIcons
                                .play_fill,
                            title: 'Play',
                            onTap:
                            playlist.songs.isEmpty
                                ? null
                                : () async {
                              await playerNotifier
                                  .playQueue(
                                playlist.songs,
                                startIndex: 0,
                              );

                              if (!context
                                  .mounted) {
                                return;
                              }

                              context.push(
                                '/now-playing',
                              );
                            },
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: _ActionButton(
                            icon:
                            CupertinoIcons
                                .shuffle,
                            title: 'Shuffle',
                            onTap:
                            playlist.songs.isEmpty
                                ? null
                                : () async {
                              final shuffled =
                              List<Song>.from(
                                playlist.songs,
                              )..shuffle();

                              await playerNotifier
                                  .playQueue(
                                shuffled,
                                startIndex: 0,
                              );

                              if (!context
                                  .mounted) {
                                return;
                              }

                              context.push(
                                '/now-playing',
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // =========================================
                    // ADD SONGS
                    // =========================================
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color:
                        const Color(
                          0xFF1C1C1E,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          14,
                        ),
                        onPressed: () {
                          _showAddSongs(
                            context,
                            ref,
                          );
                        },
                        child:
                        const Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                          children: [
                            Icon(
                              CupertinoIcons
                                  .add,
                              color: Color(
                                0xFFFF2D55,
                              ),
                              size: 20,
                            ),
                            SizedBox(
                              width: 7,
                            ),
                            Text(
                              'Add Songs',
                              style:
                              TextStyle(
                                color: Color(
                                  0xFFFF2D55,
                                ),
                                fontWeight:
                                FontWeight
                                    .w600,
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

            const SliverToBoxAdapter(
              child: SizedBox(
                height: 32,
              ),
            ),

            // =================================================
            // SONGS HEADER
            // =================================================
            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Songs',
                        style:
                        TextStyle(
                          color:
                          Colors.white,
                          fontSize: 22,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),

                    Text(
                      '${playlist.songs.length}',
                      style:
                      const TextStyle(
                        color:
                        Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(
                height: 10,
              ),
            ),

            // =================================================
            // EMPTY
            // =================================================
            if (playlist.songs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    50,
                  ),
                  child: Container(
                    width:
                    double.infinity,
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 34,
                    ),
                    decoration:
                    BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.04,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        18,
                      ),
                    ),
                    child:
                    const Column(
                      children: [
                        Icon(
                          CupertinoIcons
                              .music_note_2,
                          color:
                          Colors.white24,
                          size: 46,
                        ),

                        SizedBox(
                          height: 14,
                        ),

                        Text(
                          'Your playlist is empty',
                          style:
                          TextStyle(
                            color:
                            Colors.white,
                            fontSize: 18,
                            fontWeight:
                            FontWeight
                                .w600,
                          ),
                        ),

                        SizedBox(
                          height: 6,
                        ),

                        Text(
                          'Tap Add Songs to start building your playlist.',
                          textAlign:
                          TextAlign
                              .center,
                          style:
                          TextStyle(
                            color:
                            Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )

            // =================================================
            // SONG LIST
            // =================================================
            else
              SliverList.builder(
                itemCount:
                playlist.songs.length,
                itemBuilder:
                    (
                    context,
                    index,
                    ) {
                  final song =
                  playlist.songs[index];

                  final isCurrent =
                      playerState
                          .currentSong
                          ?.id ==
                          song.id;

                  return Padding(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 20,
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding:
                          EdgeInsets.zero,

                          onTap: () async {
                            await playerNotifier
                                .playQueue(
                              playlist.songs,
                              startIndex:
                              index,
                            );

                            if (!context
                                .mounted) {
                              return;
                            }

                            context.push(
                              '/now-playing',
                            );
                          },

                          leading:
                          ClipRRect(
                            borderRadius:
                            BorderRadius
                                .circular(
                              9,
                            ),
                            child:
                            _songArtwork(
                              song,
                              54,
                            ),
                          ),

                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            TextStyle(
                              color: isCurrent
                                  ? const Color(
                                0xFFFF2D55,
                              )
                                  : Colors
                                  .white,
                              fontSize: 16,
                              fontWeight:
                              isCurrent
                                  ? FontWeight
                                  .w600
                                  : FontWeight
                                  .normal,
                            ),
                          ),

                          subtitle: Text(
                            song.artist,
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              color:
                              Colors.white54,
                              fontSize: 13,
                            ),
                          ),

                          trailing: Row(
                            mainAxisSize:
                            MainAxisSize.min,
                            children: [
                              if (isCurrent &&
                                  playerState
                                      .isPlaying)
                                const Icon(
                                  CupertinoIcons
                                      .waveform,
                                  color: Color(
                                    0xFFFF2D55,
                                  ),
                                  size: 20,
                                ),

                              IconButton(
                                onPressed: () {
                                  _showSongOptions(
                                    context,
                                    playlistsNotifier,
                                    playlist,
                                    song,
                                  );
                                },
                                icon:
                                const Icon(
                                  CupertinoIcons
                                      .ellipsis,
                                  color:
                                  Colors.white54,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(
                          height: 1,
                          indent: 66,
                          color:
                          Colors.white12,
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SliverToBoxAdapter(
              child: SizedBox(
                height: 80,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // PLAYLIST OPTIONS
  // =========================================================
  void _showPlaylistOptions(
      BuildContext context,
      WidgetRef ref,
      MelodyPlaylist playlist,
      ) {
    final notifier =
    ref.read(
      playlistsProvider.notifier,
    );

    showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) {
        return CupertinoActionSheet(
          title: Text(
            playlist.name,
          ),
          message: Text(
            '${playlist.songs.length} ${playlist.songs.length == 1 ? 'song' : 'songs'}',
          ),
          actions: [
            // ===============================================
            // RENAME
            // ===============================================
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(
                  popupContext,
                ).pop();

                _showRenamePlaylist(
                  context,
                  notifier,
                  playlist,
                );
              },
              child:
              const Text(
                'Rename Playlist',
              ),
            ),

            // ===============================================
            // EDIT SONGS
            // ===============================================
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(
                  popupContext,
                ).pop();

                _showEditSongs(
                  context,
                  ref,
                );
              },
              child:
              const Text(
                'Edit Songs',
              ),
            ),

            // ===============================================
            // ADD SONGS
            // ===============================================
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(
                  popupContext,
                ).pop();

                _showAddSongs(
                  context,
                  ref,
                );
              },
              child:
              const Text(
                'Add Songs',
              ),
            ),

            // ===============================================
            // DELETE
            // ===============================================
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.of(
                  popupContext,
                ).pop();

                _confirmDelete(
                  context,
                  notifier,
                  playlist,
                );
              },
              child:
              const Text(
                'Delete Playlist',
              ),
            ),
          ],
          cancelButton:
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(
                popupContext,
              ).pop();
            },
            child:
            const Text(
              'Cancel',
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // RENAME PLAYLIST
  // =========================================================
  void _showRenamePlaylist(
      BuildContext context,
      PlaylistsNotifier notifier,
      MelodyPlaylist playlist,
      ) {
    final controller =
    TextEditingController(
      text: playlist.name,
    );

    controller.selection =
        TextSelection(
          baseOffset: 0,
          extentOffset:
          controller.text.length,
        );

    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title:
          const Text(
            'Rename Playlist',
          ),
          content: Padding(
            padding:
            const EdgeInsets.only(
              top: 12,
            ),
            child:
            CupertinoTextField(
              controller: controller,
              autofocus: true,
              placeholder:
              'Playlist Name',
              textCapitalization:
              TextCapitalization
                  .words,
              clearButtonMode:
              OverlayVisibilityMode
                  .editing,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
              const Text(
                'Cancel',
              ),
            ),

            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                final newName =
                controller.text
                    .trim();

                if (newName.isEmpty) {
                  return;
                }

                await notifier
                    .renamePlaylist(
                  playlist.id,
                  newName,
                );

                if (!dialogContext
                    .mounted) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
              const Text(
                'Save',
              ),
            ),
          ],
        );
      },
    ).whenComplete(
      controller.dispose,
    );
  }

  // =========================================================
  // EDIT SONGS
  // =========================================================
  void _showEditSongs(
      BuildContext context,
      WidgetRef ref,
      ) {
    final allSongs = _allSongs;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
      const Color(
        0xFF1C1C1E,
      ),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (
              context,
              ref,
              child,
              ) {
            final playlists =
            ref.watch(
              playlistsProvider,
            );

            final notifier =
            ref.read(
              playlistsProvider
                  .notifier,
            );

            final playlist =
            _findPlaylist(
              playlists,
            );

            if (playlist == null) {
              return const SizedBox
                  .shrink();
            }

            return SafeArea(
              child: SizedBox(
                height:
                MediaQuery.of(
                  context,
                )
                    .size
                    .height *
                    0.78,
                child: Column(
                  children: [
                    // =======================================
                    // HEADER
                    // =======================================
                    Padding(
                      padding:
                      const EdgeInsets
                          .fromLTRB(
                        20,
                        4,
                        12,
                        12,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  'Edit Songs',
                                  style:
                                  TextStyle(
                                    color:
                                    Colors.white,
                                    fontSize: 24,
                                    fontWeight:
                                    FontWeight
                                        .w700,
                                  ),
                                ),

                                SizedBox(
                                  height: 3,
                                ),

                                Text(
                                  'Tap songs to add or remove them.',
                                  style:
                                  TextStyle(
                                    color:
                                    Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          CupertinoButton(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 10,
                            ),
                            onPressed: () {
                              Navigator.of(
                                sheetContext,
                              ).pop();
                            },
                            child:
                            const Text(
                              'Done',
                              style:
                              TextStyle(
                                color: Color(
                                  0xFFFF2D55,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 1,
                      color:
                      Colors.white12,
                    ),

                    Expanded(
                      child:
                      ListView.separated(
                        padding:
                        const EdgeInsets
                            .only(
                          bottom: 30,
                        ),
                        itemCount:
                        allSongs.length,
                        separatorBuilder:
                            (
                            context,
                            index,
                            ) {
                          return const Divider(
                            height: 1,
                            indent: 84,
                            color:
                            Colors.white12,
                          );
                        },
                        itemBuilder:
                            (
                            context,
                            index,
                            ) {
                          final song =
                          allSongs[
                          index];

                          final isAdded =
                          playlist.songs
                              .any(
                                (item) =>
                            item.id ==
                                song.id,
                          );

                          return ListTile(
                            contentPadding:
                            const EdgeInsets
                                .symmetric(
                              horizontal:
                              20,
                              vertical: 4,
                            ),

                            leading:
                            ClipRRect(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                8,
                              ),
                              child:
                              _songArtwork(
                                song,
                                52,
                              ),
                            ),

                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                              style:
                              const TextStyle(
                                color:
                                Colors.white,
                                fontSize: 16,
                              ),
                            ),

                            subtitle: Text(
                              song.artist,
                              maxLines: 1,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                              style:
                              const TextStyle(
                                color:
                                Colors.white54,
                                fontSize: 13,
                              ),
                            ),

                            trailing: Icon(
                              isAdded
                                  ? CupertinoIcons
                                  .check_mark_circled_solid
                                  : CupertinoIcons
                                  .circle,
                              color: isAdded
                                  ? const Color(
                                0xFFFF2D55,
                              )
                                  : Colors
                                  .white30,
                              size: 25,
                            ),

                            onTap: () {
                              if (isAdded) {
                                notifier
                                    .removeSong(
                                  playlist.id,
                                  song.id,
                                );
                              } else {
                                notifier
                                    .addSong(
                                  playlist.id,
                                  song,
                                );
                              }
                            },
                          );
                        },
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

  // =========================================================
  // ADD SONGS
  // =========================================================
  void _showAddSongs(
      BuildContext context,
      WidgetRef ref,
      ) {
    final allSongs = _allSongs;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
      const Color(
        0xFF1C1C1E,
      ),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Consumer(
          builder: (
              context,
              ref,
              child,
              ) {
            final playlists =
            ref.watch(
              playlistsProvider,
            );

            final notifier =
            ref.read(
              playlistsProvider
                  .notifier,
            );

            final playlist =
            _findPlaylist(
              playlists,
            );

            if (playlist == null) {
              return const SizedBox
                  .shrink();
            }

            // Only show songs not already added.
            final availableSongs =
            allSongs.where(
                  (song) {
                return !playlist.songs.any(
                      (item) =>
                  item.id == song.id,
                );
              },
            ).toList();

            return SafeArea(
              child: SizedBox(
                height:
                MediaQuery.of(
                  context,
                )
                    .size
                    .height *
                    0.78,
                child: Column(
                  children: [
                    Padding(
                      padding:
                      const EdgeInsets
                          .fromLTRB(
                        20,
                        4,
                        12,
                        12,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Add Songs',
                              style:
                              TextStyle(
                                color:
                                Colors.white,
                                fontSize: 24,
                                fontWeight:
                                FontWeight
                                    .w700,
                              ),
                            ),
                          ),

                          CupertinoButton(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 10,
                            ),
                            onPressed: () {
                              Navigator.of(
                                sheetContext,
                              ).pop();
                            },
                            child:
                            const Text(
                              'Done',
                              style:
                              TextStyle(
                                color: Color(
                                  0xFFFF2D55,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(
                      height: 1,
                      color:
                      Colors.white12,
                    ),

                    if (availableSongs
                        .isEmpty)
                      const Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize:
                            MainAxisSize
                                .min,
                            children: [
                              Icon(
                                CupertinoIcons
                                    .check_mark_circled_solid,
                                color:
                                Color(
                                  0xFFFF2D55,
                                ),
                                size: 46,
                              ),

                              SizedBox(
                                height: 14,
                              ),

                              Text(
                                'All Songs Added',
                                style:
                                TextStyle(
                                  color:
                                  Colors.white,
                                  fontSize: 18,
                                  fontWeight:
                                  FontWeight
                                      .w600,
                                ),
                              ),

                              SizedBox(
                                height: 6,
                              ),

                              Text(
                                'Every available song is already in this playlist.',
                                textAlign:
                                TextAlign
                                    .center,
                                style:
                                TextStyle(
                                  color:
                                  Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child:
                        ListView.separated(
                          padding:
                          const EdgeInsets
                              .only(
                            bottom: 30,
                          ),
                          itemCount:
                          availableSongs
                              .length,
                          separatorBuilder:
                              (
                              context,
                              index,
                              ) {
                            return const Divider(
                              height: 1,
                              indent: 84,
                              color:
                              Colors.white12,
                            );
                          },
                          itemBuilder:
                              (
                              context,
                              index,
                              ) {
                            final song =
                            availableSongs[
                            index];

                            return ListTile(
                              contentPadding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal:
                                20,
                                vertical: 4,
                              ),

                              leading:
                              ClipRRect(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  8,
                                ),
                                child:
                                _songArtwork(
                                  song,
                                  52,
                                ),
                              ),

                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow:
                                TextOverflow
                                    .ellipsis,
                                style:
                                const TextStyle(
                                  color:
                                  Colors.white,
                                  fontSize: 16,
                                ),
                              ),

                              subtitle:
                              Text(
                                song.artist,
                                style:
                                const TextStyle(
                                  color:
                                  Colors.white54,
                                  fontSize: 13,
                                ),
                              ),

                              trailing:
                              const Icon(
                                CupertinoIcons
                                    .add_circled,
                                color:
                                Color(
                                  0xFFFF2D55,
                                ),
                                size: 25,
                              ),

                              onTap: () {
                                notifier
                                    .addSong(
                                  playlist.id,
                                  song,
                                );
                              },
                            );
                          },
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

  // =========================================================
  // SONG OPTIONS
  // =========================================================
  void _showSongOptions(
      BuildContext context,
      PlaylistsNotifier notifier,
      MelodyPlaylist playlist,
      Song song,
      ) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (popupContext) {
        return CupertinoActionSheet(
          title: Text(
            song.title,
          ),
          message: Text(
            song.artist,
          ),
          actions: [
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.of(
                  popupContext,
                ).pop();

                await notifier.removeSong(
                  playlist.id,
                  song.id,
                );
              },
              child:
              const Text(
                'Remove from Playlist',
              ),
            ),
          ],
          cancelButton:
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(
                popupContext,
              ).pop();
            },
            child:
            const Text(
              'Cancel',
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // DELETE PLAYLIST
  // =========================================================
  void _confirmDelete(
      BuildContext context,
      PlaylistsNotifier notifier,
      MelodyPlaylist playlist,
      ) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title:
          const Text(
            'Delete Playlist?',
          ),
          content: Text(
            '“${playlist.name}” will be removed from your library.',
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
              const Text(
                'Cancel',
              ),
            ),

            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.of(
                  dialogContext,
                ).pop();

                await notifier
                    .deletePlaylist(
                  playlist.id,
                );

                if (!context.mounted) {
                  return;
                }

                Navigator.of(context)
                    .pop();
              },
              child:
              const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // SONG ARTWORK
  // =========================================================
  Widget _songArtwork(
      Song song,
      double size,
      ) {
    if (song.artworkUrl == null ||
        song.artworkUrl!.isEmpty) {
      return _placeholder(
        size,
      );
    }

    return Image.network(
      song.artworkUrl!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (
          context,
          error,
          stackTrace,
          ) {
        return _placeholder(
          size,
        );
      },
    );
  }

  Widget _placeholder(
      double size,
      ) {
    return Container(
      width: size,
      height: size,
      alignment:
      Alignment.center,
      color:
      const Color(
        0xFF2C2C2E,
      ),
      child: Icon(
        CupertinoIcons.music_note_2,
        color:
        Colors.white38,
        size:
        size > 100 ? 42 : 22,
      ),
    );
  }
}

// ===========================================================
// ACTION BUTTON
// ===========================================================
class _ActionButton
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final enabled =
        onTap != null;

    return CupertinoButton(
      padding:
      const EdgeInsets.symmetric(
        vertical: 13,
      ),
      color:
      const Color(
        0xFF1C1C1E,
      ),
      disabledColor:
      const Color(
        0xFF111113,
      ),
      borderRadius:
      BorderRadius.circular(
        14,
      ),
      onPressed: onTap,
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: enabled
                ? const Color(
              0xFFFF2D55,
            )
                : Colors.white24,
            size: 20,
          ),

          const SizedBox(
            width: 7,
          ),

          Text(
            title,
            style: TextStyle(
              color: enabled
                  ? const Color(
                0xFFFF2D55,
              )
                  : Colors.white24,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}