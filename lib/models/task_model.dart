class TaskModel {
  final String id;
  final String title;
  final String category;
  final DateTime createdAt;
  DateTime? endDateTime;

  TaskModel({
    required this.id,
    required this.title,
    required this.category,
    required this.createdAt,
    this.endDateTime,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      title: map['taskInput'] ?? '',
      category: map['category'] ?? 'N/A',
      createdAt: DateTime.parse(map['createdAt']),
      endDateTime:
          map['endDateTime'] != null && map['endDateTime'] != ''
              ? DateTime.parse(map['endDateTime'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskInput': title,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String() ?? '',
    };
  }
}
