import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'audio_handler.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class AudioPlayerPage extends StatefulWidget {
  final String audioUrl;
  final Uint8List? imageBytes; // Add this parameter
  final String title;

  const AudioPlayerPage({
    super.key,
    required this.audioUrl,
    this.imageBytes,
    required this.title,
  });

  @override
  _AudioPlayerPageState createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  late AudioPlayerHandler audioHandler;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    audioHandler = Provider.of<AudioPlayerHandler>(context, listen: false);
    _init();
  }

  Future<void> _init() async {
    try {
      final currentMediaItem = audioHandler.mediaItem.value;
      if (currentMediaItem == null || currentMediaItem.id != widget.audioUrl) {
        await audioHandler.setAudioSource(
          widget.audioUrl, // Pass the URL directly
          widget.title,
          widget.imageBytes,
        );
        await audioHandler.play();
      }
    } catch (e) {
      print('Erro ao carregar o áudio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Button for Chapters List
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              // Implement function to show chapters list
            },
          ),
          // Button to Add Bookmark
          IconButton(
            icon: const Icon(Icons.bookmark_add),
            onPressed: () {
              // Implement function to add a bookmark
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Thumbnail
            widget.imageBytes != null
                ? buildCoverArt(widget.imageBytes)
                : const Icon(
                    Icons.music_note,
                    size: 360,
                    color: Colors.white,
                  ),
            const SizedBox(height: 24.0),

            // Progress Bar
            StreamBuilder<DurationState>(
              stream: Rx.combineLatest3<Duration, Duration, Duration, DurationState>(
                audioHandler.playbackState.map((state) => state.position),
                audioHandler.playbackState.map((state) => state.bufferedPosition),
                audioHandler.mediaItem.map((item) => item?.duration ?? Duration.zero),
                (position, bufferedPosition, total) => DurationState(
                  position: position,
                  bufferedPosition: bufferedPosition,
                  total: total,
                ),
              ),
              builder: (context, snapshot) {
                final durationState = snapshot.data;
                final position = durationState?.position ?? Duration.zero;
                final totalDuration = durationState?.total ?? Duration.zero;

                return Column(
                  children: [
                    Slider(
                      min: 0.0,
                      max: totalDuration.inMilliseconds.toDouble(),
                      value: position.inMilliseconds.toDouble().clamp(
                          0.0, totalDuration.inMilliseconds.toDouble()),
                      onChanged: (value) {
                        audioHandler.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position)),
                          Text(
                            '-${_formatDuration(totalDuration - position)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24.0),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 'Previous Audio' Button
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 36.0,
                  onPressed: audioHandler.skipToPrevious,
                ),
                // 'Rewind 30 Seconds' Button
                IconButton(
                  icon: const Icon(Icons.replay_30),
                  iconSize: 36.0,
                  onPressed: () {
                    final newPosition =
                        audioHandler.playbackState.value.position -
                            const Duration(seconds: 30);
                    audioHandler.seek(
                      newPosition >= Duration.zero ? newPosition : Duration.zero,
                    );
                  },
                ),
                // 'Play/Pause' Button
                StreamBuilder<PlaybackState>(
                  stream: audioHandler.playbackState,
                  builder: (context, snapshot) {
                    final playbackState = snapshot.data;
                    final processingState =
                        playbackState?.processingState ?? AudioProcessingState.idle;
                    final isPlaying = playbackState?.playing ?? false;

                    if (processingState == AudioProcessingState.loading ||
                        processingState == AudioProcessingState.buffering) {
                      return const CircularProgressIndicator();
                    } else if (isPlaying) {
                      return IconButton(
                        icon: const Icon(Icons.pause_circle_filled),
                        iconSize: 64.0,
                        onPressed: audioHandler.pause,
                      );
                    } else {
                      return IconButton(
                        icon: const Icon(Icons.play_circle_filled),
                        iconSize: 64.0,
                        onPressed: audioHandler.play,
                      );
                    }
                  },
                ),
                // 'Forward 30 Seconds' Button
                IconButton(
                  icon: const Icon(Icons.forward_30),
                  iconSize: 36.0,
                  onPressed: () {
                    final newPosition =
                        audioHandler.playbackState.value.position +
                            const Duration(seconds: 30);
                    final totalDuration =
                        audioHandler.mediaItem.value?.duration ?? Duration.zero;
                    audioHandler.seek(
                      newPosition <= totalDuration ? newPosition : totalDuration,
                    );
                  },
                ),
                // 'Next Audio' Button
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 36.0,
                  onPressed: audioHandler.skipToNext,
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // Playback Speed Button
            ElevatedButton.icon(
              icon: const Icon(Icons.speed),
              label: Text('Velocidade: ${_playbackSpeed}x'),
              onPressed: _showPlaybackSpeedDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCoverArt(Uint8List? coverArtBytes) {
    if (coverArtBytes == null || coverArtBytes.isEmpty) {
      return const Icon(Icons.music_note, size: 360, color: Colors.white);
    }
    try {
      final bytes = coverArtBytes;

      // Decode and resize the image
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        print('Error decoding image');
        return const Icon(Icons.music_note, size: 360, color: Colors.white);
      }
      img.Image resizedImage =
          img.copyResize(originalImage, width: 350, height: 350);
      final resizedBytes = Uint8List.fromList(img.encodeJpg(resizedImage));

      return Image.memory(
        resizedBytes,
        width: 360,
        height: 360,
        fit: BoxFit.cover,
      );
    } catch (e) {
      print('Error decoding cover art: $e');
      return const Icon(Icons.music_note, size: 360, color: Colors.white);
    }
  }

  // Change Playback Speed
  void _changePlaybackSpeed(double? speed) {
    if (speed != null) {
      setState(() {
        _playbackSpeed = speed;
        audioHandler.setSpeed(speed);
      });
      Navigator.pop(context);
    }
  }

  // Show Dialog to Select Playback Speed
  void _showPlaybackSpeedDialog() {
    showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Velocidade de Reprodução'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<double>(
                title: const Text('0.5x'),
                value: 0.5,
                groupValue: _playbackSpeed,
                onChanged: _changePlaybackSpeed,
              ),
              RadioListTile<double>(
                title: const Text('1.0x'),
                value: 1.0,
                groupValue: _playbackSpeed,
                onChanged: _changePlaybackSpeed,
              ),
              RadioListTile<double>(
                title: const Text('1.5x'),
                value: 1.5,
                groupValue: _playbackSpeed,
                onChanged: _changePlaybackSpeed,
              ),
              RadioListTile<double>(
                title: const Text('2.0x'),
                value: 2.0,
                groupValue: _playbackSpeed,
                onChanged: _changePlaybackSpeed,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  // Format Duration
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }
}

class DurationState {
  final Duration position;
  final Duration bufferedPosition;
  final Duration total;

  DurationState({
    required this.position,
    required this.bufferedPosition,
    required this.total,
  });
}