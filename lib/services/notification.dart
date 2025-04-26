import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class NotificationService {
  static Future<String> getAccessToken() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/notifications_key/newapp-ddcc9-b550acee13ac.json',
      );

      final accountCredentials = auth.ServiceAccountCredentials.fromJson(
        jsonString,
      );

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await auth.clientViaServiceAccount(
        accountCredentials,
        scopes,
      );

      return client.credentials.accessToken.data;
    } catch (e) {
      print('Error occurred while sending notification: $e');
      rethrow; // Optionally rethrow the error if you want it to propagate
    }
  }

  static Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      final String accessToken = await getAccessToken();
      final FirebaseAuth auth = FirebaseAuth.instance;
      String? userId = auth.currentUser?.uid;
      final String fcmUrl =
          'https://fcm.googleapis.com/v1/projects/newapp-ddcc9/messages:send';

      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(<String, dynamic>{
          'message': {
            'token': token,
            'notification': {'title': title, 'body': body},
            'data': data,
            'android': {
              'notification': {
                "sound": "custom_sound",
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'channel_id': 'high_importance_channel',
              },
            },
            'apns': {
              'payload': {
                'aps': {"sound": "custom_sound.caf", 'content-available': 1},
              },
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        final DatabaseReference userNotificationsRef = FirebaseDatabase.instance
            .ref()
            .child("lifeassistant/notifications")
            .child(userId!);

        // Read current count
        final DataSnapshot snapshot = await userNotificationsRef.get();
        int currentCount = 0;

        if (snapshot.exists && snapshot.child("count").value != null) {
          currentCount =
              int.tryParse(snapshot.child("count").value.toString()) ?? 0;
        }

        // Increment the count
        final int newCount = currentCount + 1;

        // Push new notification
        await userNotificationsRef.push().set({
          'title': title,
          'body': body,
          'timestamp': ServerValue.timestamp,
          'isRead': false,
        });

        // Update the count value
        await userNotificationsRef.child("count").set(newCount);
      } else {}
    } catch (e) {
      print('Error occurred while sending notification: $e');
    }
  }
}
