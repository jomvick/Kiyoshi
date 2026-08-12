import 'package:desktop_multi_window/desktop_multi_window.dart';

/// Opens, hides and toggles the floating Kiyoshi widget bar window.
///
/// The widget window is a secondary Flutter window created via
/// [desktop_multi_window]. It runs its own engine & isolate, identifies
/// itself through [WidgetWindowService.windowArguments], and is configured
/// (frameless, always-on-top, transparent) from inside the widget engine.
class WidgetWindowService {
  /// Argument passed when creating the widget window. The widget engine reads
  /// it in `main()` via [WindowController.fromCurrentEngine] to know it is the
  /// widget bar and not the main application window.
  static const String windowArguments = 'widget_bar';

  bool _isVisible = false;

  /// Whether the widget window currently exists and is visible.
  bool get isVisible => _isVisible;

  /// Ensures the widget window exists and is shown.
  Future<void> open() async {
    final existing = await _find();
    if (existing != null) {
      await existing.show();
      _isVisible = true;
      return;
    }
    final controller = await WindowController.create(
      const WindowConfiguration(
        hiddenAtLaunch: true,
        arguments: windowArguments,
      ),
    );
    await controller.show();
    _isVisible = true;
  }

  /// Hides the widget window without destroying its engine, so it can be
  /// shown again instantly.
  Future<void> hide() async {
    final existing = await _find();
    if (existing != null) {
      await existing.hide();
    }
    _isVisible = false;
  }

  /// Shows the widget window when hidden, hides it when visible, and creates
  /// it on first use.
  Future<void> toggle() async {
    final existing = await _find();
    if (existing == null) {
      await open();
      return;
    }
    if (_isVisible) {
      await hide();
    } else {
      await existing.show();
      _isVisible = true;
    }
  }

  /// Marks the widget as hidden. Called from the main window when the widget
  /// window reports it hid itself (e.g. via its in-window hide button).
  void markHidden() {
    _isVisible = false;
  }

  Future<WindowController?> _find() async {
    final controllers = await WindowController.getAll();
    for (final controller in controllers) {
      if (controller.arguments == windowArguments) {
        return controller;
      }
    }
    return null;
  }
}