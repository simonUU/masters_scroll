// lib/src/services/camera_service.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class CameraService {
  static List<CameraDescription>? _cameras;
  static const Uuid _uuid = Uuid();

  /// Initialize available cameras
  static Future<List<CameraDescription>> initializeCameras() async {
    _cameras ??= await availableCameras();
    return _cameras!;
  }

  /// Get available cameras
  static List<CameraDescription> get cameras => _cameras ?? [];

  /// Get the primary back camera
  static CameraDescription? get primaryCamera {
    if (cameras.isEmpty) return null;
    
    // Try to find back camera first
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        return camera;
      }
    }
    
    // Fallback to first available camera
    return cameras.first;
  }

  /// Get the front camera
  static CameraDescription? get frontCamera {
    if (cameras.isEmpty) return null;
    
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        return camera;
      }
    }
    
    return null;
  }

  /// Create directory for storing step images
  static Future<Directory> _getStepImagesDirectory(String noteId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final stepImagesDir = Directory(path.join(appDir.path, 'steps', noteId));
    
    if (!await stepImagesDir.exists()) {
      await stepImagesDir.create(recursive: true);
    }
    
    return stepImagesDir;
  }

  /// Save captured image and return the file path
  static Future<String> saveStepImage(XFile imageFile, String noteId) async {
    final stepImagesDir = await _getStepImagesDirectory(noteId);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'step_${_uuid.v4()}_$timestamp.jpg';
    final savedFile = File(path.join(stepImagesDir.path, fileName));
    
    // Copy the image file to our app directory
    await imageFile.saveTo(savedFile.path);
    
    return savedFile.path;
  }

  /// Delete step image file
  static Future<void> deleteStepImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Log error but don't throw - file might already be deleted
      print('Error deleting step image: $e');
    }
  }

  /// Clean up images for a specific note (when note is deleted)
  static Future<void> cleanupNoteImages(String noteId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final noteImagesDir = Directory(path.join(appDir.path, 'steps', noteId));
      
      if (await noteImagesDir.exists()) {
        await noteImagesDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error cleaning up note images: $e');
    }
  }

  /// Get file size in a human-readable format
  static String getFileSizeString(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Unknown size';
    }
  }

  /// Check if camera permissions are available
  static Future<bool> checkCameraPermission() async {
    try {
      final cameras = await availableCameras();
      return cameras.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}