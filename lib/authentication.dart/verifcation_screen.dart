import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:lifeassistant/routes.dart';

class VerificationScreen extends StatefulWidget {
  final User user;
  final String name;
  final String email;

  final String phone;
  final String? fcmtoken;
  final String address;

  const VerificationScreen({
    super.key,
    required this.user,
    required this.name,
    required this.email,
    required this.phone,
    required this.fcmtoken,

    this.address = '',
  });

  @override
  VerificationScreenState createState() => VerificationScreenState();
}

class VerificationScreenState extends State<VerificationScreen> {
  bool _isVerified = false;
  bool _isLoading = false;
  Timer? _timer;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkEmailVerified();

    // Start timer to check email verification every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerified();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Periodically check email verification status
  Future<void> _checkEmailVerified() async {
    await widget.user.reload(); // Reload the user to get latest info
    User? user = _auth.currentUser;

    if (user != null && user.emailVerified) {
      setState(() {
        _isVerified = true;
      });
      _timer?.cancel(); // Stop checking once verified
    }
  }

  // Function to handle "Next" button click
  Future<void> _onNext() async {
    if (_isVerified) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Store user info in Firebase Realtime Database
        await FirebaseDatabase.instance
            .ref()
            .child('lifeassistant/users')
            .child(widget.user.uid)
            .set({
              'name': widget.name,
              'email': widget.email,
              'phone': widget.phone,
              'address': widget.address.isNotEmpty ? widget.address : '',
              'isActive': true,
              'fcm_token': widget.fcmtoken,
              'profilePicture': '',
              'created_at': DateTime.now().toIso8601String(),
            });

        // Navigate to Home Screen
        Navigator.pushReplacementNamed(context, AppRoutes.mainnav);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email before proceeding.'),
        ),
      );
    }
  }

  // Optional: Function to resend verification email
  Future<void> _resendVerificationEmail() async {
    try {
      await widget.user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email resent. Please check your email.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resending email: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please verify your email address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'We have sent a verification link to your email. Please check your inbox and verify your account.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            // User Information Fields (Non-editable)
            Text('Name: ${widget.name}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text(
              'Email: ${widget.email}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Phone: ${widget.phone}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Address: ${widget.address.isNotEmpty ? widget.address : 'Not provided'}',
              style: const TextStyle(fontSize: 16),
            ),

            const Spacer(),

            // Optionally, add a button to resend verification email
            if (!_isVerified)
              Center(
                child: TextButton(
                  onPressed: _resendVerificationEmail,
                  child: const Text('Resend Verification Email'),
                ),
              ),

            // Next Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerified && !_isLoading ? _onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isVerified ? Colors.green : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                        : const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
