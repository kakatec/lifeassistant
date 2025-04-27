import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  String? userName;
  String? userEmail;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user data from Firebase
  Future<void> _fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        final userSnapshot =
            await _database.child('lifeassistant/users/${user.uid}').once();
        final userData = userSnapshot.snapshot.value as Map<dynamic, dynamic>?;

        setState(() {
          userName = userData?['name'] ?? 'Guest User';
          userEmail = userData?['email'] ?? 'guest@example.com';
          photoUrl = userData?['photoUrl'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching user data: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Profile Picture and User Details
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[300],
              backgroundImage:
                  photoUrl != null
                      ? NetworkImage(photoUrl!) // Load the image from URL
                      : null, // If no image URL, fallback to default icon
              child:
                  photoUrl == null
                      ? const Icon(Icons.person, size: 80, color: Colors.white)
                      : null,
            ),
            const SizedBox(height: 10),
            Text(
              userName ?? 'Loading...',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              userEmail ?? 'Loading...',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            // List of Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildProfileOption(
                    icon: Icons.person,
                    title: 'My profile',
                    onTap: () {
                      Navigator.pushNamed(context, '/editprofile');
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildProfileOption(
                    icon: Icons.credit_card,
                    title: 'Summarization',
                    onTap: () {
                      Navigator.pushNamed(context, '/history');
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildProfileOption(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.pushNamed(context, '/notification');
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildProfileOption(
                    icon: Icons.lock,
                    title: 'Privacy policy',
                    onTap: () {
                      // Add your onTap action here
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildProfileOption(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () async {
                      await _auth.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for Profile Option ListTile
  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      tileColor: Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
