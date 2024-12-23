import 'dart:typed_data';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayerHandler() {
    // Listen to playback events and map them to PlaybackState
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Listen to duration changes and update MediaItem accordingly
    _player.durationStream.listen((duration) {
      if (mediaItem.value != null && duration != null) {
        final updatedMediaItem = mediaItem.value!.copyWith(duration: duration);
        mediaItem.add(updatedMediaItem);
        print('MediaItem updated with duration: $duration'); // Debugging
      }
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      androidCompactActionIndices: const [0, 1, 3],
      processingState: {
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
      queueIndex: event.currentIndex,
    );
  }

  Future<void> setAudioSource(String url, String title, Uint8List? imageBytes) async {
    // Create MediaItem with extras
    final newMediaItem = MediaItem(
      id: url,
      album: "Album Name", // Replace with actual album if available
      title: title,
      artist: "Artist Name", // Replace with actual artist if available
      duration: Duration.zero, // Will be updated once duration is fetched
      extras: {'imageBytes': imageBytes}, // Pass imageBytes here
    );

    // Update MediaItem stream
    mediaItem.add(newMediaItem);
    print('MediaItem set with imageBytes: ${imageBytes?.length ?? 0}'); // Debugging

    // Set the audio source
    try {
      await _player.setUrl(url);
      print('Audio source set for URL: $url'); // Debugging
    } catch (e) {
      print('Error setting audio source: $e');
      throw e; // Re-throw to handle it upstream if needed
    }

    // Update MediaItem with actual duration if available
    if (_player.duration != null) {
      final updatedMediaItem = newMediaItem.copyWith(duration: _player.duration);
      mediaItem.add(updatedMediaItem);
      print('MediaItem updated with actual duration: ${_player.duration}'); // Debugging
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> dispose() async {
    await _player.dispose();
    // No need to call super.dispose() as it is not defined in the superclass
  }
}