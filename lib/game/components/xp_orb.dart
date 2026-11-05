import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';

enum XpOrbType {
  small,  // 10 XP (Azul neon)
  medium, // 25 XP (Violeta / Magenta neon)
  large,  // 75 XP (Dourado / Âmbar neon)
}

class XpOrbComponent extends PositionComponent with HasGameReference<AsteroidsGame> {
  final XpOrbType type;
  late final int value;
  late final Color primaryColor;
  late final double radius;

  Vector2 velocity = Vector2.zero();
  double lifeTimer = 50.0;
  double pulseTimer = 0.0;
  bool isMagnetized = false;

  XpOrbComponent({
    required Vector2 position,
    required this.type,
  }) {
    this.position = position;
    anchor = Anchor.center;

    switch (type) {
      case XpOrbType.small:
        value = 2;
        primaryColor = const Color(0xFF00E5FF); // Cyan
        radius = 4.5;
        break;
      case XpOrbType.medium:
        value = 6;
        primaryColor = const Color(0xFFE040FB); // Magenta / Neon Purple
        radius = 6.0;
        break;
      case XpOrbType.large:
        value = 14;
        primaryColor = const Color(0xFFFFD700); // Gold
        radius = 8.0;
        break;
    }

    size = Vector2.all(radius * 2);

    // Pequeno impulso inicial aleatório para espalhar ao redor do asteroide
    final random = math.Random();
    final angle = random.nextDouble() * 2 * math.pi;
    final speed = 15.0 + random.nextDouble() * 30.0;
    velocity = Vector2(math.cos(angle), math.sin(angle)) * speed;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    pulseTimer += dt;
    lifeTimer -= dt;
    if (lifeTimer <= 0) {
      removeFromParent();
      return;
    }

    final player = game.player;
    final distToPlayer = position.distanceTo(player.position);
    final magnetDist = player.magnetRadius;

    // Atração Magnética
    if (distToPlayer <= magnetDist) {
      isMagnetized = true;
      final dir = (player.position - position).normalized();
      // Quanto mais perto, mais rápido é atraído
      final accel = math.max(250.0, 700.0 * (1.0 - (distToPlayer / magnetDist)));
      velocity += dir * accel * dt;
      // Limite de velocidade de atração
      if (velocity.length > 600.0) {
        velocity = velocity.normalized() * 600.0;
      }
    } else {
      isMagnetized = false;
      // Atrito suave no espaço se não estiver magnetizado
      velocity.scale(math.exp(-1.5 * dt));
    }

    position += velocity * dt;
    wrapAround();

    // Coleta pelo jogador
    if (distToPlayer <= player.radius + radius + 4.0) {
      _collect();
    }
  }

  void _collect() {
    game.addXp(value);

    // Efeito de partículas de coleta
    game.spawnExplosionParticles(
      position: position,
      colorChoices: [primaryColor, Colors.white],
      count: type == XpOrbType.large ? 10 : 6,
      minSize: 1.5,
      maxSize: 3.5,
      minSpeed: 40.0,
      maxSpeed: 110.0,
    );

    // Texto flutuante discreto apenas para orbes médias e grandes
    if (type != XpOrbType.small) {
      game.spawnFloatingText(
        position,
        '+$value XP',
        color: primaryColor,
        fontSize: type == XpOrbType.large ? 14.0 : 12.0,
      );
    }

    removeFromParent();
  }

  void wrapAround() {
    position.x = position.x.clamp(radius, GameConstants.sectorWidth - radius).toDouble();
    position.y = position.y.clamp(radius, GameConstants.sectorHeight - radius).toDouble();
  }

  @override
  void render(Canvas canvas) {
    canvas.translate(radius, radius);

    // Pulso rítmico suave
    final pulse = 0.85 + 0.15 * math.sin(pulseTimer * 8.0);
    final currentR = radius * pulse;

    // Núcleo e aura neon
    Glow.orb(canvas, Offset.zero, currentR * 0.7, primaryColor, intensity: 1.3);
    Glow.strokeCircle(canvas, Offset.zero, currentR, Colors.white, width: 1.2, intensity: 0.9);
  }
}
