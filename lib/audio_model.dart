class AudioModel {
  final int id;
  final String title;
  final String audioUrl;
  final String imageUrl;

  AudioModel({
    required this.id,
    required this.title,
    required this.audioUrl,
    required this.imageUrl,
  });

  factory AudioModel.fromJson(Map<String, dynamic> json) {
    return AudioModel(
      id: json['id'],
      title: json['title'],
      audioUrl: json['audioUrl'],
      imageUrl: json['imageUrl'],
    );
  }
}