import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  void _handlePress() {
    if (isLoading || onPressed == null) return;
    // Provide premium haptic feedback on tap
    HapticFeedback.lightImpact();
    onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: backgroundColor != null ? BorderSide(color: backgroundColor!) : null,
        ),
        onPressed: onPressed == null ? null : _handlePress,
        child: _buildContent(context),
      );
    }

    return ElevatedButton(
      style: backgroundColor != null || foregroundColor != null
          ? ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
            )
          : null,
      onPressed: onPressed == null ? null : _handlePress,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: isOutlined
              ? (foregroundColor ?? Theme.of(context).primaryColor)
              : (foregroundColor ?? Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}
