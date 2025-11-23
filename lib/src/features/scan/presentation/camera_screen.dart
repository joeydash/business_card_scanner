import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/text_recognition_service.dart';
import '../../../services/business_card_parser.dart';
import '../../../services/openrouter_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/settings_service.dart';
import '../../../models/business_card_data.dart';
import '../../../services/card_storage_service.dart';

class CameraScreen extends StatefulWidget {
  final VoidCallback? onCardSaved;
  final int? groupId;
  
  const CameraScreen({
    super.key,
    this.onCardSaved,
    this.groupId,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final TextRecognitionService _textRecognitionService = TextRecognitionService();
  final CardStorageService _storageService = CardStorageService();
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();
  
  bool _isProcessing = false;
  bool _useOpenRouter = false;
  bool _hasScannedAny = false;

  @override
  void initState() {
    super.initState();
    _loadSettings().then((_) => _startScan());
  }

  Future<void> _loadSettings() async {
    final shouldUseOpenRouter = await _settingsService.shouldUseOpenRouter();
    if (mounted) {
      setState(() {
        _useOpenRouter = shouldUseOpenRouter;
      });
    }
  }

  Future<void> _startScan() async {
    try {
      // Check and request camera permission first
      final status = await Permission.camera.status;
      if (!status.isGranted) {
        final result = await Permission.camera.request();
        
        if (!result.isGranted) {
          if (mounted) {
            // Show dialog to open settings
            final shouldOpenSettings = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Camera Permission Required'),
                content: const Text(
                  'This app needs camera access to scan business cards. '
                  'Please enable camera permission in Settings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            );
            
            if (shouldOpenSettings == true) {
              await openAppSettings();
            }
            
            Navigator.pop(context, _hasScannedAny);
          }
          return;
        }
      }

      String? imagePath;

      if (Platform.isAndroid) {
        // Use Google ML Kit Document Scanner on Android for better control
        final options = DocumentScannerOptions(
          mode: ScannerMode.base, // Skips "Enhance" screen
          isGalleryImport: false,
          pageLimit: 1,
        );
        
        final scanner = DocumentScanner(options: options);
        final result = await scanner.scanDocument();
        
        if (result.images.isNotEmpty) {
          imagePath = result.images.first;
        }
      } else {
        // Use Cunning Document Scanner on iOS (wraps VisionKit)
        final List<String>? pictures = await CunningDocumentScanner.getPictures();
        if (pictures != null && pictures.isNotEmpty) {
          imagePath = pictures.first;
        }
      }
      
      if (imagePath != null) {
        await _processImage(imagePath);
      } else {
        // User cancelled scanning
        if (mounted) {
          Navigator.pop(context, _hasScannedAny);
        }
      }
    } catch (e) {
      debugPrint('Error launching scanner: $e');
      
      // Check if this is a user cancellation (not an actual error)
      final isCancellation = e.toString().contains('cancel') || 
                            e.toString().contains('Cancel');
      
      if (mounted) {
        if (!isCancellation) {
          // Only show error for actual failures, not user cancellation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start scanner: $e')),
          );
        }
        Navigator.pop(context, _hasScannedAny);
      }
    }
  }

  Future<void> _processImage(String imagePath) async {
    debugPrint('Processing image at: $imagePath');
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Extract text using ML Kit
      final text = await _textRecognitionService.processImage(imagePath);

      // Parse business card data based on settings
      BusinessCardData businessCardData;
      
      if (_useOpenRouter) {
        try {
          // Try OpenRouter cloud parsing
          final apiKey = await _authService.getApiKey();
          if (apiKey == null || apiKey.isEmpty) {
            throw Exception('API key not found');
          }

          final modelId = await _settingsService.getSelectedModelId();
          final openRouterService = OpenRouterService(apiKey);
          
          businessCardData = await openRouterService.parseBusinessCard(text, modelId);
          
          debugPrint('✅ Parsed with OpenRouter ($modelId)');
        } catch (e) {
          debugPrint('⚠️ OpenRouter failed, falling back to local parsing: $e');
          
          // Fallback to local parsing
          businessCardData = BusinessCardParser.parse(text);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cloud parsing failed. Using local parsing.\n${e.toString()}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Use local regex parsing
        businessCardData = BusinessCardParser.parse(text);
        debugPrint('✅ Parsed locally with regex');
      }

      if (!mounted) return;

      // Auto-save the card with groupId
      final cardWithGroup = businessCardData.copyWith(groupId: widget.groupId);
      await _storageService.saveCard(cardWithGroup);
      
      // Notify parent to refresh list in background
      widget.onCardSaved?.call();
      
      _hasScannedAny = true;

      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card saved! Ready for next scan.'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
        
        // Restart scanner loop for continuous scanning
        _startScan();
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
        // On error, we also restart the scanner so user can try again or scan another
        _startScan();
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
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              _isProcessing ? 'Processing Card...' : 'Launching Scanner...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
