// lib/src/ui/note_view/sections/title_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../note_view_state.dart';
import '../widgets/section_card.dart';

class TitleSection extends StatefulWidget {
  const TitleSection({super.key});

  @override
  State<TitleSection> createState() => _TitleSectionState();
}

class _TitleSectionState extends State<TitleSection> {
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteViewState>(
      builder: (context, state, child) {
        // Update controller text when note changes
        if (_titleController.text != (state.currentNote?.title ?? '')) {
          _titleController.text = state.currentNote?.title ?? '';
        }

        return SectionCard(
          title: 'Title',
          icon: Icons.title,
          headerColor: Colors.blue[50],
          child: state.isEditing
              ? TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter note title...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    state.titleController.text = value;
                  },
                )
              : state.currentNote?.title.isNotEmpty == true
                  ? Text(
                      state.currentNote!.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Text(
                      'Untitled Note',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
        );
      },
    );
  }
}