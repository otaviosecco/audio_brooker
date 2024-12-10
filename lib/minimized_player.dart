import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio_handler.dart';
import 'audio_player_page.dart';

class MinimizedPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final audioHandler = Provider.of<AudioPlayerHandler>(context);

    return StreamBuilder<bool>(
      stream: audioHandler.playbackState.map((state) => state.playing).distinct(),
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        if (!isPlaying) {
          return SizedBox.shrink(); // Não mostra nada se não estiver tocando
        } else {
          final mediaItem = audioHandler.mediaItem.value;
          if (mediaItem == null) return SizedBox.shrink();

          return GestureDetector(
            onTap: () {
              // Navega para a página de player completo
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AudioPlayerPage(
                    audioPath: mediaItem.id,
                    title: mediaItem.title,
                    imagePath: mediaItem.artUri?.toString(),
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
                    Image.file(
                      File(mediaItem.artUri!.path),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
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
}