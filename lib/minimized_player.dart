import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'audio_player_page.dart';

class MinimizedPlayer extends StatefulWidget {
  final MediaItem mediaItem;

  const MinimizedPlayer({Key? key, required this.mediaItem}) : super(key: key);

  @override
  _MinimizedPlayerState createState() => _MinimizedPlayerState();
}

class _MinimizedPlayerState extends State<MinimizedPlayer> {
  bool _isNavigating = false; // Flag to prevent multiple navigations

  void _navigateToPlayer() async {
    if (_isNavigating) return; // Prevent if already navigating
    setState(() {
      _isNavigating = true;
    });
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioPlayerPage(
            audioUrl: widget.mediaItem.id,
            title: widget.mediaItem.title,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToPlayer,
      child: Container(
        color: Colors.grey[800],
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            if (widget.mediaItem.imageBytes != null)
              Image.memory(
                widget.mediaItem.imageBytes!,
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
                widget.mediaItem.title,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              onPressed: () {
                // Implement play functionality without triggering navigation
              },
            ),
          ],
        ),
      ),
    );
  }
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