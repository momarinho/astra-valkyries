import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'player.dart';
import 'bullet.dart';
import 'bomb.dart';
import 'enemy_ship.dart';

/// Mina Espacial de Proximidade (Bi-direcional - Sprint 58).
/// Flutua perto de destroços militares. Quando a Valquíria OU naves inimigas
/// entram em seu sensor infravermelho, pisca rapidamente e detona (ou explode
/// ao contato direto / impacto de projéteis), funcionando como armadilha tática!
class ProximityMineComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final double radius = 16.0;
  final double triggerRadius = 155.0;
  final double blastRadius = 140.0;
  final double blastDamage = 95.0;

  bool isArmed = false;
  bool isDetonated = false;
  double armTimer = 0.0;
  double _pulseTimer = 0.0;
  double _rotation = 0.0;

  final Paint _hullPaint = Paint()
    ..color = const Color(0xFF1A2226)
    ..style = PaintingStyle.fill;

  final Paint _spikePaint = Paint()
    ..color = const Color(0xFF546E7A)
    ..strokeWidth = 2.5
    ..style = PaintingStyle.stroke;

  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  ProximityMineComponent({required Vector2 position}) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDetonated || game.state != GameState.playing) return;

    _rotation += dt * (isArmed ? 2.8 : 0.6);
    _pulseTimer += dt * (isArmed ? 16.0 : 3.5);

    final player = game.player;
    evaluateProximityTriggers(
      dt,
      playerPos: player.position,
      playerRadius: player.radius,
      enemies: game.activeEnemies,
    );
  }

  /// Sprint 58: Avalia ativação bi-direcional (jogadora OU qualquer inimigo vivo em activeEnemies).
  bool evaluateProximityTriggers(
    double dt, {
    required Vector2 playerPos,
    required double playerRadius,
    required Iterable<EnemyShipComponent> enemies,
  }) {
    if (isDetonated) return false;

    final playerDist = position.distanceTo(playerPos);
    bool immediateContact = playerDist <= radius + playerRadius + 8.0;
    if (playerDist <= triggerRadius) {
      isArmed = true;
    }

    for (final enemy in enemies) {
      if (enemy.hp <= 0 || enemy.isRemoving) continue;
      final enemyDist = position.distanceTo(enemy.position);
      if (enemyDist <= triggerRadius) {
        isArmed = true;
      }
      if (enemyDist <= radius + enemy.radius + 8.0) {
        immediateContact = true;
        break;
      }
    }

    if (isArmed) {
      armTimer += dt;
      if (immediateContact || armTimer >= 1.10) {
        detonate();
        return true;
      }
    }
    return false;
  }

  void detonate() {
    if (isDetonated) return;
    isDetonated = true;
    try {
      game.notifyMineDestroyedForUnlocks();
    } catch (_) {}

    try {
      game.playSfx('bomb_explode.wav');
      game.triggerScreenShake(duration: 0.35, intensity: 11.0);

      // Spawna explosão real que causa dano em área a inimigos e asteroides ao redor
      game.world.add(
        BombExplosionComponent(
          position: position.clone(),
          maxRadius: blastRadius,
          damage: blastDamage,
        ),
      );

      // Se a jogadora estiver muito perto do epicentro, também sofre dano térmico
      final distToPlayer = position.distanceTo(game.player.position);
      if (distToPlayer <= blastRadius * 0.75) {
        game.player.takeHit(26.0);
      }
    } catch (_) {}

    removeFromParent();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (isDetonated) return;

    if (other is BulletComponent) {
      if (other.piercesLeft <= 0) {
        other.removeFromParent();
      } else {
        other.piercesLeft--;
      }
      detonate();
    } else if (other is PlayerComponent || other is EnemyShipComponent) {
      detonate();
    }
  }

  @override
  void render(Canvas canvas) {
    try {
      final camPos = game.camera.viewfinder.position;
      final dx = (position.x - camPos.x).abs();
      final dy = (position.y - camPos.y).abs();
      if (dx > 750 + triggerRadius || dy > 450 + triggerRadius) return;
    } catch (_) {}

    super.render(canvas);

    final center = (size / 2).toOffset();
    final pulse = (math.sin(_pulseTimer) + 1.0) / 2.0;

    // 1. Anel de Sensor de Proximidade
    final ringColor = isArmed
        ? const Color(0xFFFF1744)
        : const Color(0xFFFF9100);
    _ringPaint.color = ringColor.withValues(
      alpha: isArmed ? (0.25 + 0.35 * pulse) : 0.12,
    );
    canvas.drawCircle(
      center,
      triggerRadius * (isArmed ? (1.0 - armTimer * 0.3).clamp(0.4, 1.0) : 1.0),
      _ringPaint,
    );

    // 2. Corpo Metálico Espinhoso da Mina
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_rotation);

    for (var i = 0; i < 8; i++) {
      final a = i * (math.pi / 4);
      final p1 = Offset(
        math.cos(a) * (radius * 0.6),
        math.sin(a) * (radius * 0.6),
      );
      final p2 = Offset(
        math.cos(a) * (radius * 1.35),
        math.sin(a) * (radius * 1.35),
      );
      canvas.drawLine(p1, p2, _spikePaint);
    }

    canvas.drawCircle(Offset.zero, radius * 0.85, _hullPaint);
    Glow.strokeCircle(
      canvas,
      Offset.zero,
      radius * 0.85,
      ringColor,
      width: 1.8,
      intensity: isArmed ? 1.5 : 0.8,
    );

    // 3. Núcleo de Alerta Piscante
    final coreColor = (isArmed && pulse > 0.5) ? Colors.white : ringColor;
    Glow.orb(canvas, Offset.zero, radius * (0.32 + 0.12 * pulse), coreColor);

    canvas.restore();
  }
}
