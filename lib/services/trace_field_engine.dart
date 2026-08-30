import 'dart:math';
import 'dart:ui';

/// One point of the Field. Positions are normalised (0-1) so the painter can
/// map them onto any canvas size.
class FieldParticle {
  Offset position;
  Offset velocity;
  double phase;

  FieldParticle({
    required this.position,
    required this.velocity,
    required this.phase,
  });
}

/// The visual Field itself.
///
/// Particles always drift. When the measured input drive rises, they are drawn
/// toward a set of attractor points; if enough of them actually converge the
/// engine reports high [coherence]. Formations are read out of that measured
/// coherence — nothing is drawn on top of the Field and no shape is forced.
class TraceFieldEngine {
  TraceFieldEngine({int particleCount = 150, int? seed})
      : _count = particleCount,
        _rnd = Random(seed) {
    _seedParticles();
    _regenerateAttractors();
  }

  final int _count;
  final Random _rnd;

  final List<FieldParticle> particles = [];
  List<Offset> attractors = const [];
  String _layout = 'scatter';

  /// Smoothed input drive (0-1) derived from real measured deviation.
  double drive = 0;

  /// Measured fraction of particles that have actually converged (0-1).
  double coherence = 0;

  double _regenTimer = 0;

  void _seedParticles() {
    particles.clear();
    for (var i = 0; i < _count; i++) {
      particles.add(
        FieldParticle(
          position: Offset(_rnd.nextDouble(), _rnd.nextDouble()),
          velocity: Offset(
            (_rnd.nextDouble() - 0.5) * 0.02,
            (_rnd.nextDouble() - 0.5) * 0.02,
          ),
          phase: _rnd.nextDouble() * pi * 2,
        ),
      );
    }
  }

  /// Attractor geometry is re-rolled while the Field is quiet, so the shape a
  /// convergence produces is never predetermined or repeated in sequence.
  void _regenerateAttractors() {
    final kinds = ['pair', 'triad', 'ring', 'cluster', 'scatter'];
    _layout = kinds[_rnd.nextInt(kinds.length)];
    double j() => (_rnd.nextDouble() - 0.5) * 0.08;

    switch (_layout) {
      case 'pair':
        final y = 0.40 + j();
        attractors = [
          Offset(0.40 + j(), y),
          Offset(0.60 + j(), y),
          Offset(0.50 + j(), 0.62 + j()),
        ];
        break;
      case 'triad':
        final x = 0.50 + j();
        attractors = [
          Offset(x, 0.26 + j()),
          Offset(x - 0.10 + j(), 0.52 + j()),
          Offset(x + 0.10 + j(), 0.52 + j()),
          Offset(x, 0.76 + j()),
        ];
        break;
      case 'ring':
        final cx = 0.5 + j();
        final cy = 0.5 + j();
        final r = 0.14 + _rnd.nextDouble() * 0.08;
        attractors = List.generate(6, (i) {
          final a = (i / 6) * pi * 2;
          return Offset(cx + cos(a) * r, cy + sin(a) * r);
        });
        break;
      case 'cluster':
        attractors = [Offset(0.5 + j(), 0.5 + j())];
        break;
      default:
        attractors = List.generate(
          4,
          (_) => Offset(
            0.2 + _rnd.nextDouble() * 0.6,
            0.2 + _rnd.nextDouble() * 0.6,
          ),
        );
    }
  }

  /// A loose description of the geometry the particles converged onto. This is
  /// a description of a visual arrangement only.
  String get resemblance {
    switch (_layout) {
      case 'pair':
        return 'Face-like';
      case 'triad':
        return 'Human-like';
      case 'ring':
        return 'Eye-like';
      case 'cluster':
        return 'Organic';
      default:
        return 'Geometric';
    }
  }

  /// Advances the simulation. [target] is the measured input drive (0-1).
  void tick(double dt, double target) {
    final step = dt.clamp(0.0, 0.05);
    drive += (target - drive) * (step * 2.5).clamp(0.0, 1.0);

    _regenTimer -= step;
    if (_regenTimer <= 0 && drive < 0.30) {
      _regenerateAttractors();
      _regenTimer = 5 + _rnd.nextDouble() * 8;
    }

    final pull = drive * drive * 2.2;
    final damping = 1 - (step * (1.3 + 2.2 * drive)).clamp(0.0, 0.9);
    var converged = 0;

    for (final p in particles) {
      var nearest = attractors.first;
      var best = double.infinity;
      for (final a in attractors) {
        final d = (a - p.position).distanceSquared;
        if (d < best) {
          best = d;
          nearest = a;
        }
      }

      final toward = nearest - p.position;
      final dist = toward.distance;
      if (dist > 0.0015) {
        p.velocity += toward / dist * pull * step;
      }

      p.phase += step * (0.5 + p.phase.remainder(0.7).abs());
      p.velocity += Offset(cos(p.phase), sin(p.phase)) * 0.055 * step;
      p.velocity = p.velocity * damping;

      var np = p.position + p.velocity * step * 8;
      var vx = p.velocity.dx;
      var vy = p.velocity.dy;
      if (np.dx < 0.02 || np.dx > 0.98) vx = -vx;
      if (np.dy < 0.02 || np.dy > 0.98) vy = -vy;
      p.velocity = Offset(vx, vy);
      np = Offset(np.dx.clamp(0.02, 0.98), np.dy.clamp(0.02, 0.98));
      p.position = np;

      if (dist < 0.075) converged++;
    }

    final measured = converged / particles.length;
    coherence += (measured - coherence) * (step * 3).clamp(0.0, 1.0);
  }

  List<Offset> snapshot() =>
      particles.map((p) => p.position).toList(growable: false);
}
