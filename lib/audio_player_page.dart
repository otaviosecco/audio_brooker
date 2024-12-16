import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:io';
import 'audio_handler.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerPage extends StatefulWidget {
  final String audioUrl;
  final String imageUrl;
  final String title;

  const AudioPlayerPage({
    super.key,
    required this.audioUrl,
    required this.imageUrl,
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
          widget.audioUrl,   // Passa a URL diretamente
          widget.title,
          widget.imageUrl,
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
            StreamBuilder<MediaItem?>(
              stream: audioHandler.mediaItem,
              builder: (context, snapshot) {
                final mediaItem = snapshot.data;
                if (mediaItem?.artUri != null) {
                  return _buildImage(mediaItem!.artUri!);
                } else {
                  return const Icon(
                    Icons.music_note,
                    size: 50,
                    color: Colors.white,
                  );
                }
              },
            ),
            const SizedBox(height: 24.0),

            // Barra de progresso
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
                      value: position.inMilliseconds.toDouble().clamp(0.0, totalDuration.inMilliseconds.toDouble()),
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
                          Text('-${_formatDuration(totalDuration - position)}',
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
                    final newPosition = audioHandler.playbackState.value.position - const Duration(seconds: 30);
                    audioHandler.seek(
                      newPosition >= Duration.zero ? newPosition : Duration.zero,
                    );
                  },
                ),
                // Botão 'Play/Pause'
                StreamBuilder<PlaybackState>(
                  stream: audioHandler.playbackState,
                  builder: (context, snapshot) {
                    final playbackState = snapshot.data;
                    final processingState = playbackState?.processingState ?? AudioProcessingState.idle;
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
                    final newPosition = audioHandler.playbackState.value.position + const Duration(seconds: 30);
                    final totalDuration = audioHandler.mediaItem.value?.duration ?? Duration.zero;
                    audioHandler.seek(
                      newPosition <= totalDuration ? newPosition : totalDuration,
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

  Widget _buildImage(Uri artUri) {
    if (artUri.scheme == 'asset') {
      // Se o artUri usa o esquema 'asset', carregue usando Image.asset
      return Image.asset(
        artUri.path.replaceFirst('/', ''), // Remova a primeira '/' do path
        width: 350,
        height: 350,
        fit: BoxFit.cover,
      );
    } else if (artUri.scheme == 'file') {
      // Se for um arquivo local, use Image.file
      return Image.file(
        File(artUri.toFilePath()),
        width: 350,
        height: 350,
        fit: BoxFit.cover,
      );
    } else {
      // Caso contrário, exiba um placeholder ou ícone padrão
      return const Icon(
        Icons.music_note,
        size: 350,
        color: Colors.white,
      );
    }
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