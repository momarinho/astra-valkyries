import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'player.dart';
import 'enemy_bullet.dart';
import 'chest.dart';
import 'xp_orb.dart';
import 'drop.dart';
import 'sector_boss.dart';
import 'hyperspace_gate.dart';

/// Chefe Soberano do Setor 3 (Cemitério de Dreadnoughts):
/// SCRAP GOLIATH // IRON BEHEMOTH.
/// Um colosso mecânico forjado a partir de carcaças de encouraçados destruídos.
/// Possui um anel orbital de placas de sucata magnética, dispara rajadas de
/// metralha pesada e emite pulsos eletromagnéticos (EMP) que desestabilizam escudos.
class ScrapGoliathComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks
    implements SectorBoss {
  @override
  final double radius = 64.0;

  @override
  final double maxHp = 4500.0;

  @override
  late double hp;

  @override
  bool isDefeated = false;

  @override
  String get bossName => 'SCRAP GOLIATH // IRON BEHEMOTH';

  double _flakTimer = 0.0;
  double _empTimer = 0.0;
  double _shieldOrbitAngle = 0.0;
  double _empWaveRadius = 0.0;
  double _hitFlashTimer = 0.0;

  final Paint _hullPaint = Paint()
    ..color = const Color(0xFF0D1F18)
    ..style = PaintingStyle.fill;

  final Paint _platePaint = Paint()
    ..color = const Color(0xFF1B3B2B)
    ..style = PaintingStyle.fill;

  final Paint _empPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5;

  ScrapGoliathComponent({required Vector2 position}) {
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

    _shieldOrbitAngle += dt * 1.6;

    if (_empWaveRadius > 0) {
      _empWaveRadius += dt * 420.0;
      if (_empWaveRadius > 380.0) {
        _empWaveRadius = 0.0;
      }
    }

    final player = game.player;
    final toPlayer = player.position - position;
    final dist = toPlayer.length;
    final targetDir = dist > 1.0 ? toPlayer / dist : Vector2(0, 1);

    angle = math.atan2(targetDir.y, targetDir.x) + math.pi / 2;

    final hpRatio = (hp / maxHp).clamp(0.0, 1.0);
    final speed = hpRatio > 0.5 ? 52.0 : 74.0;
    position += targetDir * (speed * dt);
    _enforceBounds();

    // 1. Canhão de Metralha Magnética (Flak Salvo)
    _flakTimer += dt;
    final flakCooldown = hpRatio > 0.4 ? 2.1 : 1.45;
    if (_flakTimer >= flakCooldown && dist <= 880.0) {
      _flakTimer = 0.0;
      _fireMagneticFlak(targetDir);
    }

    // 2. Pulso Eletromagnético (EMP Shockwave + Anel de Estilhaços)
    _empTimer += dt;
    if (_empTimer >= 6.2) {
      _empTimer = 0.0;
      _triggerEmpShockwave(player, dist);
    }
  }

  void _fireMagneticFlak(Vector2 dir) {
    final baseAngle = math.atan2(dir.y, dir.x);
    const int count = 7;
    const double spread = 0.22;

    for (var i = 0; i < count; i++) {
      final a = baseAngle + (i - (count - 1) / 2) * spread;
      final shotDir = Vector2(math.cos(a), math.sin(a));
      game.world.add(
        EnemyBulletComponent(
          position: position + shotDir * (radius + 10.0),
          radius: 5.5,
          velocity: shotDir * 245.0,
          damage: 1.0,
          bulletColor: i.isEven ? const Color(0xFF00E676) : const Color(0xFFFFB300),
        ),
      );
    }
    game.playSfx('shoot.wav');
  }

  void _triggerEmpShockwave(PlayerComponent player, double dist) {
    _empWaveRadius = radius * 0.8;
    game.playSfx('bomb_explode.wav');
    game.triggerScreenShake(duration: 0.45, intensity: 14.0);

    // Anel de 12 projéteis EMP em 360 graus
    const int ringCount = 12;
    for (var i = 0; i < ringCount; i++) {
      final a = (i * 2 * math.pi / ringCount) + _shieldOrbitAngle;
      final dir = Vector2(math.cos(a), math.sin(a));
      game.world.add(
        EnemyBulletComponent(
          position: position + dir * (radius + 8.0),
          radius: 6.0,
          velocity: dir * 210.0,
          damage: 1.0,
          bulletColor: const Color(0xFF00E5FF),
        ),
      );
    }

    // Se a jogadora estiver perto do pulso EMP, sofre repulsão magnética
    if (dist <= 360.0 && dist > 1.0) {
      final pushDir = (player.position - position).normalized();
      player.velocity += pushDir * 260.0;
      game.spawnFloatingText(
        player.position + Vector2(0, -35),
        '⚡ EMP SHOCKWAVE!',
        color: const Color(0xFF00E676),
        fontSize: 14.0,
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
      colorChoices: [const Color(0xFF00E676), const Color(0xFFFFB300), Colors.white],
      count: 4,
      minSize: 1.5,
      maxSize: 3.5,
      minSpeed: 40.0,
      maxSpeed: 110.0,
    );

    if (hp <= 0) {
      _defeat();
      return true;
    } else {
      game.spawnFloatingText(
        hitPos,
        '-${damage.toInt()}',
        color: const Color(0xFF69F0AE),
        fontSize: 12.5,
      );
      return false;
    }
  }

  void _defeat() {
    isDefeated = true;
    hp = 0;
    game.sectorMap?.isBossDefeated = true;

    game.addScore(10000);
    game.addRunCredits(1000);
    game.playSfx('powerup.wav');
    game.triggerScreenShake(duration: 2.0, intensity: 28.0);

    game.spawnExplosionParticles(
      position: position,
      colorChoices: [const Color(0xFF00E676), const Color(0xFFFFD700), Colors.white],
      count: 55,
      minSize: 3.0,
      maxSize: 6.5,
      minSpeed: 60.0,
      maxSpeed: 260.0,
    );

    // Baú Cósmico Jackpot garantido
    game.world.add(
      ChestComponent(
        position: position.clone(),
        tier: ChestTier.cosmic,
      ),
    );

    // Chuva de Orbes Grandes de XP
    for (var i = 0; i < 5; i++) {
      final a = (i * 2 * math.pi / 5);
      final offset = Vector2(math.cos(a), math.sin(a)) * 42.0;
      game.world.add(XpOrbComponent(position: position + offset, type: XpOrbType.large));
    }

    // 2 Núcleos de Memória para evolução de vínculo
    for (var i = 0; i < 2; i++) {
      final a = i * math.pi;
      final offset = Vector2(math.cos(a), math.sin(a)) * 35.0;
      game.world.add(
        DropComponent(
          position: position + offset,
          type: DropType.memoryCore,
          initialVelocity: Vector2(math.cos(a), math.sin(a)) * 35.0,
        ),
      );
    }
    game.affinityManager.getAffinity(game.selectedValkyrie.id).addXp(180);

    if (game.isBossRushMode) {
      game.onBossRushBossDefeated(position.clone());
    } else {
      game.world.add(HyperspaceGateComponent(position: position.clone()));
    }

    game.spawnFloatingText(
      position + Vector2(0, -60),
      '🏆 SCRAP GOLIATH DESMANTELADO! HIPERESPAÇO ABERTO!',
      color: const Color(0xFF00E676),
      fontSize: 20.0,
    );

    removeFromParent();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (isDefeated) return;
    if (other is PlayerComponent) {
      other.takeHit(40.0);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = (size / 2).toOffset();
    final isFlashing = _hitFlashTimer > 0;
    final strokeColor = isFlashing ? Colors.white : const Color(0xFF00E676);

    // 1. Onda de Choque EMP Expansiva (se ativa)
    if (_empWaveRadius > 0) {
      final alpha = (1.0 - (_empWaveRadius / 380.0)).clamp(0.0, 1.0);
      _empPaint.color = const Color(0xFF00E5FF).withValues(alpha: alpha * 0.8);
      canvas.drawCircle(center, _empWaveRadius, _empPaint);
    }

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // 2. Casco Octogonal Pesado de Sucata Militar
    final hullPath = Path()
      ..moveTo(0, -radius * 1.1)
      ..lineTo(radius * 0.75, -radius * 0.65)
      ..lineTo(radius * 1.0, 0)
      ..lineTo(radius * 0.8, radius * 0.75)
      ..lineTo(0, radius * 0.95)
      ..lineTo(-radius * 0.8, radius * 0.75)
      ..lineTo(-radius * 1.0, 0)
      ..lineTo(-radius * 0.75, -radius * 0.65)
      ..close();

    canvas.drawPath(hullPath, _hullPaint);
    Glow.strokePath(canvas, hullPath, strokeColor, width: 3.0, intensity: 1.5);

    // 3. Reator EMP Central
    Glow.orb(
      canvas,
      Offset.zero,
      radius * 0.35,
      isFlashing ? Colors.white : const Color(0xFF00E676),
    );

    canvas.restore();

    // 4. Anel Orbital de 6 Placas de Blindagem Magnética (no espaço da entidade)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-angle + _shieldOrbitAngle);

    for (var i = 0; i < 6; i++) {
      final a = i * (math.pi / 3);
      final plateCenter = Offset(math.cos(a) * (radius * 1.22), math.sin(a) * (radius * 1.22));
      final rect = Rect.fromCenter(center: plateCenter, width: 18.0, height: 10.0);
      canvas.drawRect(rect, _platePaint);
      Glow.strokeCircle(canvas, plateCenter, 9.0, const Color(0xFFFFB300), width: 1.5, intensity: 1.0);
    }

    canvas.restore();
  }
}
