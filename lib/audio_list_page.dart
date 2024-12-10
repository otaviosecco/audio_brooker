import 'package:audio_brooker/audio_handler.dart';
import 'package:audio_brooker/audio_player_page.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';



class AudioListPage extends StatefulWidget {
  final AudioPlayerHandler audioHandler;

  const AudioListPage({super.key, required this.audioHandler});

  @override
  _AudioListPageState createState() => _AudioListPageState();
}


class _AudioListPageState extends State<AudioListPage> {
  List<Map<String, String>> audioList = [
    {
      'title': 'SABOR DE MORANGUIN',
      'audioPath': 'assets/audios/RenanAud.mp3',
      'imagePath': 'assets/images/RenanImg.png',
    },
    // Adicione mais áudios dos assets se necessário
  ];

  @override
 Widget build(BuildContext context) {
    final audioHandler = Provider.of<AudioPlayerHandler>(context);

    void _openAudioPlayer(Map<String, dynamic> audioItem) {
      final currentMediaItem = audioHandler.mediaItem.value;
      if (currentMediaItem != null && currentMediaItem.id == audioItem['audioPath']) {
        // Se for o mesmo áudio, apenas navegue para a página do player
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlayerPage(
              audioPath: audioItem['audioPath'],
              title: audioItem['title'],
              imagePath: audioItem['imagePath'],
            ),
          ),
        );
      } else {
        // Se for um áudio diferente, configure o novo áudio
        audioHandler.stop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlayerPage(
              audioPath: audioItem['audioPath'],
              title: audioItem['title'],
              imagePath: audioItem['imagePath'],
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
            title: Text(audioItem['title'] ?? 'Unknown Title'),
            onTap: () => _openAudioPlayer(audioItem),
          );
        },
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
    // Fechar o diálogo
    Navigator.of(context).pop();

    // Lista de áudios e imagens disponíveis nos assets
    List<Map<String, String>> assetsList = [
      {
        'title': 'Áudio de Asset',
        'audioPath': 'assets/audios/RenanAud.mp3',
        'imagePath': 'assets/images/RenanImg.jpg',
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
                leading: Image.asset(
                  asset['imagePath']!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text(asset['title']!),
                onTap: () {
                  setState(() {
                    audioList.add(asset);
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
    // Fechar o diálogo
    Navigator.of(context).pop();

    // Selecionar arquivo de áudio
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      String audioPath = result.files.single.path!;
      String? title = result.files.single.name;

      // Selecionar imagem (opcional)
      FilePickerResult? imageResult = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      String? imagePath =
          imageResult?.files.single.path;

      setState(() {
        audioList.add({
          'title': title,
          'audioPath': audioPath,
          if (imagePath != null) 'imagePath': imagePath,
        });
      });
    }
  }
}
