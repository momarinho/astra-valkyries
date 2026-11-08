import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/sector.dart';
import 'package:asteroids/game/glow.dart';
import 'sector_boss.dart';
import 'dreadnought_leviathan.dart';
import 'ignis_wyrm.dart';
import 'scrap_goliath.dart';
import 'void_singularity_core.dart';

/// Covil / Arena Territorial do Chefe de Setor.
/// Gerado proceduralmente em um quadrante distante do mapa (estilo Dead Cells).
/// O Chefe reside aqui fortificado. A jogadora pode navegar até suas coordenadas
/// para desafiá-lo, ou caso demore (tempo <= 45s), o Chefe acorda em modo caçador.
class BossLairComponent extends PositionComponent with HasGameReference<AsteroidsGame> {
  final double lairRadius = 450.0;
  final double activationRadius = 750.0;
  final bool requiresBeaconCharge;
  bool isAwakened = false;
  double chargeProgress = 0.0;
  double _sealedWarnCooldown = 0.0;
  double _rotation = 0.0;
  double _pulseTimer = 0.0;

  final Paint _perimeterPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;

  final Paint _corePaint = Paint()..style = PaintingStyle.fill;

  BossLairComponent({
    required Vector2 position,
    this.requiresBeaconCharge = false,
  }) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(lairRadius * 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _rotation += dt * 0.6;
    _pulseTimer += dt * 3.0;
    if (_sealedWarnCooldown > 0) {
      _sealedWarnCooldown = math.max(0.0, _sealedWarnCooldown - dt);
    }

    if (isAwakened || game.state != GameState.playing) return;

    // 1. Clímax do Setor (45s finais): O Titã desperta automaticamente em modo caçada
    if (game.timeRemaining <= 45.0 && game.timeRemaining > 0) {
      awakenBoss(isHunt: true);
      return;
    }

    final player = game.player;
    final dist = position.distanceTo(player.position);

    // 2. Jogadora voou até o Altar / Covil do Titã no mapa
    if (dist <= activationRadius) {
      if (requiresBeaconCharge && !game.isBossAltarUnlocked) {
        if (_sealedWarnCooldown <= 0) {
          _sealedWarnCooldown = 4.5;
          game.spawnFloatingText(
            player.position + Vector2(0, -60),
            '🔒 ALTAR SELADO (${game.beaconsCharged}/${AsteroidsGame.requiredBeacons}) // ABATA SUB-CHEFES OU EXPLORE POIS!',
            color: const Color(0xFFFFB300),
            fontSize: 14.5,
          );
        }
        return;
      }

      if (requiresBeaconCharge) {
        chargeProgress = (chargeProgress + dt * 0.55).clamp(0.0, 1.0);
        if (chargeProgress >= 1.0) {
          awakenBoss(isHunt: false);
        }
      } else {
        awakenBoss(isHunt: false);
      }
      return;
    } else if (chargeProgress > 0) {
      chargeProgress = math.max(0.0, chargeProgress - dt * 0.25);
    }
  }

  void awakenBoss({required bool isHunt}) {
    if (isAwakened) return;
    isAwakened = true;
    game.sectorMap?.isBossAwakened = true;

    // Spawna o chefe específico deste setor
    final SectorBoss boss;
    switch (game.currentSector.id) {
      case SectorId.orion:
        boss = IgnisWyrmComponent(position: position.clone());
        break;
      case SectorId.graveyard:
        boss = ScrapGoliathComponent(position: position.clone());
        break;
      case SectorId.eventHorizon:
        boss = VoidSingularityCoreComponent(position: position.clone());
        break;
      case SectorId.vesta:
        boss = DreadnoughtLeviathanComponent(position: position.clone());
        break;
    }

    game.activeBoss = boss;
    game.world.add(boss);

    game.playSfx('powerup.wav');
    game.triggerScreenShake(duration: 1.5, intensity: 26.0);

    final alertMsg = isHunt
        ? '⚠️ TEMPO ESGOTANDO: O TITÃ DETECTOU SEU RASTRO E SAIU EM CAÇADA!'
        : '🚨 VOCÊ ADENTROU O COVIL DO TITÃ // ${boss.bossName}';

    game.spawnFloatingText(
      game.player.position + Vector2(0, -70),
      alertMsg,
      color: const Color(0xFFFF1744),
      fontSize: 17.0,
    );
  }

  @override
  void render(Canvas canvas) {
    try {
      final camPos = game.camera.viewfinder.position;
      final dx = (position.x - camPos.x).abs();
      final dy = (position.y - camPos.y).abs();
      if (dx > 750 + lairRadius || dy > 450 + lairRadius) return;
    } catch (_) {}

    super.render(canvas);

    final center = (size / 2).toOffset();
    final pulse = 0.92 + 0.08 * math.sin(_pulseTimer);
    final currentR = lairRadius * pulse;

    final lairColor = (game.currentSector.id == SectorId.orion)
        ? const Color(0xFFFF5722)
        : const Color(0xFFFF1744);

    // 1. Círculo de Perigo Territorial Holográfico
    _perimeterPaint.color = lairColor.withValues(alpha: 0.35);
    _perimeterPaint.strokeWidth = 2.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_rotation);

    // Arcos de aviso de fronteira hostil
    for (var i = 0; i < 6; i++) {
      final a = i * (math.pi / 3);
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: currentR),
        a,
        math.pi / 5,
        false,
        _perimeterPaint,
      );
    }
    canvas.restore();

    // 2. Núcleo do Altar / Base Orbital Adormecida
    if (!isAwakened) {
      final isUnlocked = !requiresBeaconCharge || game.isBossAltarUnlocked;
      final coreColor = isUnlocked ? const Color(0xFF00E676) : lairColor;
      _corePaint.color = coreColor.withValues(alpha: 0.18);
      canvas.drawCircle(center, 90.0 * pulse, _corePaint);

      Glow.strokeCircle(
        canvas,
        center,
        90.0 * pulse,
        coreColor,
        width: 2.0,
        intensity: 0.9,
      );

      // Anel de Sincronização de Teletransporte (estilo Risk of Rain)
      if (chargeProgress > 0) {
        final chargePaint = Paint()
          ..color = const Color(0xFF00E5FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.0;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: 115.0),
          -math.pi / 2,
          2 * math.pi * chargeProgress,
          false,
          chargePaint,
        );
      }

      // Ícone central de estado do Altar
      final skullPaint = Paint()..color = coreColor.withValues(alpha: 0.85);
      canvas.drawCircle(center, 18.0, skullPaint);
    }
  }
}
