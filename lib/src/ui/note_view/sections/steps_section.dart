// lib/src/ui/note_view/sections/steps_section.dart
import 'package:flutter/material.dart' hide Step;
import 'package:provider/provider.dart';
import '../../../db/app_db.dart';
import '../note_view_state.dart';
import '../widgets/section_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/step_card.dart';

class StepsSection extends StatelessWidget {
  const StepsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteViewState>(
      builder: (context, state, child) {
        return SectionCard(
          title: 'Steps',
          icon: Icons.list_alt,
          headerColor: Colors.purple[50],
          trailing: state.isEditing
              ? IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addNewStep(context, state),
                )
              : null,
          child: state.steps.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.list_alt,
                  message: 'No steps added yet',
                  subtitle: 'Break down your technique into steps',
                )
              : _buildStepsList(state),
        );
      },
    );
  }

  Widget _buildStepsList(NoteViewState state) {
    return Builder(
      builder: (context) {
        if (!state.isEditing) {
          // Static list when not editing
          return Column(
            children: state.steps
                .map((step) => StepCard(
                      step: step,
                      onDelete: () => _deleteStep(context, state, step.id),
                    ))
                .toList(),
          );
        }

        // Reorderable list when editing
        return ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.steps.length,
          onReorder: (oldIndex, newIndex) {
            _reorderSteps(context, state, oldIndex, newIndex);
          },
          itemBuilder: (context, index) {
            final step = state.steps[index];
            return Container(
              key: ValueKey(step.id),
              child: StepCard(
                step: step,
                onDelete: () => _deleteStep(context, state, step.id),
              ),
            );
          },
        );
      },
    );
  }

  void _reorderSteps(BuildContext context, NoteViewState state, int oldIndex, int newIndex) {
    final steps = List.of(state.steps);
    if (newIndex > oldIndex) newIndex--;
    final step = steps.removeAt(oldIndex);
    steps.insert(newIndex, step);
    
    // Update step orders
    final reorderedSteps = steps.asMap().entries.map((entry) {
      final newStep = entry.value;
      return Step(
        id: newStep.id,
        noteId: newStep.noteId,
        stepOrder: entry.key,
        title: newStep.title,
        description: newStep.description,
        imageUrl: newStep.imageUrl,
        duration: newStep.duration,
        notes: newStep.notes,
        createdAt: newStep.createdAt,
      );
    }).toList();
    
    state.reorderSteps(context, reorderedSteps);
  }

  void _addNewStep(BuildContext context, NoteViewState state) {
    // Add a new step with default title that automatically enters edit mode
    state.addStep(context, 'New Step');
  }

  void _deleteStep(BuildContext context, NoteViewState state, int stepId) {
    state.deleteStep(context, stepId);
  }
}