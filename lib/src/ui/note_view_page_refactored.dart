// lib/src/ui/note_view_page_refactored.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'note_view/note_view_state.dart';
import 'note_view/sections/title_section.dart';
import 'note_view/sections/media_section.dart';
import 'note_view/sections/content_section.dart';
import 'note_view/sections/steps_section.dart';
import 'note_view/sections/metadata_section.dart';

class NoteViewPageRefactored extends StatefulWidget {
  final int noteId;
  final bool startInEditMode;

  const NoteViewPageRefactored({
    Key? key,
    required this.noteId,
    this.startInEditMode = false,
  }) : super(key: key);

  @override
  State<NoteViewPageRefactored> createState() => _NoteViewPageRefactoredState();
}

class _NoteViewPageRefactoredState extends State<NoteViewPageRefactored> {
  late NoteViewState _state;

  @override
  void initState() {
    super.initState();
    _state = NoteViewState(
      noteId: widget.noteId,
      startInEditMode: widget.startInEditMode,
    );
    
    // Load the note after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _state.loadNote(context);
    });
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NoteViewState>.value(
      value: _state,
      child: Consumer<NoteViewState>(
        builder: (context, state, child) {
          return PopScope(
            canPop: !state.isEditing,
            onPopInvokedWithResult: (didPop, result) async {
              if (!didPop && state.isEditing) {
                await state.saveNote(context);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(state.currentNote?.title ?? 'Note'),
                elevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black87,
                actions: [
                  if (state.isEditing)
                    TextButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      onPressed: () async {
                        await state.saveNote(context);
                        state.toggleEditMode();
                      },
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: state.toggleEditMode,
                    ),
                ],
              ),
              body: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // Title section with padding
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: TitleSection(),
                          ),
                          const SizedBox(height: 16),
                          
                          // Media section spans full width (no padding)
                          const MediaSection(),
                          const SizedBox(height: 16),
                          
                          // Content and other sections with padding
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                ContentSection(),
                                SizedBox(height: 16),
                                StepsSection(),
                                SizedBox(height: 16),
                                MetadataSection(),
                                SizedBox(height: 32), // Extra bottom padding
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}