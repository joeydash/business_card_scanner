class OpenRouterModel {
  final String id;
  final String name;
  final String description;
  final double costPer1MTokens;
  final String speedRating;
  final String accuracyRating;

  const OpenRouterModel({
    required this.id,
    required this.name,
    required this.description,
    required this.costPer1MTokens,
    required this.speedRating,
    required this.accuracyRating,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'costPer1MTokens': costPer1MTokens,
        'speedRating': speedRating,
        'accuracyRating': accuracyRating,
      };

  factory OpenRouterModel.fromJson(Map<String, dynamic> json) => OpenRouterModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        costPer1MTokens: (json['costPer1MTokens'] as num).toDouble(),
        speedRating: json['speedRating'] as String,
        accuracyRating: json['accuracyRating'] as String,
      );
}

// Recommended models for business card parsing
class OpenRouterModels {
  static const List<OpenRouterModel> recommendedModels = [
    OpenRouterModel(
      id: 'openai/gpt-4o-mini',
      name: 'GPT-4o Mini',
      description: 'Fast and affordable, great for structured data extraction',
      costPer1MTokens: 0.15,
      speedRating: '⚡⚡⚡⚡',
      accuracyRating: '95%',
    ),
    OpenRouterModel(
      id: 'anthropic/claude-3-haiku',
      name: 'Claude 3 Haiku',
      description: 'Fastest Claude model, excellent for parsing',
      costPer1MTokens: 0.25,
      speedRating: '⚡⚡⚡⚡⚡',
      accuracyRating: '96%',
    ),
    OpenRouterModel(
      id: 'google/gemini-flash-1.5',
      name: 'Gemini 1.5 Flash',
      description: 'Google\'s fastest model with good accuracy',
      costPer1MTokens: 0.075,
      speedRating: '⚡⚡⚡⚡⚡',
      accuracyRating: '94%',
    ),
    OpenRouterModel(
      id: 'anthropic/claude-3.5-sonnet',
      name: 'Claude 3.5 Sonnet',
      description: 'Highest accuracy for complex business cards',
      costPer1MTokens: 3.0,
      speedRating: '⚡⚡⚡',
      accuracyRating: '98%',
    ),
    OpenRouterModel(
      id: 'meta-llama/llama-3.1-8b-instruct',
      name: 'Llama 3.1 8B',
      description: 'Open source, very affordable',
      costPer1MTokens: 0.05,
      speedRating: '⚡⚡⚡⚡',
      accuracyRating: '90%',
    ),
  ];

  static OpenRouterModel? getModelById(String id) {
    try {
      return recommendedModels.firstWhere((model) => model.id == id);
    } catch (e) {
      return null;
    }
  }

  static OpenRouterModel get defaultModel => recommendedModels[0]; // GPT-4o Mini
}
