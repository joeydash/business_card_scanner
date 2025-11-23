import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/openrouter_service.dart';
import '../../../models/app_settings.dart';
import '../../../models/openrouter_models.dart';
import 'signin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();
  
  AppSettings _settings = const AppSettings();
  bool _isLoading = true;
  bool _isLoadingModels = false;
  List<OpenRouterModel> _availableModels = [];
  String? _modelLoadError;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    final settings = await _settingsService.loadSettings();
    final hasApiKey = await _authService.isApiKeyConfigured();
    
    setState(() {
      _settings = settings.copyWith(apiKeyConfigured: hasApiKey);
      _isLoading = false;
    });

    // Load models if API key is configured
    if (hasApiKey) {
      await _loadModels();
    }
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoadingModels = true;
      _modelLoadError = null;
    });

    try {
      final apiKey = await _authService.getApiKey();
      if (apiKey == null) {
        throw Exception('API key not found');
      }

      final service = OpenRouterService(apiKey);
      final models = await service.fetchAvailableModels();
      
      setState(() {
        _availableModels = models;
        _isLoadingModels = false;
      });
    } catch (e) {
      setState(() {
        _modelLoadError = e.toString();
        _isLoadingModels = false;
        // Fallback to default models
        _availableModels = [];
      });
    }
  }

  /// Get the current model list, preferring API models but falling back to defaults
  /// Also ensures no duplicates by ID and that selected model is present
  List<OpenRouterModel> get _currentModels {
    var models = _availableModels.isEmpty 
        ? OpenRouterModels.recommendedModels 
        : _availableModels;
    
    // Deduplicate by ID
    final seen = <String>{};
    final uniqueModels = models.where((model) {
      if (seen.contains(model.id)) {
        return false;
      }
      seen.add(model.id);
      return true;
    }).toList();

    // Ensure selected model is in the list
    if (!seen.contains(_settings.selectedModelId)) {
      final selectedModel = OpenRouterModels.getModelById(_settings.selectedModelId) ??
          OpenRouterModel(
            id: _settings.selectedModelId,
            name: _settings.selectedModelId,
            description: 'Custom Model',
            costPer1MTokens: 0,
            speedRating: '?',
            accuracyRating: '?',
          );
      uniqueModels.insert(0, selectedModel);
    }

    return uniqueModels;
  }

  /// Get the currently selected model
  OpenRouterModel? get _selectedModel {
    try {
      return _currentModels.firstWhere(
        (m) => m.id == _settings.selectedModelId,
      );
    } catch (e) {
      return _currentModels.isNotEmpty ? _currentModels.first : null;
    }
  }

  Future<void> _toggleOpenRouter(bool value) async {
    if (value && !_settings.apiKeyConfigured) {
      // Need to sign in first
      await _navigateToSignIn();
      return;
    }

    setState(() {
      _settings = _settings.copyWith(useOpenRouter: value);
    });
    await _settingsService.saveSettings(_settings);
  }

  Future<void> _changeModel(String? modelId) async {
    if (modelId == null) return;
    
    setState(() {
      _settings = _settings.copyWith(selectedModelId: modelId);
    });
    await _settingsService.saveSettings(_settings);
  }

  Future<void> _navigateToSignIn() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );

    if (result == true) {
      await _loadSettings();
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out from OpenRouter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      setState(() {
        _settings = _settings.copyWith(
          useOpenRouter: false,
          apiKeyConfigured: false,
        );
      });
      await _settingsService.saveSettings(_settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // OpenRouter Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        'Cloud AI Parsing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Toggle Switch
                  SwitchListTile(
                    title: const Text('Enable Cloud Parsing'),
                    subtitle: _settings.apiKeyConfigured 
                        ? const Text('Connected', style: TextStyle(color: Colors.green))
                        : const Text('Sign in required', style: TextStyle(color: Colors.orange)),
                    value: _settings.useOpenRouter,
                    onChanged: _toggleOpenRouter,
                    contentPadding: EdgeInsets.zero,
                  ),

                  // Model Selection
                  if (_settings.useOpenRouter) ...[ 
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Model',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_isLoadingModels)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_isLoadingModels)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Loading available models...'),
                        ),
                      )
                    else
                      InkWell(
                        onTap: () => _showModelSelectionSheet(context),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedModel?.name ?? 'Select a model',
                                  style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    
                    if (_modelLoadError != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, size: 16, color: Colors.orange[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Using default models (couldn\'t fetch from API)',
                                style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    

                  ],

                  // Sign In/Out Button
                  const SizedBox(height: 16),
                  if (!_settings.apiKeyConfigured)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToSignIn,
                        icon: const Icon(Icons.login),
                        label: const Text('Sign In to OpenRouter'),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showModelSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ModelSelectionSheet(
        models: _currentModels,
        selectedId: _settings.selectedModelId,
        onSelect: (modelId) {
          _changeModel(modelId);
          Navigator.pop(context);
        },
      ),
    );
  }

}

class _ModelSelectionSheet extends StatefulWidget {
  final List<OpenRouterModel> models;
  final String selectedId;
  final Function(String) onSelect;

  const _ModelSelectionSheet({
    required this.models,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  State<_ModelSelectionSheet> createState() => _ModelSelectionSheetState();
}

class _ModelSelectionSheetState extends State<_ModelSelectionSheet> {
  late List<OpenRouterModel> _filteredModels;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredModels = widget.models;
  }

  void _filterModels(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredModels = widget.models;
      } else {
        _filteredModels = widget.models.where((model) {
          return model.name.toLowerCase().contains(query.toLowerCase()) ||
              model.id.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Select AI Model',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search models...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: _filterModels,
              ),
            ),

            const Divider(),

            // List
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filteredModels.length,
                itemBuilder: (context, index) {
                  final model = _filteredModels[index];
                  final isSelected = model.id == widget.selectedId;

                  return ListTile(
                    title: Text(
                      model.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).primaryColor : null,
                      ),
                    ),
                    subtitle: Text(
                      '\$${model.costPer1MTokens.toStringAsFixed(2)}/1M tokens • ${model.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                        : null,
                    onTap: () => widget.onSelect(model.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
