import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../models/business_card_data.dart';
import '../../../services/card_storage_service.dart';
import '../../../services/excel_export_service.dart';
import '../../settings/presentation/settings_screen.dart';
import 'camera_screen.dart';
import 'structured_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardStorageService _storageService = CardStorageService();
  final ExcelExportService _excelService = ExcelExportService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<BusinessCardData> _cards = [];
  List<BusinessCardData> _filteredCards = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreCards = true;
  bool _isExporting = false;
  String _searchQuery = '';
  
  static const int _pageSize = 20;
  int _currentOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialCards();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreCards();
    }
  }

  Future<void> _loadInitialCards() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _currentOffset = 0;
      _hasMoreCards = true;
    });
    
    final cards = await _storageService.getCardsPaginated(
      limit: _pageSize,
      offset: 0,
    );
    
    if (!mounted) return;
    setState(() {
      _cards = cards;
      _filteredCards = cards;
      _currentOffset = cards.length;
      _hasMoreCards = cards.length >= _pageSize;
      _isLoading = false;
    });
    _applySearch();
  }

  Future<void> _loadMoreCards() async {
    if (_isLoadingMore || !_hasMoreCards || _isLoading) return;
    
    setState(() => _isLoadingMore = true);
    
    final newCards = await _storageService.getCardsPaginated(
      limit: _pageSize,
      offset: _currentOffset,
    );
    
    if (!mounted) return;
    setState(() {
      _cards.addAll(newCards);
      _currentOffset += newCards.length;
      _hasMoreCards = newCards.length >= _pageSize;
      _isLoadingMore = false;
    });
    _applySearch();
  }

  // Reload from start (used after adding/deleting cards)
  Future<void> _loadCards() async {
    await _loadInitialCards();
  }

  void _applySearch() {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredCards = _cards);
      return;
    }

    setState(() {
      _filteredCards = _cards.where((card) {
        return (card.personName?.toLowerCase().contains(query) ?? false) ||
               (card.companyName?.toLowerCase().contains(query) ?? false) ||
               (card.jobTitle?.toLowerCase().contains(query) ?? false) ||
               card.emails.any((e) => e.toLowerCase().contains(query)) ||
               card.phones.any((p) => p.contains(query));
      }).toList();
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applySearch();
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
        // Use platform-specific share
        if (Platform.isIOS) {
          // Use native iOS share
          const platform = MethodChannel('native_share');
          try {
            await platform.invokeMethod('shareFile', {
              'path': fileInfo['path'],
              'subject': 'Business Cards Export',
              'text': 'Exported ${_cards.length} business card${_cards.length == 1 ? '' : 's'}',
            });
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Share failed: $e')),
              );
            }
          }
        } else {
          // Use share_plus for Android
          await Share.shareXFiles(
            [XFile(fileInfo['path'], name: fileInfo['fileName'])],
            subject: 'Business Cards Export',
            text: 'Exported ${_cards.length} business card${_cards.length == 1 ? '' : 's'}',
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



  Future<void> _deleteCard(int index) async {
    final card = _cards[index];
    if (card.id != null) {
      await _storageService.deleteCard(card.id!);
      await _loadCards();
    }
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
      MaterialPageRoute(
        builder: (context) => CameraScreen(
          onCardSaved: () {
            // Refresh list in background without showing loading indicator if possible,
            // or just call _loadCards which handles state.
            _loadCards();
          },
        ),
      ),
    );

    if (result == true) {
      _loadCards();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business card saved!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  expandedHeight: 120.0,
                  floating: true,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Card Scanner',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.deepPurple.shade50,
                            Colors.white,
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    if (_cards.isNotEmpty)
                      IconButton(
                        icon: _isExporting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                ),
                              )
                            : const Icon(Icons.file_download),
                        tooltip: 'Export to Excel',
                        onPressed: _isExporting ? null : _exportToExcel,
                      ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      tooltip: 'Settings',
                      onPressed: _openSettings,
                    ),
                    if (_cards.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        tooltip: 'Clear All',
                        onPressed: _clearAll,
                      ),
                  ],
                ),
                if (_cards.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search cards...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                if (_cards.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.credit_card,
                              size: 80,
                              color: Colors.deepPurple.shade200,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No scanned cards yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tap the + button to scan your first card',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
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
                        childCount: _filteredCards.length,
                      ),
                    ),
                  ),
                  // Loading indicator when fetching more cards
                  if (_isLoadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanNewCard,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Card'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
}
