class AudioModel {
  final String id;
  final String audioUrl;
  final String title;
  final String artist;
  final String album;
  final String coverArt;

  AudioModel({
    required this.id,
    required this.audioUrl,
    required this.title,
    required this.artist,
    required this.album,
    required this.coverArt,
  });

 // ...existing code...

  factory AudioModel.fromJson(Map<String, dynamic> json) {
    return AudioModel(
      id: json['id'].toString(),
      audioUrl: json['audioUrl'] as String? ?? '',
      title: json['title'] as String? ?? 'No Title',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      album: json['album'] as String? ?? 'Unknown Album',
      coverArt: json['coverArt'] as String? ?? '',
    );
  }
}