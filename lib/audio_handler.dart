import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:rxdart/rxdart.dart';

class DurationState {
  final Duration position;
  final Duration bufferedPosition;
  final Duration total;

  DurationState({required this.position, required this.bufferedPosition, required this.total});
}

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  // BehaviorSubject para controle de duração
  final _durationState = BehaviorSubject<DurationState>();

  AudioPlayerHandler() {
    // Listen to playback events from the player
    _player.playbackEventStream.listen(_broadcastPlaybackEvent, onError: (error) {
      // Handle errors
      print('Error in playbackEventStream: $error');
    });

    // Listen to duration changes if needed
  }

  void _broadcastPlaybackEvent(PlaybackEvent event) {
    // Atualiza o estado de reprodução
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[event.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    ));

    // Atualiza DurationState
    _durationState.add(DurationState(
      position: _player.position,
      bufferedPosition: _player.bufferedPosition,
      total: _player.duration ?? Duration.zero,
    ));
  }

  Future<void> setAudioSource(String url, String title, String imageUrl) async {
    final mediaItem = MediaItem(
      id: url,
      title: title,
      artUri: Uri.parse(imageUrl),
    );

    // Adiciona o MediaItem
    this.mediaItem.add(mediaItem);

    // Configura a fonte de áudio
    try {
      await _player.setUrl(url);
      this.mediaItem.add(mediaItem);
    } catch (e) {
      print('Erro ao configurar a URL: $e');
    }
  }
  // Outros métodos para controlar a reprodução
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    // Implementar lógica para avançar para o próximo
  }

  @override
  Future<void> skipToPrevious() async {
    // Implementar lógica para voltar para o anterior
  }

  // Configurar mídia dinâmica
  // Dentro do AudioPlayerHandler:
  Future<void> setDynamicAudioSource(String audioPath, String title, String? imageUrl) async {
    if (audioPath.startsWith('assets/')) {
      await _player.setAsset(audioPath);
    } else {
      await _player.setFilePath(audioPath);
    }

    // Obtenha a duração após configurar a fonte
    final duration = _player.duration ?? Duration.zero;

    // Ajuste o artUri com um esquema personalizado
    Uri? artUri;
    if (imageUrl != null) {
      if (imageUrl.startsWith('assets/')) {
        // Prefixe com 'asset:///'
        artUri = Uri.parse('asset:///$imageUrl');
      } else {
        // Utilize Uri.file para arquivos locais
        artUri = Uri.file(imageUrl);
      }
    }

    mediaItem.add(MediaItem(
      id: audioPath,
      album: 'Seu Álbum',
      title: title,
      artUri: artUri,
      duration: duration,
    ));
  }
}