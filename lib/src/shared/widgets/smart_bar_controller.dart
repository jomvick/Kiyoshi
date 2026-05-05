import 'package:flutter/material.dart';
import 'package:kiyoshi/src/core/theme/app_theme.dart';

class SmartBarController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> children = [];
    
    // Regex for different tokens
    final regex = RegExp(r'(#\w+)|(![1-4])|(@\w+)|(demain|tomorrow|today|lundi|monday)', caseSensitive: false);
    
    text.splitMapJoin(
      regex,
      onMatch: (Match match) {
        final matchText = match.group(0)!;
        Color color = AppTheme.primary;
        
        if (matchText.startsWith('#')) {
          color = const Color(0xFF5EEAD4); // Mint Teal
        } else if (matchText.startsWith('!')) {
          color = const Color(0xFFFF6B9A); // Pastel Red
        } else if (matchText.startsWith('@')) {
          color = const Color(0xFF7C8CFF); // Soft Blue
        } else {
          color = const Color(0xFF86EFAC); // Pale Sage
        }

        children.add(
          TextSpan(
            text: matchText,
            style: style?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        return matchText;
      },
      onNonMatch: (String nonMatch) {
        children.add(TextSpan(text: nonMatch, style: style));
        return nonMatch;
      },
    );

    return TextSpan(style: style, children: children);
  }
}
