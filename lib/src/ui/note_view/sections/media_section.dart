// lib/src/ui/note_view/sections/media_section.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../note_view_state.dart';
import '../widgets/simple_section.dart';
import '../widgets/empty_state_widget.dart';
import '../../../constants/design_constants.dart';

class MediaSection extends StatelessWidget {
  const MediaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteViewState>(
      builder: (context, state, child) {
        if (state.media.isEmpty && !state.isEditing) {
          return const SizedBox.shrink(); // Hide when empty and not editing
        }
        
        return SimpleSection(
          padding: AppSpacing.zero,
          backgroundColor: state.media.isNotEmpty ? AppColors.mediaBackground : null,
          child: Column(
            children: [
              // Add photo button when editing
              if (state.isEditing)
                Container(
                  padding: AppSpacing.sectionPadding,
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => state.addImage(context),
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Add Photo'),
                    ),
                  ),
                ),
              
              // Media horizontal scroll or empty state
              if (state.media.isEmpty)
                Padding(
                  padding: AppSpacing.sectionPadding,
                  child: const EmptyStateWidget(
                    icon: Icons.photo,
                    message: 'No media added yet',
                    subtitle: 'Tap "Add Photo" to get started',
                  ),
                )
              else
                Padding(
                  padding: AppSpacing.mediaBottomPadding,
                  child: SizedBox(
                    height: MediaSpacing.thumbnailSize,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: AppSpacing.zero,
                      itemCount: state.media.length,
                      itemBuilder: (context, index) {
                        final mediaItem = state.media[index];
                        return _MediaThumbnail(
                          mediaItem: mediaItem,
                          isEditing: state.isEditing,
                          onTap: () => _showMediaFullScreen(context, mediaItem),
                          onDelete: state.isEditing 
                            ? () => _confirmDeleteMedia(context, state, mediaItem)
                            : null,
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showMediaFullScreen(BuildContext context, dynamic mediaItem) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.fullScreenOverlay,
        child: Stack(
          children: [
            Center(
              child: Image.file(
                File(mediaItem.path),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: AppSpacing.dialogPositioning,
              right: AppSpacing.dialogPositioning,
              child: IconButton(
                icon: Icon(Icons.close, color: AppColors.fullScreenContent),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMedia(BuildContext context, NoteViewState state, dynamic mediaItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              state.deleteMedia(context, mediaItem.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.deleteText),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  final dynamic mediaItem;
  final bool isEditing;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _MediaThumbnail({
    required this.mediaItem,
    required this.isEditing,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          SizedBox(
            width: MediaSpacing.thumbnailSize,
            height: MediaSpacing.thumbnailSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppStyling.imageBorderRadius),
              child: Image.file(
                File(mediaItem.path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.imageErrorBackground,
                    child: Icon(
                      Icons.broken_image,
                      color: AppColors.iconColor,
                    ),
                  );
                },
              ),
            ),
          ),
          // Delete button when editing
          if (isEditing && onDelete != null)
            Positioned(
              top: AppSpacing.small,
              right: AppSpacing.small,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.deleteButton,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppColors.fullScreenContent,
                    size: AppStyling.smallIcon,
                  ),
                  padding: EdgeInsets.all(AppSpacing.small / 2),
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: onDelete,
                ),
              ),
            ),
        ],
      ),
    );
  }
}