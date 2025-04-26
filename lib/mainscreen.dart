import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lifeassistant/lifeassistantscreens/addtaskscreen.dart';
import 'package:lifeassistant/lifeassistantscreens/homescreen.dart';
import 'package:lifeassistant/lifeassistantscreens/imagetotextscreen.dart';
import 'package:lifeassistant/lifeassistantscreens/planner_screen.dart';
import 'package:lifeassistant/lifeassistantscreens/tasklistingscreen.dart';

class MainScreen extends StatefulWidget {
  final int indexvalue;
  const MainScreen({super.key, required this.indexvalue});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'lifeassistant/users',
  );
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String? _userName;
  bool _isLoading = true;
  int _selectedIndex = 0; // Track the selected index for IndexedStack

  // Titles for each screen

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data when the page is initialized
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showNotification(message);
      }
    });

    // Initialize local notifications
    var initializationSettingsAndroid = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void showNotification(RemoteMessage message) async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'high_importance_channel', // Same as the channel_id in FCM request
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
  }

  Future<String?> getCurrentUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    return user?.email;
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DatabaseReference userRef = _dbRef.child(user.uid);
        DataSnapshot snapshot = await userRef.get();
        if (snapshot.exists) {
          setState(() {
            _userName = snapshot.child('name').value.toString();
            _isLoading = false;
            _selectedIndex = widget.indexvalue;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Change the selected index in IndexedStack

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : IndexedStack(
                index: _selectedIndex,
                children: <Widget>[
                  Homepage(),
                  // VoiceToTextScreen(),
                  ImageToTextScreen(),
                  // TaskPlannerScreen(),
                  // CalendarTaskManagerScreen(),
                  // NotesSummarizerScreen(),
                  AddTaskScreen(),
                  TaskListScreen(),
                  CalendarTaskScreen(),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 40.0),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.schedule,
              // Icons.business_outlined,
              size: 40.0,
            ),
            label: 'campaign ',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add,
              // Icons.business_outlined,
              size: 40.0,
            ),
            label: 'Add ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_alt_outlined, size: 40.0),
            label: 'Goodness',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined, size: 40.0),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 1, 154, 123),
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }
}
