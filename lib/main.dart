// filepath: /d:/FlutterApps/audio_brooker/lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/audio_handler.dart';
import 'classes/ytdl_notifier.dart'; // Import YtdlNotifier
import 'audio_list_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized
  final audioHandler = AudioPlayerHandler();
  runApp(MyApp(audioHandler: audioHandler));
}

class MyApp extends StatelessWidget {
  final AudioPlayerHandler audioHandler;

  const MyApp({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AudioPlayerHandler>.value(
          value: audioHandler,
        ),
        ChangeNotifierProvider<YtdlNotifier>(
          create: (_) => YtdlNotifier(),
        ),
      ],
      child: MaterialApp(
        title: 'Audio Brooker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: AudioListPage(audioHandler: audioHandler,), // Remove `const` and pass no parameters
      ),
    );
  }
}