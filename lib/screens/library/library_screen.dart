import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:v2/models/album.dart';
import 'package:v2/models/song.dart';
import 'package:v2/providers/library/favorites_provider.dart';
import 'package:v2/providers/library/imported_music_provider.dart';
import 'package:v2/providers/library/playlists_provider.dart';
import 'package:v2/providers/library/recently_played_provider.dart';
import 'package:v2/providers/player/player_provider.dart';
import 'package:v2/screens/home/home_screen.dart';
import 'package:v2/widgets/media/song_artwork.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const LibraryScreen({
    super.key,
    this.scrollController,
  });

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  static const Color _accent = Color(0xFF5E5CE6);

  final GlobalKey _playlistsKey = GlobalKey();
  final GlobalKey _favoritesKey = GlobalKey();
  final GlobalKey _importedKey = GlobalKey();
  final GlobalKey _artistsKey = GlobalKey();
  final GlobalKey _albumsKey = GlobalKey();
  final GlobalKey _songsKey = GlobalKey();

  static const List<Album> _albums = <Album>[
    HomeScreen.myHumps,
    HomeScreen.afterHours,
    HomeScreen.thatsTheWay,
  ];

  List<Song> get _builtInSongs {
    return _albums.expand((Album album) => album.songs).toList();
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (!mounted) {
      return;
    }

    final BuildContext? targetContext = key.currentContext;
    if (targetContext == null || !targetContext.mounted) {
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
  }

  Future<void> _showCreatePlaylist(
    BuildContext context,
    PlaylistsNotifier notifier,
  ) async {
    final TextEditingController controller = TextEditingController();

    await showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('New Playlist'),
          content: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: CupertinoTextField(
              controller: controller,
              autofocus: true,
              placeholder: 'Playlist Name',
              clearButtonMode: OverlayVisibilityMode.editing,
              textCapitalization: TextCapitalization.words,
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                final String name = controller.text.trim();
                if (name.isEmpty) {
                  return;
                }
                await notifier.createPlaylist(name);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> _importMusic(
    BuildContext context,
    ImportedMusicNotifier notifier,
  ) async {
    final int count = await notifier.importMusic();
    if (!context.mounted || count == 0) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(count == 1 ? '1 song imported.' : '$count songs imported.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Song> favorites = ref.watch(favoritesProvider);
    final FavoritesNotifier favoritesNotifier =
        ref.read(favoritesProvider.notifier);
    final List<Song> recentlyPlayed = ref.watch(recentlyPlayedProvider);
    final importedState = ref.watch(importedMusicProvider);
    final ImportedMusicNotifier importedNotifier =
        ref.read(importedMusicProvider.notifier);
    final List<Song> importedSongs = importedState.songs;
    final playlists = ref.watch(playlistsProvider);
    final PlaylistsNotifier playlistsNotifier =
        ref.read(playlistsProvider.notifier);
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);

    final List<Song> allSongs = <Song>[
      ..._builtInSongs,
      ...importedSongs,
    ];

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 190),
      children: <Widget>[
        _LibraryOverviewCard(
          songCount: allSongs.length,
          playlistCount: playlists.length + 2,
          favoriteCount: favorites.length,
        ),
        const SizedBox(height: 28),
        const _SectionLabel(title: 'Browse'),
        const SizedBox(height: 9),
        _IOSGroup(
          children: <Widget>[
            _CategoryRow(
              icon: CupertinoIcons.music_note_list,
              title: 'Playlists',
              count: playlists.length + 2,
              onTap: () => _scrollToSection(_playlistsKey),
            ),
            _CategoryRow(
              icon: CupertinoIcons.heart_fill,
              iconColor: _accent,
              title: 'Favorite Songs',
              count: favorites.length,
              onTap: () => _scrollToSection(_favoritesKey),
            ),
            _CategoryRow(
              icon: CupertinoIcons.square_arrow_down,
              title: 'Imported Music',
              count: importedSongs.length,
              onTap: () => _scrollToSection(_importedKey),
            ),
            _CategoryRow(
              icon: CupertinoIcons.person_2_fill,
              title: 'Artists',
              count: _albums.length,
              onTap: () => _scrollToSection(_artistsKey),
            ),
            _CategoryRow(
              icon: CupertinoIcons.music_albums_fill,
              title: 'Albums',
              count: _albums.length,
              onTap: () => _scrollToSection(_albumsKey),
            ),
            _CategoryRow(
              icon: CupertinoIcons.music_note_2,
              title: 'Songs',
              count: allSongs.length,
              onTap: () => _scrollToSection(_songsKey),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Container(
          key: _playlistsKey,
          child: _SectionLabel(
            title: 'Playlists',
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 28,
              onPressed: () =>
                  _showCreatePlaylist(context, playlistsNotifier),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(CupertinoIcons.add, size: 16, color: _accent),
                  SizedBox(width: 3),
                  Text(
                    'New',
                    style: TextStyle(color: _accent, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        _IOSGroup(
          children: <Widget>[
            Container(
              key: _favoritesKey,
              child: _PlaylistRow(
                icon: CupertinoIcons.heart_fill,
                iconColor: _accent,
                title: 'Favorite Songs',
                subtitle: '${favorites.length} songs',
                onTap: favorites.isEmpty
                    ? null
                    : () => playerNotifier.playQueue(favorites, startIndex: 0),
              ),
            ),
            _PlaylistRow(
              icon: CupertinoIcons.clock_fill,
              title: 'Recently Played',
              subtitle: '${recentlyPlayed.length} songs',
              onTap: recentlyPlayed.isEmpty
                  ? null
                  : () =>
                      playerNotifier.playQueue(recentlyPlayed, startIndex: 0),
            ),
            ...playlists.map((playlist) {
              return _PlaylistRow(
                icon: CupertinoIcons.music_note_list,
                title: playlist.name,
                subtitle: '${playlist.songs.length} songs',
                onTap: () => context.push('/playlist/${playlist.id}'),
              );
            }),
          ],
        ),
        const SizedBox(height: 30),
        Container(
          key: _importedKey,
          child: _SectionLabel(
            title: 'Imported Music',
            count: importedSongs.length,
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 28,
              onPressed: importedState.isLoading
                  ? null
                  : () => _importMusic(context, importedNotifier),
              child: importedState.isLoading
                  ? const CupertinoActivityIndicator(radius: 9)
                  : const Text(
                      'Import',
                      style: TextStyle(color: _accent, fontSize: 14),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 9),
        if (importedState.errorMessage != null) ...<Widget>[
          Text(
            importedState.errorMessage!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
          const SizedBox(height: 9),
        ],
        _IOSGroup(
          children: importedState.isLoading && importedSongs.isEmpty
              ? <Widget>[
                  const _EmptyRow(
                    icon: CupertinoIcons.music_note_list,
                    title: 'Loading Music',
                    subtitle: 'Restoring your imported files.',
                    showProgress: true,
                  ),
                ]
              : importedSongs.isEmpty
                  ? <Widget>[
                      const _EmptyRow(
                        icon: CupertinoIcons.square_arrow_down,
                        title: 'No Imported Music',
                        subtitle: 'Tap Import to choose audio files.',
                      ),
                    ]
                  : List<Widget>.generate(importedSongs.length, (int index) {
                      final Song song = importedSongs[index];
                      final bool isCurrent =
                          playerState.currentSong?.id == song.id;
                      return _SongRow(
                        song: song,
                        isCurrent: isCurrent,
                        isPlaying: isCurrent && playerState.isPlaying,
                        onTap: () => playerNotifier.playQueue(
                          importedSongs,
                          startIndex: index,
                        ),
                        onDelete: () async {
                          if (isCurrent) {
                            await playerNotifier.stop();
                          }
                          await importedNotifier.removeSong(song);
                        },
                      );
                    }),
        ),
        const SizedBox(height: 30),
        Container(
          key: _artistsKey,
          child: const _SectionLabel(title: 'Artists'),
        ),
        const SizedBox(height: 11),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _albums.length,
            separatorBuilder: (_, __) => const SizedBox(width: 15),
            itemBuilder: (BuildContext context, int index) {
              final Album album = _albums[index];
              return _ArtistCard(
                album: album,
                onTap: () => context.push('/album', extra: album),
              );
            },
          ),
        ),
        const SizedBox(height: 30),
        Container(
          key: _albumsKey,
          child: const _SectionLabel(title: 'Albums'),
        ),
        const SizedBox(height: 11),
        SizedBox(
          height: 194,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _albums.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (BuildContext context, int index) {
              final Album album = _albums[index];
              return _AlbumCard(
                album: album,
                onTap: () => context.push('/album', extra: album),
              );
            },
          ),
        ),
        const SizedBox(height: 30),
        Container(
          key: _songsKey,
          child: _SectionLabel(title: 'Songs', count: allSongs.length),
        ),
        const SizedBox(height: 9),
        _IOSGroup(
          children: List<Widget>.generate(allSongs.length, (int index) {
            final Song song = allSongs[index];
            final bool isCurrent = playerState.currentSong?.id == song.id;
            final bool isFavorite =
                favorites.any((Song item) => item.id == song.id);

            return _SongRow(
              song: song,
              isCurrent: isCurrent,
              isPlaying: isCurrent && playerState.isPlaying,
              isFavorite: isFavorite,
              onTap: () => playerNotifier.playQueue(allSongs, startIndex: index),
              onFavorite: () => favoritesNotifier.toggleFavorite(song),
            );
          }),
        ),
      ],
    );
  }
}

class _LibraryOverviewCard extends StatelessWidget {
  final int songCount;
  final int playlistCount;
  final int favoriteCount;

  const _LibraryOverviewCard({
    required this.songCount,
    required this.playlistCount,
    required this.favoriteCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF0A84FF),
            Color(0xFF5E5CE6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0A84FF).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(CupertinoIcons.music_note_2, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'V2 Collection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              _OverviewValue(value: '$songCount', label: 'Songs'),
              const _OverviewDivider(),
              _OverviewValue(value: '$playlistCount', label: 'Playlists'),
              const _OverviewDivider(),
              _OverviewValue(value: '$favoriteCount', label: 'Favorites'),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewValue extends StatelessWidget {
  final String value;
  final String label;

  const _OverviewValue({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewDivider extends StatelessWidget {
  const _OverviewDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.22),
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

class _CategoryRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final int count;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      minSize: 0,
      onPressed: onTap,
      child: Row(
        children: <Widget>[
          Icon(icon, color: iconColor ?? _LibraryScreenState._accent, size: 21),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$count',
            style: TextStyle(color: _secondaryText(context), fontSize: 14),
          ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.chevron_forward,
            color: _tertiaryText(context),
            size: 15,
          ),
        ],
      ),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _PlaylistRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.62 : 1,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        minSize: 0,
        onPressed: onTap,
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _softFill(context),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: iconColor ?? _secondaryText(context),
                size: 21,
              ),
            ),
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
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: _secondaryText(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              color: _tertiaryText(context),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onDelete;

  const _SongRow({
    required this.song,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
    this.isFavorite = false,
    this.onFavorite,
    this.onDelete,
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
              fallback: _artworkFallback(context, size: 46),
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
                        ? _LibraryScreenState._accent
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 15.5,
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
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isPlaying)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                CupertinoIcons.waveform,
                color: _LibraryScreenState._accent,
                size: 19,
              ),
            ),
          if (onFavorite != null)
            CupertinoButton(
              padding: const EdgeInsets.all(7),
              minSize: 32,
              onPressed: onFavorite,
              child: Icon(
                isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                color: isFavorite
                    ? _LibraryScreenState._accent
                    : _secondaryText(context),
                size: 19,
              ),
            )
          else if (onDelete != null)
            CupertinoButton(
              padding: const EdgeInsets.all(7),
              minSize: 32,
              onPressed: onDelete,
              child: const Icon(
                CupertinoIcons.delete,
                color: Color(0xFFFF3B30),
                size: 18,
              ),
            )
          else
            Icon(
              CupertinoIcons.chevron_forward,
              color: _tertiaryText(context),
              size: 15,
            ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showProgress;

  const _EmptyRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _softFill(context),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: showProgress
                ? const CupertinoActivityIndicator(radius: 9)
                : Icon(icon, color: _secondaryText(context), size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _ArtistCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: Column(
          children: <Widget>[
            ClipOval(
              child: SongArtwork(
                source: album.imageUrl,
                width: 86,
                height: 86,
                fallback: _artworkFallback(context, size: 86, circular: true),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 145,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SongArtwork(
                source: album.imageUrl,
                width: 145,
                height: 145,
                fallback: _artworkFallback(context, size: 145),
              ),
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
              style: TextStyle(color: _secondaryText(context), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _artworkFallback(
  BuildContext context, {
  required double size,
  bool circular = false,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: _softFill(context),
      shape: circular ? BoxShape.circle : BoxShape.rectangle,
    ),
    alignment: Alignment.center,
    child: Icon(
      CupertinoIcons.music_note_2,
      color: _secondaryText(context),
      size: size * 0.34,
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
