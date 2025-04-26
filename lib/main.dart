import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lifeassistant/authwrapper.dart';
import 'package:lifeassistant/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(primarySwatch: Colors.orange),
      home:
          const AuthWrapper(), // AuthWrapper(), // Wrapper to handle auth state OnBoard
      routes: AppRoutes.getRoutes(), // Use the defined routes
    );
  }
}
