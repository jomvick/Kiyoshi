import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/app/app.dart';
import 'package:kiyoshi/src/core/services/vault_service.dart';
import 'package:kiyoshi/src/core/providers/preferences_provider.dart';
import 'package:kiyoshi/src/features/widget_bar/widget_bar_app.dart';
import 'package:kiyoshi/src/features/widget_bar/widget_window_provider.dart';
import 'package:kiyoshi/src/features/widget_bar/widget_window_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Multi-window support: detect which window this engine belongs to. The
  // widget bar runs in its own Flutter engine/window created via
  // desktop_multi_window; that engine boots the same `main()` and must be
  // routed to the widget UI instead of the main application.
  WindowController? mainController;
  String windowArguments = '';
  try {
    mainController = await WindowController.fromCurrentEngine();
    windowArguments = mainController.arguments;
  } catch (e) {
    debugPrint('Window engine detection failed: $e');
  }

  if (windowArguments == WidgetWindowService.windowArguments) {
    await _runWidgetBar(mainController);
    return;
  }

  // window_manager must be initialized in this isolate before any of its
  // APIs can be called here (e.g. from the openMainWindow handler below).
  await windowManager.ensureInitialized();

  // Intercept the native close so we can shut the widget window down
  // cleanly — in its own engine, via its own window_manager — before this
  // process exits. Without this, closing the main window while the widget's
  // secondary GTK window/engine is still alive can crash: its frame-clock
  // timer stays registered in the glib main loop and the next tick fires
  // after the shared GL/EGL context is torn down, segfaulting in
  // g_type_check_instance_cast.
  await windowManager.setPreventClose(true);
  windowManager.addListener(_AppCloseGuard());

  // Shared instance: the widget bar window can hide itself in-window and
  // notifies the main window, which must mark it hidden so the sidebar toggle
  // keeps its visibility state in sync. It can also ask the main window to
  // bring itself to front — the widget's "open full app" shortcut.
  final windowService = WidgetWindowService();
  if (mainController != null) {
    try {
      await mainController.setWindowMethodHandler((call) async {
        switch (call.method) {
          case 'widgetHidden':
            windowService.markHidden();
            break;
          case 'openMainWindow':
            await windowManager.show();
            await windowManager.focus();
            if (await windowManager.isMinimized()) {
              await windowManager.restore();
            }
            break;
        }
        return null;
      });
    } catch (e) {
      debugPrint('Failed to register widget window handler: $e');
    }
  }

  if (kDebugMode) {
    FlutterError.onError = (details) {
      debugPrint('Flutter error: ${details.exception}');
      debugPrint('Stack: ${details.stack}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Unhandled error: $error');
      debugPrint('Stack: $stack');
      return true;
    };
  }

  try {
    await VaultService().init();
  } catch (e) {
    debugPrint('Vault initialization failed: $e');
  }

  late final SharedPreferences sharedPrefs;
  try {
    sharedPrefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('SharedPreferences initialization failed: $e');
    sharedPrefs = await SharedPreferences.getInstance();
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        widgetWindowServiceProvider.overrideWithValue(windowService),
      ],
      child: const KiyoshiApp(),
    ),
  );
}

/// Boots the floating widget bar window (its own engine/isolate).
///
/// The widget window opens the same SharedPreferences / vault / database as
/// the main app so it shares dark-mode preference and live note/task data.
Future<void> _runWidgetBar(WindowController? selfController) async {
  try {
    await VaultService().init();
  } catch (e) {
    debugPrint('Vault initialization failed: $e');
  }

  final sharedPrefs = await SharedPreferences.getInstance();

  // Lets the main window ask this widget window to close itself cleanly,
  // in its own engine/isolate, before the whole app exits (see
  // _AppCloseGuard). window_manager.close() run here tears down this
  // window's GTK resources and frame clock through the normal, orderly
  // path instead of leaving them dangling when the process quits.
  if (selfController != null) {
    try {
      await selfController.setWindowMethodHandler((call) async {
        if (call.method == 'closeWidgetWindow') {
          await windowManager.ensureInitialized();
          await windowManager.close();
        }
        return null;
      });
    } catch (e) {
      debugPrint('Failed to register widget close handler: $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      ],
      child: const WidgetBarApp(),
    ),
  );
}

/// Ensures the widget bar window is closed cleanly before the main window
/// (and the process) actually exits. See the crash explanation above.
class _AppCloseGuard with WindowListener {
  @override
  void onWindowClose() async {
    try {
      final controllers = await WindowController.getAll();
      for (final controller in controllers) {
        if (controller.arguments == WidgetWindowService.windowArguments) {
          await controller.invokeMethod('closeWidgetWindow');
          break;
        }
      }
    } catch (e) {
      debugPrint('Failed to close widget window on app quit: $e');
    }
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }
}
