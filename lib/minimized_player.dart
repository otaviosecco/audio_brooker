// arquivo: minimized_player.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio_handler.dart';
import 'audio_player_page.dart';
import 'dart:io';

class MinimizedPlayer extends StatelessWidget {
  const MinimizedPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioHandler = Provider.of<AudioPlayerHandler>(context);

    return StreamBuilder<bool>(
      stream: audioHandler.playbackState.map((state) => state.playing).distinct(),
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        if (!isPlaying) {
          return const SizedBox.shrink(); // Não mostra nada se não estiver tocando
        } else {
          final mediaItem = audioHandler.mediaItem.value;
          if (mediaItem == null) return const SizedBox.shrink();

          return GestureDetector(
            onTap: () {
              // Navega para a página de player completo
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AudioPlayerPage(
                    key: ValueKey<int>(int.parse(mediaItem.id)),
                    audioUrl: mediaItem.id,
                    title: mediaItem.title,
                    imageUrl: mediaItem.artUri?.toString() ?? '',
                  ),
                ),
              );
            },
            child: Container(
              color: Colors.grey[800],
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  if (mediaItem.artUri != null)
                    _buildImage(mediaItem.artUri!)
                  else
                    const Icon(
                      Icons.music_note,
                      size: 50,
                      color: Colors.white,
                    ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      mediaItem.title,
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      audioHandler.playbackState.value.playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (audioHandler.playbackState.value.playing) {
                        audioHandler.pause();
                      } else {
                        audioHandler.play();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildImage(Uri artUri) {
    if (artUri.scheme == 'asset') {
      // Se o artUri usa o esquema 'asset', carregue usando Image.asset
      return Image.asset(
        artUri.path.replaceFirst('/', ''), // Remova a primeira '/' do path
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    } else if (artUri.scheme == 'file') {
      // Se for um arquivo local, use Image.file
      return Image.file(
        File(artUri.toFilePath()),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      );
    } else {
      // Caso contrário, exiba um placeholder ou ícone padrão
      return const Icon(
        Icons.music_note,
        size: 50,
        color: Colors.white,
      );
    }
  }
}