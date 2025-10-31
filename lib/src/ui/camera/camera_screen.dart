// lib/src/ui/camera/camera_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../services/camera_service.dart';

class CameraScreen extends StatefulWidget {
  final Function(String imagePath) onImageCaptured;
  final String noteId;

  const CameraScreen({
    super.key,
    required this.onImageCaptured,
    required this.noteId,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.auto;
  int _currentCameraIndex = 0;
  List<CameraDescription> _cameras = [];
  String? _lastCapturedImage;
  bool _showCaptureSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await CameraService.initializeCameras();
      if (_cameras.isEmpty) {
        _showError('No cameras available');
        return;
      }

      await _setupController(_cameras[_currentCameraIndex]);
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    _controller = controller;

    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _showError('Failed to initialize camera controller: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _captureImage() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await controller.takePicture();
      final savedPath = await CameraService.saveStepImage(image, widget.noteId);
      
      setState(() {
        _lastCapturedImage = savedPath;
        _showCaptureSuccess = true;
      });

      // Call the callback to create the step
      widget.onImageCaptured(savedPath);

      // Hide success indicator after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _showCaptureSuccess = false;
          });
        }
      });

    } catch (e) {
      _showError('Failed to capture image: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;

    FlashMode newMode;
    switch (_flashMode) {
      case FlashMode.auto:
        newMode = FlashMode.always;
      case FlashMode.always:
        newMode = FlashMode.off;
      case FlashMode.off:
        newMode = FlashMode.auto;
      default:
        newMode = FlashMode.auto;
    }

    try {
      await controller.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
      });
    } catch (e) {
      _showError('Failed to change flash mode: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    setState(() {
      _isInitialized = false;
    });

    await _controller?.dispose();
    
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _setupController(_cameras[_currentCameraIndex]);
  }

  Widget _buildFlashIcon() {
    switch (_flashMode) {
      case FlashMode.auto:
        return const Icon(Icons.flash_auto, color: Colors.white);
      case FlashMode.always:
        return const Icon(Icons.flash_on, color: Colors.white);
      case FlashMode.off:
        return const Icon(Icons.flash_off, color: Colors.white);
      default:
        return const Icon(Icons.flash_auto, color: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Success overlay
          if (_showCaptureSuccess)
            Positioned.fill(
              child: Container(
                color: Colors.green.withValues(alpha: 0.3),
                child: const Center(
                  child: Icon(
                    Icons.check_circle,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Top controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                ),
                
                // Flash toggle
                IconButton(
                  onPressed: _toggleFlash,
                  icon: _buildFlashIcon(),
                ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Last captured image thumbnail
                SizedBox(
                  width: 60,
                  height: 60,
                  child: _lastCapturedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_lastCapturedImage!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : null,
                ),

                // Capture button
                GestureDetector(
                  onTap: _captureImage,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _isCapturing ? Colors.grey : Colors.transparent,
                    ),
                    child: _isCapturing
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                  ),
                ),

                // Switch camera button
                SizedBox(
                  width: 60,
                  height: 60,
                  child: _cameras.length > 1
                      ? IconButton(
                          onPressed: _switchCamera,
                          icon: const Icon(
                            Icons.flip_camera_ios,
                            color: Colors.white,
                            size: 32,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),

          // Step count indicator
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Tap to capture step',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}