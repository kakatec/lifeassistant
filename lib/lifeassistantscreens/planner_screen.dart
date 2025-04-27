// calendar_task_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class CalendarTaskScreen extends StatefulWidget {
  const CalendarTaskScreen({super.key});

  @override
  State<CalendarTaskScreen> createState() => _CalendarTaskScreenState();
}

class _CalendarTaskScreenState extends State<CalendarTaskScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'lifeassistant/tasks',
  );
  List<Map<String, dynamic>> _allTasks = [];
  String _selectedView = 'Day';

  final List<String> _viewOptions = ['Day', 'Week', 'Month'];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await _dbRef.child(user.uid).get();
    List<Map<String, dynamic>> tempList = [];

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final task = Map<String, dynamic>.from(value);
        task['id'] = key;
        tempList.add(task);
      });
    }

    setState(() {
      _allTasks = tempList;
    });
  }

  Future<void> _updateEndDate(String taskId, DateTime selectedDate) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _dbRef.child(user.uid).child(taskId).update({
      'endDateTime': selectedDate.toIso8601String(),
    });

    _fetchTasks(); // Refresh list
  }

  List<Map<String, dynamic>> _filteredTasks() {
    final now = DateTime.now();

    if (_selectedView == 'Day') {
      return _allTasks.where((task) {
        final endDateTime = task['endDateTime'];
        if (endDateTime == null || endDateTime.isEmpty) return false;
        try {
          final createdAt = DateTime.parse(endDateTime);
          return createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day;
        } catch (e) {
          return false; // invalid date
        }
      }).toList();
    } else if (_selectedView == 'Week') {
      final startOfRange = now.subtract(const Duration(days: 2));
      final endOfRange = now.add(const Duration(days: 4));

      final weekTasks =
          _allTasks.where((task) {
            final endDateTime = task['endDateTime'];
            if (endDateTime == null || endDateTime.isEmpty) return false;
            try {
              final createdAt = DateTime.parse(endDateTime);
              return createdAt.isAfter(
                    startOfRange.subtract(const Duration(seconds: 1)),
                  ) &&
                  createdAt.isBefore(endOfRange.add(const Duration(days: 1)));
            } catch (e) {
              return false;
            }
          }).toList();

      // Sort by endDateTime ascending
      weekTasks.sort((a, b) {
        final aDate =
            DateTime.tryParse(a['endDateTime'] ?? '') ?? DateTime(9999);
        final bDate =
            DateTime.tryParse(b['endDateTime'] ?? '') ?? DateTime(9999);
        return aDate.compareTo(bDate);
      });

      return weekTasks;
    } else {
      // Month
      final startOfRange = now.subtract(const Duration(days: 15));
      final endOfRange = now.add(const Duration(days: 15));

      final monthTasks =
          _allTasks.where((task) {
            final endDateTime = task['endDateTime'];
            if (endDateTime == null || endDateTime.isEmpty)
              return true; // if no date, include
            try {
              final createdAt = DateTime.parse(endDateTime);
              return createdAt.isAfter(
                    startOfRange.subtract(const Duration(seconds: 1)),
                  ) &&
                  createdAt.isBefore(endOfRange.add(const Duration(days: 1)));
            } catch (e) {
              return true; // invalid date, still include
            }
          }).toList();

      // Sort by endDateTime ascending
      monthTasks.sort((a, b) {
        final aDate =
            DateTime.tryParse(a['endDateTime'] ?? '') ?? DateTime(9999);
        final bDate =
            DateTime.tryParse(b['endDateTime'] ?? '') ?? DateTime(9999);
        return aDate.compareTo(bDate);
      });

      return monthTasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _filteredTasks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchTasks),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildViewToggle(),
            const SizedBox(height: 10),
            Expanded(
              child:
                  tasks.isEmpty
                      ? const Center(
                        child: Text(
                          'No tasks found for this view.',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                      : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final createdAt = DateTime.parse(task['createdAt']);
                          final endDateTime =
                              task['endDateTime'] != null &&
                                      task['endDateTime'] != ""
                                  ? DateTime.parse(task['endDateTime'])
                                  : null;
                          final formattedCreatedAt = DateFormat(
                            'dd MMM yyyy',
                          ).format(createdAt);
                          final formattedEndDateTime =
                              endDateTime != null
                                  ? DateFormat(
                                    'dd MMM yyyy',
                                  ).format(endDateTime)
                                  : 'Not set';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task['taskInput'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Category: ${task['category'] ?? 'N/A'}',
                                  ),
                                  Text('Created At: $formattedCreatedAt'),
                                  Text('End Date: $formattedEndDateTime'),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.date_range,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Change End Date',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onPressed: () async {
                                      final pickedDate = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            endDateTime ?? DateTime.now(),
                                        firstDate:
                                            DateTime.now(), // 👉 Start from today
                                        lastDate: DateTime(2100),
                                      );

                                      if (pickedDate != null) {
                                        await _updateEndDate(
                                          task['id'],
                                          pickedDate,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            _viewOptions.map((view) {
              final isSelected = _selectedView == view;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ChoiceChip(
                  label: Text(view),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedView = view;
                    });
                  },
                  selectedColor: Colors.teal,
                  backgroundColor: Colors.teal.shade50,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
