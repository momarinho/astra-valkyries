import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'asteroid.dart';
import 'enemy_ship.dart';
import 'enemy_bullet.dart';
import 'sector_boss.dart';

/// Status elementais inspirados em Dead Cells / Hades para reações e sinergias cruzadas
enum ElementalStatus {
  none,
  solarBurn,   // 🔥 Queimadura Solar (DoT térmico acumulativo)
  cryoFreeze,  // ❄️ Congelamento Criogênico (-50% velocidade de movimento/ataque)
  ionShock,    // ⚡ Choque Iônico (propaga arco elétrico para inimigos vizinhos)
  voidRupture, // 🟣 Ruptura do Vazio (+35% dano recebido de todas as fontes)
}

/// 1. Lâminas Orbitais (Aegis Sawblades -> Celestial Buzzsaw Ring)
/// Giram continuamente ao redor da nave bloqueando projéteis inimigos e serrando enxames.
class OrbitalSawbladeComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final int bladeIndex;
  final int totalBlades;
  final double orbitRadius;
  final double damagePerHit;
  final bool isEvolved;
  double lifeTimer;
  double orbitAngle = 0.0;
  final Map<PositionComponent, double> _hitCooldowns = {};

  OrbitalSawbladeComponent({
    required this.bladeIndex,
    required this.totalBlades,
    this.orbitRadius = 92.0,
    this.damagePerHit = 42.0,
    this.isEvolved = false,
    this.lifeTimer = 4.5,
  }) {
    anchor = Anchor.center;
    final r = isEvolved ? 16.0 : 12.0;
    size = Vector2.all(r * 2);
    orbitAngle = (bladeIndex * 2 * math.pi) / math.max(1, totalBlades);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) {
      removeFromParent();
      return;
    }

    lifeTimer -= dt;
    if (lifeTimer <= 0) {
      removeFromParent();
      return;
    }

    // Limpa cooldowns por alvo (permite serrar o mesmo alvo a cada 0.25s)
    final expired = <PositionComponent>[];
    _hitCooldowns.forEach((key, value) {
      final next = value - dt;
      if (next <= 0) {
        expired.add(key);
      } else {
        _hitCooldowns[key] = next;
      }
    });
    for (final k in expired) {
      _hitCooldowns.remove(k);
    }

    final angularSpeed = isEvolved ? 6.2 : 4.4;
    orbitAngle = (orbitAngle + angularSpeed * dt) % (2 * math.pi);
    angle += 12.0 * dt;

    final pPos = game.player.position;
    position.setValues(
      pPos.x + math.cos(orbitAngle) * orbitRadius,
      pPos.y + math.sin(orbitAngle) * orbitRadius,
    );
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is EnemyBulletComponent) {
      // Lâminas orbitais destroem projéteis inimigos!
      other.removeFromParent();
      game.spawnExplosionParticles(
        position: position,
        colorChoices: [const Color(0xFF00E5FF), Colors.white],
        count: 4,
        minSize: 1.5,
        maxSize: 2.5,
        minSpeed: 20,
        maxSpeed: 60,
      );
      return;
    }

    if (_hitCooldowns.containsKey(other)) return;
    _hitCooldowns[other] = 0.24;

    if (other is EnemyShipComponent) {
      other.applyElementalStatus(ElementalStatus.voidRupture, duration: 3.5);
      other.takeDamage(damagePerHit, position);
    } else if (other is AsteroidComponent) {
      if (other.takeDamage(damagePerHit, position)) {
        game.onAsteroidDestroyed(other.position, other.scoreValue);
      }
    } else if (other is SectorBoss) {
      other.takeDamage(damagePerHit, position);
    }
  }

  @override
  void render(Canvas canvas) {
    final r = size.x / 2;
    canvas.save();
    canvas.translate(r, r);

    final color = isEvolved ? const Color(0xFFFFD700) : const Color(0xFF00E5FF);
    final path = Path();
    const teeth = 8;
    for (var i = 0; i < teeth * 2; i++) {
      final a = (i * math.pi) / teeth;
      final rad = (i % 2 == 0) ? r : r * 0.55;
      final x = math.cos(a) * rad;
      final y = math.sin(a) * rad;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.28)
        ..style = PaintingStyle.fill,
    );
    Glow.strokePath(canvas, path, color, width: 1.8, intensity: 1.3);
    canvas.restore();
  }
}

