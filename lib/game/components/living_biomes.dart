import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'player.dart';
import 'bullet.dart';
import 'enemy_bullet.dart';
import 'enemy_ship.dart';
import 'chest.dart';
import 'xp_orb.dart';
import 'drop.dart';
import 'sector_boss.dart';
import 'hyperspace_gate.dart';
import 'dead_cells_biome.dart';
import 'advanced_weapons.dart';
export 'phase4_biome_elements.dart';

/// ============================================================================
/// SPRINT 21 — SETOR 2B: ABISMO CRIOGÊNICO DE CAELUM (CRYO ABYSS)
/// ============================================================================

/// 1. Neblina de Gelo (Cryo Mist): reduz a aceleração da nave em 30%
class CryoMistZoneComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final double radius;
  static const double accelerationReductionFactor = 0.70; // -30% aceleração
  double _pulseTimer = 0.0;

  CryoMistZoneComponent({
    required Vector2 position,
    this.radius = 380.0,
  }) : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  @override
  bool containsPoint(Vector2 point) => position.distanceTo(point) <= radius;

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt * 1.2;
    try {
      if (containsPoint(game.player.position)) {
        game.player.cryoMistAccelerationMultiplier = accelerationReductionFactor;
      }
    } catch (_) {}
  }

  @override
  void render(Canvas canvas) {
    try {
      final camPos = game.camera.viewfinder.position;
      if ((position.x - camPos.x).abs() > 750 + radius ||
          (position.y - camPos.y).abs() > 450 + radius) {
        return;
      }
    } catch (_) {}

    canvas.save();
    canvas.translate(radius, radius);
    final pulse = 1.0 + 0.04 * math.sin(_pulseTimer);
    final curR = radius * pulse;

    final gradient = RadialGradient(
      colors: [
        const Color(0xFF80D8FF).withValues(alpha: 0.22),
        const Color(0xFF00B0FF).withValues(alpha: 0.12),
        Colors.transparent,
      ],
      stops: const [0.0, 0.65, 1.0],
    );
    canvas.drawCircle(
      Offset.zero,
      curR,
      Paint()
        ..shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: curR))
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      curR * 0.92,
      Paint()
        ..color = const Color(0xFF80D8FF).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }
}

/// 2. Mina Criogênica (Cryo Mine): congela a nave por 0.8s ao detonar
class CryoMineComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final double radius = 16.0;
  final double triggerRadius = 56.0;
  static const double freezeDuration = 0.8;
  bool isDetonated = false;
  double _pulseTimer = 0.0;

  CryoMineComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(32.0),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDetonated || game.state != GameState.playing) return;
    _pulseTimer += dt * 5.0;

    final player = game.player;
    if (player.position.distanceTo(position) <= triggerRadius) {
      detonate();
    }
  }

  void detonate() {
    if (isDetonated) return;
    isDetonated = true;
    try {
      game.notifyMineDestroyedForUnlocks();
    } catch (_) {}
    try {
      final player = game.player;
      if (player.position.distanceTo(position) <= triggerRadius + 30.0) {
        player.applyCryoFreeze(freezeDuration);
        player.takeHit(12.0);
        game.spawnFloatingText(
          player.position + Vector2(0, -38),
          '❄️ CONGELAMENTO CRIOGÊNICO (0.8s)!',
          color: const Color(0xFF80D8FF),
          fontSize: 13.5,
        );
      }
      game.spawnExplosionParticles(
        position: position,
        colorChoices: [const Color(0xFF80D8FF), Colors.white, const Color(0xFF00E5FF)],
        count: 18,
        minSize: 2.0,
        maxSize: 4.5,
        minSpeed: 40.0,
        maxSpeed: 150.0,
      );
      game.playSfx('asteroid_split.wav');
    } catch (_) {}
    removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent || other is BulletComponent) {
      detonate();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);
    final pulse = 0.85 + 0.15 * math.sin(_pulseTimer);
    Glow.drawGlowCircle(
      canvas,
      Offset.zero,
      radius * pulse,
      const Color(0xFF80D8FF),
      strokeWidth: 2.0,
      intensity: 1.3,
    );
    canvas.restore();
  }
}

