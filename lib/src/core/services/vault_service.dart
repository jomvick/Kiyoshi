import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class VaultService {
  static final VaultService _instance = VaultService._internal();
  factory VaultService() => _instance;
  VaultService._internal();

  static const String _vaultFolder = 'kiyoshi/vault';
  Directory? _vaultDir;

  Future<void> init() async {
    final docDir = await getApplicationDocumentsDirectory();
    _vaultDir = Directory(p.join(docDir.path, _vaultFolder));
    if (!await _vaultDir!.exists()) {
      await _vaultDir!.create(recursive: true);
    }
  }

  /// Copies an external file to the vault and returns the new local path.
  Future<String> copyToVault(String originalPath) async {
    if (_vaultDir == null) await init();
    
    final file = File(originalPath);
    if (!await file.exists()) {
      throw Exception('Original file does not exist at $originalPath');
    }

    final fileName = p.basename(originalPath);
    // Add timestamp to avoid collisions
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = '${timestamp}_$fileName';
    final destinationPath = p.join(_vaultDir!.path, newFileName);

    await file.copy(destinationPath);
    return destinationPath;
  }

  /// Deletes a file from the vault.
  Future<void> deleteFromVault(String vaultPath) async {
    // Only delete if it's actually inside our vault to be safe
    if (vaultPath.contains(_vaultFolder)) {
      final file = File(vaultPath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  String get vaultPath => _vaultDir?.path ?? '';
}
