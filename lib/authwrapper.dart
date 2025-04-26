import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lifeassistant/mainscreen.dart';
import 'package:lifeassistant/onboardingscreens.dart/onboarding.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the user is logged in, go to HomeScreen
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          if (user == null) {
            return const OnboardingScreen(); // If not logged in, show onboarding
          } else {
            // return const OnboardingScreen();
            return const MainScreen(
              indexvalue: 0,
            ); // Navigate to home if logged in
          }
        }

        // Show a loading indicator while checking auth state
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
