import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextRecognitionService {
  static const MethodChannel _channel = MethodChannel('text_recognition');
  final TextRecognizer? _textRecognizer = Platform.isAndroid ? TextRecognizer() : null;

  Future<String> processImage(String path) async {
    if (Platform.isIOS) {
      // Use Apple Vision Framework on iOS
      try {
        final String result = await _channel.invokeMethod('recognizeText', {'path': path});
        return result;
      } catch (e) {
        print('Error using Vision Framework: $e');
        // Fallback to ML Kit if Vision fails
        return await _processWithMLKit(path);
      }
    } else {
      // Use Google ML Kit on Android
      return await _processWithMLKit(path);
    }
  }

  Future<String> _processWithMLKit(String path) async {
    final textRecognizer = _textRecognizer ?? TextRecognizer();
    final inputImage = InputImage.fromFilePath(path);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  void dispose() {
    _textRecognizer?.close();
  }
}
