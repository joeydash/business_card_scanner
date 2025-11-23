import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/business_card_data.dart';
import '../../../services/card_storage_service.dart';
import '../../../services/database_helper.dart';
import '../../../services/excel_export_service.dart';
import '../../../services/group_service.dart';
import 'camera_screen.dart';
import 'structured_result_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final int? groupId;
  final String groupName;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final GroupService _groupService = GroupService();
  final ExcelExportService _excelService = ExcelExportService();
  List<BusinessCardData> _cards = [];
  List<BusinessCardData> _filteredCards = [];
  bool _isLoading = true;
  bool _isExporting = false;
  String _groupName = '';
  bool _hasChanges = false; // Track if any changes were made
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _groupName = widget.groupName;
    _loadCards();
    _searchController.addListener(_filterCards);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCards() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredCards = _cards;
      } else {
        _filteredCards = _cards.where((card) {
          final name = card.personName?.toLowerCase() ?? '';
          final company = card.companyName?.toLowerCase() ?? '';
          final email = card.emails.join(' ').toLowerCase();
          final phone = card.phones.join(' ').toLowerCase();
          return name.contains(_searchQuery) ||
                 company.contains(_searchQuery) ||
                 email.contains(_searchQuery) ||
                 phone.contains(_searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    final cards = await _dbHelper.readCardsByGroup(widget.groupId);
    setState(() {
      _cards = cards;
      _filteredCards = cards;
      _isLoading = false;
    });
  }

  Future<void> _scanCard() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          onCardSaved: () => _loadCards(),
          groupId: widget.groupId,
        ),
      ),
    );
    if (result == true) {
      _hasChanges = true; // Mark that changes were made
      _loadCards();
    }
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
        if (Platform.isIOS) {
          const platform = MethodChannel('native_share');
          try {
            await platform.invokeMethod('shareFile', {
              'path': fileInfo['path'],
              'subject': '$_groupName Export',
              'text': 'Exported ${_cards.length} card${_cards.length == 1 ? '' : 's'} from $_groupName',
            });
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Share failed: $e')),
              );
            }
          }
        } else {
          await Share.shareXFiles(
            [XFile(fileInfo['path'], name: fileInfo['fileName'])],
            subject: '$_groupName Export',
            text: 'Exported ${_cards.length} card${_cards.length == 1 ? '' : 's'} from $_groupName',
          );
        }
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

  Future<void> _renameGroup() async {
    if (widget.groupId == null) return; // Can't rename Ungrouped

    final controller = TextEditingController(text: _groupName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Group'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Group name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != _groupName) {
      await _groupService.renameGroup(widget.groupId!, result);
      setState(() => _groupName = result);
    }
  }

  Future<void> _deleteGroup() async {
    if (widget.groupId == null) return; // Can't delete Ungrouped

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "$_groupName"?\n\nCards in this group will be moved to Ungrouped.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _groupService.deleteGroup(widget.groupId!);
      if (mounted) {
        Navigator.pop(context, true); // Return true when group is deleted
      }
    }
  }

  Future<void> _deleteCard(int index) async {
    final card = _cards[index];
    if (card.id != null) {
      await _dbHelper.delete(card.id!);
      _hasChanges = true; // Mark that changes were made
      _loadCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges); // Return whether changes were made
        return false; // Prevent default pop
      },
      child: Scaffold(
        appBar: AppBar(
        title: Text(_groupName),
        actions: [
          if (widget.groupId != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Rename Group',
              onPressed: _renameGroup,
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Group', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteGroup();
                }
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search cards in this group...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          // Cards list - takes up remaining space
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty ? Icons.search_off : Icons.credit_card,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty 
                                  ? 'No cards found'
                                  : 'No cards in this group',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try a different search term'
                                  : 'Tap "Scan Card" to add cards',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Add bottom padding for fixed buttons
                        itemCount: _filteredCards.length,
                        itemBuilder: (context, index) {
                          final card = _filteredCards[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StructuredResultScreen(
                                        data: card,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadCards();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: Colors.deepPurple.shade100,
                                        child: Text(
                                          (card.personName?.isNotEmpty == true
                                                  ? card.personName![0].toUpperCase()
                                                  : card.companyName?.isNotEmpty == true
                                                      ? card.companyName![0].toUpperCase()
                                                      : '?'),
                                          style: TextStyle(
                                            color: Colors.deepPurple.shade700,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              card.personName?.isNotEmpty == true
                                                  ? card.personName!
                                                  : card.companyName ?? 'Unknown',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (card.jobTitle != null) ...[ 
                                              const SizedBox(height: 4),
                                              Text(
                                                card.jobTitle!,
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                            if (card.companyName != null &&
                                                card.personName != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                card.companyName!,
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.grey[400],
                                        ),
                                        onPressed: () => _deleteCard(index),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      // Fixed action buttons at bottom
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Export button on LEFT
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportToExcel,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.file_download),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Scan Card button on RIGHT
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _scanCard,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Scan Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
