import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:v2/models/album.dart';
import 'package:v2/providers/player/player_provider.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final Album album;

  const AlbumDetailScreen({
    super.key,
    required this.album,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  20,
                ),
                child: Column(
                  children: [
                    // Top bar
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            context.pop();
                          },
                          icon: const Icon(
                            CupertinoIcons.chevron_left,
                            color: Colors.white,
                          ),
                        ),

                        const Spacer(),

                        IconButton(
                          onPressed: () {
                            debugPrint('Album options');
                          },
                          icon: const Icon(
                            CupertinoIcons.ellipsis_circle,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Album artwork
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.network(
                        album.imageUrl,
                        width: 260,
                        height: 260,
                        fit: BoxFit.cover,
                        errorBuilder: (
                            context,
                            error,
                            stackTrace,
                            ) {
                          return Container(
                            width: 260,
                            height: 260,
                            alignment: Alignment.center,
                            color: const Color(0xFF252527),
                            child: const Icon(
                              CupertinoIcons.music_note_2,
                              color: Colors.white38,
                              size: 80,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Album title
                    Text(
                      album.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // Artist
                    Text(
                      album.artist,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFF2D55),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Play and Shuffle
                    Row(
                      children: [
                        Expanded(
                          child: _AlbumActionButton(
                            icon: CupertinoIcons.play_fill,
                            label: 'Play',
                            onTap: album.songs.isEmpty
                                ? null
                                : () async {
                              await playerNotifier.playQueue(
                                album.songs,
                                startIndex: 0,
                              );
                            },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _AlbumActionButton(
                            icon: CupertinoIcons.shuffle,
                            label: 'Shuffle',
                            onTap: album.songs.isEmpty
                                ? null
                                : () async {
                              final shuffledSongs =
                              List.of(album.songs)
                                ..shuffle();

                              await playerNotifier.playQueue(
                                shuffledSongs,
                                startIndex: 0,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Song list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final song = album.songs[index];

                  final isCurrentSong =
                      playerState.currentSong?.id == song.id;

                  return Column(
                    children: [
                      ListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 3,
                        ),

                        leading: SizedBox(
                          width: 28,
                          child: Center(
                            child: isCurrentSong
                                ? Icon(
                              playerState.isPlaying
                                  ? CupertinoIcons
                                  .waveform
                                  : CupertinoIcons
                                  .pause_fill,
                              color:
                              const Color(0xFFFF2D55),
                              size: 20,
                            )
                                : Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCurrentSong
                                ? const Color(0xFFFF2D55)
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: isCurrentSong
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),

                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),

                        trailing: const Icon(
                          CupertinoIcons.ellipsis,
                          color: Colors.white54,
                          size: 20,
                        ),

                        onTap: () async {
                          await playerNotifier.playQueue(
                            album.songs,
                            startIndex: index,
                          );
                        },
                      ),

                      const Divider(
                        height: 1,
                        indent: 68,
                        color: Colors.white12,
                      ),
                    ],
                  );
                },
                childCount: album.songs.length,
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _AlbumActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: onTap == null
                    ? Colors.white30
                    : const Color(0xFFFF2D55),
                size: 20,
              ),

              const SizedBox(width: 8),

              Text(
                label,
                style: TextStyle(
                  color: onTap == null
                      ? Colors.white30
                      : const Color(0xFFFF2D55),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}