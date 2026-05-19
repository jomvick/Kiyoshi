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

  bool _isInsideVault(String path) {
    if (_vaultDir == null) return false;
    final resolved = File(path).resolveSymbolicLinksSync();
    final vaultResolved = _vaultDir!.resolveSymbolicLinksSync();
    return p.isWithin(vaultResolved, resolved);
  }

  Future<String> copyToVault(String originalPath) async {
    if (_vaultDir == null) await init();

    final resolved = await File(originalPath).resolveSymbolicLinks();
    final file = File(resolved);
    if (!await file.exists()) {
      throw Exception('Original file does not exist at $originalPath');
    }

    final fileName = p.basename(resolved);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newFileName = '${timestamp}_$fileName';
    final destinationPath = p.join(_vaultDir!.path, newFileName);

    await file.copy(destinationPath);
    return destinationPath;
  }

  Future<void> deleteFromVault(String vaultPath) async {
    if (!_isInsideVault(vaultPath)) return;
    final file = File(vaultPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String get vaultPath => _vaultDir?.path ?? '';
}
