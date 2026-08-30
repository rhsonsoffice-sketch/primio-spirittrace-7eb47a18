import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Ambient instrument visual shown on the home screen.
/// It is decorative only — it never represents microphone activity or
/// detection of any kind.
class TraceScanner extends StatefulWidget {
  final double size;
  const TraceScanner({super.key, this.size = AppTheme.scannerSize});

  @override
  State<TraceScanner> createState() => _TraceScannerState();
}

class _TraceScannerState extends State<TraceScanner>
    with TickerProviderStateMixin {
  late final AnimationController _sweep;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _sweep.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_sweep, _pulse]),
        builder: (context, _) => CustomPaint(
          painter: _TraceScannerPainter(
            sweep: _sweep.value,
            pulse: _pulse.value,
            glow: appColors.glow,
            secondary: appColors.glowSecondary,
            ring: colors.outline,
          ),
        ),
      ),
    );
  }
}

class _TraceScannerPainter extends CustomPainter {
  final double sweep;
  final double pulse;
  final Color glow;
  final Color secondary;
  final Color ring;

  _TraceScannerPainter({
    required this.sweep,
    required this.pulse,
    required this.glow,
    required this.secondary,
    required this.ring,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final t = pulse * math.pi * 2;

    _paintAmbientGlow(canvas, center, radius);
    _paintRings(canvas, center, radius);
    _paintSweep(canvas, center, radius);
    _paintWaveRing(canvas, center, radius, t);
    _paintParticles(canvas, center, radius, t);
    _paintCore(canvas, center, radius, t);
  }

  void _paintAmbientGlow(Canvas canvas, Offset center, double radius) {
    final r = radius * 0.8;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          glow.withOpacity(0.20),
          glow.withOpacity(0.06),
          glow.withOpacity(0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, paint);
  }

  void _paintRings(Canvas canvas, Offset center, double radius) {
    for (var i = 1; i <= 4; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppTheme.borderDefault
        ..color = ring.withOpacity(0.06 + 0.04 * i);
      canvas.drawCircle(center, radius * 0.2 * i, paint);
    }

    final crossPaint = Paint()
      ..strokeWidth = AppTheme.borderDefault
      ..color = ring.withOpacity(AppTheme.opacityFaint);
    canvas.drawLine(
      Offset(center.dx - radius * 0.8, center.dy),
      Offset(center.dx + radius * 0.8, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.8),
      Offset(center.dx, center.dy + radius * 0.8),
      crossPaint,
    );
  }

  void _paintSweep(Canvas canvas, Offset center, double radius) {
    const arc = math.pi * 0.7;
    final rect = Rect.fromCircle(center: center, radius: radius * 0.82);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweep * math.pi * 2);
    canvas.translate(-center.dx, -center.dy);

    final paint = Paint()
      ..shader = SweepGradient(
        colors: [
          secondary.withOpacity(0.0),
          secondary.withOpacity(0.05),
          secondary.withOpacity(0.26),
        ],
        stops: const [0.0, 0.6, 1.0],
        startAngle: 0.0,
        endAngle: arc,
      ).createShader(rect);
    canvas.drawArc(rect, 0.0, arc, true, paint);

    final edge = Offset(math.cos(arc), math.sin(arc)) * (radius * 0.82);
    canvas.drawLine(
      center,
      center + edge,
      Paint()
        ..color = secondary.withOpacity(0.45)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _paintWaveRing(Canvas canvas, Offset center, double radius, double t) {
    const bars = 64;
    final inner = radius * 0.86;
    for (var i = 0; i < bars; i++) {
      final a = i / bars * math.pi * 2;
      final amp =
          (math.sin(a * 3 + t) * math.sin(a * 7 - t * 0.7)).abs().clamp(0.0, 1.0);
      final outer = inner + radius * 0.11 * (0.25 + amp);
      final dir = Offset(math.cos(a), math.sin(a));
      final paint = Paint()
        ..color = (i.isEven ? secondary : glow).withOpacity(0.20 + 0.45 * amp)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(center + dir * inner, center + dir * outer, paint);
    }
  }

  void _paintParticles(Canvas canvas, Offset center, double radius, double t) {
    for (var i = 0; i < 16; i++) {
      final seed = (i * 0.618) % 1.0;
      final a = seed * math.pi * 2 + sweep * math.pi * 2 * (0.3 + (i % 3) * 0.12);
      final r = radius * (0.22 + 0.56 * ((seed * 3) % 1.0));
      final opacity = (0.12 + 0.32 * math.sin(t + i).abs()).clamp(0.0, 1.0);
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawCircle(
        center + dir * r,
        1.6,
        Paint()
          ..color = (i.isEven ? glow : secondary).withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  void _paintCore(Canvas canvas, Offset center, double radius, double t) {
    final p = (math.sin(t) + 1) / 2;

    canvas.drawCircle(
      center,
      radius * (0.14 + 0.34 * p),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppTheme.borderDefault
        ..color = secondary.withOpacity(0.28 * (1 - p)),
    );
    canvas.drawCircle(
      center,
      radius * 0.07 + radius * 0.015 * p,
      Paint()
        ..color = secondary.withOpacity(0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      center,
      radius * 0.028,
      Paint()..color = secondary.withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _TraceScannerPainter old) =>
      old.sweep != sweep || old.pulse != pulse;
}
