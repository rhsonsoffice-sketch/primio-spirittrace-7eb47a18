import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class ParticleBackground extends StatefulWidget {
  final Widget child;
  const ParticleBackground({super.key, required this.child});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42);
    _particles = List.generate(50, (_) => _Particle.random(rng));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
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
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  appColors.deepBackground,
                  Theme.of(context).colorScheme.surface,
                  appColors.deepBackground,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: _AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _ParticlePainter(
                particles: _particles,
                progress: _controller.value,
                glowColor: appColors.glow,
                secondaryColor: appColors.glowSecondary,
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;
  const _AnimatedBuilder({required this.animation, required this.builder});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: builder,
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final double phase;
  final bool isSecondary;

  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.isSecondary,
  });

  factory _Particle.random(math.Random rng) => _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: rng.nextDouble() * 2 + 0.5,
        speed: rng.nextDouble() * 0.5 + 0.2,
        phase: rng.nextDouble() * math.pi * 2,
        isSecondary: rng.nextBool(),
      );
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color glowColor;
  final Color secondaryColor;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.glowColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = progress * math.pi * 2 * p.speed + p.phase;
      final dx = p.x * size.width + math.sin(t) * 20;
      final dy = (p.y + progress * p.speed * 0.3) % 1.0 * size.height;
      final color = p.isSecondary ? secondaryColor : glowColor;
      final opacity = (0.2 + 0.3 * math.sin(t * 2).abs()).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.radius * 2);
      canvas.drawCircle(Offset(dx, dy), p.radius, paint);

      final corePaint = Paint()..color = color.withOpacity(opacity * 1.5);
      canvas.drawCircle(Offset(dx, dy), p.radius * 0.4, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress;
}
