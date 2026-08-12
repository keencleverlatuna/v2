class Song {
  final String id;
  final String title;
  final String artist;
  final String audioUrl;
  final String? artworkUrl;
  final String? lyrics;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    this.artworkUrl,
    this.lyrics,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audioUrl': audioUrl,
      'artworkUrl': artworkUrl,
      'lyrics': lyrics,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      audioUrl: json['audioUrl'] as String,
      artworkUrl: json['artworkUrl'] as String?,
      lyrics: json['lyrics'] as String?,
    );
  }
}