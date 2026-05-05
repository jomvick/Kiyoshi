import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage the Zen Focus Mode state.
/// When true, the application should minimize visual clutter 
/// (hide non-essential elements, further simplify headers).
final zenModeProvider = StateProvider<bool>((ref) => false);
