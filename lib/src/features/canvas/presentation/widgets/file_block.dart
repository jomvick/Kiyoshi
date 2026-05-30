import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class FileBlockWidget extends StatefulWidget {
  final String fileName;
  final String? fileSize;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onChanged;

  const FileBlockWidget({
    super.key,
    required this.fileName,
    this.fileSize,
    this.onDelete,
    this.onChanged,
  });

  @override
  State<FileBlockWidget> createState() => _FileBlockWidgetState();
}

class _FileBlockWidgetState extends State<FileBlockWidget> {
  bool _isHovered = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles();
      if (result != null && result.files.single.path != null) {
        widget.onChanged?.call(result.files.single.path!);
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  static const _allowedSchemes = ['https:', 'http:', 'mailto:'];

  static bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    return _allowedSchemes.contains(uri.scheme);
  }

  static bool _isAllowedFilePath(String path) {
    try {
      final resolved = File(path).resolveSymbolicLinksSync();
      final allowed = ['/tmp', '/home', Platform.environment['HOME'] ?? ''];
      return allowed.any((dir) => resolved.startsWith(dir));
    } catch (_) {
      return false;
    }
  }

  Future<void> _openFile() async {
    final filePath = widget.fileName;
    if (filePath.isEmpty) return;

    if (filePath.startsWith('http')) {
      if (!_isValidUrl(filePath)) return;
      final uri = Uri.parse(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      if (!_isAllowedFilePath(filePath)) {
        debugPrint('Blocked access to file outside allowed directories: $filePath');
        return;
      }
      final file = File(filePath);
      if (await file.exists()) {
        final uri = Uri.file(filePath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    }
  }

  String get _displayName {
    if (widget.fileName.isEmpty) return 'No file selected';
    if (widget.fileName.contains('/')) {
      return widget.fileName.split('/').last;
    }
    return widget.fileName;
  }

  IconData get _fileIcon {
    final name = _displayName.toLowerCase();
    if (name.endsWith('.pdf')) return LucideIcons.fileText;
    if (name.endsWith('.zip') || name.endsWith('.rar')) return LucideIcons.archive;
    if (name.endsWith('.mp4') || name.endsWith('.mov')) return LucideIcons.video;
    if (name.endsWith('.mp3') || name.endsWith('.wav')) return LucideIcons.music;
    if (name.endsWith('.dart') || name.endsWith('.py') || name.endsWith('.js')) return LucideIcons.code;
    return LucideIcons.file;
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.fileName.isEmpty;
    if (isEmpty) return _buildEmptyState();
    return _buildFileCard();
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: _pickFile,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: AppTheme.animFastest,
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.primary.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.primary.withValues(alpha: 0.25)
                  : AppTheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.uploadCloud,
                size: 20,
                color: AppTheme.primary.withValues(alpha: _isHovered ? 0.7 : 0.4),
              ),
              const SizedBox(width: 12),
              Text(
                'Click to attach a file',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: _isHovered ? 0.8 : 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileCard() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _openFile,
        child: AnimatedContainer(
          duration: AppTheme.animFastest,
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.primary.withValues(alpha: 0.04)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.primary.withValues(alpha: 0.15)
                  : AppTheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_fileIcon, size: 20, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.onBackground,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.fileSize != null)
                      Text(
                        widget.fileSize!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                      ),
                  ],
                ),
              ),
              if (_isHovered) ...[
                Icon(
                  LucideIcons.externalLink,
                  size: 14,
                  color: AppTheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _pickFile,
                  child: Icon(
                    LucideIcons.refreshCw,
                    size: 14,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (_isHovered && widget.onDelete != null)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppTheme.error.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
