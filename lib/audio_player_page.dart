// arquivo: audio_player_page.dart

import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:io';
import 'audio_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:provider/provider.dart';

class AudioPlayerPage extends StatefulWidget {
  final String audioPath;
  final String? imagePath;
  final String title;

  const AudioPlayerPage({
    super.key,
    required this.audioPath,
    this.imagePath,
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
      if (currentMediaItem == null || currentMediaItem.id != widget.audioPath) {
        await audioHandler.setAudioSource(
          widget.audioPath,
          widget.title,
          widget.imagePath,
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
          // Botão para Lista de Capítulos
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              // Implementar função para mostrar a lista de capítulos
            },
          ),
          // Botão para Adicionar Marcador
          IconButton(
            icon: const Icon(Icons.bookmark_add),
            onPressed: () {
              // Implementar função para adicionar um marcador
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Thumbnail
            if (widget.imagePath != null)
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  image: DecorationImage(
                    image: widget.imagePath!.startsWith('assets/')
                        ? AssetImage(widget.imagePath!) as ImageProvider
                        : FileImage(File(widget.imagePath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              const Icon(
                Icons.music_note,
                size: 200,
              ),
            const SizedBox(height: 24.0),

            // Barra de progresso
            StreamBuilder<DurationState>(
              stream: _durationStateStream,
              builder: (context, snapshot) {
                final durationState = snapshot.data;
                final position = durationState?.position ?? Duration.zero;
                final totalDuration = durationState?.total ?? Duration.zero;

                return Column(
                  children: [
                    Slider(
                      min: 0.0,
                      max: totalDuration.inMilliseconds.toDouble(),
                      value: position.inMilliseconds
                          .clamp(0.0, totalDuration.inMilliseconds.toDouble())
                          .toDouble(),
                      onChanged: (value) {
                        audioHandler.seek(
                            Duration(milliseconds: value.toInt()));
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

            // Botões de controle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botão 'Voltar Áudio'
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 36.0,
                  onPressed: audioHandler.skipToPrevious,
                ),
                // Botão 'Voltar 30 Segundos'
                IconButton(
                  icon: const Icon(Icons.replay_30),
                  iconSize: 36.0,
                  onPressed: () {
                    final newPosition = audioHandler
                            .playbackState.value.position -
                        const Duration(seconds: 30);
                    audioHandler.seek(
                      newPosition >= Duration.zero
                          ? newPosition
                          : Duration.zero,
                    );
                  },
                ),
                // Botão 'Play/Pause'
                StreamBuilder<PlaybackState>(
                  stream: audioHandler.playbackState,
                  builder: (context, snapshot) {
                    final playbackState = snapshot.data;
                    final processingState = playbackState?.processingState ??
                        AudioProcessingState.idle;
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
                // Botão 'Avançar 30 Segundos'
                IconButton(
                  icon: const Icon(Icons.forward_30),
                  iconSize: 36.0,
                  onPressed: () {
                    final newPosition = audioHandler
                            .playbackState.value.position +
                        const Duration(seconds: 30);
                    final totalDuration =
                        audioHandler.mediaItem.value?.duration ??
                            Duration.zero;
                    audioHandler.seek(
                      newPosition <= totalDuration
                          ? newPosition
                          : totalDuration,
                    );
                  },
                ),
                // Botão 'Avançar Áudio'
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 36.0,
                  onPressed: audioHandler.skipToNext,
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // Botão de Velocidade de Reprodução
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

  // Stream de estado de duração
  Stream<DurationState> get _durationStateStream =>
      Rx.combineLatest2<Duration, MediaItem?, DurationState>(
        AudioService.position,
        audioHandler.mediaItem,
        (position, mediaItem) => DurationState(
          position: position,
          bufferedPosition:
              audioHandler.playbackState.value.bufferedPosition,
          total: mediaItem?.duration ?? Duration.zero,
        ),
      );

  // Mostrar diálogo para selecionar a velocidade de reprodução
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

  // Alterar velocidade de reprodução
  void _changePlaybackSpeed(double? speed) {
    if (speed != null) {
      setState(() {
        _playbackSpeed = speed;
        audioHandler.setSpeed(speed);
      });
      Navigator.pop(context);
    }
  }

  // Formatação da duração
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
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