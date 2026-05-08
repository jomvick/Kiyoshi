import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final DateTime releaseDate;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.releaseDate,
  });
}

class UpdateService {
  static const String _owner = 'ton-github-username';
  static const String _repo = 'kiyoshi';

  String _currentVersion = '1.0.0';

  UpdateService() {
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final versionFile = await rootBundle.loadString('VERSION');
      _currentVersion = versionFile.trim();
    } catch (e) {
      // Utilise la version par défaut
    }
  }

  String get currentVersion => _currentVersion;

  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_owner/$_repo/releases/latest'),
        headers: {'Accept': 'application/vnd.github+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tagName = data['tag_name'] as String;
        final version = tagName.replaceFirst('v', '');
        
        if (_isNewerVersion(version, _currentVersion)) {
          String? downloadUrl;
          
          final assets = data['assets'] as List;
          for (final asset in assets) {
            final name = asset['name'] as String;
            if (name.endsWith('.tar.gz') || name.endsWith('.zip')) {
              downloadUrl = asset['browser_download_url'] as String;
              break;
            }
          }
          
          return UpdateInfo(
            version: version,
            downloadUrl: downloadUrl ?? data['zipball_url'] as String,
            releaseNotes: data['body'] as String? ?? '',
            releaseDate: DateTime.parse(data['published_at'] as String),
          );
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
    return null;
  }

  bool _isNewerVersion(String newVersion, String currentVersion) {
    final newParts = newVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();
    
    for (var i = 0; i < newParts.length; i++) {
      final newPart = i < newParts.length ? newParts[i] : 0;
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      if (newPart > currentPart) return true;
      if (newPart < currentPart) return false;
    }
    return false;
  }

  Future<bool> downloadAndInstall(UpdateInfo update) async {
    try {
      final response = await http.get(Uri.parse(update.downloadUrl));
      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      debugPrint('Download failed: $e');
    }
    return false;
  }
}