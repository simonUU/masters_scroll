// lib/src/ui/note_view/sections/title_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../note_view_state.dart';
import '../widgets/simple_section.dart';

class TitleSection extends StatelessWidget {
  const TitleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteViewState>(
      builder: (context, state, child) {
        return SimpleSection(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: state.isEditing
              ? TextField(
                  controller: state.titleController,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter note title...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : Text(
                  state.currentNote?.title ?? 'Untitled Note',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        );
      },
    );
  }
}