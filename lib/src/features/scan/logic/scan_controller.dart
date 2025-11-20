import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../services/text_recognition_service.dart';
import '../presentation/result_screen.dart';

class ScanController {
  final TextRecognitionService _textRecognitionService = TextRecognitionService();
  CameraController? cameraController;

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await cameraController!.initialize();
  }

  Future<void> takePictureAndScan(BuildContext context) async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    if (cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile file = await cameraController!.takePicture();
      
      // Show loading or process in background? 
      // For MVP, let's show a loading dialog or just navigate to result screen which loads.
      // Let's process here and then navigate.
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final text = await _textRecognitionService.processImage(file.path);

      if (!context.mounted) return;

      Navigator.of(context).pop(); // Close loader
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultScreen(text: text),
        ),
      );
    } catch (e) {
      debugPrint('Error scanning: $e');
      if (context.mounted) {
         // Close loader if open - simplistic handling
         // Navigator.of(context).pop(); 
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void dispose() {
    cameraController?.dispose();
    _textRecognitionService.dispose();
  }
}
