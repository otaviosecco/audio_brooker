import 'package:http/http.dart' as http;
import 'package:http_interceptor/http_interceptor.dart';
import 'dart:async';
import 'dart:convert';
import '../classes/audio_model.dart';
import '../classes/ytdl_notifier.dart';

final http.Client client = InterceptedClient.build(
  interceptors: [LoggingInterceptor()],
);

const String baseUrl = 'http://172.25.224.1:3000';

class LoggingInterceptor implements InterceptorContract {
  @override
  Future<http.BaseRequest> interceptRequest({required http.BaseRequest request}) async {
    // Você pode adicionar logs ou modificar a requisição aqui
    return request;
  }

  @override
  Future<http.BaseResponse> interceptResponse({required http.BaseResponse response}) async {
    print('Response');
    print('Status code: ${response.statusCode}');
    print('Headers: ${response.headers}');
    return response;
  }

  // Implementações dos métodos exigidos pelo InterceptorContract
  @override
  bool shouldInterceptRequest() => true;

  @override
  bool shouldInterceptResponse() => true;
}

class ApiService {
  static Future<bool> login(String username, String password) async {
    final response = await client.post(
      Uri.parse('$baseUrl/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  static Future<List<dynamic>> fetchChapters(String filename) async {
    final response = await client.get(Uri.parse('$baseUrl/chapters?filename=$filename'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load chapters');
    }
  }

  static Future<List<AudioModel>> fetchAudioList() async {
    final response = await client.get(Uri.parse('$baseUrl/audioList'));

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => AudioModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load audio list');
    }
  }

  static Future<List<dynamic>> searchAudio(String query) async {
    final response = await client.get(Uri.parse('$baseUrl/search?q=$query'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to search audios');
    }
  }

  Future<void> addFromYoutube(String url, ytdlNotifier) async {
    if (url.isEmpty) {
      throw Exception('YouTube URL cannot be empty');
    }
    print('Sending YouTube URL: $url'); // Log para verificar a URL
    final response = await client.post(
      Uri.parse('$baseUrl/download'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'youtubeUrl': url,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add audio from YouTube: ${response.body}');
    }
    // If successful, fetch the updated audio list
    if(response.statusCode == 200) {
       ytdlNotifier.update();
    }
  }
}