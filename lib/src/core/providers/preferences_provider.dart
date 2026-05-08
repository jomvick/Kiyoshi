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
  final bool darkMode;
  final bool prismaticBorders;
  final bool notifications;
  final bool autoSave;
  final bool showGrid;
  final bool snapToGrid;
  final double kanbanColumnWidth;

  const AppPreferences({
    this.sidebarExpanded = true,
    this.zenModeEnabled = false,
    this.defaultDestination = 'projects',
    this.sidebarWidth = 280,
    this.darkMode = false,
    this.prismaticBorders = true,
    this.notifications = true,
    this.autoSave = true,
    this.showGrid = true,
    this.snapToGrid = true,
    this.kanbanColumnWidth = 300,
  });

  AppPreferences copyWith({
    bool? sidebarExpanded,
    bool? zenModeEnabled,
    String? defaultDestination,
    double? sidebarWidth,
    bool? darkMode,
    bool? prismaticBorders,
    bool? notifications,
    bool? autoSave,
    bool? showGrid,
    bool? snapToGrid,
    double? kanbanColumnWidth,
  }) {
    return AppPreferences(
      sidebarExpanded: sidebarExpanded ?? this.sidebarExpanded,
      zenModeEnabled: zenModeEnabled ?? this.zenModeEnabled,
      defaultDestination: defaultDestination ?? this.defaultDestination,
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      darkMode: darkMode ?? this.darkMode,
      prismaticBorders: prismaticBorders ?? this.prismaticBorders,
      notifications: notifications ?? this.notifications,
      autoSave: autoSave ?? this.autoSave,
      showGrid: showGrid ?? this.showGrid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      kanbanColumnWidth: kanbanColumnWidth ?? this.kanbanColumnWidth,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sidebarExpanded': sidebarExpanded,
      'zenModeEnabled': zenModeEnabled,
      'defaultDestination': defaultDestination,
      'sidebarWidth': sidebarWidth,
      'darkMode': darkMode,
      'prismaticBorders': prismaticBorders,
      'notifications': notifications,
      'autoSave': autoSave,
      'showGrid': showGrid,
      'snapToGrid': snapToGrid,
      'kanbanColumnWidth': kanbanColumnWidth,
    };
  }

  AppPreferences importFromJson(Map<String, dynamic> json) {
    return AppPreferences(
      sidebarExpanded: json['sidebarExpanded'] as bool? ?? sidebarExpanded,
      zenModeEnabled: json['zenModeEnabled'] as bool? ?? zenModeEnabled,
      defaultDestination: json['defaultDestination'] as String? ?? defaultDestination,
      sidebarWidth: (json['sidebarWidth'] as num?)?.toDouble() ?? sidebarWidth,
      darkMode: json['darkMode'] as bool? ?? darkMode,
      prismaticBorders: json['prismaticBorders'] as bool? ?? prismaticBorders,
      notifications: json['notifications'] as bool? ?? notifications,
      autoSave: json['autoSave'] as bool? ?? autoSave,
      showGrid: json['showGrid'] as bool? ?? showGrid,
      snapToGrid: json['snapToGrid'] as bool? ?? snapToGrid,
      kanbanColumnWidth: (json['kanbanColumnWidth'] as num?)?.toDouble() ?? kanbanColumnWidth,
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
      darkMode: _prefs.getBool('dark_mode') ?? false,
      prismaticBorders: _prefs.getBool('prismatic_borders') ?? true,
      notifications: _prefs.getBool('notifications') ?? true,
      autoSave: _prefs.getBool('auto_save') ?? true,
      showGrid: _prefs.getBool('show_grid') ?? true,
      snapToGrid: _prefs.getBool('snap_to_grid') ?? true,
      kanbanColumnWidth: _prefs.getDouble('kanban_column_width') ?? 300,
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

  Future<void> setDarkMode(bool enabled) async {
    await _prefs.setBool('dark_mode', enabled);
    state = state.copyWith(darkMode: enabled);
  }

  Future<void> setPrismaticBorders(bool enabled) async {
    await _prefs.setBool('prismatic_borders', enabled);
    state = state.copyWith(prismaticBorders: enabled);
  }

  Future<void> setNotifications(bool enabled) async {
    await _prefs.setBool('notifications', enabled);
    state = state.copyWith(notifications: enabled);
  }

  Future<void> setAutoSave(bool enabled) async {
    await _prefs.setBool('auto_save', enabled);
    state = state.copyWith(autoSave: enabled);
  }

  Future<void> setShowGrid(bool enabled) async {
    await _prefs.setBool('show_grid', enabled);
    state = state.copyWith(showGrid: enabled);
  }

  Future<void> setSnapToGrid(bool enabled) async {
    await _prefs.setBool('snap_to_grid', enabled);
    state = state.copyWith(snapToGrid: enabled);
  }

  Future<void> setKanbanColumnWidth(double width) async {
    await _prefs.setDouble('kanban_column_width', width);
    state = state.copyWith(kanbanColumnWidth: width);
  }
}