import 'package:v2/models/song.dart';

class Album {
  final String id;
  final String title;
  final String artist;
  final String imageUrl;
  final List<Song> songs;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    required this.imageUrl,
    required this.songs,
  });
}