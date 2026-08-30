import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class WaveformDisplay extends StatefulWidget {
  final bool isActive;
  final double intensity;
  const WaveformDisplay({
    super.key,
    this.isActive = false,
    this.intensity = 0.5,
  });

  @override
  State<WaveformDisplay> createState() => _WaveformDisplayState();
}

class _WaveformDisplayState extends State<WaveformDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => CustomPaint(
        size: const Size(double.infinity, 160),
        painter: _WaveformPainter(
          progress: _controller.value,
          isActive: widget.isActive,
          intensity: widget.intensity,
          primaryColor: appColors.waveform,
          glowColor: appColors.waveformGlow,
          secondaryColor: appColors.glowSecondary,
        ),
      ),
    );
  }
}



class _WaveformPainter extends CustomPainter {
  final double progress;
  final bool isActive;
  final double intensity;
  final Color primaryColor;
  final Color glowColor;
  final Color secondaryColor;

  _WaveformPainter({
    required this.progress,
    required this.isActive,
    required this.intensity,
    required this.primaryColor,
    required this.glowColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final t = progress * math.pi * 2;
    final amp = isActive ? intensity * size.height * 0.35 : size.height * 0.08;

    _drawWave(canvas, size, centerY, t, amp, glowColor, 3.0, 0.15, 0.02);
    _drawWave(canvas, size, centerY, t * 1.3, amp * 0.7, primaryColor, 2.0, 0.4, 0.015);
    _drawWave(canvas, size, centerY, t * 0.7, amp * 0.5, secondaryColor, 1.5, 0.25, 0.025);

    if (isActive) {
      final glowPaint = Paint()
        ..color = primaryColor.withOpacity(0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(size.width / 2, centerY),
          width: size.width,
          height: amp * 2,
        ),
        glowPaint,
      );
    }
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    double centerY,
    double t,
    double amp,
    Color color,
    double strokeWidth,
    double opacity,
    double freq,
  ) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var x = 0.0; x <= size.width; x += 2) {
      final y = centerY +
          math.sin(x * freq + t) * amp +
          math.sin(x * freq * 2.5 + t * 1.5) * amp * 0.3;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    final glowPaint = Paint()
      ..color = color.withOpacity(opacity * 0.3)
      ..strokeWidth = strokeWidth + 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.progress != progress || old.isActive != isActive || old.intensity != intensity;
}
