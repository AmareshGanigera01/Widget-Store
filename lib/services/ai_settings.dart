import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AiProvider { none, gemini, ollama }

class AiSettings {
  const AiSettings({
    this.provider = AiProvider.none,
    this.geminiKey = '',
    this.geminiModel = defaultGeminiModel,
    this.ollamaUrl = 'http://10.0.2.2:11434',
    this.ollamaModel = 'qwen3',
  });

  static const defaultGeminiModel = 'gemini-3.8-flash';

  final AiProvider provider;
  final String geminiKey;
  final String geminiModel;

  /// 10.0.2.2 is the host machine when running in the Android emulator.
  final String ollamaUrl;
  final String ollamaModel;

  bool get configured => switch (provider) {
        AiProvider.none => false,
        AiProvider.gemini => geminiKey.isNotEmpty,
        AiProvider.ollama => ollamaUrl.isNotEmpty && ollamaModel.isNotEmpty,
      };

  AiSettings copyWith({AiProvider? provider, String? geminiKey, String? geminiModel, String? ollamaUrl, String? ollamaModel}) =>
      AiSettings(
        provider: provider ?? this.provider,
        geminiKey: geminiKey ?? this.geminiKey,
        geminiModel: geminiModel ?? this.geminiModel,
        ollamaUrl: ollamaUrl ?? this.ollamaUrl,
        ollamaModel: ollamaModel ?? this.ollamaModel,
      );
}

/// Stored in Android Keystore-backed storage, never in the database or logs.
class AiSettingsStore {
  static const _storage = FlutterSecureStorage();

  static Future<AiSettings> load() async {
    final all = await _storage.readAll();
    const d = AiSettings();
    return AiSettings(
      provider: AiProvider.values.asNameMap()[all['ai.provider']] ?? AiProvider.none,
      geminiKey: all['ai.gemini.key'] ?? '',
      geminiModel: (all['ai.gemini.model'] ?? '').isEmpty ? d.geminiModel : all['ai.gemini.model']!,
      ollamaUrl: (all['ai.ollama.url'] ?? '').isEmpty ? d.ollamaUrl : all['ai.ollama.url']!,
      ollamaModel: (all['ai.ollama.model'] ?? '').isEmpty ? d.ollamaModel : all['ai.ollama.model']!,
    );
  }

  static Future<void> save(AiSettings s) async {
    await _storage.write(key: 'ai.provider', value: s.provider.name);
    await _storage.write(key: 'ai.gemini.key', value: s.geminiKey.trim());
    await _storage.write(key: 'ai.gemini.model', value: s.geminiModel.trim());
    await _storage.write(key: 'ai.ollama.url', value: s.ollamaUrl.trim());
    await _storage.write(key: 'ai.ollama.model', value: s.ollamaModel.trim());
  }
}
