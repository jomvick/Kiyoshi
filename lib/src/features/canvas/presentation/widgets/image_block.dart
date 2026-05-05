import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';

class ImageBlockWidget extends StatefulWidget {
  final String imageUrl;
  final String size; // 'small' | 'medium' | 'large' | 'full'
  final VoidCallback? onDelete;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSizeChanged;

  const ImageBlockWidget({
    super.key,
    required this.imageUrl,
    this.size = 'large',
    this.onDelete,
    this.onChanged,
    this.onSizeChanged,
  });

  @override
  State<ImageBlockWidget> createState() => _ImageBlockWidgetState();
}

class _ImageBlockWidgetState extends State<ImageBlockWidget> {
  bool _isHovered = false;

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        widget.onChanged?.call(result.files.single.path!);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.imageUrl.isEmpty || widget.imageUrl == 'https://';
    if (isEmpty) return _buildEmptyState();
    return _buildImageView();
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: _pickImage,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.primary.withValues(alpha: 0.05)
                : AppTheme.surfaceContainerLow.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.primary.withValues(alpha: 0.3)
                  : AppTheme.outline.withValues(alpha: 0.2),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.imagePlus,
                size: 32,
                color: AppTheme.primary.withValues(alpha: _isHovered ? 0.7 : 0.35),
              ),
              const SizedBox(height: 12),
              Text(
                'Click to upload an image',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: _isHovered ? 0.8 : 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PNG, JPG, GIF, WEBP',
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageView() {
    final maxWidth = switch (widget.size) {
      'small'  => 320.0,
      'medium' => 560.0,
      'large'  => 800.0,
      _        => double.infinity, // 'full'
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: widget.imageUrl.startsWith('http')
                      ? Image.network(
                          widget.imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          errorBuilder: (e, s, w) => _buildEmptyState(),
                        )
                      : Image.file(
                          File(widget.imageUrl),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          errorBuilder: (e, s, w) => _buildEmptyState(),
                        ),
                ),
                if (_isHovered)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _SizeBar(
                          current: widget.size,
                          onSelect: widget.onSizeChanged,
                        ),
                        const SizedBox(width: 6),
                        _ActionButton(icon: LucideIcons.imagePlus, onTap: _pickImage),
                        const SizedBox(width: 6),
                        if (widget.onDelete != null)
                          _ActionButton(
                            icon: Icons.delete_outline_rounded,
                            onTap: widget.onDelete!,
                            isDelete: true,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDelete;
  const _ActionButton({required this.icon, required this.onTap, this.isDelete = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: isDelete ? Colors.redAccent : Colors.white),
      ),
    );
  }
}

class _SizeBar extends StatelessWidget {
  final String current;
  final ValueChanged<String>? onSelect;

  const _SizeBar({required this.current, this.onSelect});

  static const _sizes = [
    ('S', 'small'),
    ('M', 'medium'),
    ('L', 'large'),
    ('↔', 'full'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _sizes.map((entry) {
          final (label, value) = entry;
          final isActive = current == value;
          return GestureDetector(
            onTap: () => onSelect?.call(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
