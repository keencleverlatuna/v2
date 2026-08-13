import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:v2/models/song.dart';
import 'package:v2/providers/player/player_provider.dart';
import 'package:v2/widgets/media/song_artwork.dart';

class RadioScreen extends ConsumerWidget {
  final ScrollController? scrollController;

  const RadioScreen({
    super.key,
    this.scrollController,
  });

  static const List<Song> stations = <Song>[
    Song(
      id: 'radio-night-drive',
      title: 'Night Drive',
      artist: 'V2 Radio',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      artworkUrl: 'https://picsum.photos/seed/nightdrive-radio/800/800',
    ),
    Song(
      id: 'radio-chill',
      title: 'Chill Waves',
      artist: 'V2 Radio',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      artworkUrl: 'https://picsum.photos/seed/chill-radio/800/800',
    ),
    Song(
      id: 'radio-focus',
      title: 'Focus Flow',
      artist: 'V2 Radio',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
      artworkUrl: 'https://picsum.photos/seed/focus-radio/800/800',
    ),
    Song(
      id: 'radio-pop',
      title: 'Pop Central',
      artist: 'V2 Radio',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
      artworkUrl: 'https://picsum.photos/seed/pop-radio/800/800',
    ),
    Song(
      id: 'radio-sunset',
      title: 'Sunset Sessions',
      artist: 'V2 Radio',
      audioUrl:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
      artworkUrl: 'https://picsum.photos/seed/sunset-radio/800/800',
    ),
  ];

  static const List<List<Color>> _stationGradients = <List<Color>>[
    <Color>[Color(0xFF0A84FF), Color(0xFF5E5CE6)],
    <Color>[Color(0xFF30B0C7), Color(0xFF34C759)],
    <Color>[Color(0xFF5E5CE6), Color(0xFFBF5AF2)],
    <Color>[Color(0xFFFF375F), Color(0xFFFF9F0A)],
    <Color>[Color(0xFFFF9F0A), Color(0xFFFF453A)],
  ];

  static const List<IconData> _stationIcons = <IconData>[
    CupertinoIcons.moon_fill,
    CupertinoIcons.waveform,
    CupertinoIcons.bolt_fill,
    CupertinoIcons.music_note_2,
    CupertinoIcons.star_fill,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);
    final Song featured = stations.first;
    final bool featuredCurrent = playerState.currentSong?.id == featured.id;
    final bool featuredPlaying = featuredCurrent && playerState.isPlaying;

    Future<void> playStation(int index, {bool openPlayer = true}) async {
      final Song station = stations[index];
      final bool isCurrent = playerState.currentSong?.id == station.id;

      if (isCurrent) {
        await playerNotifier.togglePlayPause();
      } else {
        await playerNotifier.playQueue(stations, startIndex: index);
      }

      if (openPlayer && context.mounted) {
        context.push('/now-playing');
      }
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 190),
      children: <Widget>[
        _RadioHero(
          station: featured,
          isPlaying: featuredPlaying,
          onTap: () => playStation(0),
          onPlay: () => playStation(0, openPlayer: false),
        ),
        const SizedBox(height: 28),
        const _RadioSectionTitle(
          title: 'Choose a Station',
          subtitle: 'Stream a mood made for the moment',
        ),
        const SizedBox(height: 13),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stations.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.18,
          ),
          itemBuilder: (BuildContext context, int index) {
            final Song station = stations[index];
            final bool isCurrent = playerState.currentSong?.id == station.id;
            return _StationCard(
              station: station,
              colors: _stationGradients[index],
              icon: _stationIcons[index],
              isCurrent: isCurrent,
              isPlaying: isCurrent && playerState.isPlaying,
              onTap: () => playStation(index),
            );
          },
        ),
        const SizedBox(height: 28),
        const _RadioSectionTitle(
          title: 'Now Available',
          subtitle: 'Five continuous V2 streams',
        ),
        const SizedBox(height: 10),
        _StationSummary(
          stations: stations,
          currentSongId: playerState.currentSong?.id,
          isPlaying: playerState.isPlaying,
          onSelected: (int index) => playStation(index),
        ),
      ],
    );
  }
}

class _RadioHero extends StatelessWidget {
  final Song station;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const _RadioHero({
    required this.station,
    required this.isPlaying,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 196,
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF101A3B),
              Color(0xFF234E9A),
              Color(0xFF30B0C7),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF0A84FF).withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SongArtwork(
                source: station.artworkUrl,
                width: 116,
                height: 158,
                fallback: Container(
                  width: 116,
                  height: 158,
                  color: Colors.white.withValues(alpha: 0.12),
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.antenna_radiowaves_left_right,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'LIVE • V2 RADIO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    station.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Continuous music stream',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: onPlay,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isPlaying
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_fill,
                        color: const Color(0xFF18386F),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _RadioSectionTitle({required this.title, required this.subtitle});

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

class _StationCard extends StatelessWidget {
  final Song station;
  final List<Color> colors;
  final IconData icon;
  final bool isCurrent;
  final bool isPlaying;
  final VoidCallback onTap;

  const _StationCard({
    required this.station,
    required this.colors,
    required this.icon,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: isCurrent
                ? Colors.white.withValues(alpha: 0.76)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.17),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const Spacer(),
                Icon(
                  isPlaying
                      ? CupertinoIcons.waveform
                      : CupertinoIcons.play_fill,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
            const Spacer(),
            Text(
              station.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              isCurrent ? 'Now selected' : 'Tap to listen',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationSummary extends StatelessWidget {
  final List<Song> stations;
  final String? currentSongId;
  final bool isPlaying;
  final Future<void> Function(int index) onSelected;

  const _StationSummary({
    required this.stations,
    required this.currentSongId,
    required this.isPlaying,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];

    for (int index = 0; index < stations.length; index++) {
      final Song station = stations[index];
      final bool isCurrent = currentSongId == station.id;
      rows.add(
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          minSize: 0,
          onPressed: () => onSelected(index),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: RadioScreen._stationGradients[index],
                  ),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  RadioScreen._stationIcons[index],
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      station.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent
                            ? const Color(0xFF5E5CE6)
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      station.artist,
                      style: TextStyle(
                        color: _secondaryText(context),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isCurrent && isPlaying
                    ? CupertinoIcons.waveform
                    : CupertinoIcons.chevron_forward,
                color: isCurrent
                    ? const Color(0xFF5E5CE6)
                    : _tertiaryText(context),
                size: 17,
              ),
            ],
          ),
        ),
      );

      if (index < stations.length - 1) {
        rows.add(
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
        child: Column(children: rows),
      ),
    );
  }
}

Color _groupFill(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1C1C1E)
      : Colors.white;
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