/// 3. Chefe do Setor 2B (Abismo Criogênico): GLACIAL COLOSSUS com blindagem regenerativa de gelo
class GlacialColossusComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks
    implements SectorBoss {
  @override
  final double radius = 62.0;

  @override
  final double maxHp = 3800.0;

  @override
  late double hp;

  @override
  bool isDefeated = false;

  @override
  String get bossName => 'GLACIAL COLOSSUS // CRYO TITAN';

  // Blindagem regenerativa de gelo (Sprint 21)
  final double maxIceArmorShieldHp = 400.0;
  double iceArmorShieldHp = 400.0;
  final double shieldRegenPerSecond = 28.0;
  double _salvoTimer = 0.0;
  double _hitFlashTimer = 0.0;

  GlacialColossusComponent({required Vector2 position}) {
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
    if (isDefeated || game.state != GameState.playing) return;

    if (_hitFlashTimer > 0) {
      _hitFlashTimer = math.max(0.0, _hitFlashTimer - dt);
    }

    // Regenera blindagem de gelo continuamente se não estiver sofrendo Solar Burn
    if (!hasStatus(ElementalStatus.solarBurn) && iceArmorShieldHp < maxIceArmorShieldHp) {
      iceArmorShieldHp = math.min(maxIceArmorShieldHp, iceArmorShieldHp + shieldRegenPerSecond * dt);
    }

    final player = game.player;
    final toPlayer = player.position - position;
    final dist = toPlayer.length;
    final dir = dist > 1.0 ? toPlayer / dist : Vector2(0, 1);
    angle = math.atan2(dir.y, dir.x) + math.pi / 2;

    position += dir * (48.0 * dt);
    position.x = position.x.clamp(radius + 40, GameConstants.sectorWidth - radius - 40);
    position.y = position.y.clamp(radius + 40, GameConstants.sectorHeight - radius - 40);

    _salvoTimer += dt;
    if (_salvoTimer >= 1.9 && dist <= 880.0) {
      _salvoTimer = 0.0;
      const count = 6;
      final baseA = math.atan2(dir.y, dir.x);
      for (var i = 0; i < count; i++) {
        final a = baseA + (i - 2.5) * 0.22;
        final shotDir = Vector2(math.cos(a), math.sin(a));
        game.world.add(
          EnemyBulletComponent(
            position: position + shotDir * (radius + 8.0),
            radius: 5.5,
            velocity: shotDir * 220.0,
            damage: 16.0,
            bulletColor: const Color(0xFF80D8FF),
          ),
        );
      }
      game.playSfx('shoot.wav');
    }
  }

  @override
  bool takeDamage(double damage, Vector2 hitPos) {
    if (isDefeated) return false;
    _hitFlashTimer = 0.10;

    double effectiveDmg = damage;
    if (iceArmorShieldHp > 0) {
      final shieldAbsorb = math.min(iceArmorShieldHp, effectiveDmg * 0.55);
      iceArmorShieldHp -= shieldAbsorb;
      effectiveDmg -= shieldAbsorb * 0.65;
    }

    hp -= effectiveDmg;
    if (hp <= 0) {
      _defeat();
      return true;
    }
    return false;
  }

  void _defeat() {
    isDefeated = true;
    hp = 0;
    game.sectorMap?.isBossDefeated = true;
    game.addScore(14000);
    game.addRunCredits(1100);
    game.tryDropBlueprint(position, guaranteed: true);
    game.onBossDefeatedSpeechCheck();
    game.world.add(ChestComponent(position: position.clone(), tier: ChestTier.cosmic));
    for (var i = 0; i < 6; i++) {
      final a = (i * 2 * math.pi / 6);
      game.world.add(XpOrbComponent(
        position: position + Vector2(math.cos(a), math.sin(a)) * 42.0,
        type: XpOrbType.large,
      ));
    }
    if (game.isBossRushMode) {
      game.onBossRushBossDefeated(position.clone());
    } else {
      game.world.add(HyperspaceGateComponent(position: position.clone()));
    }
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);
    final color = _hitFlashTimer > 0 ? Colors.white : const Color(0xFF80D8FF);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = const Color(0xFF002B3D).withValues(alpha: 0.92)
        ..style = PaintingStyle.fill,
    );
    Glow.drawGlowCircle(canvas, Offset.zero, radius, color, strokeWidth: 3.0, intensity: 1.5);
    if (iceArmorShieldHp > 0) {
      final shieldAlpha = (iceArmorShieldHp / maxIceArmorShieldHp).clamp(0.15, 0.85);
      canvas.drawCircle(
        Offset.zero,
        radius + 8.0,
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: shieldAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2,
      );
    }
    canvas.restore();
  }
}

