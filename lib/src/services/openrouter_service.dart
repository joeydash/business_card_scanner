import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/business_card_data.dart';
import '../models/openrouter_models.dart';

class OpenRouterService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1';
  final Dio _dio;

  OpenRouterService(String apiKey)
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'HTTP-Referer': 'https://github.com/joeydash/business_card_scanner',
              'X-Title': 'Business Card Scanner',
              'Content-Type': 'application/json',
            },
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

  /// Fetch available models from OpenRouter
  Future<List<OpenRouterModel>> fetchAvailableModels() async {
    try {
      final response = await _dio.get('/models');
      final data = response.data['data'] as List<dynamic>;
      
      // Use a map to deduplicate by ID (keep first occurrence)
      final modelMap = <String, OpenRouterModel>{};
      
      for (final modelData in data) {
        final id = modelData['id'] as String;
        
        // Skip if we already have this ID
        if (modelMap.containsKey(id)) {
          continue;
        }
        
        final name = modelData['name'] as String?;
        final pricing = modelData['pricing'] as Map<String, dynamic>?;
        
        // Only include models suitable for text processing (broad filter)
        if (id.contains('gpt') || 
            id.contains('claude') || 
            id.contains('gemini') || 
            id.contains('llama') ||
            id.contains('mistral') ||
            id.contains('deepseek') ||
            id.contains('qwen') ||
            id.contains('phi') ||
            !id.contains('diffusion')) { // Exclude obvious image models
          
          // Calculate cost per 1M tokens (prompt + completion average)
          double cost = 0.0;
          if (pricing != null) {
            final promptCost = double.tryParse(pricing['prompt']?.toString() ?? '0') ?? 0.0;
            final completionCost = double.tryParse(pricing['completion']?.toString() ?? '0') ?? 0.0;
            cost = (promptCost + completionCost) / 2 * 1000000; // Convert to per 1M tokens
          }
          
          modelMap[id] = OpenRouterModel(
            id: id,
            name: name ?? id,
            description: _getModelDescription(id),
            costPer1MTokens: cost,
            speedRating: _estimateSpeed(id),
            accuracyRating: _estimateAccuracy(id),
          );
        }
      }
      
      // Convert map values to list and sort by name for easier searching
      final models = modelMap.values.toList();
      models.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      
      return models;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to fetch models: $e');
    }
  }

  String _getModelDescription(String modelId) {
    if (modelId.contains('gpt-4o-mini')) return 'Fast and affordable GPT-4 variant';
    if (modelId.contains('gpt-4o')) return 'Latest GPT-4 optimized model';
    if (modelId.contains('gpt-4')) return 'Most capable GPT model';
    if (modelId.contains('gpt-3.5')) return 'Fast and efficient';
    if (modelId.contains('claude-3-haiku')) return 'Fastest Claude model';
    if (modelId.contains('claude-3-sonnet')) return 'Balanced Claude model';
    if (modelId.contains('claude-3.5-sonnet')) return 'Best Claude model';
    if (modelId.contains('claude-3-opus')) return 'Most capable Claude';
    if (modelId.contains('gemini-flash')) return 'Fast Google model';
    if (modelId.contains('gemini-pro')) return 'Advanced Google model';
    if (modelId.contains('llama')) return 'Open source Meta model';
    if (modelId.contains('mistral')) return 'Open source European model';
    return 'AI language model';
  }

  String _estimateSpeed(String modelId) {
    if (modelId.contains('mini') || modelId.contains('haiku') || modelId.contains('flash')) {
      return '⚡⚡⚡⚡⚡';
    } else if (modelId.contains('3.5') || modelId.contains('sonnet')) {
      return '⚡⚡⚡⚡';
    } else if (modelId.contains('gpt-4') || modelId.contains('opus')) {
      return '⚡⚡⚡';
    }
    return '⚡⚡⚡⚡';
  }

  String _estimateAccuracy(String modelId) {
    if (modelId.contains('opus') || modelId.contains('3.5-sonnet')) return '98%';
    if (modelId.contains('gpt-4o') || modelId.contains('claude-3')) return '95%';
    if (modelId.contains('gemini-pro')) return '94%';
    if (modelId.contains('gpt-3.5') || modelId.contains('llama-3')) return '90%';
    return '92%';
  }

  /// Parse business card text using OpenRouter LLM
  Future<BusinessCardData> parseBusinessCard(
    String ocrText,
    String modelId,
  ) async {
    try {
      final prompt = _buildPrompt(ocrText);
      
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': modelId,
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert at extracting structured information from business cards. '
                  'Always respond with valid JSON only, no additional text or markdown formatting.'
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.1, // Low temperature for consistent extraction
          'response_format': {'type': 'json_object'},
        },
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      return _parseResponse(content, ocrText);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to parse business card: $e');
    }
  }

  String _buildPrompt(String ocrText) {
    return '''
Extract information from this business card OCR text and return a JSON object with the following fields:

{
  "personName": "Full name of the person (or null if not found)",
  "jobTitle": "Job title or position (or null if not found)",
  "companyName": "Company name (or null if not found)",
  "emails": ["list of email addresses"],
  "phones": ["list of phone numbers"],
  "websites": ["list of website URLs, excluding social media"],
  "linkedIn": "LinkedIn profile URL or username (or null if not found)",
  "twitter": "Twitter/X handle or URL (or null if not found)",
  "address": "Physical address (or null if not found)"
}

OCR Text:
$ocrText

Return ONLY the JSON object, no additional text.
''';
  }

  BusinessCardData _parseResponse(String content, String rawText) {
    try {
      // Remove markdown code blocks if present
      String cleanedContent = content.trim();
      if (cleanedContent.startsWith('```json')) {
        cleanedContent = cleanedContent.substring(7);
      } else if (cleanedContent.startsWith('```')) {
        cleanedContent = cleanedContent.substring(3);
      }
      if (cleanedContent.endsWith('```')) {
        cleanedContent = cleanedContent.substring(0, cleanedContent.length - 3);
      }

      // Parse JSON
      final json = jsonDecode(cleanedContent.trim()) as Map<String, dynamic>;

      return BusinessCardData(
        personName: json['personName'] as String?,
        jobTitle: json['jobTitle'] as String?,
        companyName: json['companyName'] as String?,
        emails: (json['emails'] as List<dynamic>?)?.cast<String>() ?? [],
        phones: (json['phones'] as List<dynamic>?)?.cast<String>() ?? [],
        websites: (json['websites'] as List<dynamic>?)?.cast<String>() ?? [],
        linkedIn: json['linkedIn'] as String?,
        twitter: json['twitter'] as String?,
        address: json['address'] as String?,
        rawText: rawText,
      );
    } catch (e) {
      // On any error, return the raw text
      return BusinessCardData(rawText: rawText);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response!.data?['error']?['message'] ?? 'Unknown error';
      
      switch (statusCode) {
        case 401:
          return Exception('Invalid API key. Please check your OpenRouter API key.');
        case 429:
          return Exception('Rate limit exceeded. Please try again later.');
        case 402:
          return Exception('Insufficient credits. Please add credits to your OpenRouter account.');
        case 500:
        case 502:
        case 503:
          return Exception('OpenRouter service error. Please try again later.');
        default:
          return Exception('API Error ($statusCode): $message');
      }
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timeout. Please check your internet connection.');
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception('No internet connection. Please check your network.');
    } else {
      return Exception('Network error: ${e.message}');
    }
  }
}
