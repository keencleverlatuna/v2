import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:v2/models/album.dart';
import 'package:v2/models/song.dart';
import 'package:v2/providers/player/player_provider.dart';
import 'package:v2/providers/search/search_history_provider.dart';
import 'package:v2/screens/home/home_screen.dart';
import 'package:v2/widgets/media/song_artwork.dart';

class SearchScreen extends ConsumerWidget {
  final String query;
  final ValueChanged<String> onRecentSearchSelected;

  const SearchScreen({
    super.key,
    required this.query,
    required this.onRecentSearchSelected,
  });

  static const Color _accent = Color(0xFFFF2D55);

  static const List<Album> _albums = <Album>[
    HomeScreen.myHumps,
    HomeScreen.afterHours,
    HomeScreen.thatsTheWay,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String normalizedQuery = query.trim().toLowerCase();
    final List<String> history = ref.watch(searchHistoryProvider);
    final SearchHistoryNotifier historyNotifier =
        ref.read(searchHistoryProvider.notifier);
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);

    if (normalizedQuery.isEmpty) {
      return _EmptySearchView(
        history: history,
        albums: _albums,
        onRecentSelected: onRecentSearchSelected,
        onRemoveRecent: historyNotifier.removeQuery,
        onClearHistory: history.isEmpty
            ? null
            : () => _confirmClearHistory(context, historyNotifier),
      );
    }

    final List<Album> artistResults = <Album>[];
    final Set<String> seenArtists = <String>{};

    for (final Album album in _albums) {
      final String artist = album.artist.toLowerCase();
      if (artist.contains(normalizedQuery) && seenArtists.add(artist)) {
        artistResults.add(album);
      }
    }

    final List<Album> albumResults = _albums.where((Album album) {
      return album.title.toLowerCase().contains(normalizedQuery) ||
          album.artist.toLowerCase().contains(normalizedQuery);
    }).toList();

    final List<_SongMatch> songResults = <_SongMatch>[];

    for (final Album album in _albums) {
      for (int index = 0; index < album.songs.length; index++) {
        final Song song = album.songs[index];
        final bool normalMatch =
            song.title.toLowerCase().contains(normalizedQuery) ||
                song.artist.toLowerCase().contains(normalizedQuery) ||
                album.title.toLowerCase().contains(normalizedQuery);
        final bool lyricsMatch =
            (song.lyrics ?? '').toLowerCase().contains(normalizedQuery);

        if (normalMatch || lyricsMatch) {
          songResults.add(
            _SongMatch(
              song: song,
              album: album,
              index: index,
              matchedInLyrics: lyricsMatch && !normalMatch,
            ),
          );
        }
      }
    }

    final bool hasResults = artistResults.isNotEmpty ||
        albumResults.isNotEmpty ||
        songResults.isNotEmpty;

    if (!hasResults) {
      return _NoResultsView(query: query);
    }

