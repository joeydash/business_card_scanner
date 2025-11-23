import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';

  /// Load settings from SharedPreferences
  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    
    if (settingsJson == null) {
      return const AppSettings(); // Return default settings
    }

    try {
      final Map<String, dynamic> json = jsonDecode(settingsJson);
      return AppSettings.fromJson(json);
    } catch (e) {
      return const AppSettings(); // Return default on error
    }
  }

  /// Save settings to SharedPreferences
  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, settingsJson);
  }

  /// Update OpenRouter toggle
  Future<void> setUseOpenRouter(bool value) async {
    final settings = await loadSettings();
    final updated = settings.copyWith(useOpenRouter: value);
    await saveSettings(updated);
  }

  /// Update selected model
  Future<void> setSelectedModel(String modelId) async {
    final settings = await loadSettings();
    final updated = settings.copyWith(selectedModelId: modelId);
    await saveSettings(updated);
  }

  /// Update API key configured status
  Future<void> setApiKeyConfigured(bool value) async {
    final settings = await loadSettings();
    final updated = settings.copyWith(apiKeyConfigured: value);
    await saveSettings(updated);
  }

  /// Get current parsing mode (OpenRouter vs Local)
  Future<bool> shouldUseOpenRouter() async {
    final settings = await loadSettings();
    return settings.useOpenRouter && settings.apiKeyConfigured;
  }

  /// Get selected model ID
  Future<String> getSelectedModelId() async {
    final settings = await loadSettings();
    return settings.selectedModelId;
  }
}
