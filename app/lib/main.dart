import 'package:flutter/material.dart';

void main() {
  runApp(const PhishGuardApp());
}

class PhishGuardApp extends StatelessWidget {
  const PhishGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhishGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F4FD8)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  String? _result;

  // First version: two simple rules. The AI agent will replace them.
  void _analyse() {
    final text = _controller.text.toLowerCase();
    final hasLink = RegExp(r'https?://|www\.').hasMatch(text);
    const urgentWords = ['urgent', 'blocked', 'pay', 'bloqué', 'payer'];
    final isUrgent = urgentWords.any((word) => text.contains(word));

    setState(() {
      if (text.trim().isEmpty) {
        _result = 'Paste a message first.';
      } else if (hasLink && isUrgent) {
        _result = 'Suspicious: urgent message with a link. Do not click.';
      } else if (hasLink || isUrgent) {
        _result = 'Be careful: this message has a warning sign.';
      } else {
        _result = 'No obvious warning sign found.';
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PhishGuard')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Does a message look suspicious?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message or link',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _analyse, child: const Text('Analyse')),
            const SizedBox(height: 20),
            if (_result != null)
              Text(_result!, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}