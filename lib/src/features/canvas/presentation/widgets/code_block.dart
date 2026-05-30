import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';

class CodeBlockWidget extends StatefulWidget {
  final String content;
  final String? language;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onDelete;

  const CodeBlockWidget({
    super.key,
    required this.content,
    this.language,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _copied = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
  }

  @override
  void didUpdateWidget(CodeBlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content && _controller.text != widget.content) {
      _controller.text = widget.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Row(
                  children: [
                    _Dot(color: Color(0xFFFF6058)),
                    SizedBox(width: 6),
                    _Dot(color: Color(0xFFFFBC2E)),
                    SizedBox(width: 6),
                    _Dot(color: Color(0xFF2ACA44)),
                  ],
                ),
                const Spacer(),
                if (widget.language != null)
                  Text(
                    widget.language!.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.3),
                      letterSpacing: 1.5,
                    ),
                  ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _copyToClipboard,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _copied
                        ? const Icon(LucideIcons.check, size: 14, color: Color(0xFF2ACA44))
                        : Icon(
                            LucideIcons.copy,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.4),
                            key: const ValueKey('copy'),
                          ),
                  ),
                ),
                if (widget.onDelete != null) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Icon(
                      LucideIcons.trash2,
                      size: 14,
                      color: AppTheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Divider
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          // Code content
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              maxLines: null,
              onChanged: widget.onChanged,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                color: const Color(0xFFE2E8F0),
                height: 1.6,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
