import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';
import 'drop.dart';
import 'xp_orb.dart';
import 'magma_hazard.dart';

enum AsteroidVariant {
  standard,    // Rocha cinza-azulada que divide em menores
  crystalline, // Prisma de cristal que explode em chuva torrencial de XP
  magma,       // Rocha incandescente que cria poça de plasma térmico ao morrer
  golden,      // Asteroide dourado lendário (Easter Egg) com stardust e sucata
}

class AsteroidComponent extends PositionComponent with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  AsteroidsGame? testGame;
  final double radius;
  final Vector2 velocity;
  final AsteroidVariant variant;
  
  late final int numPoints;
  late final List<double> pointsOffsets;
  late final double rotationSpeed;
  late final Path cachedPath;

  late double maxHp;
  late double hp;
  double hitFlashTimer = 0.0;

  int get scoreValue {
    final base = (radius <= GameConstants.asteroidMinRadius * 1.25)
        ? 300
        : (radius <= GameConstants.asteroidMinRadius * 2.2 ? 150 : 50);

    if (variant == AsteroidVariant.crystalline) return (base * 1.5).toInt();
    if (variant == AsteroidVariant.magma) return (base * 1.3).toInt();
    if (variant == AsteroidVariant.golden) return base * 5;
    return base;
  }

  AsteroidComponent({
    required this.radius,
    required Vector2 position,
    required this.velocity,
    this.variant = AsteroidVariant.standard,
  }) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
    
    // Scale HP with asteroid size
    if (radius > GameConstants.asteroidMinRadius * 2.2) {
      maxHp = 90.0;
    } else if (radius > GameConstants.asteroidMinRadius * 1.2) {
      maxHp = 50.0;
    } else {
      maxHp = 25.0;
    }

    if (variant == AsteroidVariant.magma) {
      maxHp *= 1.35; // Magma asteroids are more durable
    } else if (variant == AsteroidVariant.crystalline) {
      maxHp *= 0.85; // Crystalline asteroids are more brittle
    }

    hp = maxHp;

    final random = math.Random();
    numPoints = variant == AsteroidVariant.crystalline
        ? (random.nextInt(3) + 6) // Geometric 6 to 8 facets
        : (random.nextInt(7) + 8); // 8 to 14 points
    pointsOffsets = List.generate(
      numPoints,
      (_) => 0.75 + random.nextDouble() * 0.5,
    );
    
    rotationSpeed = (-40.0 + random.nextDouble() * 80.0) * math.pi / 180.0;
    angle = random.nextDouble() * 2 * math.pi;

    // Pre-bake the asteroid's outer perimeter path to avoid reallocations on every frame
    final p = Path();
    for (var i = 0; i < numPoints; i++) {
      final pointAngle = (2 * math.pi * i) / numPoints;
      final r = radius * pointsOffsets[i];
      final x = r * math.cos(pointAngle);
      final y = r * math.sin(pointAngle);
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();
    cachedPath = p;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  bool shouldPrune(Vector2 playerPosition) {
    return position.distanceTo(playerPosition) > GameConstants.proximityDespawnRadius;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (hitFlashTimer > 0) {
      hitFlashTimer = math.max(0.0, hitFlashTimer - dt);
    }
    position += velocity * dt;
    angle += rotationSpeed * dt;

    try {
      final g = testGame ?? (findGame() as AsteroidsGame?) ?? (isMounted ? game : null);
      if (g != null && g.state == GameState.playing) {
        if (shouldPrune(g.player.position)) {
          removeFromParent();
          return;
        }
      }
    } catch (_) {}

    enforceSectorBounds();
  }

  bool takeDamage(double damage, Vector2 hitPos) {
    hp -= damage;
    hitFlashTimer = 0.12;

    final List<Color> sparkColors = variant == AsteroidVariant.crystalline
        ? [Colors.cyanAccent, const Color(0xFFE040FB), Colors.white]
        : (variant == AsteroidVariant.magma
            ? [Colors.deepOrangeAccent, Colors.amberAccent, Colors.yellow]
            : [Colors.orangeAccent, Colors.white, Colors.grey]);

    game.spawnExplosionParticles(
      position: hitPos,
      colorChoices: sparkColors,
      count: 4,
      minSize: 1.5,
      maxSize: 3.0,
      minSpeed: 30.0,
      maxSpeed: 90.0,
    );

    if (hp <= 0) {
      split();
      return true; // Destroyed
    } else {
      game.spawnFloatingText(
        hitPos,
        '-${damage.toInt()}',
        color: variant == AsteroidVariant.magma ? Colors.deepOrangeAccent : Colors.orangeAccent,
        fontSize: 11.5,
      );
      return false; // Still alive
    }
  }

  void enforceSectorBounds() {
    const maxX = GameConstants.sectorWidth;
    const maxY = GameConstants.sectorHeight;

    if (position.x < radius && velocity.x < 0) {
      position.x = radius;
      velocity.x = -velocity.x;
    } else if (position.x > maxX - radius && velocity.x > 0) {
      position.x = maxX - radius;
      velocity.x = -velocity.x;
    }

    if (position.y < radius && velocity.y < 0) {
      position.y = radius;
      velocity.y = -velocity.y;
    } else if (position.y > maxY - radius && velocity.y > 0) {
      position.y = maxY - radius;
      velocity.y = -velocity.y;
    }
  }

  void wrapAround() => enforceSectorBounds();

  @override
  void render(Canvas canvas) {
    // Fast viewport culling: discard rendering if completely off the screen
    try {
      final camPos = (testGame ?? game).camera.viewfinder.position;
      final dx = (position.x - camPos.x).abs();
      final dy = (position.y - camPos.y).abs();
      if (dx > 760 + radius || dy > 460 + radius) return;
    } catch (_) {}

    canvas.translate(radius, radius);

    final isFlashing = hitFlashTimer > 0;
    final path = cachedPath;

    // Interior shading based on variant
    if (variant == AsteroidVariant.crystalline) {
      final fillPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: isFlashing ? 0.45 : 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Facet interior crystal lines
      final facetPaint = Paint()
        ..color = const Color(0xFFE040FB).withValues(alpha: isFlashing ? 0.8 : 0.4)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < numPoints; i += 2) {
        final pointAngle = (2 * math.pi * i) / numPoints;
        final r = radius * pointsOffsets[i];
        canvas.drawLine(Offset.zero, Offset(r * math.cos(pointAngle), r * math.sin(pointAngle)), facetPaint);
      }

      Glow.strokePath(
        canvas,
        path,
        isFlashing ? Colors.white : const Color(0xFF00E5FF),
        width: isFlashing ? GameConstants.lineWidth * 2.0 : GameConstants.lineWidth * 1.3,
        intensity: isFlashing ? 1.8 : 1.2,
      );
    } else if (variant == AsteroidVariant.magma) {
      final fillPaint = Paint()
        ..color = const Color(0xFF260C05).withValues(alpha: 0.95)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Molten veins
      final veinPaint = Paint()
        ..color = isFlashing ? Colors.white : const Color(0xFFFF5722)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < numPoints; i += 3) {
        final pointAngle = (2 * math.pi * i) / numPoints;
        final r = radius * pointsOffsets[i] * 0.7;
        canvas.drawLine(Offset.zero, Offset(r * math.cos(pointAngle), r * math.sin(pointAngle)), veinPaint);
      }

      Glow.strokePath(
        canvas,
        path,
        isFlashing ? Colors.white : const Color(0xFFFF3D00),
        width: isFlashing ? GameConstants.lineWidth * 2.2 : GameConstants.lineWidth * 1.4,
        intensity: isFlashing ? 1.9 : 1.3,
      );
    } else if (variant == AsteroidVariant.golden) {
      // Golden Asteroid: Radiant metallic gold hull with bright solar glow
      final fillPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: isFlashing ? 0.6 : 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      final strokeColor = isFlashing ? Colors.white : const Color(0xFFFFD700);
      Glow.strokePath(
        canvas,
        path,
        strokeColor,
        width: isFlashing ? GameConstants.lineWidth * 2.2 : GameConstants.lineWidth * 1.5,
        intensity: 2.0,
      );
    } else {
      // Standard rock
      if (isFlashing) {
        final fillPaint = Paint()
          ..color = Colors.redAccent.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, fillPaint);
      }

      Glow.strokePath(
        canvas,
        path,
        isFlashing ? Colors.redAccent : const Color(0xFFDDEBFF),
        width: isFlashing ? GameConstants.lineWidth * 1.8 : GameConstants.lineWidth,
        intensity: isFlashing ? 1.6 : 0.9,
      );
    }
  }

  void split() {
    removeFromParent();

    // 0. Golden Asteroid Variant (Easter Egg)
    if (variant == AsteroidVariant.golden) {
      game.playSfx('powerup.wav');
      game.triggerScreenShake(duration: 0.35, intensity: radius * 0.25);
      game.spawnExplosionParticles(
        position: position,
        colorChoices: [const Color(0xFFFFD700), Colors.white, const Color(0xFFFFF176)],
        count: 36,
        minSize: 3.0,
        maxSize: 6.0,
        minSpeed: 80.0,
        maxSpeed: 280.0,
      );
      game.addScrap(100);
      game.spawnFloatingText(
        position + Vector2(0, -25),
        '🌟 GOLDEN ASTEROID SHATTERED! +100 SCRAP!',
        color: const Color(0xFFFFD700),
        fontSize: 16.0,
      );
      // Spawns 5 large XP orbs
      for (var i = 0; i < 5; i++) {
        final a = (i * 2 * math.pi / 5);
        final offset = Vector2(math.cos(a), math.sin(a)) * (radius * 0.5);
        game.world.add(XpOrbComponent(position: position + offset, type: XpOrbType.large));
      }
      return;
    }

    // 1. Crystal Variant: Shower of XP and crystal shatter
    if (variant == AsteroidVariant.crystalline) {
      game.playSfx('asteroid_split.wav');
      game.triggerScreenShake(duration: 0.25, intensity: radius * 0.2);

      game.spawnExplosionParticles(
        position: position,
        colorChoices: [const Color(0xFF00E5FF), const Color(0xFFE040FB), Colors.white, Colors.cyanAccent],
        count: 24,
        minSize: 2.0,
        maxSize: 4.5,
        minSpeed: 60.0,
        maxSpeed: 220.0,
      );

      // Stardust Rain: spawns 7 to 9 XP orbs!
      const int xpCount = 8;
      for (var i = 0; i < xpCount; i++) {
        final angle = (2 * math.pi * i) / xpCount;
        final offset = Vector2(math.cos(angle), math.sin(angle)) * (12.0 + math.Random().nextDouble() * 15.0);
        game.world.add(
          XpOrbComponent(
            position: position + offset,
            type: (i % 3 == 0) ? XpOrbType.medium : XpOrbType.small,
          ),
        );
      }

      game.spawnFloatingText(
        position + Vector2(0, -20),
        'CRYSTAL SHATTER! (+XP)',
        color: const Color(0xFF00E5FF),
        fontSize: 12.5,
      );
      return; // Crystalline asteroids don't divide
    }

    // 2. Magma Variant: Thermal pool eruption
    if (variant == AsteroidVariant.magma) {
      game.playSfx('bomb_explode.wav');
      game.triggerScreenShake(duration: 0.3, intensity: radius * 0.25);

      game.spawnExplosionParticles(
        position: position,
        colorChoices: [Colors.deepOrangeAccent, Colors.orange, Colors.amberAccent, Colors.yellow],
        count: 28,
        minSize: 2.5,
        maxSize: 5.0,
        minSpeed: 70.0,
        maxSpeed: 240.0,
      );

      // Spawns persistent thermal magma pool hazard
      game.world.add(
        MagmaHazardComponent(
          position: position.clone(),
          radius: math.max(60.0, radius * 1.4),
          duration: 3.5,
        ),
      );

      game.spawnFloatingText(
        position + Vector2(0, -20),
        'THERMAL ERUPTION!',
        color: const Color(0xFFFF5722),
        fontSize: 12.5,
      );
    } else {
      // Standard explosion particles & screen shake
      final numParticles = math.max(8, (radius * 0.8).toInt());
      game.spawnExplosionParticles(
        position: position,
        colorChoices: [Colors.white, Colors.orange, Colors.yellow, Colors.grey],
        count: numParticles,
        minSize: 2.0,
        maxSize: 4.0,
        minSpeed: 40.0,
        maxSpeed: 180.0,
      );
      game.triggerScreenShake(duration: 0.15, intensity: radius * 0.15);
    }

    // Standard XP drop
    final XpOrbType orbType;
    if (radius > GameConstants.asteroidMinRadius * 2.2) {
      orbType = XpOrbType.large;
    } else if (radius > GameConstants.asteroidMinRadius * 1.2) {
      orbType = XpOrbType.medium;
    } else {
      orbType = XpOrbType.small;
    }
    game.world.add(XpOrbComponent(position: position.clone(), type: orbType));

    final random = math.Random();
    final activeDrops = game.world.children.whereType<DropComponent>().length;
    double dropChance = 0.05;
    if (radius >= 50.0) {
      dropChance = 0.25;
    } else if (radius >= 30.0) {
      dropChance = 0.12;
    }

    if (activeDrops < 3 && random.nextDouble() < dropChance) {
      final roll = random.nextDouble();
      final hpRatio = game.player.hpPercent;
      final healthThreshold = hpRatio < 0.5 ? 0.65 : 0.85;

      DropType dropType;
      if (roll >= healthThreshold) {
        dropType = DropType.health;
      } else if (roll < 0.35) {
        dropType = DropType.lunarSample;
      } else if (roll < 0.60) {
        dropType = DropType.rareHelium;
      } else if (roll < 0.78) {
        dropType = DropType.shield;
      } else if (roll < 0.90) {
        dropType = DropType.darkMatter;
      } else {
        dropType = DropType.vortexSurge; // Raro Drop Especial estilo Vampire Survivors
      }

      final driftAngle = random.nextDouble() * 2 * math.pi;
      final dropVel = Vector2(math.cos(driftAngle), math.sin(driftAngle)) * 25.0;

      game.world.add(
        DropComponent(
          position: position.clone(),
          type: dropType,
          initialVelocity: dropVel,
        ),
      );
    }

    if (radius <= GameConstants.asteroidMinRadius) {
      return;
    }

    // Split into two smaller asteroids of the same variant
    final splitAngle = 20.0 + random.nextDouble() * 30.0;
    final radAngle = splitAngle * math.pi / 180.0;

    final velocityA = velocity.clone()..rotate(radAngle);
    final velocityB = velocity.clone()..rotate(-radAngle);
    final newRadius = radius - GameConstants.asteroidMinRadius;

    final asteroidA = AsteroidComponent(
      radius: newRadius,
      position: position.clone(),
      velocity: velocityA * 1.2,
      variant: variant,
    );
    
    final asteroidB = AsteroidComponent(
      radius: newRadius,
      position: position.clone(),
      velocity: velocityB * 1.2,
      variant: variant,
    );

    game.world.add(asteroidA);
    game.world.add(asteroidB);
  }
}
