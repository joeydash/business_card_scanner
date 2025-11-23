class AppSettings {
  final bool useOpenRouter;
  final String selectedModelId;
  final bool apiKeyConfigured;

  const AppSettings({
    this.useOpenRouter = false,
    this.selectedModelId = 'openai/gpt-4o-mini',
    this.apiKeyConfigured = false,
  });

  AppSettings copyWith({
    bool? useOpenRouter,
    String? selectedModelId,
    bool? apiKeyConfigured,
  }) {
    return AppSettings(
      useOpenRouter: useOpenRouter ?? this.useOpenRouter,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      apiKeyConfigured: apiKeyConfigured ?? this.apiKeyConfigured,
    );
  }

  Map<String, dynamic> toJson() => {
        'useOpenRouter': useOpenRouter,
        'selectedModelId': selectedModelId,
        'apiKeyConfigured': apiKeyConfigured,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        useOpenRouter: json['useOpenRouter'] as bool? ?? false,
        selectedModelId: json['selectedModelId'] as String? ?? 'openai/gpt-4o-mini',
        apiKeyConfigured: json['apiKeyConfigured'] as bool? ?? false,
      );
}
