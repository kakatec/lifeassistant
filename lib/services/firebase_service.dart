import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/task_model.dart';

class FirebaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'lifeassistant/tasks',
  );

  Future<List<TaskModel>> fetchTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await _dbRef.child(user.uid).get();
    List<TaskModel> tasks = [];

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        tasks.add(TaskModel.fromMap(Map<String, dynamic>.from(value), key));
      });
    }

    return tasks;
  }

  Future<void> updateTaskEndDate(String taskId, DateTime newEndDate) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _dbRef.child(user.uid).child(taskId).update({
      'endDateTime': newEndDate.toIso8601String(),
    });
  }
}
