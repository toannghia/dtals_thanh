import 'package:flutter/material.dart';

enum BadgeType { success, error, warning, info, neutral }

class StatusBadge extends StatelessWidget {
  final String text;
  final BadgeType type;

  const StatusBadge({
    super.key,
    required this.text,
    this.type = BadgeType.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    switch (type) {
      case BadgeType.success:
        bgColor = const Color(0xFFD1FAE5); // Emerald 100
        textColor = const Color(0xFF065F46); // Emerald 800
        break;
      case BadgeType.error:
        bgColor = const Color(0xFFFEE2E2); // Red 100
        textColor = const Color(0xFF991B1B); // Red 800
        break;
      case BadgeType.warning:
        bgColor = const Color(0xFFFEF3C7); // Amber 100
        textColor = const Color(0xFF92400E); // Amber 800
        break;
      case BadgeType.info:
        bgColor = const Color(0xFFDBEAFE); // Blue 100
        textColor = const Color(0xFF1E40AF); // Blue 800
        break;
      case BadgeType.neutral:
      default:
        bgColor = const Color(0xFFF1F5F9); // Slate 100
        textColor = const Color(0xFF475569); // Slate 600
        break;
    }

    // Adapt for dark mode to not be overly bright
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      bgColor = bgColor.withOpacity(0.15);
      // Brighten text colors slightly for dark mode contrast
      textColor = _lightenColor(textColor, 0.4);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
}
