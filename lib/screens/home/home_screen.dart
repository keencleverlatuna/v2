import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:v2/models/album.dart';
import 'package:v2/models/song.dart';
import 'package:v2/providers/library/imported_music_provider.dart';
import 'package:v2/providers/library/recently_played_provider.dart';
import 'package:v2/providers/player/player_provider.dart';
import 'package:v2/widgets/media/song_artwork.dart';

class HomeScreen extends ConsumerWidget {
  final ScrollController? scrollController;

  const HomeScreen({
    super.key,
    this.scrollController,
  });

  static const Color _accent = Color(0xFF5E5CE6);

  static const Album myHumps = Album(
    id: 'black-eyed-peas-my-humps',
    title: 'My Humps',
    artist: 'The Black Eyed Peas',
    imageUrl: 'https://picsum.photos/seed/blackeyedpeasmyhumps/600/600',
    songs: <Song>[
      Song(
        id: 'black-eyed-peas-my-humps',
        title: 'My Humps',
        artist: 'The Black Eyed Peas',
        audioUrl: 'assets/audio/my_humps.mp3',
        artworkUrl:
            'https://picsum.photos/seed/blackeyedpeasmyhumps/600/600',
      ),
    ],
  );

  static const Album afterHours = Album(
    id: 'the-weeknd-after-hours',
    title: 'After Hours',
    artist: 'The Weeknd',
    imageUrl: 'https://picsum.photos/seed/theweekndafterhours/600/600',
    songs: <Song>[
      Song(
        id: 'the-weeknd-after-hours',
        title: 'After Hours',
        artist: 'The Weeknd',
        audioUrl: 'assets/audio/after_hours.mp3',
        artworkUrl: 'https://picsum.photos/seed/theweekndafterhours/600/600',
      ),
    ],
  );

  static const Album thatsTheWay = Album(
    id: 'kc-sunshine-band-thats-the-way',
    title: 'That\'s the Way (I Like It)',
    artist: 'K.C. & The Sunshine Band',
    imageUrl: 'https://picsum.photos/seed/kcsunshineband/600/600',
    songs: <Song>[
      Song(
        id: 'kc-sunshine-band-thats-the-way',
        title: 'That\'s the Way (I Like It)',
        artist: 'K.C. & The Sunshine Band',
        audioUrl: 'assets/audio/thats_the_way_i_like_it.mp3',
        artworkUrl: 'https://picsum.photos/seed/kcsunshineband/600/600',
      ),
    ],
  );

  static const List<Album> _albums = <Album>[
    myHumps,
    afterHours,
    thatsTheWay,
  ];

  static List<Song> get _builtInSongs {
    return _albums.expand((Album album) => album.songs).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Song> rawRecentlyPlayed = ref.watch(recentlyPlayedProvider);
    final importedState = ref.watch(importedMusicProvider);
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);

    final Set<String> importedSongIds =
        importedState.songs.map((Song song) => song.id).toSet();

    final List<Song> recentlyPlayed = rawRecentlyPlayed.where((Song song) {
      final String source = song.audioUrl.trim();
      if (source.startsWith('assets/') ||
          source.startsWith('http://') ||
          source.startsWith('https://')) {
        return true;
      }
      return importedSongIds.contains(song.id);
    }).toList();

