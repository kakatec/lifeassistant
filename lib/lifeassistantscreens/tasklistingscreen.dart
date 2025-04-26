// task_list_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'lifeassistant/tasks',
  );
  List<Map<String, dynamic>> _allTasks = [];
  String _selectedFilter = 'All';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'academic',
    'personal',
    'work',
    'health',
    'social',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  void _markAsComplete(String taskId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _dbRef.child(user.uid).child(taskId).update({'status': 'completed'});
    _fetchTasks();
  }

  void _editTask(Map<String, dynamic> task) {
    final TextEditingController _controller = TextEditingController(
      text: task['taskInput'] ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Task'),
            content: TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Enter task'),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final newText = _controller.text.trim();
                  if (newText.isNotEmpty) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      await _dbRef.child(user.uid).child(task['id']).update({
                        'taskInput': newText,
                      });
                      Navigator.pop(context);
                      _fetchTasks();
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _deleteTask(String taskId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await _dbRef.child(user.uid).child(taskId).remove();
                  Navigator.pop(context);
                  _fetchTasks();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
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

    tempList.sort((a, b) {
      final aEnd = a['endDateTime'];
      final bEnd = b['endDateTime'];

      // Handle if one or both are null or empty
      if ((aEnd == null || aEnd.isEmpty) && (bEnd == null || bEnd.isEmpty)) {
        return 0; // both have no endDateTime -> keep original order
      } else if (aEnd == null || aEnd.isEmpty) {
        return 1; // a has no endDateTime -> a goes after b
      } else if (bEnd == null || bEnd.isEmpty) {
        return -1; // b has no endDateTime -> b goes after a
      } else {
        // Both have endDateTime -> compare them
        final aDate = DateTime.parse(aEnd);
        final bDate = DateTime.parse(bEnd);
        return aDate.compareTo(bDate); // nearest first
      }
    });

    setState(() {
      _allTasks = tempList;
    });
  }

  List<Map<String, dynamic>> _filteredTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _allTasks.where((task) {
      final String? endDateTime =
          task['endDateTime']; // Assuming this could be null or empty
      DateTime? taskDate;

      // If endDateTime is not null or empty, parse the date
      if (endDateTime != null && endDateTime.isNotEmpty) {
        try {
          taskDate = DateTime.parse(endDateTime);
        } catch (e) {
          taskDate = null; // If parsing fails, set taskDate to null
        }
      }

      bool matchesFilter = true;
      bool matchesCategory = true;

      final today = DateTime.now();

      if (_selectedFilter == 'Today' && taskDate != null) {
        // Only compare if taskDate is valid
        matchesFilter =
            taskDate.year == today.year &&
            taskDate.month == today.month &&
            taskDate.day == today.day;
      } else if (_selectedFilter == 'Completed') {
        matchesFilter = task['status'] == 'completed';
      } else if (_selectedFilter == 'Pending') {
        matchesFilter = task['status'] == 'pending';
      }

      if (_selectedCategory != 'All') {
        matchesCategory = task['category'] == _selectedCategory;
      }

      return matchesFilter && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchTasks),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFilterButtons(),
            const SizedBox(height: 10),
            _buildCategoryDropdown(),
            const SizedBox(height: 10),
            Expanded(child: _buildTaskList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(context, '/addtask');
        },
      ),
    );
  }

  Widget _buildFilterButtons() {
    final filters = ['All', 'Today', 'Completed', 'Pending'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  selectedColor: Colors.teal,
                  backgroundColor: Colors.deepPurple.shade50,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        value: _selectedCategory,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down),
        items:
            _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category[0].toUpperCase() + category.substring(1)),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedCategory = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildTaskList() {
    final tasks = _filteredTasks();

    if (tasks.isEmpty) {
      return const Center(
        child: Text('No tasks found.', style: TextStyle(fontSize: 18)),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final endDateTime = task['endDateTime'];

        String formattedDate;

        if (endDateTime != null && endDateTime.isNotEmpty) {
          try {
            final createdAt = DateTime.parse(endDateTime);
            formattedDate = DateFormat('dd MMM yyyy').format(createdAt);
          } catch (e) {
            formattedDate = 'Invalid Date';
          }
        } else {
          formattedDate = 'No Date Available';
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              task['taskInput'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Category: ${task['category'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'End date: $formattedDate',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Status: ${task['status']}',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        task['status'] == 'completed'
                            ? Colors.green
                            : Colors.redAccent,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'complete') {
                  _markAsComplete(task['id']);
                } else if (value == 'edit') {
                  _editTask(task);
                } else if (value == 'delete') {
                  _deleteTask(task['id']);
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(Icons.check, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Mark as Complete'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
            ),
          ),
        );
      },
    );
  }
}
