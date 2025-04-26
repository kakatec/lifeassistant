import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;

class VoiceToTextScreen extends StatefulWidget {
  const VoiceToTextScreen({super.key});

  @override
  _VoiceToTextScreenState createState() => _VoiceToTextScreenState();
}

class _VoiceToTextScreenState extends State<VoiceToTextScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final TextEditingController _taskController = TextEditingController();
  bool _isLoading = false;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'lifeassistant/tasks',
  );
  final String hfApiToken =
      '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'; // Replace your token

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          setState(() {
            _isListening = false;
          });
          _showSaveTaskDialog(); // <-- Show dialog after done listening
        }
      },
      onError: (error) => print('Speech error: $error'),
    );

    if (!available) {
      setState(() {
        _taskController.text = 'Speech recognition not available';
      });
    }
  }

  void _startListening() async {
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _taskController.text = result.recognizedWords;
        });
      },
      listenMode: stt.ListenMode.dictation,
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 10),
      partialResults: true,
    );
    setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  Future<void> _showSaveTaskDialog() async {
    if (_taskController.text.trim().isEmpty) return;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Save Task?'),
            content: TextField(
              controller: _taskController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Edit your task here...',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog without saving
                },
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  await addTask();
                },
                child: const Text('Yes, Save'),
              ),
            ],
          ),
    );
  }

  Future<String?> predictCategory(String inputText) async {
    try {
      final url = Uri.parse(
        'https://api-inference.huggingface.co/models/facebook/bart-large-mnli',
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $hfApiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': inputText,
          'parameters': {
            'candidate_labels': [
              'academic',
              'personal',
              'work',
              'health',
              'social',
              'other',
            ],
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final labels = List<String>.from(data['labels']);
        return labels[0];
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<void> addTask() async {
    final inputText = _taskController.text.trim();
    if (inputText.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final category = await predictCategory(inputText) ?? 'unknown';

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final newTaskRef = _dbRef.child(user.uid).push();
      await newTaskRef.set({
        'taskInput': inputText,
        'category': category,
        'createdAt': DateTime.now().toIso8601String(),
        'endDateTime': '',
        'priority': '',
        'mood': '',
        'status': 'pending',
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task added successfully!')));

      _taskController.clear();
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add task')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Voice to Task',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context); // Pop the screen if possible
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _taskController,
                maxLines: null,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Tap the mic to start speaking...',
                ),
              ),
            ),
            const Spacer(),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              GestureDetector(
                onTap: _toggleListening,
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor:
                      _isListening ? Colors.redAccent : Colors.blueAccent,
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              _isListening ? 'Listening...' : 'Tap to start speaking',
              style: TextStyle(
                fontSize: 16,
                color: _isListening ? Colors.redAccent : Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
