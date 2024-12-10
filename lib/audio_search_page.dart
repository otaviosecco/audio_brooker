import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'audio_model.dart';
import 'dart:convert';

import 'audio_player_page.dart';

class AudioSearchPage extends StatefulWidget {
  const AudioSearchPage({super.key});

  @override
  _AudioSearchPageState createState() => _AudioSearchPageState();
}

class _AudioSearchPageState extends State<AudioSearchPage> {
  List<AudioModel> searchResults = [];
  TextEditingController _controller = TextEditingController();

  Future<void> _searchAudio(String query) async {
    final response = await http.get(Uri.parse('http://<your-ip>:3000/search?q=$query'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      setState(() {
        searchResults = jsonResponse.map((audio) => AudioModel.fromJson(audio)).toList();
      });
    } else {
      throw Exception('Failed to search audios');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Search Audios'),
        ),
        body: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter audio title',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchAudio(_controller.text),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final audioItem = searchResults[index];
                  return ListTile(
                    leading: Image.network(
                      audioItem.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.music_note,
                          size: 50,
                          color: Colors.white,
                        );
                      },
                    ),
                    title: Text(audioItem.title),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPlayerPage(
                            audioUrl: audioItem.audioUrl,
                            title: audioItem.title,
                            imageUrl: audioItem.imageUrl,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ));
  }
}