import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../../../db/app_db.dart' as db;
import '../note_view_state.dart';
import '../../../constants/design_constants.dart';

class StepCard extends StatefulWidget {
  final db.Step step;
  final VoidCallback? onDelete;
  final bool startInEditMode;

  const StepCard({
    super.key,
    required this.step,
    this.onDelete,
    this.startInEditMode = false,
  });

  @override
  State<StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<StepCard> {
  late TextEditingController _titleController;
  late FocusNode _titleFocusNode;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.step.title);
    _titleFocusNode = FocusNode();
    _isEditing = widget.startInEditMode;
    
    // If starting in edit mode, focus and select all text after build
    if (widget.startInEditMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
        _titleController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _titleController.text.length,
        );
        
        // Clear the newly added step tracking in the parent state
        final noteViewState = Provider.of<NoteViewState>(context, listen: false);
        noteViewState.clearNewlyAddedStepId();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    
    // Focus the text field and select all text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
      _titleController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _titleController.text.length,
      );
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
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteText),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: AppSpacing.stepCardMargin,
      padding: AppSpacing.stepCardPadding,
      decoration: BoxDecoration(
        color: AppColors.stepCardBackground,
        borderRadius: BorderRadius.circular(AppStyling.stepCardBorderRadius),
        border: Border.all(
          color: AppColors.stepCardBorder,
          width: AppStyling.defaultBorderWidth,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              GestureDetector(
                onTap: _isEditing ? _pickImage : (widget.step.imageUrl != null ? () => _showFullScreenImage(context) : null),
                child: Container(
                  width: AppSpacing.stepImageWidth,
                  height: AppSpacing.stepImageHeight,
                  decoration: BoxDecoration(
                    color: AppColors.imagePlaceholderBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.stepImageBorderRadius),
                  ),
                  child: widget.step.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppSpacing.stepImageBorderRadius),
                          child: Image.file(
                            File(widget.step.imageUrl!),
                            width: AppSpacing.stepImageWidth,
                            height: AppSpacing.stepImageHeight,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.imageErrorBackground,
                                child: Icon(
                                  Icons.broken_image,
                                  color: AppColors.iconColor,
                                  size: AppStyling.mediumIcon,
                                ),
                              );
                            },
                          ),
                        )
                      : Icon(
                          _isEditing ? Icons.add_photo_alternate : Icons.image,
                          color: AppColors.iconColor,
                          size: AppStyling.largeIcon,
                        ),
                ),
              ),
              SizedBox(width: AppSpacing.stepImageToTextSpacing),
              
              // Text content
              Expanded(
                child: _isEditing
                    ? Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _titleController,
                              focusNode: _titleFocusNode,
                              style: Theme.of(context).textTheme.bodyMedium,
                              decoration: const InputDecoration(
                                hintText: 'Step description...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                              maxLines: null,
                              autofocus: _isEditing,
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
                              icon: Icon(Icons.delete, size: AppStyling.smallIcon),
                              iconSize: AppStyling.smallIcon,
                              constraints: AppStyling.actionButtonConstraints,
                              padding: EdgeInsets.zero,
                              color: AppColors.deleteButton,
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
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    if (widget.step.imageUrl == null) return;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Image.file(
                File(widget.step.imageUrl!),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 50,
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}