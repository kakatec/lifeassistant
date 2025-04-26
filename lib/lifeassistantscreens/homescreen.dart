import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:lifeassistant/consts.dart';
import 'package:lifeassistant/routes.dart'; // For date formatting

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser;
  final DatabaseReference databaseRef = FirebaseDatabase.instance.ref().child(
    'lifeassistant',
  );
  int mood = 3;
  String username = '';
  bool isLoadingMood = true;
  bool isLoadingTasks = true;
  List<Map<dynamic, dynamic>> tasks = [];

  final List<String> emojis = ['😢', '☹️', '😐', '🙂', '😄'];

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchTasks();
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  Future<void> fetchUserData() async {
    if (user != null) {
      final snapshot = await databaseRef.child('users/${user!.uid}').get();
      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          mood = data['mood'] ?? 3;
          username = data['name'] ?? 'User';
          isLoadingMood = false;
        });
      }
    }
  }

  Future<void> fetchTasks() async {
    if (user != null) {
      final snapshot = await databaseRef.child('tasks/${user!.uid}').get();
      if (snapshot.value != null) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        List<Map<dynamic, dynamic>> allTasks = [];
        data.forEach((key, value) {
          allTasks.add({...value, 'key': key});
        });

        List<Map<dynamic, dynamic>> filteredTasks =
            allTasks.where((task) {
              String category = (task['category'] ?? '').toLowerCase();
              if (mood <= 2) {
                return category == 'social' || category == 'health';
              } else if (mood == 3) {
                return category == 'personal';
              } else {
                return category == 'academic' || category == 'work';
              }
            }).toList();

        setState(() {
          tasks = filteredTasks;
          isLoadingTasks = false;
        });
      } else {
        setState(() {
          tasks = [];
          isLoadingTasks = false;
        });
      }
    }
  }

  Future<void> updateMood(int selectedMood) async {
    if (user != null) {
      await databaseRef.child('users/${user!.uid}').update({
        'mood': selectedMood,
      });
      setState(() {
        mood = selectedMood;
      });
      fetchTasks(); // Refresh tasks after mood change
    }
  }

  Future<void> updateTaskStatus(String taskKey, String newStatus) async {
    if (user != null) {
      await databaseRef.child('tasks/${user!.uid}/$taskKey').update({
        'status': newStatus,
      });
      fetchTasks(); // Refresh task list
    }
  }

  String formatDateTime(String dateTimeString) {
    try {
      final DateTime dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeString; // In case of error
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: SafeArea(
        child:
            isLoadingMood
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row with Greeting and Notification Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hey, $username',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isDarkMode
                                      ? Icons.light_mode
                                      : Icons.dark_mode,
                                  size: 28,
                                  color:
                                      isDarkMode
                                          ? Colors.yellow
                                          : Colors.blueGrey,
                                ),
                                onPressed: toggleTheme,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.notifications,
                                  size: 28,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.notification,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Today's Mood",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () => updateMood(index + 1),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      (mood == index + 1)
                                          ? Colors.blue.shade100
                                          : Colors.transparent,

                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  emojis[index],
                                  style: TextStyle(fontSize: 30),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      SizedBox(height: 30),
                      Text(
                        "Suggested Tasks",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 12),
                      isLoadingTasks
                          ? Center(child: CircularProgressIndicator())
                          : tasks.isEmpty
                          ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'No tasks to show!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              final String taskStatus =
                                  task['status'] ?? 'pending';
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 3,
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  title: Text(
                                    task['taskInput'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 4),
                                      Text(
                                        formatDateTime(
                                          task['endDateTime'] ?? '',
                                        ),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: getStatusColor(
                                            taskStatus,
                                          ).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          taskStatus.toUpperCase(),
                                          style: TextStyle(
                                            color: getStatusColor(taskStatus),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      updateTaskStatus(task['key'], value);
                                    },
                                    itemBuilder:
                                        (context) => [
                                          PopupMenuItem(
                                            value: 'pending',
                                            child: Text('Mark as Pending'),
                                          ),
                                          PopupMenuItem(
                                            value: 'completed',
                                            child: Text('Mark as Complete'),
                                          ),
                                        ],
                                    child: Icon(Icons.more_vert),
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
      ),
    );
  }
}