    final int resultCount =
        artistResults.length + albumResults.length + songResults.length;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 190),
      children: <Widget>[
        Text(
          '$resultCount ${resultCount == 1 ? 'result' : 'results'} for “$query”',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _secondaryText(context),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 22),
        if (artistResults.isNotEmpty) ...<Widget>[
          _SectionLabel(title: 'Artists', count: artistResults.length),
          const SizedBox(height: 9),
          _IOSGroup(
            children: artistResults.map((Album album) {
              return _ArtistRow(
                album: album,
                onTap: () async {
                  await historyNotifier.addQuery(query);
                  if (context.mounted) {
                    context.push('/album', extra: album);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 26),
        ],
        if (songResults.isNotEmpty) ...<Widget>[
          _SectionLabel(title: 'Songs', count: songResults.length),
          const SizedBox(height: 9),
          _IOSGroup(
            children: songResults.map((_SongMatch match) {
              final bool isCurrent =
                  playerState.currentSong?.id == match.song.id;
              return _SearchSongRow(
                song: match.song,
                matchedInLyrics: match.matchedInLyrics,
                isCurrent: isCurrent,
                isPlaying: isCurrent && playerState.isPlaying,
                onTap: () async {
                  await historyNotifier.addQuery(query);
                  await playerNotifier.playQueue(
                    match.album.songs,
                    startIndex: match.index,
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 26),
        ],
        if (albumResults.isNotEmpty) ...<Widget>[
          _SectionLabel(title: 'Albums', count: albumResults.length),
          const SizedBox(height: 9),
          _IOSGroup(
            children: albumResults.map((Album album) {
              return _AlbumRow(
                album: album,
                onTap: () async {
                  await historyNotifier.addQuery(query);
                  if (context.mounted) {
                    context.push('/album', extra: album);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _confirmClearHistory(
    BuildContext context,
    SearchHistoryNotifier notifier,
  ) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Clear Recent Searches?'),
          content: const Text('This removes your search history from V2.'),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await notifier.clearHistory();
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}

class _EmptySearchView extends StatelessWidget {
  final List<String> history;
  final List<Album> albums;
  final ValueChanged<String> onRecentSelected;
  final ValueChanged<String> onRemoveRecent;
  final VoidCallback? onClearHistory;

  const _EmptySearchView({
    required this.history,
    required this.albums,
    required this.onRecentSelected,
    required this.onRemoveRecent,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 190),
      children: <Widget>[
        if (history.isEmpty) ...<Widget>[
          const SizedBox(height: 18),
          Center(
            child: Column(
              children: <Widget>[
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: _softFill(context),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.search,
                    color: _secondaryText(context),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Search your music',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Find songs, artists, albums, and lyrics.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
        ] else ...<Widget>[
          _SectionLabel(
            title: 'Recent Searches',
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 28,
              onPressed: onClearHistory,
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: SearchScreen._accent,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          _IOSGroup(
            children: history.map((String recentQuery) {
              return _RecentSearchRow(
                query: recentQuery,
                onTap: () => onRecentSelected(recentQuery),
                onRemove: () => onRemoveRecent(recentQuery),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
        ],
        _SectionLabel(title: 'Browse Albums', count: albums.length),
        const SizedBox(height: 9),
        _IOSGroup(
          children: albums.map((Album album) {
            return _AlbumRow(
              album: album,
              onTap: () => context.push('/album', extra: album),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _NoResultsView extends StatelessWidget {
  final String query;

  const _NoResultsView({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: _softFill(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.search,
                color: _secondaryText(context),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Results',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No music matched “$query”.\nTry a title or artist name.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _secondaryText(context),
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final int? count;
  final Widget? trailing;

  const _SectionLabel({
    required this.title,
    this.count,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.35,
            ),
          ),
        ),
        if (trailing != null)
          trailing!
        else if (count != null)
          Text(
            '$count',
            style: TextStyle(
              color: _secondaryText(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
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
            indent: 72,
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

class _RecentSearchRow extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentSearchRow({
    required this.query,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      minSize: 0,
      onPressed: onTap,
      child: Row(
        children: <Widget>[
          Icon(
            CupertinoIcons.clock,
            color: _secondaryText(context),
            size: 20,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              query,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(4),
            minSize: 28,
            onPressed: onRemove,
            child: Icon(
              CupertinoIcons.xmark,
              color: _secondaryText(context),
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistRow extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _ArtistRow({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _MediaRow(
      artwork: ClipOval(
        child: SongArtwork(
          source: album.imageUrl,
          width: 48,
          height: 48,
          fallback: _artworkFallback(context, circular: true),
        ),
      ),
      title: album.artist,
      subtitle: 'Artist • ${album.songs.length} song',
      onTap: onTap,
    );
  }
}

class _AlbumRow extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _AlbumRow({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _MediaRow(
      artwork: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: SongArtwork(
          source: album.imageUrl,
          width: 48,
          height: 48,
          fallback: _artworkFallback(context),
        ),
      ),
      title: album.title,
      subtitle: album.artist,
      onTap: onTap,
    );
  }
}

class _SearchSongRow extends StatelessWidget {
  final Song song;
  final bool matchedInLyrics;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;

  const _SearchSongRow({
    required this.song,
    required this.matchedInLyrics,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _MediaRow(
      artwork: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: SongArtwork(
          source: song.artworkUrl,
          width: 48,
          height: 48,
          fallback: _artworkFallback(context),
        ),
      ),
      title: song.title,
      subtitle: matchedInLyrics ? '${song.artist} • Lyrics match' : song.artist,
      titleColor: isCurrent ? SearchScreen._accent : null,
      trailing: isPlaying
          ? const Icon(
              CupertinoIcons.waveform,
              color: SearchScreen._accent,
              size: 20,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _MediaRow extends StatelessWidget {
  final Widget artwork;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MediaRow({
    required this.artwork,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      minSize: 0,
      onPressed: onTap,
      child: Row(
        children: <Widget>[
          SizedBox(width: 48, height: 48, child: artwork),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor ?? Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              Icon(
                CupertinoIcons.chevron_forward,
                color: _tertiaryText(context),
                size: 16,
              ),
        ],
      ),
    );
  }
}

class _SongMatch {
  final Song song;
  final Album album;
  final int index;
  final bool matchedInLyrics;

  const _SongMatch({
    required this.song,
    required this.album,
    required this.index,
    required this.matchedInLyrics,
  });
}

Widget _artworkFallback(BuildContext context, {bool circular = false}) {
  return Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: _softFill(context),
      shape: circular ? BoxShape.circle : BoxShape.rectangle,
    ),
    alignment: Alignment.center,
    child: Icon(
      CupertinoIcons.music_note_2,
      color: _secondaryText(context),
      size: 21,
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