/// 2. Corrente Elétrica (Tesla Arc Cannon -> Mjolnir Storm Conduit)
/// Renderiza o arco voltaico que salta entre múltiplos inimigos.
class TeslaLightningComponent extends PositionComponent {
  final List<Vector2> chainPoints;
  final Color arcColor;
  double lifeTimer = 0.22;

  TeslaLightningComponent({
    required this.chainPoints,
    this.arcColor = const Color(0xFF80D8FF),
  });

  @override
  void update(double dt) {
    super.update(dt);
    lifeTimer -= dt;
    if (lifeTimer <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (chainPoints.length < 2) return;
    final alpha = (lifeTimer / 0.22).clamp(0.0, 1.0);
    final path = Path()..moveTo(chainPoints.first.x, chainPoints.first.y);

    final rng = math.Random(chainPoints.length * 37);
    for (var i = 1; i < chainPoints.length; i++) {
      final prev = chainPoints[i - 1];
      final curr = chainPoints[i];
      final mid = (prev + curr) * 0.5 +
          Vector2((rng.nextDouble() - 0.5) * 18.0, (rng.nextDouble() - 0.5) * 18.0);
      path.lineTo(mid.x, mid.y);
      path.lineTo(curr.x, curr.y);
    }

    Glow.strokePath(
      canvas,
      path,
      arcColor.withValues(alpha: alpha),
      width: 2.4,
      intensity: 1.5,
    );
  }
}

/// 3. Bumerangue Quântico (Quantum Chakram -> Chronos Eclipse Glaive)
/// Atravessa os inimigos na ida e retorna acelerando para a nave causando dano dobrado.
class ChakramProjectileComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  Vector2 velocity;
  final double baseDamage;
  final bool isEvolved;
  double elapsed = 0.0;
  bool returning = false;
  final Set<PositionComponent> _hitOutbound = {};
  final Set<PositionComponent> _hitInbound = {};

  ChakramProjectileComponent({
    required Vector2 position,
    required this.velocity,
    required this.baseDamage,
    this.isEvolved = false,
  }) {
    this.position = position.clone();
    anchor = Anchor.center;
    final r = isEvolved ? 18.0 : 13.0;
    size = Vector2.all(r * 2);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) {
      removeFromParent();
      return;
    }

    elapsed += dt;
    angle += 15.0 * dt;

    if (!returning && elapsed >= 0.65) {
      returning = true;
    }

    if (returning) {
      final toPlayer = game.player.position - position;
      if (toPlayer.length < 28.0 || elapsed > 3.2) {
        removeFromParent();
        return;
      }
      final desiredVel = toPlayer.normalized() * (isEvolved ? 640.0 : 520.0);
      velocity.lerp(desiredVel, (8.0 * dt).clamp(0.0, 1.0));
    }

    position += velocity * dt;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    final hitSet = returning ? _hitInbound : _hitOutbound;
    if (hitSet.contains(other)) return;
    hitSet.add(other);

    final dmg = returning ? baseDamage * 1.65 : baseDamage;
    if (other is EnemyShipComponent) {
      if (isEvolved) {
        other.applyElementalStatus(ElementalStatus.cryoFreeze, duration: 3.0);
      }
      other.takeDamage(dmg, position);
    } else if (other is AsteroidComponent) {
      if (other.takeDamage(dmg, position)) {
        game.onAsteroidDestroyed(other.position, other.scoreValue);
      }
    } else if (other is SectorBoss) {
      other.takeDamage(dmg, position);
    }
  }

  @override
  void render(Canvas canvas) {
    final r = size.x / 2;
    canvas.save();
    canvas.translate(r, r);
    final color = isEvolved ? const Color(0xFFFFD700) : const Color(0xFF00E676);

    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.45,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }
}

