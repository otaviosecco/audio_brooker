import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio_handler.dart';
import 'audio_list_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Adicione esta linha
  final audioHandler = AudioPlayerHandler();
  runApp(MyApp(audioHandler: audioHandler));
}

class MyApp extends StatelessWidget {
  final AudioPlayerHandler audioHandler;

  const MyApp({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return Provider<AudioPlayerHandler>.value(
      value: audioHandler,
      child: MaterialApp(
        title: 'Audio Brooker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: AudioListPage(audioHandler: audioHandler),
      ),
    );
  }
}