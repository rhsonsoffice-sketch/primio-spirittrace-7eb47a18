import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/investigation.dart';
import '../../theme/theme.dart';
import '../common/glowing_card.dart';
import 'response_fingerprint.dart';
import 'skeptic_context.dart';

class ResponseCard extends StatelessWidget {
  final QuestionResponse response;
  final VoidCallback? onReveal;
  final VoidCallback? onPlay;
  final VoidCallback? onRepeatTest;
  final VoidCallback? onMark;
  final VoidCallback? onNote;
  final bool isRepeated;
  final bool environmentalChange;
  final RepeatComparison? comparison;
  final bool expandDetails;
  final bool skepticMode;
  final bool blindActive;

  const ResponseCard({
    super.key,
    required this.response,
    this.onReveal,
    this.onPlay,
    this.onRepeatTest,
    this.onMark,
    this.onNote,
    this.isRepeated = false,
    this.environmentalChange = false,
    this.comparison,
    this.expandDetails = false,
    this.skepticMode = false,
    this.blindActive = false,
  });

  Color _statusColor(AppColorsExtension appColors, ColorScheme colors) {
    switch (response.status) {
      case ResponseStatus.saved:
        return appColors.success;
      case ResponseStatus.unexplained:
        return appColors.warning;
      case ResponseStatus.dismissed:
      case ResponseStatus.backgroundNoise:
      case ResponseStatus.explained:
        return appColors.subtleText;
      case ResponseStatus.unreviewed:
        return colors.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final hasResponse = response.hasResponse;
    final isLocked =
        (response.blindMode || blindActive) && !response.revealed && hasResponse;
    final timeStr = DateFormat('HH:mm:ss').format(response.timestamp);
    final accent =
        response.isUncertain ? appColors.warning : appColors.glowSecondary;

    return GlowingCard(
      glowColor: hasResponse ? accent : colors.outline,
      glowIntensity: hasResponse ? 0.2 : 0.05,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline,
                  size: AppTheme.iconSm, color: appColors.subtleText),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  response.question,
                  style: text.bodyMedium?.copyWith(color: appColors.subtleText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(timeStr, style: text.labelSmall),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          if (response.isRepeatTest)
            _Chip(
              label: 'REPEAT TEST',
              color: colors.secondary,
              margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            ),
          if (isLocked)
            _LockedBlock(onReveal: onReveal)
          else if (hasResponse) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: AppTheme.opacitySubtle),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(
                  color: accent.withValues(alpha: AppTheme.opacitySubtle),
                  width: AppTheme.borderDefault,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    response.isUncertain
                        ? 'UNCERTAIN RESPONSE'
                        : response.classification.label,
                    style: text.labelSmall?.copyWith(color: accent),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  TweenAnimationBuilder<double>(
                    key: ValueKey('${response.id}-${response.revealed}'),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, child) => Opacity(
                      opacity: v,
                      child: Transform.scale(
                        scale: 0.88 + 0.12 * v,
                        alignment: Alignment.centerLeft,
                        child: child,
                      ),
                    ),
                    child: Text(
                      response.detectedResponse!.toUpperCase(),
                      style: text.titleLarge?.copyWith(color: accent),
                    ),
                  ),
                  if (response.latencyLabel != null) ...[
                    const SizedBox(height: AppTheme.spacingXs),
                    Text('RESPONSE TIMING',
                        style: text.labelSmall
                            ?.copyWith(color: appColors.subtleText)),
                    Text(response.latencyLabel!,
                        style: text.bodySmall
                            ?.copyWith(color: colors.onSurface)),
                  ],
                  if (isRepeated) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    _Chip(
                      label: (comparison ?? RepeatComparison.repeated).label,
                      color: appColors.success,
                    ),
                  ] else if (comparison != null) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    _Chip(label: comparison!.label, color: appColors.subtleText),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ResponseFingerprint(
              response: response,
              environmentalChange: environmentalChange,
              recurring: isRepeated,
            ),
            if (skepticMode)
              SkepticContext(
                response: response,
                environmentalChange: environmentalChange,
                recurring: isRepeated,
              ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest
                    .withValues(alpha: AppTheme.opacitySubtle),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                response.classification.label,
                style: text.labelMedium?.copyWith(color: appColors.subtleText),
              ),
            ),
            if (expandDetails) ...[
              const SizedBox(height: AppTheme.spacingSm),
              ResponseFingerprint(
                response: response,
                environmentalChange: environmentalChange,
              ),
            ],
            if (skepticMode)
              SkepticContext(
                response: response,
                environmentalChange: environmentalChange,
              ),
          ],
          if ((response.note ?? '').isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: colors.tertiary.withValues(alpha: AppTheme.opacitySubtle),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NOTE',
                      style: text.labelSmall?.copyWith(color: colors.tertiary)),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(response.note!,
                      style: text.bodySmall?.copyWith(color: colors.onSurface)),
                ],
              ),
            ),
          ],
          if (!isLocked) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingSm,
              children: [
                if (response.audioPath != null && onPlay != null)
                  _ActionChip(
                    icon: Icons.play_arrow,
                    label: 'REPLAY AUDIO',
                    onTap: onPlay,
                    color: appColors.glowSecondary,
                  ),
                if (onMark != null)
                  _ActionChip(
                    icon: Icons.flag_outlined,
                    label: response.status.label,
                    onTap: onMark,
                    color: _statusColor(appColors, colors),
                  ),
                if (onNote != null)
                  _ActionChip(
                    icon: Icons.edit_note,
                    label: (response.note ?? '').isEmpty ? 'ADD NOTE' : 'EDIT NOTE',
                    onTap: onNote,
                    color: colors.tertiary,
                  ),
                if (onRepeatTest != null && !response.isRepeatTest)
                  _ActionChip(
                    icon: Icons.repeat,
                    label: 'REPEAT TEST',
                    onTap: onRepeatTest,
                    color: colors.secondary,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LockedBlock extends StatefulWidget {
  final VoidCallback? onReveal;
  const _LockedBlock({this.onReveal});

  @override
  State<_LockedBlock> createState() => _LockedBlockState();
}

class _LockedBlockState extends State<_LockedBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: appColors.warning.withValues(alpha: AppTheme.opacitySubtle),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: appColors.warning.withValues(alpha: AppTheme.opacitySubtle),
          width: AppTheme.borderDefault,
        ),
      ),
      child: Column(
        children: [
          Text('⚠️ POSSIBLE RESPONSE DETECTED',
              style: text.labelMedium?.copyWith(color: appColors.warning)),
          const SizedBox(height: AppTheme.spacingXs),
          Text('RESPONSE LOCKED',
              style: text.labelLarge?.copyWith(color: appColors.warning)),
          const SizedBox(height: AppTheme.spacingSm),
          SizedBox(
            height: AppTheme.lockedTraceHeight,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                size: const Size(double.infinity, AppTheme.lockedTraceHeight),
                painter: _LockedTracePainter(
                  progress: _controller.value,
                  color: appColors.warning,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          TextButton.icon(
            onPressed: widget.onReveal == null
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    widget.onReveal!();
                  },
            icon: const Icon(Icons.visibility, size: AppTheme.iconSm),
            label: const Text('REVEAL RESPONSE'),
            style: TextButton.styleFrom(foregroundColor: appColors.warning),
          ),
        ],
      ),
    );
  }
}

class _LockedTracePainter extends CustomPainter {
  final double progress;
  final Color color;

  _LockedTracePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final t = progress * math.pi * 2;
    const bars = 40;
    final gap = size.width / bars;

    for (var i = 0; i < bars; i++) {
      final phase = math.sin(i * 0.7 + t) * math.sin(i * 0.21 - t * 0.5);
      final h = (size.height * 0.12 + size.height * 0.3 * phase.abs())
          .clamp(2.0, size.height / 2);
      final x = gap * i + gap / 2;
      canvas.drawLine(
        Offset(x, centerY - h / 2),
        Offset(x, centerY + h / 2),
        Paint()
          ..color = color.withOpacity(0.25 + 0.35 * phase.abs())
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LockedTracePainter old) =>
      old.progress != progress;
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final EdgeInsets? margin;
  const _Chip({required this.label, required this.color, this.margin});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppTheme.opacitySubtle),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(label, style: text.labelSmall?.copyWith(color: color)),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm,
          vertical: AppTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppTheme.opacitySubtle),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppTheme.iconSm, color: color),
            const SizedBox(width: AppTheme.spacingXs),
            Text(label, style: text.labelSmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
