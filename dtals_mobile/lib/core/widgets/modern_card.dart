import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const ModernCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardContent = padding != null 
        ? Padding(padding: padding!, child: child) 
        : child;

    final container = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.05), 
             blurRadius: 10, 
             offset: const Offset(0, 4)
           ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              // Slightly transparent white to reduce glare in dark mode
              color: color ?? (isDark ? Colors.white.withOpacity(0.88) : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.15) : const Color(0xFFE2E8F0), 
                width: 1
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: onTap != null 
                ? InkWell(
                    onTap: onTap,
                    child: cardContent,
                  )
                : cardContent,
            ),
          ),
        ),
      ),
    );

    // Force Light Theme inside the card so text and icons are always highly visible on the solid white background
    return Theme(
      data: AppTheme.lightTheme,
      child: container,
    );
  }
}

