import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/app/app.dart';
import 'package:kiyoshi/src/core/services/vault_service.dart';
import 'package:kiyoshi/src/core/providers/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      ],
      child: const KiyoshiApp(),
    ),
  );
}