/// 4. Aura Gravitacional Repulsora (Repulsor Gravity Aura -> Event Horizon Nova Pulse)
/// Pulso de área 360° ao redor da nave que causa dano, aplica Ruptura e repele enxames.
class GravityAuraPulseComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final double maxRadius;
  final double damage;
  final bool isEvolved;
  double elapsed = 0.0;
  final double duration = 0.35;
  bool _appliedDamage = false;

  GravityAuraPulseComponent({
    required Vector2 position,
    required this.maxRadius,
    required this.damage,
    this.isEvolved = false,
  }) {
    this.position = position.clone();
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) {
      removeFromParent();
      return;
    }

    position.setFrom(game.player.position);
    elapsed += dt;

    if (!_appliedDamage) {
      _appliedDamage = true;
      _triggerPulseImpact();
    }

    if (elapsed >= duration) {
      removeFromParent();
    }
  }

  void _triggerPulseImpact() {
    for (final e in List<EnemyShipComponent>.from(game.world.children.whereType<EnemyShipComponent>())) {
      final d = e.position.distanceTo(position);
      if (d <= maxRadius + e.radius) {
        e.applyElementalStatus(ElementalStatus.voidRupture, duration: 4.0);
        if (isEvolved) {
          e.applyElementalStatus(ElementalStatus.cryoFreeze, duration: 2.5);
        }
        e.takeDamage(damage, e.position);
        // Empurrão repulsor para afastar enxames da nave
        final pushDir = (e.position - position);
        if (pushDir.length > 0.1) {
          e.position += pushDir.normalized() * (isEvolved ? 48.0 : 28.0);
        }
      }
    }
    for (final a in List<AsteroidComponent>.from(game.world.children.whereType<AsteroidComponent>())) {
      final d = a.position.distanceTo(position);
      if (d <= maxRadius + a.radius) {
        if (a.takeDamage(damage * 0.85, a.position)) {
          game.onAsteroidDestroyed(a.position, a.scoreValue);
        }
      }
    }
    final boss = game.activeBoss;
    if (boss != null && !boss.isDefeated) {
      if (boss.position.distanceTo(position) <= maxRadius + boss.radius) {
        boss.takeDamage(damage, boss.position);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (elapsed / duration).clamp(0.0, 1.0);
    final curR = maxRadius * progress;
    final alpha = (1.0 - progress).clamp(0.0, 1.0);
    final color = isEvolved ? const Color(0xFFE040FB) : const Color(0xFF7C4DFF);

    canvas.drawCircle(
      Offset.zero,
      curR,
      Paint()
        ..color = color.withValues(alpha: 0.16 * alpha)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      curR,
      Paint()
        ..color = color.withValues(alpha: 0.85 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }
}

/// 5. Feixe Orbital Térmico (Solar Thermal Lance -> Helios Core Melter)
/// Raio contínuo de plasma solar que perfura toda a linha à frente aplicando Solar Burn.
class ThermalLanceBeamComponent extends PositionComponent {
  final Vector2 startPos;
  final Vector2 endPos;
  final bool isEvolved;
  double lifeTimer = 0.16;

  ThermalLanceBeamComponent({
    required this.startPos,
    required this.endPos,
    this.isEvolved = false,
  });

  @override
  void update(double dt) {
    super.update(dt);
    lifeTimer -= dt;
    if (lifeTimer <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alpha = (lifeTimer / 0.16).clamp(0.0, 1.0);
    final outerColor = isEvolved ? const Color(0xFFFFD700) : const Color(0xFFFF5722);
    canvas.drawLine(
      Offset(startPos.x, startPos.y),
      Offset(endPos.x, endPos.y),
      Paint()
        ..color = outerColor.withValues(alpha: 0.55 * alpha)
        ..strokeWidth = isEvolved ? 14.0 : 8.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(startPos.x, startPos.y),
      Offset(endPos.x, endPos.y),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.95 * alpha)
        ..strokeWidth = isEvolved ? 5.0 : 3.0
        ..strokeCap = StrokeCap.round,
    );
  }
}

/// 6. Drones Aliados Autônomos (Valkyrie Wingmen -> Seraphim Drone Squadron)
class WingmanDroneComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final int droneIndex;
  final double damage;
  final bool isEvolved;
  double lifeTimer = 6.0;
  double shootTimer = 0.0;
  double hoverAngle = 0.0;

  WingmanDroneComponent({
    required this.droneIndex,
    required this.damage,
    this.isEvolved = false,
  }) {
    anchor = Anchor.center;
    size = Vector2.all(16.0);
    hoverAngle = droneIndex * math.pi;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) {
      removeFromParent();
      return;
    }

    lifeTimer -= dt;
    if (lifeTimer <= 0) {
      removeFromParent();
      return;
    }

    hoverAngle += 2.2 * dt;
    final offset = Vector2(math.cos(hoverAngle) * 54.0, math.sin(hoverAngle) * 54.0);
    position.setFrom(game.player.position + offset);

    shootTimer -= dt;
    if (shootTimer <= 0) {
      shootTimer = isEvolved ? 0.28 : 0.45;
      _fireAtNearestTarget();
    }
  }

  void _fireAtNearestTarget() {
    Vector2? targetPos;
    double bestDist = 620.0;

    for (final e in game.world.children.whereType<EnemyShipComponent>()) {
      final d = e.position.distanceTo(position);
      if (d < bestDist) {
        bestDist = d;
        targetPos = e.position;
      }
    }
    if (targetPos == null && game.activeBoss != null && !game.activeBoss!.isDefeated) {
      targetPos = game.activeBoss!.position;
    }
    if (targetPos == null) {
      for (final a in game.world.children.whereType<AsteroidComponent>()) {
        final d = a.position.distanceTo(position);
        if (d < bestDist) {
          bestDist = d;
          targetPos = a.position;
        }
      }
    }

    final dir = (targetPos != null && (targetPos - position).length > 1.0)
        ? (targetPos - position).normalized()
        : game.player.forward;

    // Importa BulletComponent via game.world
    game.spawnWingmanBullet(
      position: position.clone(),
      velocity: dir * 560.0,
      damage: damage,
      isEvolved: isEvolved,
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(8, 8);
    final color = isEvolved ? const Color(0xFFFFD700) : const Color(0xFF00E5FF);
    final path = Path()
      ..moveTo(0, -8)
      ..lineTo(7, 6)
      ..lineTo(0, 3)
      ..lineTo(-7, 6)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.35));
    Glow.strokePath(canvas, path, color, width: 1.5, intensity: 1.2);
    canvas.restore();
  }
}

