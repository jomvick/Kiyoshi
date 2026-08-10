/// AI Agent configuration domain entities for Kiyoshi.
/// Supports OpenAI, Google Gemini, Anthropic Claude and local Ollama models.
library;

enum AiProvider {
  openAI('OpenAI', 'https://api.openai.com/v1'),
  gemini('Google Gemini', 'https://generativelanguage.googleapis.com/v1beta'),
  anthropic('Anthropic Claude', 'https://api.anthropic.com/v1'),
  ollama('Ollama (Local)', 'http://localhost:11434');

  const AiProvider(this.displayName, this.defaultBaseUrl);

  final String displayName;
  final String defaultBaseUrl;

  /// Returns true if this provider typically runs locally without a key.
  bool get isLocal => this == AiProvider.ollama;
}

/// Per-provider configuration stored in SharedPreferences.
class AiProviderConfig {
  final AiProvider provider;
  final String apiKey;
  final String baseUrl;
  final String model;
  final bool isEnabled;

  AiProviderConfig({
    required this.provider,
    this.apiKey = '',
    String? baseUrl,
    required this.model,
    this.isEnabled = false,
  }) : baseUrl = baseUrl ?? provider.defaultBaseUrl;

  AiProviderConfig copyWith({
    String? apiKey,
    String? baseUrl,
    String? model,
    bool? isEnabled,
  }) {
    return AiProviderConfig(
      provider: provider,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'model': model,
        'isEnabled': isEnabled,
      };

  factory AiProviderConfig.fromJson(Map<String, dynamic> json) {
    final providerName = json['provider'] as String? ?? AiProvider.openAI.name;
    final provider = AiProvider.values.firstWhere(
      (p) => p.name == providerName,
      orElse: () => AiProvider.openAI,
    );
    return AiProviderConfig(
      provider: provider,
      apiKey: json['apiKey'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? provider.defaultBaseUrl,
      model: json['model'] as String? ?? defaultModelFor(provider),
      isEnabled: json['isEnabled'] as bool? ?? false,
    );
  }

  static String defaultModelFor(AiProvider provider) {
    return switch (provider) {
      AiProvider.openAI => 'gpt-4o-mini',
      AiProvider.gemini => 'gemini-2.0-flash',
      AiProvider.anthropic => 'claude-3-5-haiku-20241022',
      AiProvider.ollama => 'llama3.2',
    };
  }

  /// Default model suggestions per provider.
  static List<String> modelsFor(AiProvider provider) {
    return switch (provider) {
      AiProvider.openAI => [
          'gpt-4o-mini',
          'gpt-4o',
          'gpt-4-turbo',
          'gpt-3.5-turbo',
        ],
      AiProvider.gemini => [
          'gemini-2.0-flash',
          'gemini-1.5-flash-latest',
          'gemini-1.5-flash',
          'gemini-1.5-pro-latest',
          'gemini-1.5-pro',
        ],
      AiProvider.anthropic => [
          'claude-3-5-haiku-20241022',
          'claude-3-5-sonnet-20241022',
          'claude-3-opus-20240229',
        ],
      AiProvider.ollama => [
          'llama3.2',
          'llama3.1',
          'mistral',
          'qwen2.5',
          'gemma3',
          'phi4',
        ],
    };
  }
}

/// Global AI settings: which provider is active + all per-provider configs.
class AiSettings {
  final AiProvider activeProvider;
  final Map<AiProvider, AiProviderConfig> configs;
  final String systemPrompt;
  final bool autoExecute; // true = execute immediately, false = show confirm

  const AiSettings({
    this.activeProvider = AiProvider.ollama,
    this.configs = const {},
    this.systemPrompt = defaultSystemPrompt,
    this.autoExecute = true,
  });

  AiProviderConfig get activeConfig =>
      configs[activeProvider] ??
      AiProviderConfig(
        provider: activeProvider,
        model: AiProviderConfig.defaultModelFor(activeProvider),
      );

  AiSettings copyWith({
    AiProvider? activeProvider,
    Map<AiProvider, AiProviderConfig>? configs,
    String? systemPrompt,
    bool? autoExecute,
  }) {
    return AiSettings(
      activeProvider: activeProvider ?? this.activeProvider,
      configs: configs ?? this.configs,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      autoExecute: autoExecute ?? this.autoExecute,
    );
  }

  AiSettings withProviderConfig(AiProviderConfig config) {
    final updated = Map<AiProvider, AiProviderConfig>.from(configs);
    updated[config.provider] = config;
    return copyWith(configs: updated);
  }

  Map<String, dynamic> toJson() => {
        'activeProvider': activeProvider.name,
        'configs': {
          for (final e in configs.entries) e.key.name: e.value.toJson(),
        },
        'systemPrompt': systemPrompt,
        'autoExecute': autoExecute,
      };

  factory AiSettings.fromJson(Map<String, dynamic> json) {
    final providerName =
        json['activeProvider'] as String? ?? AiProvider.ollama.name;
    final activeProvider = AiProvider.values.firstWhere(
      (p) => p.name == providerName,
      orElse: () => AiProvider.ollama,
    );
    final rawConfigs = json['configs'] as Map<String, dynamic>? ?? {};
    final configs = <AiProvider, AiProviderConfig>{};
    for (final entry in rawConfigs.entries) {
      final provider = AiProvider.values.firstWhere(
        (p) => p.name == entry.key,
        orElse: () => AiProvider.openAI,
      );
      configs[provider] =
          AiProviderConfig.fromJson(entry.value as Map<String, dynamic>);
    }
    return AiSettings(
      activeProvider: activeProvider,
      configs: configs,
      systemPrompt: json['systemPrompt'] as String? ?? defaultSystemPrompt,
      autoExecute: json['autoExecute'] as bool? ?? true,
    );
  }

  static const defaultSystemPrompt = '''You are Kiyoshi AI, a helpful assistant built directly into the Kiyoshi productivity app.
You can create and manage tasks, projects, workspaces, and notes by calling tools.
Always respond concisely. When you create or update something, briefly confirm the action.
If the user gives you ambiguous requests, ask one clarifying question before acting.
Respond in the same language the user used (French or English).''';
}
