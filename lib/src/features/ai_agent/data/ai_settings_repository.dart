/// AI Settings persistence repository using SharedPreferences.
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kiyoshi/src/features/ai_agent/domain/entities/ai_config.dart';

class AiSettingsRepository {
  static const _key = 'ai_settings_v1';

  final SharedPreferences _prefs;

  const AiSettingsRepository(this._prefs);

  AiSettings load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const AiSettings();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AiSettings.fromJson(json);
    } catch (_) {
      return const AiSettings();
    }
  }

  Future<void> save(AiSettings settings) async {
    await _prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
