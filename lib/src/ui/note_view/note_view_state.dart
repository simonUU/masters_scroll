// lib/src/ui/note_view/note_view_state.dart
import 'dart:convert';
import 'package:flutter/material.dart' hide Step;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../db/app_db.dart';
import '../../services/camera_service.dart';
import '../camera/camera_screen.dart';

class NoteViewState extends ChangeNotifier {
  final String noteId;
  final bool startInEditMode;
  
  // Controllers
  final _titleController = TextEditingController();
  late QuillController _quillController;
  late QuillController _readOnlyController;
  
  // State variables
  bool _isLoading = true;
  bool _isEditing = false;
  List<MediaItem> _media = [];
  List<Step> _steps = [];
  Note? _currentNote;
  String? _newlyAddedStepId;
  
  // Getters
  TextEditingController get titleController => _titleController;
  QuillController get quillController => _quillController;
  QuillController get readOnlyController => _readOnlyController;
  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;
  List<MediaItem> get media => _media;
  List<Step> get steps => _steps;
  Note? get currentNote => _currentNote;
  String? get newlyAddedStepId => _newlyAddedStepId;
  
  NoteViewState({required this.noteId, this.startInEditMode = false}) {
    _isEditing = startInEditMode;
    _quillController = QuillController.basic();
    _readOnlyController = QuillController.basic();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _readOnlyController.dispose();
    super.dispose();
  }
  
  Future<void> loadNote(BuildContext context) async {
    try {
      final db = Provider.of<AppDb>(context, listen: false);
      final note = await (db.select(db.notes)..where((t) => t.id.equals(noteId))).getSingle();
      
      _currentNote = note;
      _titleController.text = note.title;
      
      if (note.content != null && note.content!.isNotEmpty) {
        try {
          final deltaJson = jsonDecode(note.content!);
          final document = Document.fromJson(deltaJson);
          
          // Create both editable and read-only controllers with the same content
          _quillController = QuillController(
            document: document,
            selection: const TextSelection.collapsed(offset: 0),
          );
          
          _readOnlyController = QuillController(
            document: Document.fromJson(deltaJson),
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (e) {
          print('Error parsing note content: $e');
          _quillController = QuillController.basic();
          _readOnlyController = QuillController.basic();
        }
      }

      final media = await db.getMediaForNoteOnce(noteId);
      _media = media;
      
      final steps = await db.getStepsForNote(noteId);
      _steps = steps;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading note: $e');
      _isLoading = false;
      notifyListeners();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading note: $e')),
        );
      }
    }
  }
  
