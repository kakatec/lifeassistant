import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class DailyPlannerScreen extends StatefulWidget {
  const DailyPlannerScreen({Key? key}) : super(key: key);

  @override
  State<DailyPlannerScreen> createState() => _DailyPlannerScreenState();
}

class _DailyPlannerScreenState extends State<DailyPlannerScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'lifeassistant/tasks',
  );
  List<Map<String, dynamic>> _allTasks = [];
  String _selectedView = 'Day';
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isLoading = true;

  final List<String> _viewOptions = ['Day', 'Week', 'Month'];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
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
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
    }
  }

  Future<void> _updateTaskEndDate(String taskId, DateTime newDate) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _dbRef.child(user.uid).child(taskId).update({
      'endDateTime': newDate.toIso8601String(),
    });

    _fetchTasks();
  }

  List<Map<String, dynamic>> _tasksForDay(DateTime day) {
    return _allTasks.where((task) {
      if (task['endDateTime'] == null || task['endDateTime'].toString().isEmpty)
        return false;
      final taskDate = DateTime.parse(task['endDateTime']);
      return taskDate.year == day.year &&
          taskDate.month == day.month &&
          taskDate.day == day.day;
    }).toList();
  }

  Widget _buildDayView() {
    final todayTasks = _tasksForDay(DateTime.now());

    return todayTasks.isEmpty
        ? const Center(child: Text('No tasks for today'))
        : ListView.builder(
          itemCount: todayTasks.length,
          itemBuilder: (context, index) {
            final task = todayTasks[index];
            return _buildTaskCard(task);
          },
        );
  }

  Widget _buildWeekView() {
    final startOfWeek = _focusedDay.subtract(
      Duration(days: _focusedDay.weekday - 1),
    );
    final daysOfWeek = List.generate(
      7,
      (index) => startOfWeek.add(Duration(days: index)),
    );

    return ListView.builder(
      itemCount: daysOfWeek.length,
      itemBuilder: (context, index) {
        final day = daysOfWeek[index];
        final tasks = _tasksForDay(day);

        return DragTarget<Map<String, dynamic>>(
          onWillAccept:
              (data) =>
                  day.isAfter(DateTime.now().subtract(const Duration(days: 1))),
          onAccept: (task) => _updateTaskEndDate(task['id'], day),
          builder: (context, candidateData, rejectedData) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, dd MMM').format(day),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...tasks.map((task) => _buildDraggableTask(task)).toList(),
                    if (candidateData.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Drop to move here!',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMonthView() {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              final tasks = _tasksForDay(date);
              if (tasks.isNotEmpty) {
                return Positioned(
                  bottom: 1,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.teal,
                    ),
                  ),
                );
              }
              return null;
            },
          ),
          selectedDayPredicate: (day) => isSameDay(day, _focusedDay),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: DragTarget<Map<String, dynamic>>(
            onWillAccept:
                (data) => _focusedDay.isAfter(
                  DateTime.now().subtract(const Duration(days: 1)),
                ),
            onAccept: (task) => _updateTaskEndDate(task['id'], _focusedDay),
            builder: (context, candidateData, rejectedData) {
              final dayTasks = _tasksForDay(_focusedDay);
              return ListView(
                children:
                    dayTasks.map((task) => _buildDraggableTask(task)).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(task['taskInput'] ?? ''),
        subtitle: Text('Category: ${task['category'] ?? 'N/A'}'),
      ),
    );
  }

  Widget _buildDraggableTask(Map<String, dynamic> task) {
    return LongPressDraggable<Map<String, dynamic>>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: Card(
          color: Colors.teal,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              task['taskInput'] ?? '',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: _buildTaskCard(task)),
      child: _buildTaskCard(task),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Planner'),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchTasks),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildViewToggle(),
                    const SizedBox(height: 10),
                    Expanded(
                      child:
                          _selectedView == 'Day'
                              ? _buildDayView()
                              : _selectedView == 'Week'
                              ? _buildWeekView()
                              : _buildMonthView(),
                    ),
                  ],
                ),
              ),
    );
  }
}
