import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'package:asteroids/game/weapons.dart';
import 'player.dart';
import 'bullet.dart';
import 'enemy_bullet.dart';
import 'chest.dart';
import 'asteroid.dart';
import 'enemy_ship.dart';

/// 1. Barreira Física de Megaestrutura (Corredores e Câmaras estilo Dead Cells — Física Unificada Sprint 19)
class MegastructureWallComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final Vector2 wallSize;
  final Color wallColor;

  MegastructureWallComponent({
    required Vector2 position,
    required this.wallSize,
    this.wallColor = const Color(0xFF00E5FF),
  }) {
    this.position = position.clone();
    size = wallSize.clone();
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  void resolveAsteroidCollision(AsteroidComponent a) {
    if (a.isRemoving || a.hp <= 0) return;
    final halfW = size.x / 2 + a.radius;
    final halfH = size.y / 2 + a.radius;
    final dx = a.position.x - position.x;
    final dy = a.position.y - position.y;

    if (dx.abs() < halfW && dy.abs() < halfH) {
      final impactSpeed = a.velocity.length;
      final overlapX = halfW - dx.abs();
      final overlapY = halfH - dy.abs();
      final signX = dx == 0 ? 1.0 : dx.sign;
      final signY = dy == 0 ? 1.0 : dy.sign;

      if (overlapX < overlapY) {
        a.position.x += signX * (overlapX + 1.0);
        a.velocity.x = signX * a.velocity.x.abs() * 0.85;
      } else {
        a.position.y += signY * (overlapY + 1.0);
        a.velocity.y = signY * a.velocity.y.abs() * 0.85;
      }

      // Se a velocidade de impacto for alta, o asteroide sofre dano estrutural ou se fragmenta
      if (impactSpeed >= 50.0) {
        final impactDmg = math.max(25.0, impactSpeed * 0.55);
        final destroyed = a.takeDamage(impactDmg, a.position);
        if (destroyed) {
          try {
            game.onAsteroidDestroyed(a.position, a.scoreValue);
          } catch (_) {}
        }
      }
    }
  }

  void resolveEnemyCollision(EnemyShipComponent e) {
    if (e.isRemoving || e.hp <= 0) return;
    final halfW = size.x / 2 + e.radius;
    final halfH = size.y / 2 + e.radius;
    final dx = e.position.x - position.x;
    final dy = e.position.y - position.y;

    if (dx.abs() < halfW && dy.abs() < halfH) {
      final overlapX = halfW - dx.abs();
      final overlapY = halfH - dy.abs();
      final signX = dx == 0 ? 1.0 : dx.sign;
      final signY = dy == 0 ? 1.0 : dy.sign;

      // Bloqueia fisicamente a nave inimiga e aplica força de desvio tático (steering avoidance)
      if (overlapX < overlapY) {
        e.position.x += signX * (overlapX + 1.0);
        e.velocity.x = signX * e.baseSpeed * 0.65;
        final steerSign = dy >= 0 ? 1.0 : -1.0;
        e.velocity.y += steerSign * e.baseSpeed * 0.80;
      } else {
        e.position.y += signY * (overlapY + 1.0);
        e.velocity.y = signY * e.baseSpeed * 0.65;
        final steerSign = dx >= 0 ? 1.0 : -1.0;
        e.velocity.x += steerSign * e.baseSpeed * 0.80;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    // 1. Empurra fisicamente a nave da jogadora caso encoste na parede da megaestrutura
    final p = game.player;
    final halfW = size.x / 2 + p.radius;
    final halfH = size.y / 2 + p.radius;
    final dx = p.position.x - position.x;
    final dy = p.position.y - position.y;

    if (dx.abs() < halfW && dy.abs() < halfH) {
      final overlapX = halfW - dx.abs();
      final overlapY = halfH - dy.abs();
      if (overlapX < overlapY) {
        p.position.x += (dx == 0 ? 1.0 : dx.sign) * overlapX;
        p.velocity.x = -p.velocity.x * 0.35;
      } else {
        p.position.y += (dy == 0 ? 1.0 : dy.sign) * overlapY;
        p.velocity.y = -p.velocity.y * 0.35;
      }
    }

    // 2. Física Unificada (Sprint 19): Asteroides, Naves Inimigas e Projéteis
    for (final child in List<Component>.from(game.world.children)) {
      if (child is AsteroidComponent) {
        resolveAsteroidCollision(child);
      } else if (child is EnemyShipComponent) {
        resolveEnemyCollision(child);
      } else if (child is EnemyBulletComponent) {
        final bHalfW = size.x / 2 + child.radius;
        final bHalfH = size.y / 2 + child.radius;
        if ((child.position.x - position.x).abs() < bHalfW &&
            (child.position.y - position.y).abs() < bHalfH) {
          child.removeFromParent();
        }
      } else if (child is BulletComponent) {
        final bHalfW = size.x / 2 + child.radius;
        final bHalfH = size.y / 2 + child.radius;
        if ((child.position.x - position.x).abs() < bHalfW &&
            (child.position.y - position.y).abs() < bHalfH) {
          child.removeFromParent();
        }
      }
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is BulletComponent) {
      other.removeFromParent();
    } else if (other is EnemyBulletComponent) {
      other.removeFromParent();
    } else if (other is AsteroidComponent) {
      resolveAsteroidCollision(other);
    } else if (other is EnemyShipComponent) {
      resolveEnemyCollision(other);
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFF0B1324).withValues(alpha: 0.94)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = wallColor.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }
}

/// 2. Portão de Contenção Laser (Divide câmaras; pode ser desativado destruindo o emissor ou atravessado com Dash)
class LaserContainmentGateComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final double length;
  final bool isHorizontal;
  double generatorHp = 140.0;
  bool isDeactivated = false;
  double pulseTimer = 0.0;

  LaserContainmentGateComponent({
    required Vector2 position,
    this.length = 260.0,
    this.isHorizontal = true,
  }) {
    this.position = position.clone();
    size = isHorizontal ? Vector2(length, 22.0) : Vector2(22.0, length);
    anchor = Anchor.center;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDeactivated || game.state != GameState.playing) return;
    pulseTimer += dt * 6.0;

    final p = game.player;
    final halfW = size.x / 2 + p.radius;
    final halfH = size.y / 2 + p.radius;
    final dx = (p.position.x - position.x).abs();
    final dy = (p.position.y - position.y).abs();

    if (dx < halfW && dy < halfH) {
      // Se estiver em Dash/Invulnerável, atravessa livremente; caso contrário, sofre choque e recuo
      if (!p.isInvulnerable() && p.dashActiveTimer <= 0) {
        p.takeHit(12.0);
        if (isHorizontal) {
          p.velocity.y = -p.velocity.y.sign * 180.0;
        } else {
          p.velocity.x = -p.velocity.x.sign * 180.0;
        }
      }
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (isDeactivated) return;
    if (other is BulletComponent) {
      generatorHp -= other.damage;
      other.removeFromParent();
      if (generatorHp <= 0) {
        isDeactivated = true;
        game.addRunCredits(35);
        game.spawnFloatingText(
          position,
          '🔓 PORTÃO LASER DESATIVADO! (+35c)',
          color: const Color(0xFF00E676),
          fontSize: 13.0,
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (isDeactivated) return;
    final pulse = (math.sin(pulseTimer) + 1) * 0.5;
    final beamPaint = Paint()
      ..color = const Color(0xFFFF1744).withValues(alpha: 0.55 + pulse * 0.35)
      ..strokeWidth = 5.0 + pulse * 2.0
      ..strokeCap = StrokeCap.round;

    if (isHorizontal) {
      canvas.drawLine(Offset(0, size.y / 2), Offset(size.x, size.y / 2), beamPaint);
    } else {
      canvas.drawLine(Offset(size.x / 2, 0), Offset(size.x / 2, size.y), beamPaint);
    }
  }
}

/// 3. Porta Cronometrada estilo Dead Cells (Timed Vault < 2m00s)
class TimedVaultComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final double radius = 110.0;
  final double targetTimeRemaining = 60.0; // Em uma run de 180s, >60s restantes = menos de 2m00s gastos!
  bool isOpened = false;
  bool isLockedForever = false;

  TimedVaultComponent({required Vector2 position}) {
    this.position = position.clone();
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing || isOpened) return;

    if (game.timeRemaining < targetTimeRemaining) {
      isLockedForever = true;
      return;
    }

    if (game.player.position.distanceTo(position) <= radius) {
      isOpened = true;
      game.addRunCredits(250);
      game.tryDropBlueprint(position, guaranteed: true);
      game.world.add(ChestComponent(position: position + Vector2(0, 35), tier: ChestTier.gold));
      game.spawnFloatingText(
        position + Vector2(0, -35),
        '⏱️ COFRE CRONOMETRADO ABERTO! (+250c + DIAGRAMA)',
        color: const Color(0xFFFFD700),
        fontSize: 15.0,
      );
      game.playSfx('powerup.wav');
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);
    final color = isOpened
        ? const Color(0xFF00E676)
        : (isLockedForever ? Colors.redAccent : const Color(0xFFFFD700));
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.14)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.restore();
  }
}

/// 4. Porta Intocável estilo Dead Cells (Flawless Boss Vault)
class FlawlessVaultComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final double radius = 105.0;
  bool isClaimed = false;

  FlawlessVaultComponent({required Vector2 position}) {
    this.position = position.clone();
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
  }

  bool get canClaim => !isClaimed && game.flawlessBossKill;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing || isClaimed) return;

    if (canClaim && game.player.position.distanceTo(position) <= radius) {
      isClaimed = true;
      game.addRunCredits(300);
      game.tryDropBlueprint(position, guaranteed: true);
      game.world.add(ChestComponent(position: position + Vector2(0, -30), tier: ChestTier.cosmic));
      game.spawnFloatingText(
        position + Vector2(0, -45),
        '👑 COFRE INTOCÁVEL DESBLOQUEADO! (+300c + JACKPOT)',
        color: const Color(0xFF00E5FF),
        fontSize: 15.5,
      );
      game.playSfx('powerup.wav');
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);
    final color = isClaimed
        ? const Color(0xFF00E676)
        : (canClaim ? const Color(0xFF00E5FF) : Colors.white38);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.14)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.restore();
  }
}

