// arquivo: audio_handler.dart

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  AudioPlayerHandler() {
    // Configure o player aqui
    _notifyAudioHandlerAboutPlaybackEvents();
  }

  // Notificar o sistema sobre eventos de reprodução
  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((event) {
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    });
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
  Future<void> setAudioSource(String audioPath, String title, String? imageUrl) async {
    // Definir metadados da mídia
    mediaItem.add(MediaItem(
      id: audioPath,
      album: 'Seu Álbum',
      title: title,
      artUri: imageUrl != null ? Uri.parse(imageUrl) : null,
    ));

    // Carregar a fonte de áudio
    if (audioPath.startsWith('assets/')) {
      await _player.setAsset(audioPath);
    } else {
      await _player.setFilePath(audioPath);
    }
  }
}