import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/firebase_service.dart';
import '../models/task_model.dart';
import '../widgets/task_card.dart';
import 'package:intl/intl.dart';

class TaskPlannerScreen extends StatefulWidget {
  const TaskPlannerScreen({super.key});

  @override
  State<TaskPlannerScreen> createState() => _TaskPlannerScreenState();
}

class _TaskPlannerScreenState extends State<TaskPlannerScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<TaskModel> _tasks = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _viewType = 'Day'; // 'Day', 'Week', 'Month'

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await _firebaseService.fetchTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  List<TaskModel> get _filteredTasks {
    if (_viewType == 'Day') {
      return _tasks.where((task) {
        return task.createdAt.year == _focusedDay.year &&
            task.createdAt.month == _focusedDay.month &&
            task.createdAt.day == _focusedDay.day;
      }).toList();
    } else if (_viewType == 'Week') {
      final startOfWeek = _focusedDay.subtract(
        Duration(days: _focusedDay.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return _tasks.where((task) {
        return task.createdAt.isAfter(
              startOfWeek.subtract(const Duration(seconds: 1)),
            ) &&
            task.createdAt.isBefore(endOfWeek.add(const Duration(days: 1)));
      }).toList();
    } else {
      return _tasks.where((task) {
        return task.createdAt.year == _focusedDay.year &&
            task.createdAt.month == _focusedDay.month;
      }).toList();
    }
  }

  Future<void> _changeTaskDate(TaskModel task) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: task.endDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      await _firebaseService.updateTaskEndDate(task.id, pickedDate);
      await _loadTasks();
    }
  }

  Widget _buildTaskList() {
    if (_filteredTasks.isEmpty) {
      return const Center(child: Text('No tasks found.'));
    }

    return ListView.builder(
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        return TaskCard(task: task, onChangeDate: () => _changeTaskDate(task));
      },
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime(2100),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      calendarFormat:
          _viewType == 'Month' ? CalendarFormat.month : CalendarFormat.week,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.teal,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Planner'),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _viewType = value;
              });
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(value: 'Day', child: Text('Day View')),
                  const PopupMenuItem(value: 'Week', child: Text('Week View')),
                  const PopupMenuItem(
                    value: 'Month',
                    child: Text('Month View'),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendar(),
          const SizedBox(height: 10),
          Expanded(child: _buildTaskList()),
        ],
      ),
    );
  }
}