    if (!importedState.isLoading) {
      final Set<String> visibleIds =
          recentlyPlayed.map((Song song) => song.id).toSet();
      final List<String> staleIds = rawRecentlyPlayed
          .where((Song song) => !visibleIds.contains(song.id))
          .map((Song song) => song.id)
          .toList();

      if (staleIds.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final notifier = ref.read(recentlyPlayedProvider.notifier);
          for (final String songId in staleIds) {
            await notifier.removeSong(songId);
          }
        });
      }
    }

    final List<Song> allSongs = <Song>[
      ..._builtInSongs,
      ...importedState.songs,
    ];

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 190),
      children: <Widget>[
        _HomeHero(
          songCount: allSongs.length,
          onPlay: allSongs.isEmpty
              ? null
              : () => playerNotifier.playQueue(allSongs, startIndex: 0),
        ),
        const SizedBox(height: 28),
        const _SectionTitle(
          title: 'Quick Picks',
          subtitle: 'Albums ready to play',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 184,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _albums.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) {
              final Album album = _albums[index];
              return _QuickPickCard(
                album: album,
                onTap: () => context.push('/album', extra: album),
                onPlay: () => playerNotifier.playQueue(
                  album.songs,
                  startIndex: 0,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        _SectionTitle(
          title: 'Continue Listening',
          subtitle: recentlyPlayed.isEmpty
              ? 'Your played songs will appear here'
              : '${recentlyPlayed.length} recent tracks',
        ),
        const SizedBox(height: 10),
        _IOSGroup(
          children: recentlyPlayed.isEmpty
              ? <Widget>[
                  const _EmptyHomeRow(),
                ]
              : List<Widget>.generate(
                  recentlyPlayed.take(4).length,
                  (int index) {
                    final Song song = recentlyPlayed[index];
                    final bool isCurrent =
                        playerState.currentSong?.id == song.id;
                    return _HomeSongRow(
                      song: song,
                      isCurrent: isCurrent,
                      isPlaying: isCurrent && playerState.isPlaying,
                      onTap: () => playerNotifier.playQueue(
                        recentlyPlayed,
                        startIndex: index,
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 28),
        _SectionTitle(
          title: 'All Music',
          subtitle: '${allSongs.length} songs in V2',
        ),
        const SizedBox(height: 10),
        _IOSGroup(
          children: List<Widget>.generate(allSongs.length, (int index) {
            final Song song = allSongs[index];
            final bool isCurrent = playerState.currentSong?.id == song.id;
            return _HomeSongRow(
              song: song,
              isCurrent: isCurrent,
              isPlaying: isCurrent && playerState.isPlaying,
              onTap: () =>
                  playerNotifier.playQueue(allSongs, startIndex: index),
            );
          }),
        ),
      ],
    );
  }
}

class _HomeHero extends StatelessWidget {
  final int songCount;
  final VoidCallback? onPlay;

  const _HomeHero({required this.songCount, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF0A84FF),
            Color(0xFF5E5CE6),
            Color(0xFF30D158),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF5E5CE6).withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'V2 MIX',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your sound,\none tap away.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$songCount songs available',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onPlay,
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.play_fill,
                color: onPlay == null
                    ? const Color(0xFFC7C7CC)
                    : const Color(0xFF242466),
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(color: _secondaryText(context), fontSize: 13),
        ),
      ],
    );
  }
}

class _QuickPickCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const _QuickPickCard({
    required this.album,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 142,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: _groupFill(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _groupBorder(context), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: SongArtwork(
                    source: album.imageUrl,
                    width: 124,
                    height: 112,
                    fallback: _artworkFallback(context, width: 124, height: 112),
                  ),
                ),
                Positioned(
                  right: 7,
                  bottom: 7,
                  child: GestureDetector(
                    onTap: onPlay,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.play_fill,
                        color: Color(0xFF242466),
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              album.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _secondaryText(context), fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _IOSGroup extends StatelessWidget {
  final List<Widget> children;

  const _IOSGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final List<Widget> separated = <Widget>[];
    for (int index = 0; index < children.length; index++) {
      separated.add(children[index]);
      if (index < children.length - 1) {
        separated.add(
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 66,
            color: _divider(context),
          ),
        );
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _groupFill(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _groupBorder(context), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: separated),
      ),
    );
  }
}

class _HomeSongRow extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;

  const _HomeSongRow({
    required this.song,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      minSize: 0,
      onPressed: onTap,
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: SongArtwork(
              source: song.artworkUrl,
              width: 46,
              height: 46,
              fallback: _artworkFallback(context, width: 46, height: 46),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent
                        ? HomeScreen._accent
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (isPlaying)
            const Icon(
              CupertinoIcons.waveform,
              color: HomeScreen._accent,
              size: 19,
            )
          else
            Icon(
              CupertinoIcons.play_fill,
              color: _tertiaryText(context),
              size: 16,
            ),
          const SizedBox(width: 5),
        ],
      ),
    );
  }
}

class _EmptyHomeRow extends StatelessWidget {
  const _EmptyHomeRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _softFill(context),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              CupertinoIcons.clock,
              color: _secondaryText(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Play any song to start your listening history.',
              style: TextStyle(
                color: _secondaryText(context),
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _artworkFallback(
  BuildContext context, {
  required double width,
  required double height,
}) {
  return Container(
    width: width,
    height: height,
    color: _softFill(context),
    alignment: Alignment.center,
    child: Icon(
      CupertinoIcons.music_note_2,
      color: _secondaryText(context),
      size: 28,
    ),
  );
}

Color _groupFill(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1C1C1E)
      : Colors.white;
}

Color _softFill(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF2C2C2E)
      : const Color(0xFFEFEFF4);
}

Color _groupBorder(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.04);
}

Color _divider(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.black.withValues(alpha: 0.10);
}

Color _secondaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF98989D)
      : const Color(0xFF6C6C70);
}

Color _tertiaryText(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF636366)
      : const Color(0xFFC7C7CC);
}
