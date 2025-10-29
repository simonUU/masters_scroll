import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../../db/app_db.dart' as db;
import '../note_view_state.dart';

class StepCard extends StatefulWidget {
  final db.Step step;
  final VoidCallback? onDelete;

  const StepCard({
    super.key,
    required this.step,
    this.onDelete,
  });

  @override
  State<StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<StepCard> {
  late TextEditingController _titleController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.step.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _titleController.text = widget.step.title;
    });
  }

  Future<void> _saveChanges() async {
    if (!mounted) return;
    
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final noteViewState = context.read<NoteViewState>();
      
      await noteViewState.updateStep(
        context,
        widget.step.id,
        title: title,
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save step: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final noteViewState = context.read<NoteViewState>();
    await noteViewState.addStepImage(context, widget.step.id);
  }

  void _deleteStep() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Step'),
        content: const Text('Are you sure you want to delete this step?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          GestureDetector(
            onTap: _isEditing ? _pickImage : null,
            child: Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: widget.step.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(widget.step.imageUrl!),
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                          );
                        },
                      ),
                    )
                  : Icon(
                      _isEditing ? Icons.add_photo_alternate : Icons.image,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Text content
          Expanded(
            child: _isEditing
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          style: Theme.of(context).textTheme.bodyMedium,
                          decoration: const InputDecoration(
                            hintText: 'Step description...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          maxLines: null,
                          autofocus: true,
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else ...[
                        IconButton(
                          onPressed: _cancelEditing,
                          icon: const Icon(Icons.close, size: 16),
                          iconSize: 16,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          onPressed: _saveChanges,
                          icon: const Icon(Icons.check, size: 16),
                          iconSize: 16,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          onPressed: _deleteStep,
                          icon: const Icon(Icons.delete, size: 16),
                          iconSize: 16,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                          padding: EdgeInsets.zero,
                          color: Colors.red.shade400,
                        ),
                      ],
                    ],
                  )
                : GestureDetector(
                    onTap: _startEditing,
                    child: Text(
                      widget.step.title,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}