import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String _apiKeyKey = 'openrouter_api_key';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Save API key securely
  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyKey, value: apiKey);
  }

  /// Retrieve API key from secure storage
  Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyKey);
  }

  /// Check if API key is configured
  Future<bool> isApiKeyConfigured() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Remove API key (sign out)
  Future<void> signOut() async {
    await _secureStorage.delete(key: _apiKeyKey);
  }

  /// Validate API key format
  bool isValidApiKeyFormat(String apiKey) {
    // OpenRouter API keys typically start with 'sk-or-'
    return apiKey.trim().isNotEmpty && apiKey.startsWith('sk-or-');
  }
}
