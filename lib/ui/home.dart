import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:note_taking/service/databaseHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  final Function(bool) onThemeChanged;

  Home({super.key, required this.onThemeChanged});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, dynamic>> _allNotes = [];
  bool _isLoadingNote = true;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isDarkMode = false;

  Future<void> _loadThemePreferences() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = pref.getBool('isDarkMode') ?? false;
    });
  }

  void _toggleTheme(bool value) async {
    setState(() {
      _isDarkMode = value;
      widget.onThemeChanged(_isDarkMode);
    });
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setBool('isDarkMode', _isDarkMode); // Save the theme preference
  }

  void _reloadNotes() async {
    final note = await QueryHelper.getAllNotes();
    setState(() {
      _allNotes = note;
      _isLoadingNote = false;
    });
  }

  Future<void> _addNotes() async {
    await QueryHelper.createNote(_titleController.text, _descriptionController.text);
    _reloadNotes();
  }

  Future<void> _updateNote(int id) async {
    await QueryHelper.updateNote(id, _titleController.text, _descriptionController.text);
    _reloadNotes();
  }

  void _deleteNote(int id) async {
    await QueryHelper.deleteNote(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Note has been deleted!")),
    );
    _reloadNotes();
  }

  void _deleteAllNotes() async {
    final noteCount = await QueryHelper.getNoteCount();
    if (noteCount > 0) {
      await QueryHelper.deleteAllNotes();
      _reloadNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All notes have been deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No notes to delete')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _reloadNotes();
    _loadThemePreferences();
  }

  // Input note without navigating to another screen
  void showBottomSheetContent(int? id) async {
    if (id != null) {
      final currentNote = _allNotes.firstWhere((element) => element['id'] == id);
      _titleController.text = currentNote['title'];
      _descriptionController.text = currentNote['description'];
    }

    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: 15,
                  left: 15,
                  right: 15,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Note Title',
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Description ',
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: OutlinedButton(
                        onPressed: () async {
                          if (id == null) {
                            await _addNotes();
                          }
                          if (id != null) {
                            await _updateNote(id);
                          }
                          _titleController.text = "";
                          _descriptionController.text = "";
                          Navigator.of(context).pop();
                        },
                        child: Text(id == null ? "Add Note" : "Update Note"),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255,199,21,133),
        actions: [
          IconButton(
            onPressed: () async {
              _deleteAllNotes();
            },
            icon: Icon(Icons.delete_forever),
          color: Colors.black,
          ),
          IconButton(
            onPressed: () {
              _appExit();
            },
            icon: Icon(Icons.exit_to_app),
            color: Colors.black,
          ),
          Transform.scale(
            scale: 1.0,
            child: Switch(
              value: _isDarkMode,
              onChanged: (value) {
                _toggleTheme(value);
              },


            ),

          ),
        ],
        title: const Text('Notes',style: TextStyle(color: Colors.white,fontFamily: 'RaleWay'),),
      ),
      body: SafeArea(
        child: _isLoadingNote
            ? Center(
          child: CircularProgressIndicator(),
        )
            : ListView.builder(
          itemCount: _allNotes.length,
          itemBuilder: (context, index) => Card(
            margin: EdgeInsets.all(16),
            child: ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        _allNotes[index]['title'],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          showBottomSheetContent(_allNotes[index]['id']);
                        },
                        icon: Icon(Icons.edit,),

                      ),
                      IconButton(
                        onPressed: () {
                          _deleteNote(_allNotes[index]['id']);
                        },
                        icon: Icon(Icons.delete),
                      ),
                    ],
                  ),
                ],
              ),
              subtitle: Text(
                _allNotes[index]['description'],
                style: TextStyle(
                  fontSize: 22,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showBottomSheetContent(null);
        },
        child: const Icon(Icons.add),
        backgroundColor: Color.fromARGB(255,188,143,143),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _appExit() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to exit the app'),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                SystemNavigator.pop(); // Exit the app
              },
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }
}
