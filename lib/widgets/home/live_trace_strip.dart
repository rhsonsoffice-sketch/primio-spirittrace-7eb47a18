import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Idle trace shown on the home screen. The microphone is not opened here,
/// so this is explicitly labelled as an idle trace rather than live audio.
class LiveTraceStrip extends StatefulWidget {
  const LiveTraceStrip({super.key});

  @override
  State<LiveTraceStrip> createState() => _LiveTraceStripState();
}

class _LiveTraceStripState extends State<LiveTraceStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: appColors.cardHighlight.withOpacity(AppTheme.opacityOverlay),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: colors.outline.withOpacity(AppTheme.opacityFaint),
          width: AppTheme.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('LIVE AUDIO TRACE',
                  style: text.labelSmall?.copyWith(color: appColors.subtleText)),
              const Spacer(),
              Text('IDLE — MIC NOT ACTIVE',
                  style: text.labelSmall?.copyWith(color: appColors.subtleText)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          SizedBox(
            height: AppTheme.traceStripHeight,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                size: const Size(double.infinity, AppTheme.traceStripHeight),
                painter: _IdleTracePainter(
                  progress: _controller.value,
                  color: appColors.waveform,
                  glowColor: appColors.waveformGlow,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdleTracePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color glowColor;

  _IdleTracePainter({
    required this.progress,
    required this.color,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final t = progress * math.pi * 2;
    final path = Path();

    for (var x = 0.0; x <= size.width; x += 2) {
      final y = centerY +
          math.sin(x * 0.045 + t) * size.height * 0.10 +
          math.sin(x * 0.011 - t * 0.6) * size.height * 0.06;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = glowColor.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _IdleTracePainter old) =>
      old.progress != progress;
}
