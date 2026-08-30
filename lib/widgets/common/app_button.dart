import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool compact;
  final bool pulse;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.compact = false,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final height = compact ? AppTheme.buttonHeightSm : AppTheme.buttonHeight;

    final style = switch (variant) {
      AppButtonVariant.primary => ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, height),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      AppButtonVariant.secondary => ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, height),
          backgroundColor: appColors.cardHighlight,
          foregroundColor: colors.onSurface,
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      AppButtonVariant.outline => OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, height),
          side: BorderSide(color: colors.outline.withOpacity(0.3)),
          foregroundColor: colors.onSurface,
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      AppButtonVariant.danger => ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, height),
          backgroundColor: appColors.danger.withOpacity(AppTheme.opacitySubtle),
          foregroundColor: appColors.danger,
          textStyle: text.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
    };

    void handlePress() {
      HapticFeedback.selectionClick();
      onPressed?.call();
    }

    final effectiveOnPressed = onPressed == null ? null : handlePress;

    final child = icon != null
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppTheme.iconMd),
              const SizedBox(width: AppTheme.spacingSm),
              Flexible(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          )
        : Text(label);

    if (variant == AppButtonVariant.outline) {
      return OutlinedButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: child,
      );
    }

    final button = ElevatedButton(
      onPressed: effectiveOnPressed,
      style: style,
      child: child,
    );

    if (variant == AppButtonVariant.primary) {
      if (pulse && onPressed != null) {
        return _PulseGlow(color: colors.primary, child: button);
      }
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: -2,
            ),
          ],
        ),
        child: button,
      );
    }
    return button;
  }
}

class _PulseGlow extends StatefulWidget {
  final Widget child;
  final Color color;

  const _PulseGlow({required this.child, required this.color});

  @override
  State<_PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<_PulseGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      builder: (context, child) {
        final v = _controller.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.25 + 0.30 * v),
                blurRadius: 18 + 22 * v,
                spreadRadius: -2 + 3 * v,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
