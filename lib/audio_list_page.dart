import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio_handler.dart';
import 'audio_player_page.dart';
import 'audio_model.dart';
import 'http/api_service.dart';

class AudioListPage extends StatefulWidget {
  final AudioPlayerHandler audioHandler;

  const AudioListPage({super.key, required this.audioHandler});

  @override
  _AudioListPageState createState() => _AudioListPageState();
}

class _AudioListPageState extends State<AudioListPage> {
  List<AudioModel> audioList = [];

  @override
  void initState() {
    super.initState();
    fetchAudioList();
  }

  Future<List<AudioModel>> fetchAudioList() async {
    try {
      List<AudioModel> fetchedAudioList = await ApiService.fetchAudioList();
      setState(() {
        audioList = fetchedAudioList;
      });
      return audioList;
    } catch (e) {
      debugPrint('Error fetching audio list: $e');
      setState(() {
        audioList = [];
      });
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = Provider.of<AudioPlayerHandler>(context);

    void _openAudioPlayer(AudioModel audioItem) {
      final currentMediaItem = audioHandler.mediaItem.value;
      if (currentMediaItem != null && currentMediaItem.id == audioItem.audioUrl) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlayerPage(
              audioUrl: audioItem.audioUrl,
              title: audioItem.title,
              imageUrl: audioItem.coverArt,
            ),
          ),
        );
      } else {
        audioHandler.stop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlayerPage(
              audioUrl: audioItem.audioUrl,
              title: audioItem.title,
              imageUrl: audioItem.coverArt,
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Áudios'),
      ),
      body: ListView.builder(
        itemCount: audioList.length,
        itemBuilder: (context, index) {
          final audioItem = audioList[index];
          return ListTile(
            leading: audioItem.coverArt.isNotEmpty
                ? Image.network(
                    audioItem.coverArt,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.music_note,
                        size: 50,
                        color: Colors.white,
                      );
                    },
                  )
                : const Icon(
                    Icons.music_note,
                    size: 50,
                    color: Colors.white,
                  ),
            title: Text(audioItem.title),
            onTap: () => _openAudioPlayer(audioItem),
          );
        },
      ),
    );
  }

  Widget buildCoverArt(String coverArtBase64) {
    if (coverArtBase64.isEmpty) {
      return const Icon(Icons.music_note); // Ícone padrão caso não haja capa
    } else {
      final bytes = base64Decode(coverArtBase64.split(',').last);
      return Image.memory(bytes, fit: BoxFit.cover);
    }
  }
}