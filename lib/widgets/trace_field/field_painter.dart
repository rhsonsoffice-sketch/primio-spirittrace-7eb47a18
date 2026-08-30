import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../services/trace_field_engine.dart';
import '../../theme/theme.dart';

/// Paints the Field from the engine's actual particle positions.
class FieldPainter extends CustomPainter {
  final TraceFieldEngine engine;
  final Color primary;
  final Color secondary;
  final List<Offset>? replayFrame;

  FieldPainter({
    required this.engine,
    required this.primary,
    required this.secondary,
    this.replayFrame,
    Listenable? repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = ui.Gradient.radial(
        rect.center,
        size.longestSide * 0.7,
        [
          primary.withValues(alpha: 0.16 + engine.drive * 0.14),
          Colors.transparent,
        ],
        const [0.0, 1.0],
      );
    canvas.drawRect(rect, bg);

    final points = replayFrame ?? engine.snapshot();
    final coherence = replayFrame != null ? 0.9 : engine.coherence;
    final drive = replayFrame != null ? 0.9 : engine.drive;

    // connective threads appear only when particles genuinely converge
    if (coherence > 0.55) {
      final line = Paint()
        ..color = secondary.withValues(alpha: (coherence - 0.5) * 0.5)
        ..strokeWidth = 0.7
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < points.length; i += 2) {
        final a = points[i];
        for (var j = i + 1; j < points.length; j += 5) {
          final b = points[j];
          final dx = (a.dx - b.dx).abs();
          final dy = (a.dy - b.dy).abs();
          if (dx < 0.05 && dy < 0.05) {
            canvas.drawLine(
              Offset(a.dx * size.width, a.dy * size.height),
              Offset(b.dx * size.width, b.dy * size.height),
              line,
            );
          }
        }
      }
    }

    final dot = Paint()..style = PaintingStyle.fill;
    final glow = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final o = Offset(p.dx * size.width, p.dy * size.height);
      final t = i / points.length;
      final color = Color.lerp(primary, secondary, t)!;
      final radius = 1.1 + drive * 1.6 + coherence * 1.2;

      glow.color = color.withValues(alpha: 0.10 + coherence * 0.22);
      canvas.drawCircle(o, radius * 2.6, glow);
      dot.color = color.withValues(alpha: 0.55 + drive * 0.35);
      canvas.drawCircle(o, radius, dot);
    }
  }

  @override
  bool shouldRepaint(covariant FieldPainter old) =>
      old.replayFrame != replayFrame;
}

/// The full-bleed animated Field surface.
class FieldSurface extends StatelessWidget {
  final TraceFieldEngine engine;
  final Listenable repaint;
  final List<Offset>? replayFrame;

  const FieldSurface({
    super.key,
    required this.engine,
    required this.repaint,
    this.replayFrame,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    return RepaintBoundary(
      child: CustomPaint(
        painter: FieldPainter(
          engine: engine,
          primary: colors.primary,
          secondary: appColors.glowSecondary,
          replayFrame: replayFrame,
          repaint: repaint,
        ),
        size: Size.infinite,
      ),
    );
  }
}