/// 5. Mercador Errante do Vazio (Void Merchant In-Game Shop Zone)
class VoidMerchantComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final double radius = 130.0;
  bool hasTraded = false;
  double interactProgress = 0.0;
  static const double requiredTime = 1.2;

  AsteroidsGame? _customGame;
  @override
  AsteroidsGame get game => _customGame ?? super.game;
  set customGame(AsteroidsGame g) => _customGame = g;

  VoidMerchantComponent({required Vector2 position}) {
    this.position = position.clone();
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing || hasTraded) return;

    if (game.player.position.distanceTo(position) <= radius) {
      interactProgress += dt;
      if (interactProgress >= requiredTime) {
        completeTrade();
      }
    } else {
      interactProgress = math.max(0.0, interactProgress - dt);
    }
  }

  void completeTrade() {
    hasTraded = true;
    const tradeCost = 50;
    if (game.runCredits >= tradeCost) {
      game.runCredits -= tradeCost;
    } else if (game.totalCredits >= tradeCost) {
      game.totalCredits -= tradeCost;
    }

    // Restaura +25 HP e concede Sobrecarregador Tático temporário (10.0s)
    game.player.heal(25.0);
    game.player.activateBloodOverdrive(10.0);
    game.spawnFloatingText(
      position + Vector2(0, -35),
      '🛒 MERCADOR: +25 HP & SOBRECARGA TÁTICA (10s)!',
      color: const Color(0xFFFFD700),
      fontSize: 14.5,
    );
    game.playSfx('powerup.wav');
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);
    final color = hasTraded ? Colors.white24 : const Color(0xFFFFB300);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.14)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.restore();
  }
}

