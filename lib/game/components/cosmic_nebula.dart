import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';

enum NebulaType {
  ionCloud,    // Rapid weapon recharge (+30% fire rate), but shields suppressed
  darkMatter,  // High critical chance (+50% crit rate), but movement damped (-30% max speed)
}

/// Large interactive cosmic nebula region.
/// Alters weapon fire cadences, ship speed, or critical damage when the player navigates inside.
class CosmicNebulaComponent extends PositionComponent with HasGameReference<AsteroidsGame> {
  final NebulaType type;
  final double radius;
  double _pulseTimer = 0.0;

  CosmicNebulaComponent({
    required Vector2 position,
    required this.type,
    this.radius = 420.0,
  }) : super(position: position, size: Vector2.all(radius * 2), anchor: Anchor.center);

  String get name => type == NebulaType.ionCloud ? 'ION NEBULA' : 'DARK MATTER POCKET';

  String get modifierText => type == NebulaType.ionCloud
      ? '⚡ HYPER-CADENCE +30% // SHIELD DISRUPTION'
      : '🎯 CRIT CHANCE +50% // GRAVITY DAMPED -30%';

  Color get primaryColor => type == NebulaType.ionCloud
      ? const Color(0xFFE040FB) // Electric Magenta / Violet
      : const Color(0xFF00E5FF); // Neon Cyan / Indigo

  Color get secondaryColor => type == NebulaType.ionCloud
      ? const Color(0xFF7C4DFF)
      : const Color(0xFF1A237E);

  @override
  bool containsPoint(Vector2 point) {
    return position.distanceTo(point) <= radius;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt * 0.8;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final pulse = 1.0 + 0.05 * math.sin(_pulseTimer);
    final currentRadius = radius * pulse;

    // Multi-stop volumetric radial gradient for deep space gas cloud
    final gradient = RadialGradient(
      colors: [
        primaryColor.withOpacity(0.18),
        secondaryColor.withOpacity(0.12),
        secondaryColor.withOpacity(0.05),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 0.75, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: currentRadius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, currentRadius, paint);

    // Subtle gas perimeter boundary line
    final boundaryPaint = Paint()
      ..color = primaryColor.withOpacity(0.14 + 0.06 * math.sin(_pulseTimer * 1.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset.zero, currentRadius * 0.95, boundaryPaint);

    // Ambient floating dust motes inside nebula
    final motePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 18; i++) {
      final a = (i * (2 * math.pi / 18)) + 0.1 * math.sin(_pulseTimer + i);
      final r = (0.2 + (i % 6) * 0.12) * radius;
      final x = r * math.cos(a);
      final y = r * math.sin(a);
      final alpha = (0.35 + 0.35 * math.sin(_pulseTimer * 2.0 + i)).clamp(0.0, 1.0);
      motePaint.color = primaryColor.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), 2.0 + (i % 3) * 0.8, motePaint);
    }
  }
}
