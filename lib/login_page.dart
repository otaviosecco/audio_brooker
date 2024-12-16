import 'package:flutter/material.dart';
import 'audio_list_page.dart';
import 'http/api_service.dart';
import 'main.dart';
import 'audio_handler.dart';

class LoginPage extends StatefulWidget {
  final AudioPlayerHandler audioHandler;

  const LoginPage({super.key, required this.audioHandler});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    bool success = await ApiService.login(
      _usernameController.text,
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    print('Login success: $success');

    if (success) {
      print('Navigating to MainPage');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AudioListPage(audioHandler: widget.audioHandler),
        ),
      );
    } else {
      print('Login failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}