  Future<void> saveNote(BuildContext context) async {
    try {
      final db = Provider.of<AppDb>(context, listen: false);
      final delta = _quillController.document.toDelta();
      final content = jsonEncode(delta.toJson());
      
      final newTitle = _titleController.text.trim().isEmpty ? 'Untitled Note' : _titleController.text.trim();
      
      await db.updateNoteContent(noteId, content, title: newTitle);
      
      // Update the read-only controller with the new content
      final deltaJson = jsonDecode(content);
      _readOnlyController = QuillController(
        document: Document.fromJson(deltaJson),
        selection: const TextSelection.collapsed(offset: 0),
      );
      
      if (_currentNote != null) {
        // Update the note object for display
        _currentNote = Note(
          id: _currentNote!.id,
          title: newTitle,
          content: content,
          parentId: _currentNote!.parentId,
          sortOrder: _currentNote!.sortOrder,
          isExpanded: _currentNote!.isExpanded,
          createdAt: _currentNote!.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      
      notifyListeners();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error saving note: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }
  
  void toggleEditMode() {
    if (_isEditing) {
      // Note: Save will be handled by the page when this is called
    } else {
      // Sync current content to edit controller
      final deltaJson = _readOnlyController.document.toDelta().toJson();
      _quillController = QuillController(
        document: Document.fromJson(deltaJson),
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
    
    _isEditing = !_isEditing;
    notifyListeners();
  }
  
  Future<void> addImage(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null && context.mounted) {
      try {
        final db = Provider.of<AppDb>(context, listen: false);
        await db.addMedia(noteId, 'image', image.path);
        
        final media = await db.getMediaForNoteOnce(noteId);
        _media = media;
        notifyListeners();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image added successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding image: $e')),
          );
        }
      }
    }
  }
  
  String formatDate(DateTime date) {
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

  // Steps management methods
  Future<void> addStep(BuildContext context, String title, {String? description}) async {
    try {
      final db = Provider.of<AppDb>(context, listen: false);
      final newStepId = await db.createStep(noteId, title, description: description);
      
      // Track the newly added step
      _newlyAddedStepId = newStepId;
      
      // Reload steps
      final steps = await db.getStepsForNote(noteId);
      _steps = steps;
      notifyListeners();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Step added successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding step: $e')),
        );
      }
    }
  }

  void clearNewlyAddedStepId() {
    _newlyAddedStepId = null;
  }

  Future<void> updateStep(BuildContext context, String stepId, {String? title, String? description, String? imageUrl, String? duration, String? notes}) async {
    try {
      final db = Provider.of<AppDb>(context, listen: false);
      await db.updateStep(stepId, title: title, description: description, imageUrl: imageUrl, duration: duration, notes: notes);
      
      // Reload steps
      final steps = await db.getStepsForNote(noteId);
      _steps = steps;
      notifyListeners();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating step: $e')),
        );
      }
    }
  }

  Future<void> deleteStep(BuildContext context, String stepId) async {
    try {
      final db = Provider.of<AppDb>(context, listen: false);
      await db.deleteStep(stepId);
      
      // Reload steps
      final steps = await db.getStepsForNote(noteId);
      _steps = steps;
      notifyListeners();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Step deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting step: $e')),
        );
      }
    }
  }

  Future<void> reorderSteps(BuildContext context, List<Step> newOrder) async {
    try {
      final db = Provider.of<AppDb>(context, listen: false);
      final stepIds = newOrder.map((step) => step.id).toList();
      await db.reorderSteps(noteId, stepIds);
      
      _steps = newOrder;
      notifyListeners();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reordering steps: $e')),
        );
      }
    }
  }

  Future<void> addStepImage(BuildContext context, String stepId) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null && context.mounted) {
      await updateStep(context, stepId, imageUrl: image.path);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Step image added successfully')),
        );
      }
    }
  }

  // Camera functionality
  Future<void> openCameraMode(BuildContext context) async {
    try {
      // Check if camera is available
      final hasCamera = await CameraService.checkCameraPermission();
      if (!hasCamera) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera not available')),
          );
        }
        return;
      }

      // Initialize cameras
      await CameraService.initializeCameras();

      if (context.mounted) {
        // Navigate to camera screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CameraScreen(
              noteId: noteId,
              onImageCaptured: (imagePath) => _onCameraImageCaptured(context, imagePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening camera: $e')),
        );
      }
    }
  }

  Future<void> _onCameraImageCaptured(BuildContext context, String imagePath) async {
    try {
      final db = Provider.of<AppDb>(context, listen: false);
      
      // Generate step title based on current step count
      final stepNumber = _steps.length + 1;
      final stepTitle = 'Step $stepNumber';
      
      // Create step with image
      final newStepId = await db.createStepWithImage(noteId, stepTitle, imagePath);
      
      // Also add the image to the media section
      await db.addMedia(noteId, 'image', imagePath);
      
      // Track the newly added step
      _newlyAddedStepId = newStepId;
      
      // Reload steps and media
      final steps = await db.getStepsForNote(noteId);
      _steps = steps;
      
      final media = await db.getMediaForNoteOnce(noteId);
      _media = media;
      
      notifyListeners();
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating step from camera: $e')),
        );
      }
    }
  }
}