// ignore_for_file: library_private_types_in_public_api

import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio_handler.dart';
import 'audio_player_page.dart';
import 'package:image/image.dart' as img;

class MinimizedPlayer extends StatefulWidget {
  final MediaItem? mediaItem; // Make mediaItem nullable
  const MinimizedPlayer({super.key, this.mediaItem});
  
  @override
  _MinimizedPlayerState createState() => _MinimizedPlayerState();
}

class _MinimizedPlayerState extends State<MinimizedPlayer> {
  bool _isNavigating = false; // Flag to prevent multiple navigations

  void _navigateToPlayer() async {
    if (_isNavigating || widget.mediaItem == null) return; // Prevent if already navigating or no media
    setState(() {
      _isNavigating = true;
    });
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AudioPlayerPage(
            audioUrl: widget.mediaItem!.id,
            title: widget.mediaItem!.title,
            imageBytes: widget.mediaItem!.extras?['imageBytes'], // Adjust as needed
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
    if (widget.mediaItem == null) {
      return const SizedBox.shrink(); // Return empty widget if no media
    }

    return GestureDetector(
      onTap: _navigateToPlayer,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            if (widget.mediaItem!.extras != null && widget.mediaItem!.extras!['imageBytes'] != null)
              Image.memory(
                widget.mediaItem!.extras!['imageBytes'],
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
                widget.mediaItem!.title,
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              onPressed: () {
                // Implement play functionality without triggering navigation
                // For example:
                // context.read<AudioPlayerHandler>().play();
                // Ensure audioHandler is accessible here
                final audioHandler = Provider.of<AudioPlayerHandler>(context, listen: false);
                audioHandler.play();
              },
            ),
          ],
        ),
      ),
    );
  }
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
      return Icon(Icons.music_note, size: 40);
    }
  }