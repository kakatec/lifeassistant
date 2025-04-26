import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotesSummarizerScreen extends StatefulWidget {
  const NotesSummarizerScreen({super.key});

  @override
  State<NotesSummarizerScreen> createState() => _NotesSummarizerScreenState();
}

class _NotesSummarizerScreenState extends State<NotesSummarizerScreen> {
  final TextEditingController _notesController = TextEditingController();
  List<String> _summaryPoints = [];
  bool _isLoading = false;
  void summarizeText() async {
    final inputText = _notesController.text.trim();
    const apiUrl =
        'https://api-inference.huggingface.co/models/facebook/bart-large-cnn';
    const apiToken = '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';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'inputs': inputText}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _summaryPoints = data[0]['summary_text'];
        _isLoading = false;
      });
      // return data[0]['summary_text'];
    } else {
      print('Error: ${response.body}');
      return null;
    }
  }

  void _summarizeNotes() {
    final inputText = _notesController.text.trim();
    if (inputText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter some text')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      final sentences = inputText.split(
        RegExp(r'[.!?]\s+'),
      ); // Splitting by sentences
      List<String> selectedSentences = [];

      for (var sentence in sentences) {
        if (sentence.trim().isNotEmpty) {
          selectedSentences.add(sentence.trim());
        }
      }

      // Pick first 3–5 sentences or less if not available
      selectedSentences = selectedSentences.take(5).toList();

      setState(() {
        _summaryPoints = selectedSentences;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Notes Summarizer'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _notesController,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Enter your long notes here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _summarizeNotes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Summarize', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            if (_summaryPoints.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _summaryPoints.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(Icons.check, size: 12),
                      title: Text(_summaryPoints[index]),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
