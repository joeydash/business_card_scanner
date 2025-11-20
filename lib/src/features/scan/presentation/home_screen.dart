import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/business_card_data.dart';
import '../../../services/card_storage_service.dart';
import '../../../services/excel_export_service.dart';
import 'camera_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardStorageService _storageService = CardStorageService();
  final ExcelExportService _excelService = ExcelExportService();
  List<BusinessCardData> _cards = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    final cards = await _storageService.getAllCards();
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
  }

  Future<void> _exportToExcel() async {
    if (_cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cards to export')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final fileInfo = await _excelService.exportToExcel(_cards);
      setState(() => _isExporting = false);

      if (mounted) {
        // Share the file using share_plus
        await Share.shareXFiles(
          [XFile(fileInfo['path'], name: fileInfo['fileName'])],
          subject: 'Business Cards Export',
          text: 'Exported ${_cards.length} business card${_cards.length == 1 ? '' : 's'}',
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }



  Future<void> _deleteCard(int index) async {
    await _storageService.deleteCard(index);
    _loadCards();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Cards'),
        content: const Text('Are you sure you want to delete all scanned cards?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.clearAll();
      _loadCards();
    }
  }

  void _scanNewCard() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );

    if (result == true) {
      _loadCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Card Scanner'),
        actions: [
          if (_cards.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_card,
                        size: 100,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No scanned cards yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tap the + button to scan your first card',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isExporting ? null : _exportToExcel,
                              icon: _isExporting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.file_download),
                              label: Text(
                                _isExporting ? 'Exporting...' : 'Export to Excel',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        '${_cards.length} card${_cards.length == 1 ? '' : 's'} scanned',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _cards.length,
                        itemBuilder: (context, index) {
                          final card = _cards[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple,
                                child: Text(
                                  (card.personName?.isNotEmpty == true
                                          ? card.personName![0].toUpperCase()
                                          : card.companyName?.isNotEmpty == true
                                              ? card.companyName![0].toUpperCase()
                                              : '?'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                card.personName?.isNotEmpty == true
                                    ? card.personName!
                                    : card.companyName ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (card.jobTitle != null)
                                    Text(card.jobTitle!),
                                  if (card.companyName != null &&
                                      card.personName != null)
                                    Text(card.companyName!),
                                  if (card.emails.isNotEmpty)
                                    Text(
                                      card.emails.first,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCard(index),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanNewCard,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Card'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