/// ============================================================================
/// SPRINT 21 — SETOR 3B: COLMEIA XENO-BIOLÓGICA DE NÊMESIS (XENO HIVE)
/// ============================================================================

/// 4. Parede Orgânica Pulsante (Organic Biomass Wall): regenera HP continuamente
class OrganicBiomassWallComponent extends MegastructureWallComponent {
  final double maxHp = 260.0;
  double hp = 260.0;
  final double regenRate = 22.0; // Regenera +22 HP/s se não for destruída
  double _pulseTimer = 0.0;

  OrganicBiomassWallComponent({
    required super.position,
    required super.wallSize,
  }) : super(wallColor: const Color(0xFFFF4081));

  bool takeDamage(double damage) {
    hp -= damage;
    if (hp <= 0) {
      hp = 0;
      removeFromParent();
      return true;
    }
    return false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;
    _pulseTimer += dt * 3.5;

    if (hp > 0 && hp < maxHp) {
      hp = math.min(maxHp, hp + regenRate * dt);
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is BulletComponent) {
      takeDamage(other.damage);
      other.removeFromParent();
      return;
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void render(Canvas canvas) {
    final pulse = 1.0 + 0.04 * math.sin(_pulseTimer);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y * pulse),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFF2D0822).withValues(alpha: 0.94)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFFFF4081).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );
  }
}

/// 5. Casulo Xeno (Xeno Cocoon): libera Void Swarmers ao ser atingido
class XenoCocoonComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final double radius = 24.0;
  double hp = 55.0;
  bool hasHatched = false;
  double _pulseTimer = 0.0;

  XenoCocoonComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(48.0),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hasHatched || game.state != GameState.playing) return;
    _pulseTimer += dt * 4.0;

    if (game.player.position.distanceTo(position) <= 68.0) {
      hatchSwarm();
    }
  }

  bool takeDamage(double damage) {
    if (hasHatched) return false;
    hp -= damage;
    hatchSwarm();
    return true;
  }

  void hatchSwarm({int swarmCount = 5}) {
    if (hasHatched) return;
    hasHatched = true;
    try {
      for (var i = 0; i < swarmCount; i++) {
        final a = (i * 2 * math.pi / swarmCount);
        final spawnPos = position + Vector2(math.cos(a), math.sin(a)) * 28.0;
        final swarmer = VoidSwarmComponent(position: spawnPos);
        if (game.asteroidField != null) {
          game.asteroidField!.spawnOrPromoteEnemy(swarmer);
        } else {
          game.world.add(swarmer);
        }
      }
      game.spawnFloatingText(
        position + Vector2(0, -30),
        '🪲 CASULO XENO ECLODIU!',
        color: const Color(0xFFFF4081),
        fontSize: 13.0,
      );
      game.playSfx('asteroid_split.wav');
    } catch (_) {}
    removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is BulletComponent) {
      other.removeFromParent();
      takeDamage(other.damage);
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);
    final pulse = 0.90 + 0.10 * math.sin(_pulseTimer);
    canvas.drawCircle(
      Offset.zero,
      radius * pulse,
      Paint()
        ..color = const Color(0xFF4A0E2E).withValues(alpha: 0.90)
        ..style = PaintingStyle.fill,
    );
    Glow.drawGlowCircle(
      canvas,
      Offset.zero,
      radius * pulse,
      const Color(0xFFFF4081),
      strokeWidth: 2.2,
      intensity: 1.3,
    );
    canvas.restore();
  }
}

