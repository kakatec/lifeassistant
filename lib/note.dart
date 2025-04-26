import 'package:flutter/material.dart';
import 'notemodal.dart';
import 'usermodel.dart';
import 'database_helper.dart';

class NoteApp extends StatefulWidget {
  @override
  _NoteAppState createState() => _NoteAppState();
}

class _NoteAppState extends State<NoteApp> {
  List<Note> _notes = [];
  List<UserInfo> _users = [];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    final notes = await DatabaseHelper.instance.fetchNotes();
    final users = await DatabaseHelper.instance.fetchUsers();

    setState(() {
      _notes = notes;
      _users = users;
    });
  }

  void _addNote() async {
    final title = _titleController.text;
    final content = _contentController.text;

    if (title.isEmpty || content.isEmpty) return;

    await DatabaseHelper.instance.insertNote(
      Note(title: title, content: content),
    );
    _titleController.clear();
    _contentController.clear();
    _refreshData();
  }

  void _addUser() async {
    await DatabaseHelper.instance.insertUserInfo(
      UserInfo(name: "John", email: "john@example.com"),
    );
    _refreshData();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("User saved")));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('SQLite Notes & Users')),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Inputs
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(labelText: 'Content'),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: _addNote, child: Text('Add Note')),
                  ElevatedButton(onPressed: _addUser, child: Text('Add User')),
                ],
              ),
              SizedBox(height: 24),

              // Notes Section
              Text(
                "Notes",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return Card(
                    child: ListTile(
                      title: Text(note.title),
                      subtitle: Text(note.content),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          await DatabaseHelper.instance.deleteNote(note.id!);
                          _refreshData();
                        },
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),

              // Users Section
              Text(
                "Users",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return Card(
                    child: ListTile(
                      title: Text(user.name),
                      subtitle: Text(user.email),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
