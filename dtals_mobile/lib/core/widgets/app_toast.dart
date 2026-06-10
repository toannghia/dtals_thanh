import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppToastType { info, success, warning, error }

class AppToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    _remove();
    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (ctx) => _ToastOverlay(
        message: message,
        type: type,
      ),
    );
    overlay.insert(_entry!);

    _timer = Timer(duration, _remove);
  }

  static void _remove() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastOverlay extends StatelessWidget {
  final String message;
  final AppToastType type;

  const _ToastOverlay({
    required this.message,
    required this.type,
  });

  Color _backgroundColor() {
    switch (type) {
      case AppToastType.success:
        return AppTheme.successColor;
      case AppToastType.warning:
        return AppTheme.warningColor;
      case AppToastType.error:
        return AppTheme.errorColor;
      case AppToastType.info:
      default:
        return AppTheme.infoColor;
    }
  }

  IconData _icon() {
    switch (type) {
      case AppToastType.success:
        return Icons.check_circle_outline;
      case AppToastType.warning:
        return Icons.warning_amber_outlined;
      case AppToastType.error:
        return Icons.error_outline;
      case AppToastType.info:
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _backgroundColor();

    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 12, right: 12),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(16 * (1 - value), 0),
                    child: child,
                  ),
                );
              },
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_icon(), color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          message,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