/// 6. Chefe do Setor 3B (Colmeia Xeno): CARRIER HIVE ALPHA que lança enxames parasitários
class CarrierHiveAlphaComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks
    implements SectorBoss {
  @override
  final double radius = 66.0;

  @override
  final double maxHp = 4600.0;

  @override
  late double hp;

  @override
  bool isDefeated = false;

  @override
  String get bossName => 'CARRIER HIVE ALPHA // XENO BROODMOTHER';

  double _swarmSpawnTimer = 0.0;
  double _bioSalvoTimer = 0.0;
  double _hitFlashTimer = 0.0;

  CarrierHiveAlphaComponent({required Vector2 position}) {
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

  void spawnParasiticSwarm({int count = 4}) {
    for (var i = 0; i < count; i++) {
      final a = (i * 2 * math.pi / count);
      final spawnPos = position + Vector2(math.cos(a), math.sin(a)) * (radius + 20.0);
      final swarmer = VoidSwarmComponent(position: spawnPos);
      if (game.asteroidField != null) {
        game.asteroidField!.spawnOrPromoteEnemy(swarmer);
      } else {
        game.world.add(swarmer);
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated || game.state != GameState.playing) return;

    if (_hitFlashTimer > 0) {
      _hitFlashTimer = math.max(0.0, _hitFlashTimer - dt);
    }

    final player = game.player;
    final toPlayer = player.position - position;
    final dist = toPlayer.length;
    final dir = dist > 1.0 ? toPlayer / dist : Vector2(0, 1);
    angle = math.atan2(dir.y, dir.x) + math.pi / 2;

    position += dir * (44.0 * dt);
    position.x = position.x.clamp(radius + 40, GameConstants.sectorWidth - radius - 40);
    position.y = position.y.clamp(radius + 40, GameConstants.sectorHeight - radius - 40);

    _swarmSpawnTimer += dt;
    if (_swarmSpawnTimer >= 3.6) {
      _swarmSpawnTimer = 0.0;
      spawnParasiticSwarm(count: 4);
    }

    _bioSalvoTimer += dt;
    if (_bioSalvoTimer >= 2.0 && dist <= 900.0) {
      _bioSalvoTimer = 0.0;
      const count = 8;
      for (var i = 0; i < count; i++) {
        final a = (i * 2 * math.pi / count);
        final shotDir = Vector2(math.cos(a), math.sin(a));
        game.world.add(
          EnemyBulletComponent(
            position: position + shotDir * (radius + 8.0),
            radius: 5.5,
            velocity: shotDir * 215.0,
            damage: 16.0,
            bulletColor: const Color(0xFFFF4081),
          ),
        );
      }
    }
  }

  @override
  bool takeDamage(double damage, Vector2 hitPos) {
    if (isDefeated) return false;
    _hitFlashTimer = 0.10;
    hp -= damage;
    if (hp <= 0) {
      _defeat();
      return true;
    }
    return false;
  }

  void _defeat() {
    isDefeated = true;
    hp = 0;
    game.sectorMap?.isBossDefeated = true;
    game.addScore(18000);
    game.addRunCredits(1500);
    game.tryDropBlueprint(position, guaranteed: true);
    game.onBossDefeatedSpeechCheck();
    game.world.add(ChestComponent(position: position.clone(), tier: ChestTier.cosmic));
    for (var i = 0; i < 6; i++) {
      final a = (i * 2 * math.pi / 6);
      game.world.add(XpOrbComponent(
        position: position + Vector2(math.cos(a), math.sin(a)) * 44.0,
        type: XpOrbType.large,
      ));
    }
    if (game.isBossRushMode) {
      game.onBossRushBossDefeated(position.clone());
    } else {
      game.world.add(HyperspaceGateComponent(position: position.clone()));
    }
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);
    final color = _hitFlashTimer > 0 ? Colors.white : const Color(0xFFFF4081);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = const Color(0xFF2B071C).withValues(alpha: 0.94)
        ..style = PaintingStyle.fill,
    );
    Glow.drawGlowCircle(canvas, Offset.zero, radius, color, strokeWidth: 3.2, intensity: 1.6);
    canvas.restore();
  }
}

