import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:void_protocol/constants.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'player.dart';

enum DropType {
  lunarSample, // Fragmento Lunar (+100 pts)
  rareHelium,  // Hélio-3 Raro (+250 pts)
  darkMatter,  // Matéria Escura (+500 pts)
  shield,      // Escudo Fotônico (4s Invulnerabilidade)
  health,      // Cápsula de Reparo (+1 Vida)
  cometDust,   // Poeira Estelar do Cometa (+1000 pts + Reparo/Escudo)
  memoryCore,  // Núcleo de Memória Cósmico (+15 Bond XP da Valquíria)
  vortexSurge, // Sobrecarga de Vórtice estilo Vampire Survivors Nduja Fritta (7.5s temporário!)
}

class DropComponent extends PositionComponent with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  AsteroidsGame? customGame;

  @override
  AsteroidsGame get game => customGame ?? super.game;

  final DropType type;
  Vector2 velocity;
  double lifespan = 8.0;
  final double maxLifespan = 8.0;
  double pulseTimer = 0.0;
  final double radius = 12.0;

  // Zero-GC Cached Paint and Path instances (60-120 FPS)
  static final Paint _glowPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _innerPaint = Paint()
    ..color = Colors.black.withOpacity(0.85)
    ..style = PaintingStyle.fill;
  static final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  static final Path _scratchPath = Path();

  DropComponent({
    required Vector2 position,
    required this.type,
    Vector2? initialVelocity,
  }) : velocity = initialVelocity ?? Vector2.zero() {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void onMount() {
    super.onMount();
    game.activeDrops.add(this);
  }

  @override
  void onRemove() {
    game.activeDrops.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    lifespan -= dt;
    if (lifespan <= 0) {
      removeFromParent();
      return;
    }

    pulseTimer += dt * 4.0;

    // Gentle magnetic tractor pull towards player if within 160 pixels
    final player = game.player;
    final distToPlayer = (player.position - position).length;
    if (distToPlayer < 160.0 && distToPlayer > 0.1) {
      final pullDir = (player.position - position).normalized();
      velocity += pullDir * 240.0 * dt;
    }

    // Apply friction to drift velocity
    velocity.scale(math.exp(-1.5 * dt));
    position += velocity * dt;

    // Wrap around screen edges
    _wrapAround();
  }

  void _wrapAround() {
    position.x = position.x.clamp(radius, GameConstants.sectorWidth - radius).toDouble();
    position.y = position.y.clamp(radius, GameConstants.sectorHeight - radius).toDouble();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (game.state != GameState.playing) return;

    if (other is PlayerComponent) {
      _collect();
    }
  }

  void _collect() {
    game.playSfx('powerup.wav');

    Color particleColor;
    switch (type) {
      case DropType.lunarSample:
        game.score += 100;
        game.samplesCollected++;
        game.spawnFloatingText(
          position,
          "+100 AMOSTRA LUNAR!",
          color: Colors.cyanAccent,
          fontSize: 15.0,
        );
        particleColor = Colors.cyanAccent;
        break;

      case DropType.rareHelium:
        game.score += 250;
        game.samplesCollected++;
        game.spawnFloatingText(
          position,
          "+250 HÉLIO-3 RARO!",
          color: Colors.amberAccent,
          fontSize: 16.0,
        );
        particleColor = Colors.amberAccent;
        break;

      case DropType.darkMatter:
        game.score += 500;
        game.samplesCollected++;
        game.triggerScreenShake(duration: 0.2, intensity: 5.0);
        game.spawnFloatingText(
          position,
          "+500 MATÉRIA ESCURA! 🌌",
          color: const Color(0xFFE040FB),
          fontSize: 17.5,
          velocity: Vector2(0, -35),
        );
        particleColor = const Color(0xFFE040FB);
        break;

      case DropType.shield:
        game.player.invulnerableTimer = 4.0;
        game.spawnFloatingText(
          position,
          "ESCUDO 4s!",
          color: Colors.lightBlueAccent,
          fontSize: 15.0,
        );
        particleColor = Colors.lightBlueAccent;
        break;

      case DropType.health:
        const healAmount = 20.0;
        game.player.heal(healAmount);
        game.spawnFloatingText(
          position,
          "+${healAmount.toInt()} HP REPARO! 💚",
          color: const Color(0xFF00E676),
          fontSize: 16.0,
        );
        particleColor = const Color(0xFF00E676);
        break;

      case DropType.cometDust:
        game.score += 1500;
        game.samplesCollected += 2;
        game.player.heal(40.0);
        game.player.invulnerableTimer = math.max(game.player.invulnerableTimer, 4.0);
        game.triggerScreenShake(duration: 0.35, intensity: 8.0);
        game.spawnFloatingText(
          position,
          "+1500 POEIRA DO COMETA! ☄️",
          color: const Color(0xFF00E5FF),
          fontSize: 18.0,
          velocity: Vector2(0, -40),
        );
        particleColor = const Color(0xFF00E5FF);
        break;

      case DropType.memoryCore:
        final pilotId = game.selectedValkyrie.id;
        final leveledUp = game.affinityManager.getAffinity(pilotId).addXp(15);
        game.spawnFloatingText(
          position,
          leveledUp ? "+15 AFINIDADE! ELO SUBIU! 💖" : "+15 AFINIDADE! 💖",
          color: const Color(0xFFFF4081),
          fontSize: 16.5,
          velocity: Vector2(0, -32),
        );
        particleColor = const Color(0xFFFF4081);
        break;

      case DropType.vortexSurge:
        game.player.activateVortexSurge(3.5);
        game.triggerScreenShake(duration: 0.3, intensity: 6.0);
        game.spawnFloatingText(
          position,
          "🌀 SOBRECARGA DE VÓRTICE! (3.5s)",
          color: const Color(0xFFD500F9),
          fontSize: 17.0,
          velocity: Vector2(0, -36),
        );
        particleColor = const Color(0xFFD500F9);
        break;
    }

    // Explosion particles upon pickup
    game.spawnExplosionParticles(
      position: position,
      colorChoices: [particleColor, Colors.white],
      count: 18,
      minSize: 2.0,
      maxSize: 4.5,
      minSpeed: 60.0,
      maxSpeed: 160.0,
    );

    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    // Fast viewport frustum culling: skip rendering if off-screen
    try {
      final camPos = game.camera.viewfinder.position;
      final dx = (position.x - camPos.x).abs();
      final dy = (position.y - camPos.y).abs();
      if (dx > game.visibleHalfWidth + radius || dy > game.visibleHalfHeight + radius) return;
    } catch (_) {}

    // Blinking effect in the last 2.5 seconds of lifespan
    if (lifespan < 2.5 && (DateTime.now().millisecondsSinceEpoch % 200 < 100)) {
      return;
    }

    canvas.translate(radius, radius);

    final pulseScale = 1.0 + math.sin(pulseTimer) * 0.18;
    Color mainColor;

    switch (type) {
      case DropType.lunarSample:
        mainColor = Colors.cyanAccent;
        break;
      case DropType.rareHelium:
        mainColor = Colors.amberAccent;
        break;
      case DropType.darkMatter:
        mainColor = const Color(0xFFE040FB);
        break;
      case DropType.shield:
        mainColor = Colors.lightBlueAccent;
        break;
      case DropType.health:
        mainColor = const Color(0xFF00E676);
        break;
      case DropType.cometDust:
        mainColor = const Color(0xFF00E5FF);
        break;
      case DropType.memoryCore:
        mainColor = const Color(0xFFFF4081);
        break;
      case DropType.vortexSurge:
        mainColor = const Color(0xFFD500F9);
        break;
    }

    // Outer glowing ring (Zero-GC)
    _glowPaint.color = mainColor.withOpacity((type == DropType.darkMatter || type == DropType.cometDust) ? 0.48 : 0.28);
    _glowPaint.strokeWidth = (type == DropType.darkMatter || type == DropType.cometDust) ? 4.5 : 3.0;
    canvas.drawCircle(Offset.zero, radius * pulseScale, _glowPaint);

    if (type == DropType.darkMatter || type == DropType.cometDust) {
      // Secondary outer orbital halo
      _strokePaint.color = (type == DropType.cometDust ? Colors.amberAccent : mainColor).withOpacity(0.35);
      _strokePaint.strokeWidth = 1.5;
      canvas.drawCircle(Offset.zero, radius * (pulseScale + 0.3), _strokePaint);
    }

    // Inner filled circle
    canvas.drawCircle(Offset.zero, radius * 0.85, _innerPaint);

    _strokePaint.color = mainColor;
    _strokePaint.strokeWidth = 1.8;
    canvas.drawCircle(Offset.zero, radius * 0.85, _strokePaint);

    // Draw vector symbol inside
    _fillPaint.color = mainColor;

    if (type == DropType.health) {
      // Cross
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 3, height: 10), _fillPaint);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 10, height: 3), _fillPaint);
    } else if (type == DropType.lunarSample) {
      // Diamond Crystal
      _scratchPath.reset();
      _scratchPath.moveTo(0, -6);
      _scratchPath.lineTo(5, 0);
      _scratchPath.lineTo(0, 6);
      _scratchPath.lineTo(-5, 0);
      _scratchPath.close();
      canvas.drawPath(_scratchPath, _fillPaint);
    } else if (type == DropType.rareHelium) {
      // Star / Hexagon
      _scratchPath.reset();
      for (int i = 0; i < 6; i++) {
        final a = (i * math.pi) / 3;
        final r = (i % 2 == 0) ? 6.0 : 3.0;
        final x = r * math.cos(a);
        final y = r * math.sin(a);
        if (i == 0) {
          _scratchPath.moveTo(x, y);
        } else {
          _scratchPath.lineTo(x, y);
        }
      }
      _scratchPath.close();
      canvas.drawPath(_scratchPath, _fillPaint);
    } else if (type == DropType.darkMatter) {
      // Cosmic core: circle + cross flares
      canvas.drawCircle(Offset.zero, 3.5, _fillPaint);
      _strokePaint.color = mainColor;
      _strokePaint.strokeWidth = 1.8;
      canvas.drawLine(const Offset(-6, 0), const Offset(6, 0), _strokePaint);
      canvas.drawLine(const Offset(0, -6), const Offset(0, 6), _strokePaint);
    } else if (type == DropType.shield) {
      // Shield circle outline
      _strokePaint.color = mainColor;
      _strokePaint.strokeWidth = 2.0;
      canvas.drawCircle(Offset.zero, 4.5, _strokePaint);
    } else if (type == DropType.cometDust) {
      // Comet nucleus core + star flare ring
      canvas.drawCircle(Offset.zero, 3.5, _fillPaint);
      _strokePaint.color = Colors.amberAccent;
      _strokePaint.strokeWidth = 1.3;
      canvas.drawCircle(Offset.zero, 6.5, _strokePaint);
    } else if (type == DropType.memoryCore) {
      // Stylized Heart Gem
      _scratchPath.reset();
      _scratchPath.moveTo(0, 4.5);
      _scratchPath.lineTo(-4.5, -0.5);
      _scratchPath.cubicTo(-6.0, -3.0, -3.0, -6.0, 0, -2.5);
      _scratchPath.cubicTo(3.0, -6.0, 6.0, -3.0, 4.5, -0.5);
      _scratchPath.close();
      canvas.drawPath(_scratchPath, _fillPaint);
    } else if (type == DropType.vortexSurge) {
      // Swirling Vortex Spiral
      _strokePaint.color = mainColor;
      _strokePaint.strokeWidth = 2.0;
      canvas.drawCircle(Offset.zero, 3.0, _fillPaint);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 6.0),
        pulseTimer * 4.0,
        math.pi * 1.3,
        false,
        _strokePaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 8.5),
        pulseTimer * 4.0 + math.pi,
        math.pi * 1.2,
        false,
        _strokePaint,
      );
    }
  }
}
