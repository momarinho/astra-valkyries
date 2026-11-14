import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:void_protocol/constants.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/glow.dart';
import 'player.dart';
import 'enemy_bullet.dart';
import 'chest.dart';
import 'xp_orb.dart';
import 'drop.dart';
import 'sector_boss.dart';
import 'hyperspace_gate.dart';

/// Chefe Soberano Final do Setor 4 (Abismo Event Horizon):
/// VOID SINGULARITY CORE // EVENT HORIZON APEX.
/// Uma singularidade cósmica senciente cercada por anéis de acreção relativísticos.
/// Distorce a gravidade puxando a Valquíria em direção ao horizonte de eventos,
/// dispara espirais de antimatéria e emite explosões de radiação Quasar.
class VoidSingularityCoreComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks
    implements SectorBoss {
  @override
  final double radius = 68.0;

  @override
  final double maxHp = 6000.0;

  @override
  late double hp;

  @override
  bool isDefeated = false;

  @override
  String get bossName => 'VOID SINGULARITY CORE // EVENT HORIZON APEX';

  final double gravityPullRadius = 520.0;
  double _spiralTimer = 0.0;
  double _quasarTimer = 0.0;
  double _spiralAngle = 0.0;
  double _accretionRotation = 0.0;
  double _pulseTimer = 0.0;
  double _hitFlashTimer = 0.0;

  final Paint _horizonPaint = Paint()
    ..color = const Color(0xFF05000D)
    ..style = PaintingStyle.fill;

  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  VoidSingularityCoreComponent({required Vector2 position}) {
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

    _accretionRotation += dt * 2.4;
    _pulseTimer += dt * 3.8;

    final player = game.player;
    final toPlayer = player.position - position;
    final dist = toPlayer.length;
    final targetDir = dist > 1.0 ? toPlayer / dist : Vector2(0, 1);

    final hpRatio = (hp / maxHp).clamp(0.0, 1.0);
    final moveSpeed = hpRatio > 0.5 ? 48.0 : 72.0;
    position += targetDir * (moveSpeed * dt);
    _enforceBounds();

    // 1. Campo Gravitacional Ativo: puxa suavemente a nave quando dentro de 520px
    if (dist <= gravityPullRadius && dist > radius) {
      final pullStrength = (1.0 - (dist / gravityPullRadius)).clamp(0.15, 1.0) * 115.0;
      player.velocity -= targetDir * (pullStrength * dt);
    }

    // 2. Espiral de Antimatéria Relativística
    _spiralTimer += dt;
    final spiralInterval = hpRatio > 0.4 ? 1.35 : 0.90;
    if (_spiralTimer >= spiralInterval && dist <= 920.0) {
      _spiralTimer = 0.0;
      _fireAntimatterSpiral();
    }

    // 3. Explosão de Radiação Quasar (Hawking Burst)
    _quasarTimer += dt;
    if (_quasarTimer >= 5.5) {
      _quasarTimer = 0.0;
      _fireQuasarBurst(targetDir);
    }
  }

  void _fireAntimatterSpiral() {
    _spiralAngle += 0.48;
    const int arms = 4;
    for (var i = 0; i < arms; i++) {
      final a = _spiralAngle + i * (math.pi / 2);
      final dir = Vector2(math.cos(a), math.sin(a));
      game.world.add(
        EnemyBulletComponent(
          position: position + dir * (radius + 8.0),
          radius: 5.5,
          velocity: dir * 235.0,
          damage: 1.0,
          bulletColor: i.isEven ? const Color(0xFFE040FB) : const Color(0xFF7C4DFF),
        ),
      );
    }
    game.playSfx('shoot.wav');
  }

  void _fireQuasarBurst(Vector2 toPlayerDir) {
    game.playSfx('bomb_explode.wav');
    game.triggerScreenShake(duration: 0.4, intensity: 14.0);

    const int count = 14;
    for (var i = 0; i < count; i++) {
      final a = (i * 2 * math.pi / count);
      final dir = Vector2(math.cos(a), math.sin(a));
      game.world.add(
        EnemyBulletComponent(
          position: position + dir * (radius + 10.0),
          radius: 6.2,
          velocity: dir * 265.0,
          damage: 1.0,
          bulletColor: const Color(0xFFFFD700),
        ),
      );
    }
  }

  void _enforceBounds() {
    position.x = position.x.clamp(radius + 40, GameConstants.sectorWidth - radius - 40);
    position.y = position.y.clamp(radius + 40, GameConstants.sectorHeight - radius - 40);
  }

  @override
  bool takeDamage(double damage, Vector2 hitPos) {
    if (isDefeated) return false;

    hp -= damage;
    _hitFlashTimer = 0.10;

    game.spawnExplosionParticles(
      position: hitPos,
      colorChoices: [const Color(0xFFE040FB), const Color(0xFF7C4DFF), Colors.white],
      count: 4,
      minSize: 1.5,
      maxSize: 3.5,
      minSpeed: 45.0,
      maxSpeed: 120.0,
    );

    if (hp <= 0) {
      _defeat();
      return true;
    } else {
      game.spawnFloatingText(
        hitPos,
        '-${damage.toInt()}',
        color: const Color(0xFFEA80FC),
        fontSize: 12.5,
      );
      return false;
    }
  }

  void _defeat() {
    isDefeated = true;
    hp = 0;
    game.sectorMap?.isBossDefeated = true;
    game.campaignCompleted = true;
    game.onBossDefeatedSpeechCheck();
    game.hyperModeUnlocked = true;
    game.saveHyperModeState();

    game.addScore(25000);
    game.addRunCredits(2500);
    game.playSfx('powerup.wav');
    game.triggerScreenShake(duration: 2.5, intensity: 32.0);

    game.spawnExplosionParticles(
      position: position,
      colorChoices: [
        const Color(0xFFE040FB),
        const Color(0xFF7C4DFF),
        const Color(0xFFFFD700),
        Colors.white,
      ],
      count: 70,
      minSize: 3.0,
      maxSize: 7.0,
      minSpeed: 70.0,
      maxSpeed: 300.0,
    );

    // Baú Cósmico Jackpot
    game.world.add(
      ChestComponent(
        position: position.clone(),
        tier: ChestTier.cosmic,
      ),
    );

    // 8 Orbes Grandes de XP
    for (var i = 0; i < 8; i++) {
      final a = (i * 2 * math.pi / 8);
      final offset = Vector2(math.cos(a), math.sin(a)) * 48.0;
      game.world.add(XpOrbComponent(position: position + offset, type: XpOrbType.large));
    }

    // 3 Núcleos de Memória
    for (var i = 0; i < 3; i++) {
      final a = (i * 2 * math.pi / 3);
      final offset = Vector2(math.cos(a), math.sin(a)) * 38.0;
      game.world.add(
        DropComponent(
          position: position + offset,
          type: DropType.memoryCore,
          initialVelocity: Vector2(math.cos(a), math.sin(a)) * 40.0,
        ),
      );
    }
    game.affinityManager.getAffinity(game.selectedValkyrie.id).addXp(250);

    if (game.isBossRushMode) {
      game.onBossRushBossDefeated(position.clone());
    } else {
      game.world.add(HyperspaceGateComponent(position: position.clone()));
    }

    game.spawnFloatingText(
      position + Vector2(0, -65),
      '👑 SINGULARIDADE EXTINTA! HIPER MODO DESBLOQUEADO! 👑',
      color: const Color(0xFFFFD700),
      fontSize: 22.0,
    );

    removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (isDefeated) return;
    if (other is PlayerComponent) {
      other.takeHit(50.0);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = (size / 2).toOffset();
    final pulse = 0.90 + 0.10 * math.sin(_pulseTimer);
    final isFlashing = _hitFlashTimer > 0;

    // 1. Anel de Distorção Gravitacional Externa
    _ringPaint.color = const Color(0xFF7C4DFF).withValues(alpha: 0.14);
    _ringPaint.strokeWidth = 1.5;
    canvas.drawCircle(center, gravityPullRadius * 0.45 * pulse, _ringPaint);

    // 2. Disco de Acreção em Rotação Relativística
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_accretionRotation);

    for (var ring = 1; ring <= 3; ring++) {
      final r = radius * (0.65 + ring * 0.22) * pulse;
      final c = ring == 1
          ? const Color(0xFFE040FB)
          : (ring == 2 ? const Color(0xFF7C4DFF) : const Color(0xFFFFD700));
      _ringPaint.color = isFlashing ? Colors.white : c.withValues(alpha: 0.78);
      _ringPaint.strokeWidth = 3.0;

      for (var seg = 0; seg < 3; seg++) {
        final startA = seg * (2 * math.pi / 3) + (ring.isEven ? _accretionRotation : -_accretionRotation);
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: r),
          startA,
          math.pi / 2.2,
          false,
          _ringPaint,
        );
      }
    }
    canvas.restore();

    // 3. Horizonte de Eventos Absoluto (Esfera Negra com Borda Violeta Neon)
    canvas.drawCircle(center, radius * 0.75 * pulse, _horizonPaint);
    Glow.strokeCircle(
      canvas,
      center,
      radius * 0.75 * pulse,
      isFlashing ? Colors.white : const Color(0xFFE040FB),
      width: 3.2,
      intensity: 1.8,
    );

    // 4. Ponto Singular Central
    Glow.orb(
      canvas,
      center,
      radius * 0.22 * pulse,
      isFlashing ? Colors.white : const Color(0xFFFFD700),
    );
  }
}
