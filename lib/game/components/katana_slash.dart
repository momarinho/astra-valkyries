import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'asteroid.dart';
import 'cargo_wreck.dart';
import 'breakable_prop.dart';
import 'enemy_ship.dart';
import 'enemy_bullet.dart';
import 'sector_boss.dart';
import 'advanced_weapons.dart';

/// ⚔️ KatanaSlashComponent: Lâmina taquiônica em formato de crescente energético.
/// Corta obstáculos em linha reta, desfere dano crítico em asteroides/naves inimigas
/// e APARA / DESTRÓI projéteis inimigos que cruzarem seu caminho (Tachyon Parry).
class KatanaSlashComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final double slashWidth;
  final double slashHeight;
  final Vector2 velocity;
  double lifeTimer;
  final double damage;
  final Color slashColor;
  final Color coreColor;
  int piercesLeft;
  final bool isVoidMuramasa;
  final Set<PositionComponent> _damagedTargets = {};

  KatanaSlashComponent({
    required Vector2 position,
    required double angle,
    required this.velocity,
    required this.lifeTimer,
    this.slashWidth = 48.0,
    this.slashHeight = 16.0,
    this.damage = 32.0,
    this.slashColor = const Color(0xFF00E5FF), // Cyber Cyan
    this.coreColor = Colors.white,
    this.piercesLeft = 4,
    this.isVoidMuramasa = false,
  }) {
    this.position = position;
    this.angle = angle;
    anchor = Anchor.center;
    size = Vector2(slashWidth, slashHeight);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Hitbox retangular cobrindo o arco de corte
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) {
      removeFromParent();
      return;
    }

    position += velocity * dt;
    wrapAround();

    lifeTimer -= dt;
    if (lifeTimer <= 0) {
      removeFromParent();
    }
  }

  void wrapAround() {
    if (position.x < -slashWidth ||
        position.x > GameConstants.sectorWidth + slashWidth ||
        position.y < -slashWidth ||
        position.y > GameConstants.sectorHeight + slashWidth) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    // 1. 🛡️ TACHYON PARRY: Anula e destrói projéteis inimigos em voo
    if (other is EnemyBulletComponent) {
      other.removeFromParent();
      game.spawnExplosionParticles(
        position: other.position,
        colorChoices: [slashColor, Colors.white],
        count: 5,
        minSize: 1.5,
        maxSize: 3.0,
        minSpeed: 30.0,
        maxSpeed: 90.0,
      );
      game.spawnFloatingText(
        other.position + Vector2(0, -14),
        'PARRY!',
        color: slashColor,
        fontSize: 12.0,
      );
      if (piercesLeft > 0) {
        piercesLeft--;
      } else {
        removeFromParent();
      }
      return;
    }

    if (_damagedTargets.contains(other)) return;
    _damagedTargets.add(other);

    double dealtDamage = damage;
    bool isCrit = false;
    try {
      final totalCritChance = (game.rogueCritChance + game.player.bonusCritChance).clamp(0.0, 1.0);
      if (totalCritChance > 0 && math.Random().nextDouble() < totalCritChance) {
        dealtDamage *= 2.0;
        isCrit = true;
      }
    } catch (_) {}

    if (other is AsteroidComponent) {
      final destroyed = other.takeDamage(dealtDamage, position);
      if (isCrit) {
        game.spawnFloatingText(
          position + Vector2(0, -18),
          'SLICE CRIT!',
          color: const Color(0xFFFF5252),
          fontSize: 13.0,
        );
      }
      if (destroyed) {
        game.playSfx('asteroid_split.wav');
        game.onAsteroidDestroyed(other.position, other.scoreValue);
      } else {
        game.playSfx('asteroid_split.wav');
      }
    } else if (other is EnemyShipComponent) {
      if (isVoidMuramasa) {
        other.applyElementalStatus(ElementalStatus.voidRupture, duration: 4.0);
      }
      other.takeDamage(dealtDamage, position);
      if (isCrit) {
        game.spawnFloatingText(
          position + Vector2(0, -18),
          'SLICE CRIT!',
          color: const Color(0xFFFF5252),
          fontSize: 13.0,
        );
      }
    } else if (other is CargoWreckComponent) {
      other.takeDamage(dealtDamage, position);
    } else if (other is BreakablePropComponent) {
      other.takeDamage(dealtDamage, position);
    } else if (other is SectorBoss) {
      other.takeDamage(dealtDamage, position);
    }

    // Faíscas cortantes de impacto
    game.spawnExplosionParticles(
      position: position,
      colorChoices: [slashColor, Colors.white],
      count: 4,
      minSize: 1.5,
      maxSize: 2.5,
      minSpeed: 30.0,
      maxSpeed: 80.0,
    );

    if (piercesLeft > 0) {
      piercesLeft--;
    } else {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final halfW = w / 2;
    final halfH = h / 2;

    canvas.save();
    canvas.translate(halfW, halfH);

    // Geometria em arco crescente que curva na direção do movimento (local -Y)
    final path = Path();
    path.moveTo(-halfW, 0);
    path.quadraticBezierTo(0, -halfH, halfW, 0);
    path.quadraticBezierTo(0, -halfH * 0.25, -halfW, 0);
    path.close();

    // 1. Brilho halo exterior
    final glowPaint = Paint()
      ..color = slashColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, glowPaint);

    // 2. Corpo cortante de plasma
    final bladePaint = Paint()
      ..color = slashColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bladePaint);

    // 3. Fio da lâmina taquiônica (núcleo branco afiadíssimo)
    final edgePath = Path();
    edgePath.moveTo(-halfW * 0.85, 0);
    edgePath.quadraticBezierTo(0, -halfH * 0.85, halfW * 0.85, 0);

    final edgePaint = Paint()
      ..color = coreColor
      ..strokeWidth = isVoidMuramasa ? 2.5 : 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawPath(edgePath, edgePaint);

    canvas.restore();
  }
}
