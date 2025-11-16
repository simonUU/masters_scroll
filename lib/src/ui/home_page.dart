// lib/src/ui/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/app_db.dart';
import 'hierarchical_note_tree.dart';
import 'note_view_page_refactored.dart';
import '../constants/design_constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDb>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.sectionBackground,
      appBar: AppBar(
        title: const Text('Martial Notes'),
        backgroundColor: AppColors.cardBackground,
      ),
      body: StreamBuilder<List<Note>>(
        stream: db.watchHierarchicalNotes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final notes = snapshot.data!;
          
          if (notes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_tree, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notes yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create your martial arts knowledge tree',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Example: School > Class > Technique',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          return const HierarchicalNoteTree();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final id = await db.createNote('New Note', '');
          if (mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NoteViewPageRefactored(noteId: id, startInEditMode: true),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
