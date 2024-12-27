import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart'; // Add this import
import 'package:image/image.dart' as img; // Add this import
import 'classes/ytdl_notifier.dart';
import 'providers/audio_handler.dart';
import 'audio_player_page.dart';
import 'classes/audio_model.dart';
import 'http/api_service.dart';
import 'minimized_player.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<YtdlNotifier>(context, listen: false).addListener(_onYtdlUpdate);
      fetchAudioList(); // Optionally fetch the list on init
    });
  }

  @override
  void dispose() {
    Provider.of<YtdlNotifier>(context, listen: false).removeListener(_onYtdlUpdate);
    super.dispose();
  }

  void _onYtdlUpdate() {
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
      setState(() => audioList = []);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = Provider.of<AudioPlayerHandler>(context);

    void _openAudioPlayer(AudioModel audioItem, Uint8List? resizedImage) {
      final currentMediaItem = audioHandler.mediaItem.value;
      if (currentMediaItem != null && currentMediaItem.id == audioItem.audioUrl) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlayerPage(
              audioUrl: audioItem.audioUrl,
              title: audioItem.title,
              imageBytes: resizedImage, // Pass resized image bytes
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
              imageBytes: resizedImage, // Pass resized image bytes
            ),
          ),
        );
      }
    }

    return ChangeNotifierProvider<YtdlNotifier>(
      create: (context) => YtdlNotifier(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lista de Áudios'),
        ),
        body: Stack(
          children: [
            ListView.builder(
              itemCount: audioList.length,
              itemBuilder: (context, index) {
                final audioItem = audioList[index];
                return ListTile(
                  leading: buildCoverArt(audioItem.coverArt, (resizedImage) {}),
                  title: Text(audioItem.title),
                  onTap: () {
                    buildCoverArt(audioItem.coverArt, (resizedImage) {
                      _openAudioPlayer(audioItem, resizedImage);
                    });
                  },
                );
              },
            ),
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                ListView.builder(
                  itemCount: audioList.length,
                  itemBuilder: (context, index) {
                    final audioItem = audioList[index];
                    return ListTile(
                      leading: buildCoverArt(audioItem.coverArt, (resizedImage) {}),
                      title: Text(audioItem.title),
                      onTap: () {
                        buildCoverArt(audioItem.coverArt, (resizedImage) {
                          _openAudioPlayer(audioItem, resizedImage);
                        });
                      },
                    );
                  },
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.grey, // Add background color here
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            alignment: Alignment.center,
                            onPressed: () async {
                              final TextEditingController ytLinkController = TextEditingController();
                              final ytLink = await showDialog<String>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('YouTube Link'),
                                    content: TextField(
                                      controller: ytLinkController,
                                      decoration: const InputDecoration(hintText: 'Enter YouTube link here'),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('Cancel'),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                      TextButton(
                                        child: const Text('OK'),
                                        onPressed: () => Navigator.of(context).pop(ytLinkController.text),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (ytLink != null && ytLink.isNotEmpty) {
                                // Handle the YouTube link here
                                final apiService = ApiService();
                                apiService.addFromYoutube(ytLink, context.read<YtdlNotifier>());
                              }
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ),
                      ),
                      StreamBuilder<MediaItem?>(
                        stream: audioHandler.mediaItem,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return MinimizedPlayer(mediaItem: snapshot.data!);
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],            
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCoverArt(String? coverArtBase64, Function(Uint8List?) onImageReady) {
    if (coverArtBase64 == null || coverArtBase64.isEmpty) {
      return const Icon(Icons.music_note, size: 40);
    }
    try {
      String base64String = coverArtBase64.contains(',')
          ? coverArtBase64.split(',').last
          : coverArtBase64;
      final bytes = base64Decode(base64String);

      // Decode and resize the image
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        print('Error decoding image');
        onImageReady(null);
        return const Icon(Icons.music_note, size: 40);
      }
      img.Image resizedImage = img.copyResize(originalImage, width: 350, height: 350);
      final resizedBytes = Uint8List.fromList(img.encodeJpg(resizedImage));

      // Pass the resized image bytes to AudioPlayerPage
      onImageReady(resizedBytes);

      return Image.memory(resizedBytes, width: 40, height: 40, fit: BoxFit.cover);
    } catch (e) {
      print('Error decoding cover art: $e');
      onImageReady(null);
      return const Icon(Icons.music_note, size: 40);
    }
  }
}