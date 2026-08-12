import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:kiyoshi/src/features/widget_bar/cards/quick_capture_card.dart';
import 'package:kiyoshi/src/features/widget_bar/cards/today_tasks_card.dart';
import 'package:kiyoshi/src/features/widget_bar/cards/calendar_card.dart';
import 'package:kiyoshi/src/features/widget_bar/cards/mini_kanban_card.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:kiyoshi/src/features/widget_bar/widget_window_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

class WidgetBarScreen extends ConsumerStatefulWidget {
  const WidgetBarScreen({super.key});

  @override
  ConsumerState<WidgetBarScreen> createState() => _WidgetBarScreenState();
}

class _WidgetBarScreenState extends ConsumerState<WidgetBarScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _titles = [
    'Quick Capture',
    'Today',
    'Calendar',
    'Mini Kanban',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Brings the main Kiyoshi window to the front without closing the
  /// widget — the widget's shortcut back into the full app. A desktop
  /// widget should expose a few features without a context switch, but
  /// getting to the full app should always be one tap away too.
  void _openMainApp() async {
    try {
      final controllers = await WindowController.getAll();
      for (final controller in controllers) {
        if (controller.arguments != WidgetWindowService.windowArguments) {
          await controller.invokeMethod('openMainWindow');
          break;
        }
      }
    } catch (e) {
      debugPrint('Failed to open main window: $e');
    }
  }

  void _hideWindow() async {
    // Hiding (not closing) the GTK window keeps the widget engine alive. On
    // Linux, destroying a desktop_multi_window sub-window leaves its implicit
    // view invalid, and the next frame-clock tick paints it -> SIGSEGV in
    // gdk_gl_texture_from_surface. Hiding avoids the teardown entirely and the
    // widget can be shown again instantly from the sidebar.
    await windowManager.hide();
    await _notifyMainWindowHidden();
  }

  /// Tells the main window that the widget was hidden by the user, so its
  /// sidebar toggle state stays in sync.
  Future<void> _notifyMainWindowHidden() async {
    try {
      final controllers = await WindowController.getAll();
      for (final controller in controllers) {
        if (controller.arguments != WidgetWindowService.windowArguments) {
          await controller.invokeMethod('widgetHidden');
          break;
        }
      }
    } catch (e) {
      debugPrint('Failed to notify main window of widget hide: $e');
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = AppTheme.isDark(context);

    // Native per-pixel window transparency on Linux depends on the
    // desktop_multi_window plugin's platform code, which isn't reliable
    // across compositors. Rather than gamble on it, the card fills the
    // window edge-to-edge (only a small inset for the drop shadow) and
    // the Scaffold behind it is a solid, near-matching color instead of
    // Colors.transparent. If transparency works, nobody notices. If it
    // doesn't, the rounded corners reveal this color instead of a raw
    // black GTK square.
    final fallbackBg =
        isDark ? const Color(0xFF23221F) : const Color(0xFFE7F1EF);

    // Two-layer approach to get rounded corners back without reopening the
    // black-square bug:
    //  1. An OUTER solid layer with square corners, painted edge-to-edge
    //     across 100% of the window. Flutter guarantees this paints fully
    //     — there is no native compositing involved, it's one plain rect.
    //  2. An INNER rounded card, inset a few px, clipped with ClipRRect
    //     (not just a decoration borderRadius) so its corners are cut
    //     against something Flutter itself painted — the outer layer —
    //     never against the native GTK canvas.
    // The 4 corner triangles and the inset margin always show the outer
    // solid color, never black, because that outer layer has no gaps of
    // its own to begin with.
    return Scaffold(
      backgroundColor: fallbackBg,
      body: Container(
        color: fallbackBg,
        padding: const EdgeInsets.all(7),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF3A3937).withValues(alpha: 0.85),
                        const Color(0xFF262624).withValues(alpha: 0.9),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.92),
                        const Color(0xFFE0F2F1).withValues(alpha: 0.9),
                      ],
              ),
              border: Border.all(
                color: scheme.primary.withValues(alpha: isDark ? 0.35 : 0.25),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                _buildHeader(scheme),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: const [
                      QuickCaptureCard(),
                      TodayTasksCard(),
                      CalendarCard(),
                      MiniKanbanCard(),
                    ],
                  ),
                ),
                _buildDots(scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    return DragToMoveArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LucideIcons.layoutGrid,
                size: 15,
                color: scheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _titles[_currentPage],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
            ),
            const Spacer(),
            _WindowButton(
              // A minimize button on a frameless, skip-taskbar window is a
              // trap: minimized, it has no taskbar entry to restore it
              // from and effectively vanishes. "Open full app" is the
              // shortcut that actually earns its place in the header.
              icon: LucideIcons.externalLink,
              onTap: _openMainApp,
              tooltip: 'Open Kiyoshi',
              color: scheme.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 4),
            _WindowButton(
              icon: LucideIcons.eyeOff,
              onTap: _hideWindow,
              tooltip: 'Hide widget',
              color: scheme.error.withValues(alpha: 0.85),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_titles.length, (index) {
          final active = index == _currentPage;
          return GestureDetector(
            onTap: () => _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active
                    ? scheme.primary
                    : scheme.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WindowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color color;

  const _WindowButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}