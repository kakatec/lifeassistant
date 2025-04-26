// calendar_task_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class CalendarTaskManagerScreen extends StatefulWidget {
  const CalendarTaskManagerScreen({super.key});

  @override
  State<CalendarTaskManagerScreen> createState() =>
      _CalendarTaskManagerScreenState();
}

class _CalendarTaskManagerScreenState extends State<CalendarTaskManagerScreen> {
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

  Future<void> _updateTaskDate(String taskId, DateTime newDate) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _dbRef.child(user.uid).child(taskId).update({
      'endDateTime': newDate.toIso8601String(),
    });

    _fetchTasks();
  }

  List<Map<String, dynamic>> _getTodayTasks() {
    final now = DateTime.now();
    return _allTasks.where((task) {
      final createdAt = DateTime.parse(task['createdAt']);
      return createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _getWeekTasks() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    Map<String, List<Map<String, dynamic>>> weekTasks = {
      'Monday': [],
      'Tuesday': [],
      'Wednesday': [],
      'Thursday': [],
      'Friday': [],
      'Saturday': [],
      'Sunday': [],
    };

    for (var task in _allTasks) {
      final createdAt = DateTime.parse(task['createdAt']);
      if (createdAt.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
          createdAt.isBefore(startOfWeek.add(const Duration(days: 7)))) {
        final weekday = DateFormat('EEEE').format(createdAt);
        if (weekTasks.containsKey(weekday)) {
          weekTasks[weekday]!.add(task);
        }
      }
    }

    return weekTasks;
  }

  Map<String, List<Map<String, dynamic>>> _getMonthTasks() {
    final now = DateTime.now();
    Map<String, List<Map<String, dynamic>>> monthTasks = {};

    for (var task in _allTasks) {
      final createdAt = DateTime.parse(task['createdAt']);
      if (createdAt.year == now.year && createdAt.month == now.month) {
        final day = DateFormat('yyyy-MM-dd').format(createdAt);
        if (!monthTasks.containsKey(day)) {
          monthTasks[day] = [];
        }
        monthTasks[day]!.add(task);
      }
    }

    return monthTasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Planner'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          _buildViewToggle(),
          const SizedBox(height: 10),
          Expanded(child: _buildSelectedView()),
        ],
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

  Widget _buildSelectedView() {
    if (_selectedView == 'Day') {
      return _buildDayView();
    } else if (_selectedView == 'Week') {
      return _buildWeekView();
    } else {
      return _buildMonthView();
    }
  }

  Widget _buildDayView() {
    final tasks = _getTodayTasks();
    return tasks.isEmpty
        ? const Center(child: Text('No tasks for today'))
        : ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            final createdAt = DateTime.parse(task['createdAt']);
            final formattedDate = DateFormat('dd MMM yyyy').format(createdAt);

            return ListTile(
              title: Text(task['taskInput'] ?? ''),
              subtitle: Text('Created at: $formattedDate'),
              trailing: IconButton(
                icon: const Icon(Icons.edit_calendar),
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    _updateTaskDate(task['id'], pickedDate);
                  }
                },
              ),
            );
          },
        );
  }

  Widget _buildWeekView() {
    final weekTasks = _getWeekTasks();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return ListView.builder(
      itemCount: weekdays.length,
      itemBuilder: (context, index) {
        final day = weekdays[index];
        final tasks = weekTasks[day] ?? [];

        return ExpansionTile(
          title: Text(day),
          children:
              tasks.map((task) {
                return LongPressDraggable<Map<String, dynamic>>(
                  data: task,
                  feedback: Material(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.teal,
                      child: Text(
                        task['taskInput'] ?? '',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  child: DragTarget<Map<String, dynamic>>(
                    onAccept: (receivedTask) {
                      final newDate = DateTime.now().add(
                        Duration(days: index - DateTime.now().weekday + 1),
                      );
                      _updateTaskDate(receivedTask['id'], newDate);
                    },
                    builder: (context, candidateData, rejectedData) {
                      return ListTile(title: Text(task['taskInput'] ?? ''));
                    },
                  ),
                );
              }).toList(),
        );
      },
    );
  }

  Widget _buildMonthView() {
    final monthTasks = _getMonthTasks();
    final today = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(today.year, today.month);

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, index) {
        final day = today.add(Duration(days: index));
        final formattedDay = DateFormat('yyyy-MM-dd').format(day);
        final tasks = monthTasks[formattedDay] ?? [];

        return DragTarget<Map<String, dynamic>>(
          onAccept: (task) {
            _updateTaskDate(task['id'], day);
          },
          builder: (context, candidateData, rejectedData) {
            return Card(
              color:
                  day.isBefore(today)
                      ? Colors.grey.shade300
                      : Colors.teal.shade50,
              child: Column(
                children: [
                  Text('${day.day}'),
                  ...tasks.map(
                    (task) => LongPressDraggable<Map<String, dynamic>>(
                      data: task,
                      feedback: Material(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.teal,
                          child: Text(
                            task['taskInput'] ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.all(4),
                        color: Colors.teal.shade100,
                        child: Text(
                          task['taskInput'] ?? '',
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
