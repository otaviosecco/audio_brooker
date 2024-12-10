import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:provider/provider.dart';
import 'audio_handler.dart';
import 'audio_list_page.dart';
import 'minimized_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.your_app.channel.audio',
      androidNotificationChannelName: 'Reprodução de Áudio',
      androidNotificationOngoing: true,
    ),
  );
  runApp(
    MyApp(audioHandler: audioHandler),
  );
}

class MyApp extends StatelessWidget {
  final AudioPlayerHandler audioHandler;

  const MyApp({super.key, required this.audioHandler});

  @override
  Widget build(BuildContext context) {
    return Provider<AudioPlayerHandler>.value(
      value: audioHandler,
      child: MaterialApp(
        title: 'Tocador de Áudio',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const MainPage(),
      )
    );
  }
}


class MainPage extends StatelessWidget {
  const MainPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AudioListPage(audioHandler: Provider.of<AudioPlayerHandler>(context)),
          const Align(
            alignment: Alignment.bottomCenter,
            child: MinimizedPlayer(),
          ),
        ],
      ),
    );
  }
}