/// 6. Santuário Amaldiçoado (Cursed Shrine: Sacrifica 20% HP por Arma Lendária MK 3 + Sucata)
class CursedShrineComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final double radius = 105.0;
  bool isActivated = false;
  double channelTimer = 0.0;

  AsteroidsGame? _customGame;
  @override
  AsteroidsGame get game => _customGame ?? super.game;
  set customGame(AsteroidsGame g) => _customGame = g;

  CursedShrineComponent({required Vector2 position}) {
    this.position = position.clone();
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing || isActivated) return;

    if (game.player.position.distanceTo(position) <= radius) {
      channelTimer += dt;
      if (channelTimer >= 1.2) {
        activateShrine();
      }
    } else {
      channelTimer = math.max(0.0, channelTimer - dt);
    }
  }

  void activateShrine() {
    if (isActivated) return;
    isActivated = true;

    // Sacrifica 15% do HP atual (nunca letal, mantém pelo menos 15 HP)
    final p = game.player;
    final sacrifice = math.min(p.hp - 15.0, p.maxHp * 0.15);
    if (sacrifice > 0) {
      p.hp -= sacrifice;
    }

    // Recompensa: Sobrecarga Sangrenta Temporária (10s)! (Dano x2, alta cadência)
    // Os poderes duram poucos segundos em vez de alterar permanentemente as armas
    p.activateBloodOverdrive(10.0);
    p.invulnerableTimer = math.max(p.invulnerableTimer, 2.5);

    game.addRunCredits(100);
    game.chargeBossBeacon('SANTUÁRIO DO VAZIO');
    game.triggerScreenShake(duration: 0.45, intensity: 10.0);
    game.spawnFloatingText(
      position + Vector2(0, -35),
      '🩸 PACTO SANGRENTO: SOBRECARGA 10s (DANO x2 & CADÊNCIA)! +100c',
      color: const Color(0xFFE040FB),
      fontSize: 14.5,
    );
    game.playSfx('special.wav');
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);
    final color = isActivated ? Colors.white24 : const Color(0xFFE040FB);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
    canvas.restore();
  }
}
