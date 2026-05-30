import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';

class LinkBlockWidget extends StatefulWidget {
  final String url;
  final String? title;
  final String? faviconUrl;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onDelete;

  const LinkBlockWidget({
    super.key,
    required this.url,
    this.title,
    this.faviconUrl,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<LinkBlockWidget> createState() => _LinkBlockWidgetState();
}

class _LinkBlockWidgetState extends State<LinkBlockWidget> {
  bool _isHovered = false;
  bool _isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.url);
  }

  @override
  void didUpdateWidget(LinkBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url && _controller.text != widget.url) {
      _controller.text = widget.url;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _allowedSchemes = ['https:', 'http:', 'mailto:'];

  static bool _isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    return _allowedSchemes.contains(uri.scheme);
  }

  Future<void> _openUrl() async {
    if (_isEditing) return;
    if (!_isValidUrl(widget.url)) return;
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _openUrl,
        child: AnimatedContainer(
          duration: AppTheme.animFastest,
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.primary.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: _isHovered
                  ? AppTheme.primary.withValues(alpha: 0.2)
                  : AppTheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: widget.faviconUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          widget.faviconUrl!,
                          width: 20,
                          height: 20,
                          cacheWidth: 40, // Small icons don't need big buffers
                          cacheHeight: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            LucideIcons.link,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                        ),
                      )
                    : const Icon(LucideIcons.link2, size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: _controller,
                        autofocus: true,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.onBackground,
                            ),
                        decoration: const InputDecoration(
                          hintText: 'Enter URL...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (val) {
                          setState(() => _isEditing = false);
                          widget.onChanged?.call(val);
                        },
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title ?? widget.url,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.onBackground,
                                  fontWeight: FontWeight.w600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.url,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primary.withValues(alpha: 0.7),
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
              ),
              if (_isHovered && !_isEditing) ...[
                Icon(LucideIcons.externalLink,
                    size: 14,
                    color: AppTheme.primary.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
              ],
              if (_isHovered && widget.onChanged != null && !_isEditing) ...[
                GestureDetector(
                  onTap: () => setState(() => _isEditing = true),
                  child: Icon(
                    LucideIcons.edit2,
                    size: 16,
                    color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 12),
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