/// 7. Minas de Kiting Traseiras (Void Cluster Mines -> Abyssal Minefield Matrix)
/// Deixadas atrás da nave enquanto a jogadora recua; explodem aplicando Void Rupture + Cryo Freeze!
class PlayerClusterMineComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final double damage;
  final double blastRadius;
  final bool isEvolved;
  double lifeTimer = 6.5;
  double pulseTimer = 0.0;
  bool _detonated = false;

  PlayerClusterMineComponent({
    required Vector2 position,
    required this.damage,
    this.blastRadius = 115.0,
    this.isEvolved = false,
  }) {
    this.position = position.clone();
    anchor = Anchor.center;
    size = Vector2.all(20.0);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) {
      removeFromParent();
      return;
    }

    pulseTimer += dt * 6.0;
    lifeTimer -= dt;
    if (lifeTimer <= 0) {
      detonate();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is EnemyShipComponent || other is AsteroidComponent || other is SectorBoss) {
      detonate();
    }
  }

  void detonate() {
    if (_detonated) return;
    _detonated = true;
    removeFromParent();

    for (final e in List<EnemyShipComponent>.from(game.world.children.whereType<EnemyShipComponent>())) {
      if (e.position.distanceTo(position) <= blastRadius + e.radius) {
        e.applyElementalStatus(ElementalStatus.voidRupture, duration: 4.5);
        if (isEvolved) {
          e.applyElementalStatus(ElementalStatus.cryoFreeze, duration: 3.0);
        }
        e.takeDamage(damage, e.position);
      }
    }
    for (final a in List<AsteroidComponent>.from(game.world.children.whereType<AsteroidComponent>())) {
      if (a.position.distanceTo(position) <= blastRadius + a.radius) {
        if (a.takeDamage(damage, a.position)) {
          game.onAsteroidDestroyed(a.position, a.scoreValue);
        }
      }
    }
    final boss = game.activeBoss;
    if (boss != null && !boss.isDefeated && boss.position.distanceTo(position) <= blastRadius + boss.radius) {
      boss.takeDamage(damage, boss.position);
    }

    game.spawnExplosionParticles(
      position: position,
      colorChoices: [const Color(0xFFE040FB), const Color(0xFF00E5FF), Colors.white],
      count: 16,
      minSize: 2.0,
      maxSize: 4.5,
      minSpeed: 40.0,
      maxSpeed: 160.0,
    );
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(10, 10);
    final pulse = (math.sin(pulseTimer) + 1) * 0.5;
    final color = isEvolved ? const Color(0xFFFFD700) : const Color(0xFFE040FB);
    canvas.drawCircle(
      Offset.zero,
      7.0 + pulse * 2.5,
      Paint()..color = color.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      Offset.zero,
      5.0,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.restore();
  }
}
