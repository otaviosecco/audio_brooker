import 'dart:io';

import 'package:file_picker/file_picker.dart';
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

  Future<void> fetchAudioList() async {
    try {
      List<dynamic> jsonResponse = await ApiService.fetchAudioList();
      setState(() {
        audioList = jsonResponse.map((audio) => AudioModel.fromJson(audio)).toList();
      });
    } catch (e) {
      throw Exception('Failed to load audio list');
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = Provider.of<AudioPlayerHandler>(context);

    void _openAudioPlayer(Map<String, dynamic> audioItem) {
      final currentMediaItem = audioHandler.mediaItem.value;
      if (currentMediaItem != null && currentMediaItem.id == audioItem['audioUrl']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlayerPage(
              audioUrl: audioItem['audioUrl'],
              title: audioItem['title'],
              imageUrl: audioItem['imageUrl'],
            ),
          ),
        );
      } else {
        audioHandler.stop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlayerPage(
              audioUrl: audioItem['audioUrl'],
              title: audioItem['title'],
              imageUrl: audioItem['imageUrl'],
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
            leading: Image.network(
              audioItem.imageUrl,
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
            ),
            title: Text(audioItem.title),
            onTap: () => _openAudioPlayer({
              'audioUrl': audioItem.audioUrl,
              'title': audioItem.title,
              'imageUrl': audioItem.imageUrl,
            }),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAudioDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddAudioDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adicionar Áudio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: _addAudioFromAssets,
                child: const Text('Selecionar Áudio dos Assets'),
              ),
              ElevatedButton(
                onPressed: _addAudioFromFile,
                child: const Text('Selecionar Áudio do Arquivo'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addAudioFromAssets() async {
    Navigator.of(context).pop();

    List<Map<String, String>> assetsList = [
      {
        'title': 'Áudio de Asset',
        'audioPath': 'assets/audios/RenanAud.mp3',
        'imagePath': 'asset:///assets/images/RenanImg.png',
      },
      // Adicione mais áudios dos assets se necessário
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecionar Áudio dos Assets'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: assetsList.map((asset) {
              return ListTile(
                leading: _buildImage(Uri.parse(asset['imagePath']!)),
                title: Text(asset['title']!),
                onTap: () {
                  setState(() {
                    audioList.add(AudioModel.fromJson(asset));
                  });
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _addAudioFromFile() async {
    Navigator.of(context).pop();

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      String audioPath = result.files.single.path!;
      String? title = result.files.single.name;

      FilePickerResult? imageResult = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      String? imagePath = imageResult?.files.single.path;

      String? imageUri;
      if (imagePath != null) {
        if (imagePath.startsWith('assets/')) {
          imageUri = 'asset:///$imagePath';
        } else {
          imageUri = Uri.file(imagePath).toString();
        }
      }

      setState(() {
        audioList.add(AudioModel(
          id: audioList.length + 1,
          title: title ?? 'Sem Título',
          audioUrl: audioPath,
          imageUrl: imageUri ?? '',
        ));
      });
    }
  }

  Widget _buildImage(Uri artUri) {
    if (artUri.scheme == 'asset') {
      return Image.asset(
        artUri.path.replaceFirst('/', ''),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    } else if (artUri.scheme == 'file') {
      return Image.file(
        File(artUri.toFilePath()),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    } else {
      return const Icon(
        Icons.music_note,
        size: 50,
        color: Colors.white,
      );
    }
  }
}