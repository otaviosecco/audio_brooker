import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'http/api_service.dart';
import 'providers/audio_handler.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

// adicionado:
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

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

  // Para armazenar capítulos
  List<dynamic> _chapters = [];
  // Para armazenar dados locais do usuário (posições salvas, etc.)
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _initAudioHandler();
    _initChapters();
  }

  Future<void> _initAudioHandler() async {
    audioHandler = Provider.of<AudioPlayerHandler>(context, listen: false);
    try {
      // Verifica se nada está em reprodução
      if (audioHandler.mediaItem.value?.id != widget.audioUrl) {
        await audioHandler.stop();
        await audioHandler.updateQueue([]);
        // Carrega o áudio atual
        await audioHandler.addQueueItem(
          MediaItem(
            id: widget.audioUrl,
            album: "",
            title: widget.title,
            artUri: Uri.parse(widget.audioUrl),
          ),
        );
        await audioHandler.play();
      }
    } catch (e) {
      print('Erro ao carregar o áudio: $e');
    }
  }

  // Carrega capítulos
  Future<void> _initChapters() async {
    await _loadUserData();
    final filename = widget.title.replaceAll(' ', '%20');
    try {
      // Tenta buscar os capítulos no backend
      final apiService = ApiService();
      final responseChapters = await ApiService.fetchChapters(filename);
      _chapters = responseChapters;
    } catch (e) {
      // Se falhar, define capítulos vazios
      _chapters = [];
    }
    _resumePositionIfAvailable();
  }

  // Tenta retomar a posição caso exista
  void _resumePositionIfAvailable() {
    final lastPos = _userData[widget.audioUrl]?.toString() ?? '0';
    if (audioHandler.playbackState.value.position == Duration.zero && lastPos != '0') {
      audioHandler.seek(Duration(seconds: int.tryParse(lastPos) ?? 0));
    }
  }

  // Carrega dados locais (posições de cada áudio)
  Future<void> _loadUserData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/user_data.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        _userData = json.decode(contents);
      }
    } catch (e) {
      _userData = {};
    }
  }

  // Salva dados locais (posição atual do áudio)
  Future<void> _saveUserData() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/user_data.json');
      await file.writeAsString(json.encode(_userData));
    } catch (e) {
      // handle error
    }
  }

  @override
  void dispose() {
    final currentPos = audioHandler.playbackState.value.position.inSeconds;
    _userData[widget.audioUrl] = currentPos;
    _saveUserData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pop();
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              // Exibir lista de capítulos
              _showChaptersDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add),
            onPressed: () {
              // Implementar função para adicionar um bookmark
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
                      value: position.inMilliseconds
                          .toDouble()
                          .clamp(0.0, totalDuration.inMilliseconds.toDouble()),
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
                    final newPosition = audioHandler.playbackState.value.position -
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
                    final newPosition = audioHandler.playbackState.value.position +
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

  // Exibe lista de capítulos
  void _showChaptersDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Capítulos'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: _chapters.length,
              itemBuilder: (context, index) {
                final chapter = _chapters[index];
                return ListTile(
                  title: Text(chapter['title'] ?? 'Chapter'),
                  onTap: () {
                    Navigator.of(context).pop();
                    final startTime = chapter['start_time'] ?? 0;
                    audioHandler.seek(Duration(seconds: startTime));
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget buildCoverArt(Uint8List? coverArtBytes) {
    if (coverArtBytes == null || coverArtBytes.isEmpty) {
      return const Icon(Icons.music_note, size: 360, color: Colors.white);
    }
    try {
      final bytes = coverArtBytes;
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) {
        print('Error decoding image');
        return const Icon(Icons.music_note, size: 360, color: Colors.white);
      }
      img.Image resizedImage = img.copyResize(originalImage, width: 350, height: 350);
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final twoMin = twoDigits(duration.inMinutes.remainder(60));
    final twoSec = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoMin:$twoSec';
  }

  void _changePlaybackSpeed(double? speed) {
    if (speed != null) {
      setState(() {
        _playbackSpeed = speed;
        audioHandler.setSpeed(speed);
      });
      Navigator.pop(context);
    }
  }

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
        );
      },
    );
  }
}

// Classe para gerenciar duração (auxiliar)
class DurationState {
  final Duration position;
  final Duration bufferedPosition;
  final Duration total;

  const DurationState({
    required this.position,
    required this.bufferedPosition,
    required this.total,
  });
}