/// ============================================================================
/// SPRINT 24 — SETOR 5 SECRETO: O TRONO DO VAZIO (PRIMORDIAL VOID SOVEREIGN)
/// ============================================================================

/// 7. Chefe Secreto Final do Setor 5: PRIMORDIAL VOID SOVEREIGN
class PrimordialVoidSovereignComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks
    implements SectorBoss {
  @override
  final double radius = 74.0;

  @override
  final double maxHp = 7500.0;

  @override
  late double hp;

  @override
  bool isDefeated = false;

  @override
  String get bossName => 'PRIMORDIAL VOID SOVEREIGN // THE ARCHITECT';

  double _novaTimer = 0.0;
  double _rotation = 0.0;
  double _hitFlashTimer = 0.0;

  PrimordialVoidSovereignComponent({required Vector2 position}) {
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
    if (isDefeated || game.state != GameState.playing) return;

    if (_hitFlashTimer > 0) {
      _hitFlashTimer = math.max(0.0, _hitFlashTimer - dt);
    }
    _rotation += dt * 2.2;

    final player = game.player;
    final toPlayer = player.position - position;
    final dist = toPlayer.length;
    final dir = dist > 1.0 ? toPlayer / dist : Vector2(0, 1);

    position += dir * (56.0 * dt);
    position.x = position.x.clamp(radius + 40, GameConstants.sectorWidth - radius - 40);
    position.y = position.y.clamp(radius + 40, GameConstants.sectorHeight - radius - 40);

    _novaTimer += dt;
    if (_novaTimer >= 1.5 && dist <= 960.0) {
      _novaTimer = 0.0;
      const count = 12;
      for (var i = 0; i < count; i++) {
        final a = _rotation + (i * 2 * math.pi / count);
        final shotDir = Vector2(math.cos(a), math.sin(a));
        game.world.add(
          EnemyBulletComponent(
            position: position + shotDir * (radius + 10.0),
            radius: 6.0,
            velocity: shotDir * 255.0,
            damage: 20.0,
            bulletColor: i.isEven ? const Color(0xFFFFD700) : const Color(0xFFE040FB),
          ),
        );
      }
    }
  }

  @override
  bool takeDamage(double damage, Vector2 hitPos) {
    if (isDefeated) return false;
    _hitFlashTimer = 0.10;
    hp -= damage;
    if (hp <= 0) {
      _defeat();
      return true;
    }
    return false;
  }

  void _defeat() {
    isDefeated = true;
    hp = 0;
    game.sectorMap?.isBossDefeated = true;
    game.campaignCompleted = true;
    game.primordialSovereignDefeated = true;
    game.addScore(50000);
    game.addRunCredits(5000);
    game.onBossDefeatedSpeechCheck();
    game.world.add(ChestComponent(position: position.clone(), tier: ChestTier.cosmic));
    game.world.add(HyperspaceGateComponent(position: position.clone()));
    game.spawnFloatingText(
      position + Vector2(0, -70),
      '✨ SOBERANO PRIMORDIAL DERROTADO! PROTOCOLO QUEBRADO! ✨',
      color: const Color(0xFFFFD700),
      fontSize: 20.0,
    );
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);
    final color = _hitFlashTimer > 0 ? Colors.white : const Color(0xFFFFD700);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = const Color(0xFF140024).withValues(alpha: 0.96)
        ..style = PaintingStyle.fill,
    );
    Glow.drawGlowCircle(canvas, Offset.zero, radius, color, strokeWidth: 3.6, intensity: 1.9);
    canvas.restore();
  }
}
