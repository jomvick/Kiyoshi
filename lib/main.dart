import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiyoshi/src/app/app.dart';
import 'package:kiyoshi/src/core/services/vault_service.dart';
import 'package:kiyoshi/src/core/providers/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Vault (Invisible Management)
  await VaultService().init();
  
  // Initialize SharedPreferences
  final sharedPrefs = await SharedPreferences.getInstance();
  
  // Set window properties for Zen light theme
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
