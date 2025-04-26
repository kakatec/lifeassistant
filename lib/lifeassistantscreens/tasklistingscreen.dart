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

    tempList.sort(
      (a, b) => DateTime.parse(
        a['createdAt'],
      ).compareTo(DateTime.parse(b['createdAt'])),
    );

    setState(() {
      _allTasks = tempList;
    });
  }

  List<Map<String, dynamic>> _filteredTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _allTasks.where((task) {
      final taskDate = DateTime.parse(task['createdAt']);
      bool matchesFilter = true;
      bool matchesCategory = true;

      if (_selectedFilter == 'Today') {
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
        final createdAt = DateTime.parse(task['createdAt']);
        final formattedDate = DateFormat('dd MMM yyyy').format(createdAt);

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
                  'Created: $formattedDate',
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
            trailing: Icon(
              task['status'] == 'completed'
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              color: task['status'] == 'completed' ? Colors.green : Colors.grey,
            ),
          ),
        );
      },
    );
  }
}
