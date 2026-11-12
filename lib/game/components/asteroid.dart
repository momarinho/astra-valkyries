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
import 'enemy_ship.dart';
import 'advanced_weapons.dart';
import '../../services/achievement_service.dart';

enum AsteroidVariant {
  standard, // Rocha cinza-azulada que divide em menores
  crystalline, // Prisma de cristal que explode em chuva torrencial de XP
  magma, // Rocha incandescente que cria poça de plasma térmico ao morrer
  golden, // Asteroide dourado lendário (Easter Egg) com stardust e sucata
  titanium, // Veio de titânio (DRG Survivor) com sucata e retardamento tático
}

class AsteroidComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  AsteroidsGame? testGame;
  final double radius;
  final Vector2 velocity;
  final AsteroidVariant variant;

  late final int numPoints;
  late final List<double> pointsOffsets;
  late final double rotationSpeed;
  late final Path cachedPath;
  late final List<Offset> cachedVertices;
  late final List<Offset> cachedNormals;

  late double maxHp;
  late double hp;
  double hitFlashTimer = 0.0;

  // Zero-GC Cached Paint instances for high-performance asteroid rendering (60-120 FPS)
  static final Paint _sharedFillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _sharedStrokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _sunRimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _specularPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _shadowRimPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _facetShadePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  int get scoreValue {
    final base = (radius <= GameConstants.asteroidMinRadius * 1.25)
        ? 300
        : (radius <= GameConstants.asteroidMinRadius * 2.2 ? 150 : 50);

    if (variant == AsteroidVariant.crystalline) return (base * 1.5).toInt();
    if (variant == AsteroidVariant.magma) return (base * 1.3).toInt();
    if (variant == AsteroidVariant.golden) return base * 5;
    if (variant == AsteroidVariant.titanium) return (base * 2.0).toInt();
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
    } else if (variant == AsteroidVariant.titanium) {
      maxHp *= 1.60; // Veio de titânio reforçado
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

    // Pre-bake the asteroid's outer perimeter path, vertices and edge outward normals
    final p = Path();
    final vertices = <Offset>[];
    for (var i = 0; i < numPoints; i++) {
      final pointAngle = (2 * math.pi * i) / numPoints;
      final r = radius * pointsOffsets[i];
      final x = r * math.cos(pointAngle);
      final y = r * math.sin(pointAngle);
      vertices.add(Offset(x, y));
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();
    cachedPath = p;
    cachedVertices = vertices;

    // Outward edge normals oriented for clockwise vertices in screen coordinates (Y down)
    final normals = <Offset>[];
    for (var i = 0; i < numPoints; i++) {
      final v1 = vertices[i];
      final v2 = vertices[(i + 1) % numPoints];
      final dx = v2.dx - v1.dx;
      final dy = v2.dy - v1.dy;
      final nx = dy;
      final ny = -dx;
      final len = math.sqrt(nx * nx + ny * ny);
      if (len > 0.0001) {
        normals.add(Offset(nx / len, ny / len));
      } else {
        normals.add(const Offset(0.0, -1.0));
      }
    }
    cachedNormals = normals;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void onMount() {
    super.onMount();
    game.activeAsteroids.add(this);
  }

  @override
  void onRemove() {
    game.activeAsteroids.remove(this);
    super.onRemove();
  }

  bool shouldPrune(Vector2 playerPosition) {
    return position.distanceTo(playerPosition) >
        GameConstants.proximityDespawnRadius;
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
      final g =
          testGame ??
          (findGame() as AsteroidsGame?) ??
          (isMounted ? game : null);
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
        color: variant == AsteroidVariant.magma
            ? Colors.deepOrangeAccent
            : Colors.orangeAccent,
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

    // Interior shading based on variant (Zero-GC Reusable Paints)
    if (variant == AsteroidVariant.crystalline) {
      _sharedFillPaint.color = const Color(
        0xFF00E5FF,
      ).withValues(alpha: isFlashing ? 0.45 : 0.15);
      canvas.drawPath(path, _sharedFillPaint);

      // Facet interior crystal lines
      _sharedStrokePaint.color = const Color(
        0xFFE040FB,
      ).withValues(alpha: isFlashing ? 0.8 : 0.4);
      _sharedStrokePaint.strokeWidth = 1.0;
      for (var i = 0; i < numPoints; i += 2) {
        final pointAngle = (2 * math.pi * i) / numPoints;
        final r = radius * pointsOffsets[i];
        canvas.drawLine(
          Offset.zero,
          Offset(r * math.cos(pointAngle), r * math.sin(pointAngle)),
          _sharedStrokePaint,
        );
      }

      Glow.strokePath(
        canvas,
        path,
        isFlashing ? Colors.white : const Color(0xFF00E5FF),
        width: isFlashing
            ? GameConstants.lineWidth * 2.0
            : GameConstants.lineWidth * 1.3,
        intensity: isFlashing ? 1.8 : 1.2,
      );
    } else if (variant == AsteroidVariant.magma) {
      _sharedFillPaint.color = const Color(0xFF260C05).withValues(alpha: 0.95);
      canvas.drawPath(path, _sharedFillPaint);

      // Molten veins
      _sharedStrokePaint.color = isFlashing
          ? Colors.white
          : const Color(0xFFFF5722);
      _sharedStrokePaint.strokeWidth = 1.5;
      for (var i = 0; i < numPoints; i += 3) {
        final pointAngle = (2 * math.pi * i) / numPoints;
        final r = radius * pointsOffsets[i] * 0.7;
        canvas.drawLine(
          Offset.zero,
          Offset(r * math.cos(pointAngle), r * math.sin(pointAngle)),
          _sharedStrokePaint,
        );
      }

      Glow.strokePath(
        canvas,
        path,
        isFlashing ? Colors.white : const Color(0xFFFF3D00),
        width: isFlashing
            ? GameConstants.lineWidth * 2.2
            : GameConstants.lineWidth * 1.4,
        intensity: isFlashing ? 1.9 : 1.3,
      );
    } else if (variant == AsteroidVariant.golden) {
      // Golden Asteroid: Radiant metallic gold hull with bright solar glow
      _sharedFillPaint.color = const Color(
        0xFFFFD700,
      ).withValues(alpha: isFlashing ? 0.6 : 0.25);
      canvas.drawPath(path, _sharedFillPaint);

      final strokeColor = isFlashing ? Colors.white : const Color(0xFFFFD700);
      Glow.strokePath(
        canvas,
        path,
        strokeColor,
        width: isFlashing
            ? GameConstants.lineWidth * 2.2
            : GameConstants.lineWidth * 1.5,
        intensity: 2.0,
      );
    } else if (variant == AsteroidVariant.titanium) {
      // Titanium Ore Asteroid: Slate-metallic hull with bright cyan-titanium mineral seams
      _sharedFillPaint.color = isFlashing
          ? Colors.white
          : const Color(0xFF101B2B).withValues(alpha: 0.94);
      canvas.drawPath(path, _sharedFillPaint);

      _sharedStrokePaint.color = isFlashing
          ? Colors.white
          : const Color(0xFF80D8FF).withValues(alpha: 0.85);
      _sharedStrokePaint.strokeWidth = 1.8;
      for (var i = 0; i < numPoints; i += 2) {
        final pointAngle = (2 * math.pi * i) / numPoints;
        final r = radius * pointsOffsets[i] * 0.75;
        canvas.drawLine(
          Offset.zero,
          Offset(r * math.cos(pointAngle), r * math.sin(pointAngle)),
          _sharedStrokePaint,
        );
      }

      Glow.strokePath(
        canvas,
        path,
        isFlashing ? Colors.white : const Color(0xFF00E5FF),
        width: isFlashing
            ? GameConstants.lineWidth * 2.2
            : GameConstants.lineWidth * 1.5,
        intensity: 1.8,
      );
    } else {
      // Standard rock: preenchimento opaco escuro para ocluir estrelas/bioma + borda luminosa nítida
      _sharedFillPaint.color = isFlashing
          ? Colors.white.withValues(alpha: 0.90)
          : const Color(0xFF0C101A).withValues(alpha: 0.88);
      canvas.drawPath(path, _sharedFillPaint);

      // Chiseled internal facet lines reacting to star light
      _renderStandardFacets(canvas, isFlashing);

      Glow.strokePath(
        canvas,
        path,
        isFlashing ? Colors.white : const Color(0xFFDDEBFF),
        width: isFlashing
            ? GameConstants.lineWidth * 2.2
            : GameConstants.lineWidth * 1.4,
        intensity: isFlashing ? 1.7 : 1.1,
      );
    }

    // SPRINT 56: Iluminação Estelar Direcional nos Asteroides (Sunlight Normal Shading)
    _renderSunlightShading(canvas, isFlashing);
  }

  void _renderStandardFacets(Canvas canvas, bool isFlashing) {
    Vector2 starLightDir;
    Color starColor;
    try {
      final g =
          testGame ??
          (findGame() as AsteroidsGame?) ??
          (isMounted ? game : null);
      if (g != null) {
        starLightDir = g.currentSector.starLightDirection;
        starColor = g.currentSector.starColor;
      } else {
        starLightDir = Vector2(-0.7071, -0.7071);
        starColor = const Color(0xFFE3F2FD);
      }
    } catch (_) {
      starLightDir = Vector2(-0.7071, -0.7071);
      starColor = const Color(0xFFE3F2FD);
    }

    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    final localSunX = starLightDir.x * cosA + starLightDir.y * sinA;
    final localSunY = -starLightDir.x * sinA + starLightDir.y * cosA;

    _facetShadePaint.strokeWidth = 1.0;
    for (var i = 0; i < numPoints; i += 2) {
      final v = cachedVertices[i];
      final norm = cachedNormals[i];
      final dot = norm.dx * localSunX + norm.dy * localSunY;

      if (dot > 0.1) {
        _facetShadePaint.color = starColor.withValues(
          alpha: isFlashing ? 0.6 : 0.20 * dot,
        );
      } else {
        _facetShadePaint.color = const Color(
          0xFF04070F,
        ).withValues(alpha: isFlashing ? 0.3 : 0.45);
      }
      canvas.drawLine(
        Offset.zero,
        Offset(v.dx * 0.70, v.dy * 0.70),
        _facetShadePaint,
      );
    }
  }

  void _renderSunlightShading(Canvas canvas, bool isFlashing) {
    Vector2 starLightDir;
    Color starColor;
    try {
      final g =
          testGame ??
          (findGame() as AsteroidsGame?) ??
          (isMounted ? game : null);
      if (g != null) {
        starLightDir = g.currentSector.starLightDirection;
        starColor = g.currentSector.starColor;
      } else {
        starLightDir = Vector2(-0.7071, -0.7071);
        starColor = const Color(0xFFE3F2FD);
      }
    } catch (_) {
      starLightDir = Vector2(-0.7071, -0.7071);
      starColor = const Color(0xFFE3F2FD);
    }

    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    final localSunX = starLightDir.x * cosA + starLightDir.y * sinA;
    final localSunY = -starLightDir.x * sinA + starLightDir.y * cosA;

    for (var i = 0; i < numPoints; i++) {
      final v1 = cachedVertices[i];
      final v2 = cachedVertices[(i + 1) % numPoints];
      final norm = cachedNormals[i];
      final dot = norm.dx * localSunX + norm.dy * localSunY;

      if (dot > 0.05) {
        // Face voltada para a estrela celestial do setor (Sunlit Rim Highlight)
        final k = dot.clamp(0.0, 1.0);
        final rimAlpha = isFlashing ? 0.95 : (0.45 + 0.50 * k);

        Color baseRim;
        switch (variant) {
          case AsteroidVariant.crystalline:
            baseRim = const Color(0xFF00E5FF);
            break;
          case AsteroidVariant.magma:
            baseRim = const Color(0xFFFF9100);
            break;
          case AsteroidVariant.golden:
            baseRim = const Color(0xFFFFD700);
            break;
          case AsteroidVariant.titanium:
            baseRim = const Color(0xFF80D8FF);
            break;
          case AsteroidVariant.standard:
            baseRim = const Color(0xFFDDEBFF);
            break;
        }

        final rimColor = isFlashing
            ? Colors.white
            : Color.lerp(baseRim, starColor, 0.45)!;

        _sunRimPaint.color = rimColor.withValues(
          alpha: rimAlpha.clamp(0.0, 1.0),
        );
        _sunRimPaint.strokeWidth = GameConstants.lineWidth * (1.2 + 1.3 * k);
        canvas.drawLine(v1, v2, _sunRimPaint);

        // Realce especular puro no ápice das arestas frontais
        if (k > 0.35 && Glow.enabled) {
          _specularPaint.color = Colors.white.withValues(
            alpha: isFlashing ? 0.95 : (0.75 * k),
          );
          _specularPaint.strokeWidth = 1.0;
          canvas.drawLine(v1, v2, _specularPaint);
        }
      } else {
        // Face na sombra cósmica (Deep Cosmic Shadow)
        final shadowAlpha = isFlashing ? 0.30 : 0.60;
        _shadowRimPaint.color = const Color(
          0xFF03050A,
        ).withValues(alpha: shadowAlpha);
        _shadowRimPaint.strokeWidth = GameConstants.lineWidth * 0.9;
        canvas.drawLine(v1, v2, _shadowRimPaint);
      }
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
        colorChoices: [
          const Color(0xFFFFD700),
          Colors.white,
          const Color(0xFFFFF176),
        ],
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
        game.world.add(
          XpOrbComponent(position: position + offset, type: XpOrbType.large),
        );
      }
      return;
    }

    // 1. Crystal Variant: Shower of XP and crystal shatter
    if (variant == AsteroidVariant.crystalline) {
      game.playSfx('asteroid_split.wav');
      game.triggerScreenShake(duration: 0.25, intensity: radius * 0.2);

      game.spawnExplosionParticles(
        position: position,
        colorChoices: [
          const Color(0xFF00E5FF),
          const Color(0xFFE040FB),
          Colors.white,
          Colors.cyanAccent,
        ],
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
        final offset =
            Vector2(math.cos(angle), math.sin(angle)) *
            (12.0 + math.Random().nextDouble() * 15.0);
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
        colorChoices: [
          Colors.deepOrangeAccent,
          Colors.orange,
          Colors.amberAccent,
          Colors.yellow,
        ],
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
    } else if (variant == AsteroidVariant.titanium) {
      game.playSfx('titanium_mine.wav');
      game.triggerScreenShake(duration: 0.35, intensity: radius * 0.28);
      game.spawnExplosionParticles(
        position: position,
        colorChoices: [
          const Color(0xFF80D8FF),
          Colors.white,
          const Color(0xFF00E5FF),
          const Color(0xFF90CAF9),
        ],
        count: 28,
        minSize: 2.2,
        maxSize: 5.0,
        minSpeed: 70.0,
        maxSpeed: 240.0,
      );
      game.addRunCredits(35);
      AchievementService.unlock('titanium_tycoon');
      game.spawnFloatingText(
        position + Vector2(0, -25),
        '⛏️ VEIO DE TITÂNIO EXTRAÍDO! (+35 SUCATA)',
        color: const Color(0xFF80D8FF),
        fontSize: 14.5,
      );

      for (var i = 0; i < 2; i++) {
        final a = (i * math.pi);
        final offset = Vector2(math.cos(a), math.sin(a)) * (radius * 0.4);
        game.world.add(
          XpOrbComponent(position: position + offset, type: XpOrbType.medium),
        );
      }

      // Tactical Corridor Carving Shockwave: slows nearby enemies by 30% for 3.0s (O(1) Entity Registry)
      final enemies = game.activeEnemies.isNotEmpty
          ? game.activeEnemies
          : game.world.children.whereType<EnemyShipComponent>();
      for (final enemy in enemies) {
        if (enemy.position.distanceToSquared(position) <= 140.0 * 140.0) {
          enemy.applyElementalStatus(ElementalStatus.cryoFreeze, duration: 3.0);
        }
      }
      return;
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
    final activeDrops = game.activeDrops.isNotEmpty
        ? game.activeDrops.length
        : game.world.children.whereType<DropComponent>().length;
    double dropChance = 0.05;
    if (radius >= 50.0) {
      dropChance = 0.25;
    } else if (radius >= 30.0) {
      dropChance = 0.12;
    }

    if (activeDrops < 3 && random.nextDouble() < dropChance) {
      final roll = random.nextDouble();
      final hpRatio = game.player.hpPercent;

      DropType dropType;
      // Vampire Survivors style: Asteroides comuns nunca dropam vida.
      // Apenas titãs gigantes (> 55px) com jogador em perigo crítico (< 25% HP) têm 6% de chance de nanites de reparo.
      if (radius >= 55.0 && hpRatio < 0.25 && random.nextDouble() < 0.06) {
        dropType = DropType.health;
      } else if (roll < 0.38) {
        dropType = DropType.lunarSample;
      } else if (roll < 0.68) {
        dropType = DropType.rareHelium;
      } else if (roll < 0.88) {
        dropType = DropType.shield;
      } else if (roll < 0.98) {
        dropType = DropType.darkMatter;
      } else {
        dropType = DropType
            .vortexSurge; // Raro Drop Especial estilo Vampire Survivors (2% de chance)
      }

      final driftAngle = random.nextDouble() * 2 * math.pi;
      final dropVel =
          Vector2(math.cos(driftAngle), math.sin(driftAngle)) * 25.0;

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
