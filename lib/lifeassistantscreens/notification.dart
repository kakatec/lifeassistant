import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref().child(
    "lifeassistant/notifications",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(0, 137, 123, 1),
                Color.fromRGBO(0, 137, 123, 1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(
              context,
            ); // This pops the current screen off the stack
          },
        ),
      ),
      body: StreamBuilder(
        stream: dbRef.child(userId).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No notifications yet"));
          }

          Map<dynamic, dynamic> notifications =
              (snapshot.data!.snapshot.value as Map<dynamic, dynamic>);

          List<Map<String, dynamic>> notificationList =
              notifications.entries
                  .where(
                    (entry) => entry.key != 'count',
                  ) // 👈 filter out the count
                  .map((entry) {
                    return {
                      'id': entry.key,
                      ...Map<String, dynamic>.from(entry.value),
                    };
                  })
                  .toList();

          notificationList.sort(
            (a, b) => b['timestamp'].compareTo(a['timestamp']),
          );

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: notificationList.length,
            itemBuilder: (context, index) {
              var notification = notificationList[index];
              bool isRead = notification['isRead'] ?? false;

              return GestureDetector(
                onTap: () => _showNotificationPopup(notification),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      if (!isRead)
                        const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(
                            Icons.notifications,
                            color: Color.fromARGB(255, 12, 128, 134),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              notification['body'],
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showNotificationPopup(Map<String, dynamic> notification) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(notification['title']),
          content: SingleChildScrollView(child: Text(notification['body'])),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );

    // Only proceed if the notification is unread
    if (!(notification['isRead'] ?? false)) {
      // Mark notification as read
      await dbRef.child(userId).child(notification['id']).update({
        'isRead': true,
      });

      // Get the current count
      final countSnapshot = await dbRef.child(userId).child('count').get();
      int currentCount = 0;
      if (countSnapshot.exists) {
        currentCount = int.tryParse(countSnapshot.value.toString()) ?? 0;
      }

      // Decrease count (not below 0)
      int newCount = currentCount > 0 ? currentCount - 1 : 0;

      // Update the count in Firebase
      await dbRef.child(userId).child('count').set(newCount);
    }
  }
}
