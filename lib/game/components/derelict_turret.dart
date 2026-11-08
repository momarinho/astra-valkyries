import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'bullet.dart';
import 'enemy_bullet.dart';
import 'xp_orb.dart';

/// Torreta Defensiva Automatizada Abandonada (Setor 3: Cemitério de Dreadnoughts).
/// Fixada em destroços militares antigos, gira os canhões gêmeos em direção à
/// Valquíria e dispara projéteis de plasma esmeralda. Destruí-la rende sucata e XP.
class DerelictTurretComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final double radius = 22.0;
  final double maxHp = 280.0;
  late double hp;
  double shootCooldown = 1.8;
  double hitFlashTimer = 0.0;
  double _turretAngle = 0.0;

  final Paint _basePaint = Paint()
    ..color = const Color(0xFF10201C)
    ..style = PaintingStyle.fill;

  final Paint _barrelPaint = Paint()
    ..color = const Color(0xFF00E676)
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  DerelictTurretComponent({required Vector2 position}) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
    hp = maxHp;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    if (hitFlashTimer > 0) {
      hitFlashTimer = math.max(0.0, hitFlashTimer - dt);
    }

    final player = game.player;
    final toPlayer = player.position - position;
    final dist = toPlayer.length;

    if (dist > 1.0) {
      final dir = toPlayer / dist;
      _turretAngle = math.atan2(dir.y, dir.x);

      shootCooldown -= dt;
      if (shootCooldown <= 0 && dist <= 620.0) {
        shootCooldown = 2.2;
        _fireTwinVolley(dir);
      }
    }
  }

  void _fireTwinVolley(Vector2 dir) {
    final perp = Vector2(-dir.y, dir.x);
    for (final offset in [-6.0, 6.0]) {
      final spawnPos = position + dir * (radius + 6.0) + perp * offset;
      game.world.add(
        EnemyBulletComponent(
          position: spawnPos,
          radius: 4.5,
          velocity: dir * 240.0,
          damage: 1.0,
          bulletColor: const Color(0xFF00E676),
        ),
      );
    }
    game.playSfx('shoot.wav');
  }

  bool takeDamage(double damage, Vector2 hitPos) {
    hp -= damage;
    hitFlashTimer = 0.12;

    game.spawnExplosionParticles(
      position: hitPos,
      colorChoices: [const Color(0xFF00E676), Colors.white, Colors.amber],
      count: 4,
      minSize: 1.5,
      maxSize: 3.0,
      minSpeed: 30.0,
      maxSpeed: 90.0,
    );

    if (hp <= 0) {
      _destroy();
      return true;
    }
    return false;
  }

  void _destroy() {
    game.addScore(450);
    game.addRunCredits(65);
    game.playSfx('asteroid_split.wav');
    game.triggerScreenShake(duration: 0.25, intensity: 7.0);

    game.spawnExplosionParticles(
      position: position,
      colorChoices: [const Color(0xFF00E676), Colors.white, const Color(0xFFFFB300)],
      count: 22,
      minSize: 2.0,
      maxSize: 4.5,
      minSpeed: 40.0,
      maxSpeed: 160.0,
    );

    game.world.add(XpOrbComponent(position: position.clone(), type: XpOrbType.large));
    game.spawnFloatingText(
      position + Vector2(0, -25),
      '💥 TURRET DESTROYED! +450',
      color: const Color(0xFF00E676),
      fontSize: 13.5,
    );

    removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is BulletComponent) {
      takeDamage(other.damage, other.position);
      if (other.piercesLeft > 0) {
        other.piercesLeft--;
      } else {
        other.removeFromParent();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    try {
      final camPos = game.camera.viewfinder.position;
      final dx = (position.x - camPos.x).abs();
      final dy = (position.y - camPos.y).abs();
      if (dx > 750 + radius || dy > 450 + radius) return;
    } catch (_) {}

    super.render(canvas);

    final center = (size / 2).toOffset();
    final isFlashing = hitFlashTimer > 0;
    final strokeColor = isFlashing ? Colors.white : const Color(0xFF00E676);

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // 1. Base Octogonal Blindada
    final basePath = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * (math.pi / 4) + math.pi / 8;
      final pt = Offset(math.cos(a) * radius, math.sin(a) * radius);
      if (i == 0) {
        basePath.moveTo(pt.dx, pt.dy);
      } else {
        basePath.lineTo(pt.dx, pt.dy);
      }
    }
    basePath.close();

    canvas.drawPath(basePath, _basePaint);
    Glow.strokePath(canvas, basePath, strokeColor, width: 2.0, intensity: 1.2);

    // 2. Canhões Gêmeos Giratórios
    canvas.rotate(_turretAngle);
    _barrelPaint.color = strokeColor;
    canvas.drawLine(const Offset(0, -6), Offset(radius * 1.25, -6), _barrelPaint);
    canvas.drawLine(const Offset(0, 6), Offset(radius * 1.25, 6), _barrelPaint);

    // 3. Cúpula de Sensor Central
    Glow.orb(canvas, Offset.zero, radius * 0.42, strokeColor);

    canvas.restore();
  }
}
