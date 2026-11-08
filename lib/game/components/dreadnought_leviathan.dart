import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'player.dart';
import 'enemy_ship.dart';
import 'enemy_bullet.dart';
import 'chest.dart';
import 'drop.dart';
import 'xp_orb.dart';
import 'sector_boss.dart';
import 'hyperspace_gate.dart';

class DreadnoughtLeviathanComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks
    implements SectorBoss {
  @override
  final double radius = 72.0;

  @override
  final double maxHp = 3500.0;

  @override
  late double hp;

  @override
  String get bossName => 'DREADNOUGHT LEVIATHAN // SECTOR TITAN';

  double hitFlashTimer = 0.0;

  double shootTimer = 0.0;
  double spiralTimer = 0.0;
  double summonTimer = 0.0;
  double beamTimer = 0.0;
  double deathTimer = 0.0;

  bool isDefeated = false;
  double spiralAngle = 0.0;
  Vector2 velocity = Vector2.zero();

  // Telegraphed Heavy Railgun Beam
  bool isTelegraphingBeam = false;
  double beamTelegraphDuration = 0.0;
  Vector2 lockedBeamDir = Vector2.zero();

  DreadnoughtLeviathanComponent({required Vector2 position}) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
    hp = maxHp;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    game.activeBoss = this;
    game.playSfx('powerup.wav');
    game.triggerScreenShake(duration: 0.8, intensity: 20.0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) {
      removeFromParent();
      return;
    }

    if (hitFlashTimer > 0) {
      hitFlashTimer = math.max(0.0, hitFlashTimer - dt);
    }

    if (isDefeated) {
      deathTimer += dt;
      // Staggered destruction particle bursts
      if (math.Random().nextDouble() < 0.4) {
        final randOffset = Vector2(
          (math.Random().nextDouble() - 0.5) * radius * 1.6,
          (math.Random().nextDouble() - 0.5) * radius * 1.6,
        );
        game.spawnExplosionParticles(
          position: position + randOffset,
          colorChoices: [const Color(0xFFFFD700), const Color(0xFFFF1744), Colors.white, Colors.orangeAccent],
          count: 12,
          minSize: 2.5,
          maxSize: 5.5,
          minSpeed: 60.0,
          maxSpeed: 240.0,
        );
      }

      if (deathTimer >= 3.5) {
        if (!game.isBossRushMode) {
          game.completeMission(survived: true);
        }
        removeFromParent();
      }
      return;
    }

    final player = game.player;
    final toPlayer = player.position - position;
    final distToPlayer = toPlayer.length;
    final targetDir = distToPlayer > 1.0 ? toPlayer.normalized() : Vector2(0, 1);

    // Rotate slowly towards player
    final targetAngle = math.atan2(targetDir.y, targetDir.x) + math.pi / 2;
    angle = targetAngle;

    final hpFraction = (hp / maxHp).clamp(0.0, 1.0);

    // Speed scales slightly as hull breaches
    final speed = hpFraction > 0.66 ? 42.0 : (hpFraction > 0.30 ? 58.0 : 75.0);
    velocity = targetDir * speed;
    position += velocity * dt;
    _enforceSectorBounds();

    // 1. Alternating Twin Turret Volleys
    shootTimer += dt;
    final turretCadence = hpFraction > 0.30 ? 1.8 : 1.2;
    if (shootTimer >= turretCadence && distToPlayer <= 900.0) {
      shootTimer = 0.0;
      _fireTwinTurrets(targetDir);
    }

    // 2. Danmaku Spiral Rings (Phase 2 & 3)
    if (hpFraction <= 0.66) {
      spiralTimer += dt;
      final spiralCadence = hpFraction <= 0.30 ? 1.6 : 2.5;
      if (spiralTimer >= spiralCadence) {
        spiralTimer = 0.0;
        _fireSpiralDanmakuRing(hpFraction <= 0.30 ? 10 : 8);
      }
    }

    // 3. Scout Drone Escort Summons
    summonTimer += dt;
    if (summonTimer >= 8.0 && hpFraction > 0.15) {
      summonTimer = 0.0;
      _summonScoutEscorts();
    }

    // 4. Telegraphed Railgun Beam (Phase 2 & 3)
    if (hpFraction <= 0.66) {
      beamTimer += dt;
      if (!isTelegraphingBeam && beamTimer >= 6.5) {
        isTelegraphingBeam = true;
        beamTelegraphDuration = 1.0;
        lockedBeamDir = targetDir;
        game.playSfx('dash.wav');
      } else if (isTelegraphingBeam) {
        beamTelegraphDuration -= dt;
        if (beamTelegraphDuration <= 0) {
          isTelegraphingBeam = false;
          beamTimer = 0.0;
          _fireHeavyRailgunBeam(lockedBeamDir);
        }
      }
    }
  }

  void _fireTwinTurrets(Vector2 forwardDir) {
    final right = Vector2(-forwardDir.y, forwardDir.x);
    for (final offset in [-radius * 0.55, radius * 0.55]) {
      final spawnPos = position + forwardDir * (radius * 0.8) + right * offset;
      game.world.add(
        EnemyBulletComponent(
          position: spawnPos,
          radius: 5.5,
          velocity: forwardDir * 260.0,
          damage: 1.0,
          bulletColor: const Color(0xFFFF1744), // Crimson
        ),
      );
    }
    game.playSfx('shoot.wav');
  }

  void _fireSpiralDanmakuRing(int bulletCount) {
    spiralAngle += 0.28;
    for (var i = 0; i < bulletCount; i++) {
      final a = spiralAngle + (i * 2 * math.pi / bulletCount);
      final dir = Vector2(math.cos(a), math.sin(a));
      game.world.add(
        EnemyBulletComponent(
          position: position + dir * (radius + 4.0),
          radius: 5.0,
          velocity: dir * 210.0,
          damage: 1.0,
          bulletColor: const Color(0xFFD500F9), // Purple Neon
        ),
      );
    }
    game.playSfx('shoot.wav');
  }

  void _summonScoutEscorts() {
    final random = math.Random();
    for (var i = 0; i < 3; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final spawnPos = position + Vector2(math.cos(angle), math.sin(angle)) * (radius + 40.0);
      game.world.add(
        EnemyShipComponent(
          position: spawnPos,
          type: EnemyType.scout,
        ),
      );
    }
  }

  void _fireHeavyRailgunBeam(Vector2 dir) {
    game.playSfx('bomb_explode.wav');
    game.triggerScreenShake(duration: 0.35, intensity: 12.0);

    // Line of high-speed heavy plasma bolts
    for (var i = 0; i < 6; i++) {
      final spawnPos = position + dir * (radius + 15.0 + i * 28.0);
      game.world.add(
        EnemyBulletComponent(
          position: spawnPos,
          radius: 7.0,
          velocity: dir * 420.0,
          damage: 1.0,
          bulletColor: const Color(0xFFFFD700), // Imperial Gold
        ),
      );
    }
  }

  void _enforceSectorBounds() {
    position.x = position.x.clamp(radius, GameConstants.sectorWidth - radius);
    position.y = position.y.clamp(radius, GameConstants.sectorHeight - radius);
  }

  bool takeDamage(double damage, Vector2 hitPos) {
    if (isDefeated) return false;
    hp -= damage;
    hitFlashTimer = 0.12;

    game.spawnExplosionParticles(
      position: hitPos,
      colorChoices: [const Color(0xFFFFD700), const Color(0xFFFF1744), Colors.white],
      count: 4,
      minSize: 1.5,
      maxSize: 3.5,
      minSpeed: 40.0,
      maxSpeed: 100.0,
    );

    if (hp <= 0) {
      _defeat();
      return true;
    } else {
      game.spawnFloatingText(
        hitPos,
        '-${damage.toInt()}',
        color: const Color(0xFFFF8A80),
        fontSize: 12.5,
      );
      return false;
    }
  }

  void _defeat() {
    isDefeated = true;
    hp = 0;
    game.onBossDefeatedSpeechCheck();
    game.addScore(5000);
    game.addRunCredits(500);
    game.playSfx('powerup.wav');
    game.triggerScreenShake(duration: 1.5, intensity: 25.0);

    // Guaranteed Legendary Cosmic Chest Drop!
    game.world.add(
      ChestComponent(
        position: position.clone(),
        tier: ChestTier.cosmic, // 5 rewards jackpot!
      ),
    );

    // Stardust fountain (5 large gems)
    for (var i = 0; i < 5; i++) {
      final a = (i * 2 * math.pi / 5);
      final offset = Vector2(math.cos(a), math.sin(a)) * 25.0;
      game.world.add(
        XpOrbComponent(
          position: position + offset,
          type: XpOrbType.large,
        ),
      );
    }

    // Guaranteed Memory Cores (2x) to boost pilot bond
    for (var i = 0; i < 2; i++) {
      final a = (i * math.pi) + math.pi / 4;
      final offset = Vector2(math.cos(a), math.sin(a)) * 35.0;
      game.world.add(
        DropComponent(
          position: position + offset,
          type: DropType.memoryCore,
          initialVelocity: Vector2(math.cos(a), math.sin(a)) * 40.0,
        ),
      );
    }
    game.affinityManager.getAffinity(game.selectedValkyrie.id).addXp(150);
    game.hyperModeUnlocked = true;
    game.saveHyperModeState();

    if (game.isBossRushMode) {
      game.onBossRushBossDefeated(position.clone());
    } else {
      // Abre Portal de Hiperespaço para o próximo setor!
      game.world.add(HyperspaceGateComponent(position: position.clone()));
    }

    game.spawnFloatingText(
      position + Vector2(0, -60),
      '🏆 SECTOR SECURED! DREADNOUGHT DESTROYED!',
      color: const Color(0xFFFFD700),
      fontSize: 20.0,
    );
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is PlayerComponent) {
      other.takeHit(45.0);
      final push = (other.position - position).normalized();
      other.velocity += push * 380.0;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);

    // 1. Draw Telegraphed Heavy Railgun Laser (along forward nose axis)
    if (isTelegraphingBeam) {
      final pulse = (math.sin(DateTime.now().millisecondsSinceEpoch / 45.0) + 1) / 2;
      final laserPaint = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: 0.55 + pulse * 0.45)
        ..strokeWidth = 3.5 + pulse * 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, -radius * 1.3), const Offset(0, -900.0), laserPaint);
    }

    final isFlashing = hitFlashTimer > 0;
    final hpRatio = (hp / maxHp).clamp(0.0, 1.0);

    // Outer Armored Battleship Hull
    final hullPath = Path()
      ..moveTo(0, -radius * 1.3)
      ..lineTo(radius * 0.5, -radius * 0.7)
      ..lineTo(radius * 0.95, -radius * 0.2)
      ..lineTo(radius * 0.85, radius * 0.6)
      ..lineTo(radius * 0.35, radius * 1.1)
      ..lineTo(0, radius * 0.8)
      ..lineTo(-radius * 0.35, radius * 1.1)
      ..lineTo(-radius * 0.85, radius * 0.6)
      ..lineTo(-radius * 0.95, -radius * 0.2)
      ..lineTo(-radius * 0.5, -radius * 0.7)
      ..close();

    final hullPaint = Paint()
      ..color = const Color(0xFF0F0B18).withValues(alpha: 0.96)
      ..style = PaintingStyle.fill;
    canvas.drawPath(hullPath, hullPaint);

    final hullBorderColor = isFlashing
        ? Colors.white
        : (hpRatio > 0.66
            ? const Color(0xFF00E5FF)
            : (hpRatio > 0.30 ? const Color(0xFFD500F9) : const Color(0xFFFF1744)));

    Glow.strokePath(
      canvas,
      hullPath,
      hullBorderColor,
      width: 3.2,
      intensity: 1.6,
    );

    // Glowing Power Core in Center
    final coreColor = isFlashing
        ? Colors.white
        : (hpRatio > 0.66
            ? const Color(0xFF00E5FF)
            : (hpRatio > 0.30 ? const Color(0xFFE040FB) : const Color(0xFFFF1744)));

    final coreRadius = 14.0 + 3.0 * math.sin(DateTime.now().millisecondsSinceEpoch / 120.0);
    final corePaint = Paint()
      ..color = coreColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, coreRadius, corePaint);

    Glow.strokeCircle(
      canvas,
      Offset.zero,
      coreRadius * 1.4,
      coreColor,
      width: 2.2,
      intensity: 1.8,
    );

    // Twin Heavy Gun Wings
    final wingGunPaint = Paint()
      ..color = hullBorderColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(-radius * 0.55, -radius * 0.2), Offset(-radius * 0.55, -radius * 1.1), wingGunPaint);
    canvas.drawLine(Offset(radius * 0.55, -radius * 0.2), Offset(radius * 0.55, -radius * 1.1), wingGunPaint);

    canvas.restore();
  }
}
