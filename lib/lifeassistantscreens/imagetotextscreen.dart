import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class ImageToTextScreen extends StatefulWidget {
  const ImageToTextScreen({super.key});

  @override
  _ImageToTextScreenState createState() => _ImageToTextScreenState();
}

class _ImageToTextScreenState extends State<ImageToTextScreen> {
  File? _image;
  final TextEditingController _textController = TextEditingController();
  bool _isProcessing = false;
  bool _isLoading = false;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'lifeassistant/tasks',
  );
  final String hfApiToken =
      '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'; // Replace it

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _textController.text = '';
        _isProcessing = true;
      });

      await _extractText(File(pickedFile.path));
    }
  }

  Future<void> _extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      setState(() {
        _textController.text = recognizedText.text.trim();
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      textRecognizer.close();
    }
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
    final inputText = _textController.text.trim();
    if (inputText.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final category = await predictCategory(inputText) ?? 'unknown';
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

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
      _clearScreen();
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

  void _clearScreen() {
    setState(() {
      _image = null;
      _textController.clear();
    });
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Save as Task?'),
            content: const Text(
              'Do you want to save this recognized text as a task?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _clearScreen();
                },
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  addTask();
                },
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image to Task'), centerTitle: true),
      body: SafeArea(
        child: GestureDetector(
          onTap:
              () =>
                  FocusScope.of(
                    context,
                  ).unfocus(), // Dismiss keyboard when tap outside
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image, color: Colors.white),
                  label: const Text(
                    'Pick Image from Gallery',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _image!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Center(
                    child: Text(
                      'No image selected',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                const SizedBox(height: 20),
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator())
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 150,
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Recognized text will appear here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                if (_textController.text.trim().isNotEmpty && !_isProcessing)
                  ElevatedButton(
                    onPressed: _showSaveDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Task',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                if (_isLoading) ...[
                  const SizedBox(height: 20),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
