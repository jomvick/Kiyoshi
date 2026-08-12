import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/features/widget_bar/widget_window_service.dart';

final widgetWindowServiceProvider = Provider<WidgetWindowService>((ref) {
  return WidgetWindowService();
});