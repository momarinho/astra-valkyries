import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'player.dart';
import 'sector_boss.dart';
import 'enemy_bullet.dart';
import 'chest.dart';
import 'drop.dart';
import 'xp_orb.dart';
import 'hyperspace_gate.dart';
import 'solar_fire_trail.dart';

class _WyrmSegment {
  Vector2 position;
  double radius;
  _WyrmSegment({required this.position, required this.radius});
}

/// Chefe do Setor 2 (Forja Solar de Órion): Ignis Wyrm (Solar Leviathan).
/// Serpente titânica de plasma solar com múltiplos segmentos articulados.
/// Deixa rastros de magma ionizado e cospe rajadas triplas de plasma estelar.
class IgnisWyrmComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks
    implements SectorBoss {
  @override
  final double radius = 58.0;

  @override
  final double maxHp = 4200.0;

  @override
  late double hp;

  @override
  bool isDefeated = false;

  @override
  String get bossName => 'IGNIS WYRM // SOLAR LEVIATHAN';

  final int segmentCount = 8;
  final List<_WyrmSegment> segments = [];

  double _slitherTimer = 0.0;
  double _shootTimer = 0.0;
  double _trailTimer = 0.0;
  double _burstTimer = 0.0;
  double _currentSpeed = 115.0;
  double _deathTimer = 0.0;

  final Paint _headPaint = Paint()..style = PaintingStyle.fill;
  final Paint _segmentPaint = Paint()..style = PaintingStyle.fill;
  final Paint _glowPaint = Paint()..style = PaintingStyle.stroke;

  IgnisWyrmComponent({required Vector2 position}) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
    hp = maxHp;

    // Inicializa segmentos da cauda
    for (var i = 0; i < segmentCount; i++) {
      final segR = radius * (1.0 - (i * 0.07));
      segments.add(
        _WyrmSegment(
          position: position - Vector2(i * 35.0, 0),
          radius: segR.clamp(20.0, radius),
        ),
      );
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    game.activeBoss = this;
    game.playSfx('powerup.wav');
    game.triggerScreenShake(duration: 1.0, intensity: 22.0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) {
      _deathTimer += dt;
      if (_deathTimer >= 1.5) {
        removeFromParent();
      }
      return;
    }

    _slitherTimer += dt * 3.5;
    final hpFraction = (hp / maxHp).clamp(0.0, 1.0);
    _currentSpeed = hpFraction > 0.4 ? 120.0 : 160.0;

    // 1. Movimento ondulatório senoidal (slithering) em direção à jogadora
    final player = game.player;
    final toPlayer = player.position - position;
    final dist = toPlayer.length;
    final desiredAngle = math.atan2(toPlayer.y, toPlayer.x);

    // Adiciona ondulação orgânica de serpente
    final slitherOffset = math.sin(_slitherTimer) * 0.45;
    angle = desiredAngle + slitherOffset;

    final forward = Vector2(math.cos(angle), math.sin(angle));
    position += forward * (_currentSpeed * dt);

    _enforceSectorBounds();

    // 2. Cinemática Inversa dos Segmentos da Cauda
    Vector2 prevPos = position.clone();
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final toPrev = prevPos - seg.position;
      final segDist = toPrev.length;
      const targetSpacing = 38.0;

      if (segDist > targetSpacing) {
        final dir = toPrev / segDist;
        seg.position = prevPos - dir * targetSpacing;
      }
      prevPos = seg.position;
    }

    // 3. Deixa rastro de magma solar a partir do último segmento
    _trailTimer += dt;
    if (_trailTimer >= 0.35) {
      _trailTimer = 0.0;
      final tail = segments.last;
      game.world.add(
        SolarFireTrailComponent(
          position: tail.position.clone(),
          initialRadius: 28.0,
        ),
      );
    }

    // 4. Ataque: Disparo triplo de bolas de fogo de plasma
    _shootTimer += dt;
    final shootCadence = hpFraction > 0.4 ? 2.2 : 1.4;
    if (_shootTimer >= shootCadence && dist <= 850.0) {
      _shootTimer = 0.0;
      _firePlasmaBurst(forward);
    }

    // 5. Ataque Enraged: Erupção Solar em Espiral (HP < 40%)
    if (hpFraction <= 0.40) {
      _burstTimer += dt;
      if (_burstTimer >= 3.0) {
        _burstTimer = 0.0;
        _fireSolarNova();
      }
    }

    // Dano de colisão por toque na cabeça
    if (dist <= radius + player.radius) {
      player.takeHit(40.0);
      final push = (player.position - position).normalized();
      player.velocity += push * 350.0;
    }
  }

  void _firePlasmaBurst(Vector2 forward) {
    game.playSfx('dash.wav');
    final angles = [-0.25, 0.0, 0.25];
    final baseAngle = math.atan2(forward.y, forward.x);

    for (final aOffset in angles) {
      final shotAngle = baseAngle + aOffset;
      final shotDir = Vector2(math.cos(shotAngle), math.sin(shotAngle));
      game.world.add(
        EnemyBulletComponent(
          position: position + shotDir * (radius * 0.9),
          radius: 6.5,
          velocity: shotDir * 280.0,
          damage: 1.0,
          bulletColor: const Color(0xFFFF5722),
        ),
      );
    }
  }

  void _fireSolarNova() {
    game.playSfx('bomb_explode.wav');
    game.triggerScreenShake(duration: 0.4, intensity: 12.0);

    const projectileCount = 8;
    for (var i = 0; i < projectileCount; i++) {
      final a = (i * 2 * math.pi / projectileCount) + _slitherTimer;
      final dir = Vector2(math.cos(a), math.sin(a));
      game.world.add(
        EnemyBulletComponent(
          position: position + dir * radius,
          radius: 5.5,
          velocity: dir * 210.0,
          damage: 1.0,
          bulletColor: const Color(0xFFFFD700),
        ),
      );
    }
  }

  void _enforceSectorBounds() {
    position.x = position.x.clamp(radius, GameConstants.sectorWidth - radius);
    position.y = position.y.clamp(radius, GameConstants.sectorHeight - radius);
  }

  @override
  bool takeDamage(double damage, Vector2 hitPos) {
    if (isDefeated) return false;
    hp -= damage;

    game.spawnExplosionParticles(
      position: hitPos,
      colorChoices: [const Color(0xFFFF5722), const Color(0xFFFFD700), Colors.white],
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
        color: const Color(0xFFFFAB91),
        fontSize: 12.5,
      );
      return false;
    }
  }

  void _defeat() {
    isDefeated = true;
    hp = 0;
    game.onBossDefeatedSpeechCheck();
    game.addScore(8000);
    game.addRunCredits(800);
    game.playSfx('powerup.wav');
    game.triggerScreenShake(duration: 2.0, intensity: 28.0);

    // Explosão em cascata pelos segmentos
    for (final seg in segments) {
      game.spawnExplosionParticles(
        position: seg.position,
        colorChoices: [const Color(0xFFFF5722), const Color(0xFFFFD700), Colors.white],
        count: 12,
        minSize: 2.5,
        maxSize: 5.0,
        minSpeed: 40.0,
        maxSpeed: 140.0,
      );
    }

    // Drop garantido de Baú Cósmico Jackpot (5 recompensas)
    game.world.add(
      ChestComponent(
        position: position.clone(),
        tier: ChestTier.cosmic,
      ),
    );

    // Fonte de orbes grandes de stardust
    for (var i = 0; i < 6; i++) {
      final a = (i * 2 * math.pi / 6);
      final offset = Vector2(math.cos(a), math.sin(a)) * 30.0;
      game.world.add(
        XpOrbComponent(
          position: position + offset,
          type: XpOrbType.large,
        ),
      );
    }

    // Cores de memória da Valquíria
    for (var i = 0; i < 3; i++) {
      final a = (i * 2 * math.pi / 3);
      final offset = Vector2(math.cos(a), math.sin(a)) * 40.0;
      game.world.add(
        DropComponent(
          position: position + offset,
          type: DropType.memoryCore,
          initialVelocity: Vector2(math.cos(a), math.sin(a)) * 45.0,
        ),
      );
    }
    game.affinityManager.getAffinity(game.selectedValkyrie.id).addXp(200);
    game.hyperModeUnlocked = true;
    game.saveHyperModeState();

    if (game.isBossRushMode) {
      game.onBossRushBossDefeated(position.clone());
    } else {
      // Abre Portal de Hiperespaço para o Setor 3 (Graveyard)
      game.world.add(HyperspaceGateComponent(position: position.clone()));
    }

    game.spawnFloatingText(
      position + Vector2(0, -60),
      '🏆 SOLAR WYRM EXTINTO! HIPERESPAÇO ATIVADO!',
      color: const Color(0xFFFFD700),
      fontSize: 20.0,
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Renderiza segmentos da cauda primeiro (atrás da cabeça)
    for (var i = segments.length - 1; i >= 0; i--) {
      final seg = segments[i];
      final relPos = seg.position - position + (size / 2);
      final offset = relPos.toOffset();

      final t = i / segments.length;
      final segColor = Color.lerp(const Color(0xFFFF5722), const Color(0xFFD84315), t)!;
      _segmentPaint.color = segColor;

      canvas.drawCircle(offset, seg.radius, _segmentPaint);

      // Núcleo incandescente de plasma
      _segmentPaint.color = const Color(0xFFFFD700).withValues(alpha: 0.85);
      canvas.drawCircle(offset, seg.radius * 0.45, _segmentPaint);

      // Borda com brilho solar
      _glowPaint.color = const Color(0xFFFFAB40);
      _glowPaint.strokeWidth = 2.0;
      canvas.drawCircle(offset, seg.radius, _glowPaint);
    }

    // 2. Renderiza a Cabeça do Dragão Solar
    final center = (size / 2).toOffset();
    _headPaint.color = const Color(0xFFFF3D00);
    canvas.drawCircle(center, radius, _headPaint);

    // Placas de armadura solar
    _headPaint.color = const Color(0xFFBF360C);
    final armorPath = Path();
    armorPath.moveTo(center.dx - radius * 0.6, center.dy - radius * 0.5);
    armorPath.lineTo(center.dx + radius * 0.8, center.dy);
    armorPath.lineTo(center.dx - radius * 0.6, center.dy + radius * 0.5);
    armorPath.close();
    canvas.drawPath(armorPath, _headPaint);

    // Olhos incandescentes
    final eyePaint = Paint()..color = const Color(0xFFFFF9C4);
    canvas.drawCircle(center + const Offset(14, -12), 5.5, eyePaint);
    canvas.drawCircle(center + const Offset(14, 12), 5.5, eyePaint);

    Glow.orb(
      canvas,
      center + const Offset(14, -12),
      5.5,
      const Color(0xFFFFD700),
    );
    Glow.orb(
      canvas,
      center + const Offset(14, 12),
      5.5,
      const Color(0xFFFFD700),
    );
  }
}
