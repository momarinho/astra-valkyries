import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';

enum NebulaType {
  ionCloud, // Rapid weapon recharge (+30% fire rate), but shields suppressed
  darkMatter, // High critical chance (+50% crit rate), but movement damped (-30% max speed)
}

/// Large interactive cosmic nebula region (Rebalanceada na Sprint 20).
/// Possui deriva espacial contínua, duração finita (25 a 35s) e Sobrecarga Térmica/Radiação:
/// permanecer mais de 6s contínuos drena 5% de HP/segundo até a nave sair da área.
class CosmicNebulaComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final NebulaType type;
  final double radius;
  final Vector2 driftVelocity;
  final double maxDuration;
  double elapsedTimer = 0.0;
  double playerInsideTimer = 0.0;
  static const double overloadThreshold = 6.0;
  bool isOverloaded = false;
  double _overloadWarningTimer = 0.0;
  double _pulseTimer = 0.0;

  // Zero-GC Cached Paints
  static final Paint _gasPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _boundaryPaint = Paint()..style = PaintingStyle.stroke;
  static final Paint _motePaint = Paint()..style = PaintingStyle.fill;

  CosmicNebulaComponent({
    required Vector2 position,
    required this.type,
    this.radius = 420.0,
    Vector2? driftVelocity,
    this.maxDuration = 30.0,
  }) : driftVelocity =
           driftVelocity ??
           (type == NebulaType.ionCloud
               ? Vector2(22.0, -14.0)
               : Vector2(-18.0, 16.0)),
       super(
         position: position,
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
       );

  String get name =>
      type == NebulaType.ionCloud ? 'ION NEBULA' : 'DARK MATTER POCKET';

  String get modifierText {
    final baseText = type == NebulaType.ionCloud
        ? '⚡ HYPER-CADENCE +30% // SHIELD DISRUPTION'
        : '🎯 CRIT CHANCE +50% // GRAVITY DAMPED -30%';
    if (isOverloaded) {
      return '☢️ SOBRECARGA DE RADIAÇÃO (-5% HP/s) // $baseText';
    }
    return baseText;
  }

  Color get primaryColor => type == NebulaType.ionCloud
      ? const Color(0xFFE040FB) // Electric Magenta / Violet
      : const Color(0xFF00E5FF); // Neon Cyan / Indigo

  Color get secondaryColor => type == NebulaType.ionCloud
      ? const Color(0xFF7C4DFF)
      : const Color(0xFF1A237E);

  @override
  bool containsPoint(Vector2 point) {
    return position.distanceTo(point) <= radius;
  }

  @override
  void onMount() {
    super.onMount();
    game.activeNebulae.add(this);
  }

  @override
  void onRemove() {
    game.activeNebulae.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt * 0.8;

    // 1. Deriva espacial contínua (Sprint 20)
    position += driftVelocity * dt;
    if (position.x < radius) {
      position.x = radius;
      driftVelocity.x = driftVelocity.x.abs();
    } else if (position.x > GameConstants.sectorWidth - radius) {
      position.x = GameConstants.sectorWidth - radius;
      driftVelocity.x = -driftVelocity.x.abs();
    }
    if (position.y < radius) {
      position.y = radius;
      driftVelocity.y = driftVelocity.y.abs();
    } else if (position.y > GameConstants.sectorHeight - radius) {
      position.y = GameConstants.sectorHeight - radius;
      driftVelocity.y = -driftVelocity.y.abs();
    }

    // 2. Duração finita (25 a 35s)
    elapsedTimer += dt;
    if (elapsedTimer >= maxDuration) {
      removeFromParent();
      return;
    }

    // 3. Sobrecarga Térmica / Radiação após 6s contínuos dentro da nuvem: drena 5% HP/s
    try {
      if (game.state == GameState.playing) {
        final player = game.player;
        if (containsPoint(player.position)) {
          playerInsideTimer += dt;
          if (playerInsideTimer > overloadThreshold) {
            isOverloaded = true;
            final drain = player.maxHp * 0.05 * dt;
            player.hp = math.max(1.0, player.hp - drain);
            _overloadWarningTimer += dt;
            if (_overloadWarningTimer >= 1.0) {
              _overloadWarningTimer = 0.0;
              game.spawnFloatingText(
                player.position + Vector2(0, -36),
                '☢️ SOBRECARGA NEBULAR! (-5% HP/s)',
                color: const Color(0xFFFF1744),
                fontSize: 13.0,
              );
            }
          }
        } else {
          if (isOverloaded) {
            try {
              game.notifyNebulaOverloadSurvivedForUnlocks();
            } catch (_) {}
          }
          playerInsideTimer = math.max(0.0, playerInsideTimer - dt * 2.5);
          isOverloaded = playerInsideTimer > overloadThreshold;
          _overloadWarningTimer = 0.0;
        }
      }
    } catch (_) {}
  }

  @override
  void render(Canvas canvas) {
    try {
      final camPos = game.camera.viewfinder.position;
      final dx = (position.x - camPos.x).abs();
      final dy = (position.y - camPos.y).abs();
      if (dx > 750 + radius || dy > 450 + radius) return;
    } catch (_) {}

    super.render(canvas);

    final pulse = 1.0 + 0.05 * math.sin(_pulseTimer);
    final currentRadius = radius * pulse;

    _gasPaint.shader = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: 0.18),
        secondaryColor.withValues(alpha: 0.12),
        secondaryColor.withValues(alpha: 0.05),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 0.75, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: currentRadius));

    canvas.drawCircle(Offset.zero, currentRadius, _gasPaint);

    // Subtle gas perimeter boundary line
    _boundaryPaint.color = primaryColor.withValues(
      alpha: 0.14 + 0.06 * math.sin(_pulseTimer * 1.5),
    );
    _boundaryPaint.strokeWidth = 1.2;
    canvas.drawCircle(Offset.zero, currentRadius * 0.95, _boundaryPaint);

    // Ambient floating dust motes inside nebula
    for (int i = 0; i < 18; i++) {
      final a = (i * (2 * math.pi / 18)) + 0.1 * math.sin(_pulseTimer + i);
      final r = (0.2 + (i % 6) * 0.12) * radius;
      final x = r * math.cos(a);
      final y = r * math.sin(a);
      final alpha = (0.35 + 0.35 * math.sin(_pulseTimer * 2.0 + i)).clamp(
        0.0,
        1.0,
      );
      _motePaint.color = primaryColor.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), 2.0 + (i % 3) * 0.8, _motePaint);
    }
  }
}
