class Note {
  final int? id;
  final String title;
  final String content;

  Note({this.id, required this.title, required this.content});

  // Convert a Note into a Map
  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'content': content};
  }

  // Convert a Map into a Note
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(id: map['id'], title: map['title'], content: map['content']);
  }
}
