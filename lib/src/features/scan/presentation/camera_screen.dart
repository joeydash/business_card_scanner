import 'package:flutter/material.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import '../../../services/text_recognition_service.dart';
import '../../../services/business_card_parser.dart';
import '../../../models/business_card_data.dart';
import '../../../services/card_storage_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final TextRecognitionService _textRecognitionService = TextRecognitionService();
  final CardStorageService _storageService = CardStorageService();
  bool _isProcessing = false;

  Future<void> _processImage(String imagePath) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Extract text using ML Kit
      final text = await _textRecognitionService.processImage(imagePath);

      // Parse business card data
      final businessCardData = BusinessCardParser.parse(text);

      if (!mounted) return;

      // Auto-save the card
      await _storageService.saveCard(businessCardData);

      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business card saved!'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Return to home screen
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error scanning: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _textRecognitionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CameraAwesomeBuilder.awesome(
        saveConfig: SaveConfig.photo(),
        onMediaTap: (mediaCapture) {
          // Handle captured media
          if (mediaCapture.isPicture) {
            final path = mediaCapture.captureRequest.when(
              single: (single) => single.file?.path,
            );
            if (path != null) {
              _processImage(path);
            }
          }
        },
        topActionsBuilder: (state) => Container(
          padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Position business card within the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        middleContentBuilder: (state) => _isProcessing
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : CustomPaint(
                painter: CardOverlayPainter(),
                child: Container(),
              ),
        bottomActionsBuilder: (state) => AwesomeBottomActions(
          state: state,
          left: Container(), // Remove left action
          captureButton: AwesomeCaptureButton(
            state: state,
          ),
          right: AwesomeFlashButton(
            state: state,
          ),
        ),
      ),
    );
  }
}

// Custom painter for card overlay guide
class CardOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw rounded rectangle guide
    final centerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.height * 0.65,
    );
    
    final rect = RRect.fromRectAndRadius(
      centerRect,
      const Radius.circular(16),
    );

    canvas.drawRRect(rect, paint);

    // Draw corner markers
    final cornerPaint = Paint()
      ..color = Colors.deepPurple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = 30.0;
    
    // Top-left corner
    canvas.drawLine(
      centerRect.topLeft,
      Offset(centerRect.topLeft.dx + cornerLength, centerRect.topLeft.dy),
      cornerPaint,
    );
    canvas.drawLine(
      centerRect.topLeft,
      Offset(centerRect.topLeft.dx, centerRect.topLeft.dy + cornerLength),
      cornerPaint,
    );
    
    // Top-right corner
    canvas.drawLine(
      centerRect.topRight,
      Offset(centerRect.topRight.dx - cornerLength, centerRect.topRight.dy),
      cornerPaint,
    );
    canvas.drawLine(
      centerRect.topRight,
      Offset(centerRect.topRight.dx, centerRect.topRight.dy + cornerLength),
      cornerPaint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      centerRect.bottomLeft,
      Offset(centerRect.bottomLeft.dx + cornerLength, centerRect.bottomLeft.dy),
      cornerPaint,
    );
    canvas.drawLine(
      centerRect.bottomLeft,
      Offset(centerRect.bottomLeft.dx, centerRect.bottomLeft.dy - cornerLength),
      cornerPaint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      centerRect.bottomRight,
      Offset(centerRect.bottomRight.dx - cornerLength, centerRect.bottomRight.dy),
      cornerPaint,
    );
    canvas.drawLine(
      centerRect.bottomRight,
      Offset(centerRect.bottomRight.dx, centerRect.bottomRight.dy - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
