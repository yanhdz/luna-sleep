import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

/// Large capsule-shaped primary button with optional gradient and glow.
class LunaButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Color? backgroundColor;
  final bool isLoading;
  final bool isDestructive;

  const LunaButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.gradient,
    this.backgroundColor,
    this.isLoading = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultGradient = isDestructive
        ? const LinearGradient(
            colors: [AppColors.danger, Color(0xFFFF8FAD)])
        : AppColors.primaryGradient;

    return GestureDetector(
      onTap: (isLoading || onPressed == null) ? null : onPressed,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: backgroundColor == null ? (gradient ?? defaultGradient) : null,
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: isDestructive
                  ? AppColors.danger.withAlpha(80)
                  : AppColors.primary.withAlpha(80),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            else if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
            ],
            if (!isLoading)
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
          ],
        ),
      )
          .animate(target: onPressed == null ? 0 : 1)
          .fade(begin: 0.5, end: 1.0),
    );
  }
}
