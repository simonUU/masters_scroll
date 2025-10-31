// lib/src/ui/note_view/sections/steps_section.dart
import 'package:flutter/material.dart' hide Step;
import 'package:provider/provider.dart';
import '../../../db/app_db.dart';
import '../note_view_state.dart';
import '../widgets/simple_section.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/step_card.dart';

class StepsSection extends StatelessWidget {
  const StepsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteViewState>(
      builder: (context, state, child) {
        if (state.steps.isEmpty && !state.isEditing) {
          return const SizedBox.shrink(); // Hide when empty and not editing
        }
        
        return SimpleSection(
          showBorder: true,
          backgroundColor: Colors.white,
          child: Column(
            children: [
              // Steps list or empty state
              if (state.steps.isEmpty)
                const EmptyStateWidget(
                  icon: Icons.list_alt,
                  message: 'No steps added yet',
                  subtitle: 'Break down your technique into steps',
                )
              else
                _buildStepsList(state),
              
              // Add step button when editing - now positioned after the steps
              if (state.isEditing) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addNewStep(context, state),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Step'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => state.openCameraMode(context),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera Mode'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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
                      startInEditMode: step.id == state.newlyAddedStepId,
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
                startInEditMode: step.id == state.newlyAddedStepId,
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

  void _deleteStep(BuildContext context, NoteViewState state, String stepId) {
    state.deleteStep(context, stepId);
  }
}