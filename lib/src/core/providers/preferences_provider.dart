import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.dart');
});

final preferencesProvider = StateNotifierProvider<PreferencesNotifier, AppPreferences>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesNotifier(prefs);
});

class AppPreferences {
  final bool sidebarExpanded;
  final bool zenModeEnabled;
  final String defaultDestination;
  final double sidebarWidth;

  const AppPreferences({
    this.sidebarExpanded = true,
    this.zenModeEnabled = false,
    this.defaultDestination = 'projects',
    this.sidebarWidth = 280,
  });

  AppPreferences copyWith({
    bool? sidebarExpanded,
    bool? zenModeEnabled,
    String? defaultDestination,
    double? sidebarWidth,
  }) {
    return AppPreferences(
      sidebarExpanded: sidebarExpanded ?? this.sidebarExpanded,
      zenModeEnabled: zenModeEnabled ?? this.zenModeEnabled,
      defaultDestination: defaultDestination ?? this.defaultDestination,
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
    );
  }
}

class PreferencesNotifier extends StateNotifier<AppPreferences> {
  final SharedPreferences _prefs;

  PreferencesNotifier(this._prefs) : super(const AppPreferences()) {
    _loadPreferences();
  }

  void _loadPreferences() {
    state = AppPreferences(
      sidebarExpanded: _prefs.getBool('sidebar_expanded') ?? true,
      zenModeEnabled: _prefs.getBool('zen_mode_enabled') ?? false,
      defaultDestination: _prefs.getString('default_destination') ?? 'projects',
      sidebarWidth: _prefs.getDouble('sidebar_width') ?? 280,
    );
  }

  Future<void> setSidebarExpanded(bool expanded) async {
    await _prefs.setBool('sidebar_expanded', expanded);
    state = state.copyWith(sidebarExpanded: expanded);
  }

  Future<void> setZenModeEnabled(bool enabled) async {
    await _prefs.setBool('zen_mode_enabled', enabled);
    state = state.copyWith(zenModeEnabled: enabled);
  }

  Future<void> setDefaultDestination(String destination) async {
    await _prefs.setString('default_destination', destination);
    state = state.copyWith(defaultDestination: destination);
  }

  Future<void> setSidebarWidth(double width) async {
    await _prefs.setDouble('sidebar_width', width);
    state = state.copyWith(sidebarWidth: width);
  }
}