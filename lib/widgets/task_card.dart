import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onChangeDate;

  const TaskCard({Key? key, required this.task, required this.onChangeDate})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${task.category}'),
            Text(
              'End: ${task.endDateTime != null ? task.endDateTime!.toLocal().toString().split(' ')[0] : "Not set"}',
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_calendar, color: Colors.teal),
          onPressed: onChangeDate,
        ),
      ),
    );
  }
}
