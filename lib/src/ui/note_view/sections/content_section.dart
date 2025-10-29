// lib/src/ui/note_view/sections/content_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import '../note_view_state.dart';
import '../widgets/simple_section.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/quill_toolbar.dart';

class ContentSection extends StatelessWidget {
  const ContentSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteViewState>(
      builder: (context, state, child) {
        return SimpleSection(
          showBorder: true,
          backgroundColor: Colors.white,
          child: Column(
            children: [
              if (state.isEditing) ...[
                CustomQuillToolbar(controller: state.quillController),
                const SizedBox(height: 12),
              ],
              SizedBox(
                height: 200,
                child: _buildQuillEditor(state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuillEditor(NoteViewState state) {
    final controller = state.isEditing 
        ? state.quillController 
        : state.readOnlyController;
    
    final isEmpty = controller.document.isEmpty() ||
        (controller.document.length == 1 && 
         controller.document.toPlainText().trim().isEmpty);

    if (!state.isEditing && isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.edit_note,
        message: 'No content yet',
        subtitle: 'Tap edit to add content',
      );
    }

    return QuillEditor(
      controller: controller,
      focusNode: FocusNode(),
      scrollController: ScrollController(),
    );
  }
}