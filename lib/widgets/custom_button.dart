import 'package:flutter/material.dart';
import 'package:mtc/utils/theme_provider.dart';

/// Primary filled button — uses theme primary color
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppTheme t;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double? width;
  final double fontSize;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.t,
    this.isLoading = false,
    this.icon,
    this.height = 52,
    this.width,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: isLoading
              ? t.primary.withOpacity(0.5)
              : onTap == null
                  ? t.primary.withOpacity(0.3)
                  : t.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading || onTap == null
              ? []
              : [
                  BoxShadow(
                    color: t.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: t.background, strokeWidth: 2))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: t.background, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                          color: t.background,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Outlined / ghost button
class OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppTheme t;
  final IconData? icon;
  final double height;
  final Color? borderColor;
  final Color? labelColor;

  const OutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.t,
    this.icon,
    this.height = 52,
    this.borderColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = borderColor ?? t.primary;
    final text  = labelColor  ?? t.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: text, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                    color: text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Danger / destructive button (red)
class DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;

  const DangerButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.redAccent.withOpacity(0.3), width: 1.5),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.redAccent, strokeWidth: 2))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.redAccent, size: 17),
                      const SizedBox(width: 8),
                    ],
                    Text(label,
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Small icon action button — used in cards and app bars
class IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final AppTheme t;
  final Color? color;
  final String? badge;

  const IconActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.t,
    this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? t.primary;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: c.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: c.withOpacity(0.3)),
            ),
            child: Icon(icon, color: c, size: 19),
          ),
          if (badge != null)
            Positioned(
              top: 0, right: 0,
              child: Container(
                width: 16, height: 16,
                decoration: BoxDecoration(
                    color: c, shape: BoxShape.circle),
                child: Center(
                  child: Text(badge!,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}