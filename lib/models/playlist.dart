import 'package:v2/models/song.dart';

class MelodyPlaylist {
  final String id;
  final String name;
  final List<Song> songs;

  const MelodyPlaylist({
    required this.id,
    required this.name,
    this.songs = const [],
  });

  MelodyPlaylist copyWith({
    String? id,
    String? name,
    List<Song>? songs,
  }) {
    return MelodyPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      songs: songs ?? this.songs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songs': songs
          .map((song) => song.toJson())
          .toList(),
    };
  }

  factory MelodyPlaylist.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawSongs =
        json['songs'] as List<dynamic>? ?? [];

    return MelodyPlaylist(
      id: json['id'] as String,
      name: json['name'] as String,
      songs: rawSongs
          .map(
            (item) => Song.fromJson(
          Map<String, dynamic>.from(
            item as Map,
          ),
        ),
      )
          .toList(),
    );
  }
}