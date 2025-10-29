// lib/src/ui/hierarchical_note_tree.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/app_db.dart';
import 'note_view_page_refactored.dart';

class HierarchicalNoteTree extends StatefulWidget {
  const HierarchicalNoteTree({Key? key}) : super(key: key);

  @override
  State<HierarchicalNoteTree> createState() => _HierarchicalNoteTreeState();
}

class _HierarchicalNoteTreeState extends State<HierarchicalNoteTree> {
  final Map<int, bool> _expandedStates = {};

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<AppDb>(context, listen: false);

    return StreamBuilder<List<Note>>(
      stream: db.watchHierarchicalNotes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allNotes = snapshot.data!;
        final rootNotes = allNotes.where((note) => note.parentId == null).toList();

        if (allNotes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_add, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No notes yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap the + button to create your first note',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Add a drop zone for root level
            DragTarget<Note>(
              onWillAccept: (draggedNote) => draggedNote != null,
              onAccept: (draggedNote) async {
                await _showMoveConfirmation(draggedNote, null);
              },
              builder: (context, candidateData, rejectedData) {
                final isReceivingDrag = candidateData.isNotEmpty;
                return Container(
                  height: isReceivingDrag ? 40 : 20,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: isReceivingDrag
                      ? BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          border: Border.all(color: Colors.blue, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  child: isReceivingDrag
                      ? const Center(
                          child: Text(
                            'Drop here to move to root level',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: rootNotes.length,
                itemBuilder: (context, index) {
                  return _buildNoteTree(rootNotes[index], allNotes, 0);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoteTree(Note note, List<Note> allNotes, int depth) {
    final db = Provider.of<AppDb>(context, listen: false);
    final children = allNotes.where((n) => n.parentId == note.id).toList();
    final hasChildren = children.isNotEmpty;
    final isExpanded = _expandedStates[note.id] ?? note.isExpanded;

    return Column(
      children: [
        // Note item with drag and drop
        Container(
          margin: EdgeInsets.only(left: depth * 20.0),
          child: DragTarget<Note>(
            onWillAccept: (draggedNote) => 
                draggedNote != null && 
                draggedNote.id != note.id && 
                !_isDescendant(note.id, draggedNote.id, allNotes),
            onAccept: (draggedNote) async {
              await _showMoveConfirmation(draggedNote, note);
            },
            builder: (context, candidateData, rejectedData) {
              final isReceivingDrag = candidateData.isNotEmpty;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: isReceivingDrag ? Colors.blue.withOpacity(0.1) : null,
                elevation: isReceivingDrag ? 4 : 1,
                child: Draggable<Note>(
                  data: note,
                  feedback: Material(
                    elevation: 6,
                    child: Container(
                      width: 250,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.drag_handle, color: Colors.blue),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              note.title.isNotEmpty ? note.title : 'Untitled Note',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.5,
                    child: _buildNoteContent(note, hasChildren, isExpanded, db),
                  ),
                  child: Dismissible(
                    key: Key('note_${note.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await _showDeleteConfirmation(context, note);
                    },
                    onDismissed: (direction) async {
                      await db.deleteNote(note.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Note "${note.title.isNotEmpty ? note.title : 'Untitled Note'}" deleted'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: _buildNoteContent(note, hasChildren, isExpanded, db),
                  ),
                ),
              );
            },
          ),
        ),
        // Children (if expanded)
        if (hasChildren && isExpanded)
          ...children.map((child) => _buildNoteTree(child, allNotes, depth + 1)),
      ],
    );
  }

  Widget _buildNoteContent(Note note, bool hasChildren, bool isExpanded, AppDb db) {
    return ListTile(
      leading: hasChildren
          ? IconButton(
              icon: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _expandedStates[note.id] = !isExpanded;
                });
                db.toggleNoteExpanded(note.id, !isExpanded);
              },
            )
          : const SizedBox(width: 48),
      title: Text(
        note.title.isNotEmpty ? note.title : 'Untitled Note',
        style: TextStyle(
          fontWeight: hasChildren ? FontWeight.w600 : FontWeight.w500,
          color: hasChildren ? Colors.blue[800] : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.content != null && note.content!.isNotEmpty)
            Text(
              _extractPlainText(note.content!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          Text(
            _formatDate(note.createdAt),
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 20),
        onSelected: (value) async {
          switch (value) {
            case 'add_child':
              await _createChildNote(note.id);
              break;
            case 'move':
              await _showMoveDialog(note);
              break;
            case 'delete':
              final shouldDelete = await _showDeleteConfirmation(context, note);
              if (shouldDelete == true) {
                await db.deleteNote(note.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Note "${note.title.isNotEmpty ? note.title : 'Untitled Note'}" deleted'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'add_child',
            child: Row(
              children: [
                Icon(Icons.add, color: Colors.green),
                SizedBox(width: 8),
                Text('Add Sub-note'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'move',
            child: Row(
              children: [
                Icon(Icons.move_up, color: Colors.blue),
                SizedBox(width: 8),
                Text('Move'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => NoteViewPageRefactored(noteId: note.id),
          ),
        );
      },
    );
  }

  Future<void> _showMoveConfirmation(Note draggedNote, Note? targetParent) async {
    final targetName = targetParent?.title.isNotEmpty == true 
        ? targetParent!.title 
        : 'Root Level';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Move'),
        content: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              const TextSpan(text: 'Move '),
              TextSpan(
                text: '"${draggedNote.title.isNotEmpty ? draggedNote.title : 'Untitled Note'}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' to '),
              TextSpan(
                text: '"$targetName"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Move'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = Provider.of<AppDb>(context, listen: false);
      await db.moveNote(draggedNote.id, targetParent?.id, 0);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moved "${draggedNote.title.isNotEmpty ? draggedNote.title : 'Untitled Note'}" to $targetName'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, Note note) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title.isNotEmpty ? note.title : 'Untitled Note'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _createChildNote(int parentId) async {
    final db = Provider.of<AppDb>(context, listen: false);
    final noteId = await db.createNote('New Sub-note', '', parentId: parentId);
    if (mounted) {
      // Expand parent to show the new child
      setState(() {
        _expandedStates[parentId] = true;
      });
      await db.toggleNoteExpanded(parentId, true);
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NoteViewPageRefactored(noteId: noteId, startInEditMode: true),
        ),
      );
    }
  }

  Future<void> _showMoveDialog(Note note) async {
    final db = Provider.of<AppDb>(context, listen: false);
    final allNotes = await db.watchHierarchicalNotes().first;
    final possibleParents = allNotes.where((n) => n.id != note.id && !_isDescendant(n.id, note.id, allNotes)).toList();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move "${note.title.isNotEmpty ? note.title : 'Untitled Note'}"'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              ListTile(
                title: const Text('Root Level'),
                leading: const Icon(Icons.home),
                onTap: () async {
                  await db.moveNote(note.id, null, 0);
                  Navigator.of(context).pop();
                },
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: possibleParents.length,
                  itemBuilder: (context, index) {
                    final parent = possibleParents[index];
                    return ListTile(
                      title: Text(parent.title.isNotEmpty ? parent.title : 'Untitled Note'),
                      leading: const Icon(Icons.folder),
                      onTap: () async {
                        await db.moveNote(note.id, parent.id, 0);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  bool _isDescendant(int potentialParentId, int nodeId, List<Note> allNotes) {
    final descendants = _getAllDescendants(nodeId, allNotes);
    return descendants.contains(potentialParentId);
  }

  Set<int> _getAllDescendants(int nodeId, List<Note> allNotes) {
    final descendants = <int>{};
    final children = allNotes.where((n) => n.parentId == nodeId);
    
    for (final child in children) {
      descendants.add(child.id);
      descendants.addAll(_getAllDescendants(child.id, allNotes));
    }
    
    return descendants;
  }

  String _extractPlainText(String content) {
    try {
      final List<dynamic> ops = jsonDecode(content);
      final buffer = StringBuffer();
      for (final op in ops) {
        if (op['insert'] is String) {
          buffer.write(op['insert']);
        }
      }
      return buffer.toString().trim();
    } catch (_) {
      return content.length > 100 ? '${content.substring(0, 100)}...' : content;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}