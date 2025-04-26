// add_task_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:lifeassistant/routes.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _taskController = TextEditingController();
  bool _isLoading = false;

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'lifeassistant/tasks',
  );
  final String hfApiToken =
      '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'; // replace it

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
        'endDateTime': '', // will fill later
        'priority': '', // will fill later
        'mood': '', // will fill later
        'status': 'pending', // pending / completed
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

  Future<void> addTaskViaImage() async {
    Navigator.pushNamed(context, AppRoutes.addthroughimage);
  }

  Future<void> addTaskViaVoice() async {
    Navigator.pushNamed(context, AppRoutes.addvoice);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Task'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_turned_in_outlined,
                size: 100,
                color: Colors.teal,
              ),
              const SizedBox(height: 20),
              Text(
                "What's on your mind?",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _taskController,
                decoration: InputDecoration(
                  labelText: 'Enter your task...',
                  labelStyle: const TextStyle(color: Colors.black),
                  filled: true,
                  fillColor: Colors.deepPurple.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.teal),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.teal)
                  : Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save_alt, color: Colors.white),
                          label: const Text(
                            'Add Task',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          onPressed: addTask,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.image_outlined,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Add Task via Image',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          onPressed: addTaskViaImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(
                            Icons.mic_none_outlined,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Add Task via Voice',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                          onPressed: addTaskViaVoice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
