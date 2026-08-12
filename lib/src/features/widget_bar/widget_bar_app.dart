import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:kiyoshi/src/core/providers/preferences_provider.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/features/widget_bar/widget_bar_screen.dart';
import 'package:window_manager/window_manager.dart';

/// The floating Kiyoshi widget bar window.
///
/// Runs in its own engine (created via [desktop_multi_window]) and renders a
/// frameless, always-on-top, transparent window that behaves like a desktop
/// widget. The four swipeable cards live in [WidgetBarScreen].
class WidgetBarApp extends ConsumerStatefulWidget {
  const WidgetBarApp({super.key});

  @override
  ConsumerState<WidgetBarApp> createState() => _WidgetBarAppState();
}

class _WidgetBarAppState extends ConsumerState<WidgetBarApp> {
  @override
  void initState() {
    super.initState();
    _configureWindow();
  }

  Future<void> _configureWindow() async {
    await windowManager.ensureInitialized();
    // Sized to fit the widget's actual content (header + card + dots),
    // not a full-screen mini-app. 600px left visible dead space below
    // short lists (e.g. Quick Capture with only 1-2 items) since the
    // ListView doesn't stretch to fill leftover height — 520px is a
    // tighter fit while still giving Calendar/Kanban room to breathe.
    const options = WindowOptions(
      size: Size(400, 520),
      minimumSize: Size(360, 440),
      maximumSize: Size(460, 680),
      center: true,
      alwaysOnTop: true,
      skipTaskbar: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );

    unawaited(
      windowManager.waitUntilReadyToShow(options, () async {
        await windowManager.setAsFrameless();
        await windowManager.setBackgroundColor(Colors.transparent);
        await windowManager.setAlwaysOnTop(true);
        await windowManager.setSkipTaskbar(true);
        await windowManager.setResizable(true);
        await windowManager.show();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);

    final base = prefs.darkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

    return MaterialApp(
      title: 'Kiyoshi Widget',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: const WidgetBarScreen(),
    );
  }
}