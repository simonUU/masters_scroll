// lib/src/ui/note_view/sections/media_section.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../note_view_state.dart';
import '../widgets/simple_section.dart';
import '../widgets/empty_state_widget.dart';

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
          padding: EdgeInsets.zero,
          backgroundColor: state.media.isNotEmpty ? Colors.grey.shade50 : null,
          child: Column(
            children: [
              // Add photo button when editing
              if (state.isEditing)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => state.addImage(context),
                      icon: const Icon(Icons.add_a_photo),
                      label: const Text('Add Photo'),
                    ),
                  ),
                ),
              
              // Media grid or empty state
              if (state.media.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: EmptyStateWidget(
                    icon: Icons.photo,
                    message: 'No media added yet',
                    subtitle: 'Tap "Add Photo" to get started',
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: state.media.length,
                    itemBuilder: (context, index) {
                      final mediaItem = state.media[index];
                      return _MediaThumbnail(
                        mediaItem: mediaItem,
                        onTap: () => _showMediaFullScreen(context, mediaItem),
                      );
                    },
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
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Image.file(
                File(mediaItem.path),
                fit: BoxFit.contain,
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

class _MediaThumbnail extends StatelessWidget {
  final dynamic mediaItem;
  final VoidCallback onTap;

  const _MediaThumbnail({
    required this.mediaItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(mediaItem.path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}