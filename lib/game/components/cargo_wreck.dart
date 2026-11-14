import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/roguelite_systems.dart';
import 'package:void_protocol/game/components/drop.dart';
import 'package:void_protocol/game/components/xp_orb.dart';

/// Destructible Derelict Cargo Container floating in the sector.
/// Can be breached by weapon fire to release emergency repair nanites,
/// photonic shields, rare celestial materials, and Flight Recorder Black Boxes (Sprint 22).
class CargoWreckComponent extends PositionComponent with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  double hp = 180.0;
  final double maxHp = 180.0;
  double hitFlashTimer = 0.0;
  double rotationSpeed = 0.08;
  double _beaconTimer = 0.0;
  FlightRecorderLog? recoveredLog;

  final Paint _hullPaint = Paint()
    ..color = const Color(0xFF263238)
    ..style = PaintingStyle.fill;

  final Paint _stripePaint = Paint()
    ..color = const Color(0xFFFFB300)
    ..style = PaintingStyle.fill;

  final Paint _borderPaint = Paint()
    ..color = const Color(0xFF78909C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  CargoWreckComponent({required Vector2 position})
      : super(
          position: position,
          size: Vector2(46.0, 30.0),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(size: size));
  }

  @override
  void onMount() {
    super.onMount();
    game.activeCargoWrecks.add(this);
  }

  @override
  void onRemove() {
    game.activeCargoWrecks.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    angle += rotationSpeed * dt;
    _beaconTimer += dt * 4.0;
    if (hitFlashTimer > 0) {
      hitFlashTimer = math.max(0.0, hitFlashTimer - dt);
    }
  }

  bool takeDamage(double damage, Vector2 hitPos) {
    hp -= damage;
    hitFlashTimer = 0.12;

    if (isMounted) {
      try {
        game.spawnExplosionParticles(
          position: hitPos,
          colorChoices: [const Color(0xFFFFB300), Colors.white, Colors.grey],
          count: 4,
          minSize: 1.5,
          maxSize: 3.0,
          minSpeed: 30.0,
          maxSpeed: 80.0,
        );
      } catch (_) {}
    }

    if (hp <= 0) {
      _breach();
      return true;
    } else {
      if (isMounted) {
        try {
          game.spawnFloatingText(
            hitPos,
            '-${damage.toInt()}',
            color: const Color(0xFFFFB300),
            fontSize: 11.5,
          );
        } catch (_) {}
      }
      return false;
    }
  }

  void _breach() {
    recoveredLog = FlightRecorderLog.allFlightRecorders[
        position.x.toInt().abs() % FlightRecorderLog.allFlightRecorders.length];
    try {
      recoveredLog = game.recoverFlightRecorder(position);
    } catch (_) {}
    if (isMounted) {
      try {
        game.addScore(450);
        game.addRunCredits(80);
        game.chargeBossBeacon('CARGUEIRO BRECHADO');
        game.playSfx('asteroid_split.wav');
        game.triggerScreenShake(duration: 0.35, intensity: 6.0);

        game.spawnFloatingText(
          position + Vector2(0, -30),
          '📦 CARGO CONTAINER BREACHED! +450 PTS',
          color: const Color(0xFF64FFDA),
          fontSize: 15.0,
          velocity: Vector2(0, -30),
        );

        game.spawnExplosionParticles(
          position: position,
          colorChoices: [const Color(0xFF64FFDA), const Color(0xFFFFB300), Colors.white],
          count: 24,
          minSize: 2.0,
          maxSize: 5.0,
          minSpeed: 50.0,
          maxSpeed: 160.0,
        );

        // Eject random rare drop: Shield, Health, Rare Helium or Vortex Surge
        final random = math.Random();
        final dropRoll = random.nextInt(4);
        DropType dropType;
        switch (dropRoll) {
          case 0:
            dropType = DropType.shield;
            break;
          case 1:
            dropType = DropType.health;
            break;
          case 2:
            dropType = DropType.rareHelium;
            break;
          case 3:
          default:
            dropType = DropType.vortexSurge;
            break;
        }

        game.world.add(DropComponent(position: position.clone(), type: dropType));

        // Eject 3 Medium Stardust Orbs
        for (int i = 0; i < 3; i++) {
          final a = i * (2 * math.pi / 3);
          final offset = Vector2(math.cos(a), math.sin(a))..scale(35.0);
          game.world.add(XpOrbComponent(position: position + offset, type: XpOrbType.medium));
        }

        removeFromParent();
      } catch (_) {}
    }
  }

  @override
  void render(Canvas canvas) {
    try {
      final camPos = game.camera.viewfinder.position;
      final dx = (position.x - camPos.x).abs();
      final dy = (position.y - camPos.y).abs();
      if (dx > 750 + size.x || dy > 450 + size.y) return;
    } catch (_) {}

    super.render(canvas);

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    final rect = Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y);

    // Flash white/yellow on hit
    if (hitFlashTimer > 0) {
      canvas.drawRect(rect, Paint()..color = Colors.white);
      canvas.restore();
      return;
    }

    // Outer Container Body
    canvas.drawRect(rect, _hullPaint);

    // Hazard Stripes (Diagonal warning slashes)
    final stripePath = Path()
      ..moveTo(-16, -14)
      ..lineTo(-8, -14)
      ..lineTo(-14, 14)
      ..lineTo(-22, 14)
      ..close();
    canvas.drawPath(stripePath, _stripePaint);

    final stripePath2 = Path()
      ..moveTo(6, -14)
      ..lineTo(14, -14)
      ..lineTo(8, 14)
      ..lineTo(0, 14)
      ..close();
    canvas.drawPath(stripePath2, _stripePaint);

    // Reinforced Container Frame Outline
    canvas.drawRect(rect, _borderPaint);

    // Emergency Status Beacon
    final beaconColor = (hp < maxHp * 0.4)
        ? const Color(0xFFFF2A55)
        : const Color(0xFF64FFDA);
    final beaconAlpha = 0.5 + 0.5 * math.sin(_beaconTimer);
    canvas.drawCircle(
      const Offset(14, -6),
      3.0,
      Paint()..color = beaconColor.withOpacity(beaconAlpha),
    );

    canvas.restore();
  }
}
