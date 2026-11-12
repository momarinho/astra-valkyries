import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/sector.dart';
import 'package:asteroids/game/roguelite_systems.dart';
import 'bullet.dart';

/// ============================================================================
/// SPRINT 25 & 26 — CAMADAS VISUAIS DOS 6 BIOMAS, ELEMENTOS INTERATIVOS,
/// RELÍQUIAS PERMANENTES & CÁPSULAS DE ESTASE (COFFINS)
/// ============================================================================

/// Camada 0 e Camada 1: Backdrop Abissal e Sub-Piso Arquitetural puramente vetorial de alta definição.
class BiomeBackdropComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final SectorId sectorId;
  double _animTimer = 0.0;
  final List<Vector2> _ambientMotes = [];

  BiomeBackdropComponent({required this.sectorId})
      : super(
          position: Vector2.zero(),
          size: Vector2(GameConstants.sectorWidth, GameConstants.sectorHeight),
          priority: -45,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final rng = math.Random(sectorId.index * 7919);
    for (int i = 0; i < 48; i++) {
      _ambientMotes.add(Vector2(
        rng.nextDouble() * GameConstants.screenWidth,
        rng.nextDouble() * GameConstants.screenHeight,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTimer += dt;

    final width = GameConstants.screenWidth;
    final height = GameConstants.screenHeight;
    for (int i = 0; i < _ambientMotes.length; i++) {
      final mote = _ambientMotes[i];
      switch (sectorId) {
        case SectorId.vesta:
        case SectorId.orion:
          mote.y -= 32.0 * dt;
          mote.x += math.sin(_animTimer + i) * 14.0 * dt;
          break;
        case SectorId.cryoAbyss:
          mote.y += 26.0 * dt;
          mote.x += math.cos(_animTimer + i) * 12.0 * dt;
          break;
        case SectorId.graveyard:
          mote.x -= 18.0 * dt;
          mote.y += math.sin(_animTimer * 0.5 + i) * 10.0 * dt;
          break;
        case SectorId.xenoHive:
          mote.x += math.sin(_animTimer * 1.5 + i) * 18.0 * dt;
          mote.y += math.cos(_animTimer * 1.5 + i) * 18.0 * dt;
          break;
        case SectorId.eventHorizon:
        case SectorId.voidThrone:
          mote.x += math.sin(_animTimer + i) * 22.0 * dt;
          mote.y += math.cos(_animTimer + i) * 22.0 * dt;
          break;
      }
      if (mote.x < 0) mote.x = width;
      if (mote.x > width) mote.x = 0;
      if (mote.y < 0) mote.y = height;
      if (mote.y > height) mote.y = 0;
    }
  }

  void _renderAmbientMotes(Canvas canvas, double width, double height) {
    final sector = Sector.findById(sectorId);
    final moteColor = sector.primaryColor;
    final motePaint = Paint()..style = PaintingStyle.fill;
    final haloPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < _ambientMotes.length; i++) {
      final pos = _ambientMotes[i].toOffset();
      final pulse = 0.5 + 0.5 * math.sin(_animTimer * 2.4 + i);
      final r = (1.2 + (i % 2)) * (0.7 + 0.3 * pulse);

      motePaint.color = moteColor.withValues(alpha: 0.16 + 0.10 * pulse);
      haloPaint.color = moteColor.withValues(alpha: 0.05 * pulse);

      canvas.drawCircle(pos, r * 2.0, haloPaint);
      canvas.drawCircle(pos, r, motePaint);
    }
  }

  @override
  void render(Canvas canvas) {
    final width = GameConstants.screenWidth;
    final height = GameConstants.screenHeight;

    Vector2 camPos;
    try {
      camPos = game.camera.viewfinder.position;
    } catch (_) {
      camPos = Vector2(GameConstants.sectorWidth / 2, GameConstants.sectorHeight / 2);
    }

    // 1. Renderiza o Fundo Espacial Procedural Profundo com Parallax e Cores Vivas do Bioma
    canvas.save();
    canvas.translate(camPos.x - width / 2, camPos.y - height / 2);

    final sector = Sector.findById(sectorId);
    final normX = (camPos.x / GameConstants.sectorWidth).clamp(0.0, 1.0);
    final normY = (camPos.y / GameConstants.sectorHeight).clamp(0.0, 1.0);

    // Gradiente Abissal de Profundidade Cósmica do Bioma
    final deepVoidShader = RadialGradient(
      center: Alignment(
        -0.4 + normX * 0.8,
        -0.4 + normY * 0.8,
      ),
      radius: 1.1,
      colors: [
        sector.primaryColor.withValues(alpha: 0.08),
        sector.secondaryColor.withValues(alpha: 0.03),
        const Color(0xFF02040A),
      ],
      stops: const [0.0, 0.55, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..shader = deepVoidShader);

    // Nuvens de Poeira Cósmica Volumétrica com Parallax Suave (BlendMode.plus)
    final cloudOffset1 = Offset(
      width * 0.35 - (normX - 0.5) * 80.0,
      height * 0.40 - (normY - 0.5) * 60.0,
    );
    canvas.drawCircle(
      cloudOffset1,
      width * 0.45,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            sector.primaryColor.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: cloudOffset1, radius: width * 0.45)),
    );

    final cloudOffset2 = Offset(
      width * 0.75 - (normX - 0.5) * 120.0,
      height * 0.70 - (normY - 0.5) * 90.0,
    );
    canvas.drawCircle(
      cloudOffset2,
      width * 0.50,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = RadialGradient(
          colors: [
            sector.secondaryColor.withValues(alpha: 0.04),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: cloudOffset2, radius: width * 0.50)),
    );

    // Vinheta atmosférica cinematográfica
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.30),
          Colors.black.withValues(alpha: 0.82),
        ],
        stops: const [0.55, 0.80, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), vignettePaint);

    // Partículas atmosféricas temáticas flutuantes sutis (micro-fagulhas, geada, esporos)
    _renderAmbientMotes(canvas, width, height);

    canvas.restore();

    // 2. Renderiza as Macro-Estruturas e Sub-Pisos Arquiteturais nos slots globais do mapa
    final center = const Offset(
      GameConstants.sectorWidth / 2,
      GameConstants.sectorHeight / 2,
    );

    switch (sectorId) {
      case SectorId.vesta:
        _renderVestaBackdrop(canvas, center);
        break;
      case SectorId.orion:
        _renderHeliosForgeBackdrop(canvas, center);
        break;
      case SectorId.cryoAbyss:
        _renderCryoAbyssBackdrop(canvas, center);
        break;
      case SectorId.graveyard:
        _renderAegisGraveyardBackdrop(canvas, center);
        break;
      case SectorId.xenoHive:
        _renderXenoHiveBackdrop(canvas, center);
        break;
      case SectorId.eventHorizon:
      case SectorId.voidThrone:
        _renderVoidThroneBackdrop(canvas, center);
        break;
    }
  }

  void _renderVestaBackdrop(Canvas canvas, Offset center) {
    // 1. Planeta Vulcânico Rachado no quadrante Noroeste (Camada 0)
    const planetCenter = Offset(950, 950);
    canvas.drawCircle(
      planetCenter,
      620,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF6D00).withValues(alpha: 0.22),
            const Color(0xFF3E2723).withValues(alpha: 0.18),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: planetCenter, radius: 620)),
    );

    // 2. Halo de Nebulosa e Campo de Poeira Cósmica de Cinturão de Mineração
    final dustPaint1 = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final dustPaint2 = Paint()
      ..color = const Color(0xFFFF9100).withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(3400, 1600), 750, dustPaint1);
    canvas.drawCircle(const Offset(1600, 3400), 750, dustPaint2);
  }

  void _renderHeliosForgeBackdrop(Canvas canvas, Offset center) {
    // 1. Colossal Estrela de Dyson no centro ao fundo (Camada 0)
    final pulse = 1.0 + math.sin(_animTimer * 1.8) * 0.04;
    canvas.drawCircle(
      center,
      780 * pulse,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF59D).withValues(alpha: 0.28),
            const Color(0xFFFF6D00).withValues(alpha: 0.16),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 780 * pulse)),
    );

    // 2. 5 Pontes de Energia Solar Translúcidas ligando Asa Oeste (x=1550) e Asa Leste (x=3250)
    final bridgePaint = Paint()
      ..color = const Color(0xFFFF9100).withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    final bridgeBorder = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final y in [1500.0, 1950.0, 2400.0, 2850.0, 3300.0]) {
      final rect = Rect.fromCenter(center: Offset(center.dx, y), width: 1400, height: 68);
      canvas.drawRect(rect, bridgePaint);
      canvas.drawRect(rect, bridgeBorder);
    }
  }

  void _renderCryoAbyssBackdrop(Canvas canvas, Offset center) {
    // Piso glacial translúcido e anéis dos 4 Obeliscos Rúnicos de Caelum
    final iceFloorPaint = Paint()
      ..color = const Color(0xFF80D8FF).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 3200, height: 2600),
      iceFloorPaint,
    );

    final obeliskOffsets = [
      const Offset(1350, 1350),
      const Offset(3450, 1350),
      const Offset(1350, 3450),
      const Offset(3450, 3450),
    ];
    for (final o in obeliskOffsets) {
      canvas.drawCircle(
        o,
        140,
        Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  void _renderAegisGraveyardBackdrop(Canvas canvas, Offset center) {
    // Silhuetas de sub-piso dos Cascos de Encouraçados e passarelas laranja
    final hullPaint = Paint()
      ..color = const Color(0xFF102820).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final gridPaint = Paint()
      ..color = const Color(0xFFFF9100).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Casco Oeste e Casco Leste
    final westHull = Rect.fromCenter(center: const Offset(1450, 2400), width: 700, height: 1900);
    final eastHull = Rect.fromCenter(center: const Offset(3350, 2400), width: 700, height: 1900);
    canvas.drawRect(westHull, hullPaint);
    canvas.drawRect(eastHull, hullPaint);
    canvas.drawRect(westHull, gridPaint);
    canvas.drawRect(eastHull, gridPaint);

    // Passarela superior e inferior ligando os dois cascos
    canvas.drawRect(Rect.fromCenter(center: const Offset(2400, 1650), width: 1200, height: 90), gridPaint);
    canvas.drawRect(Rect.fromCenter(center: const Offset(2400, 3150), width: 1200, height: 90), gridPaint);
  }

  void _renderXenoHiveBackdrop(Canvas canvas, Offset center) {
    // Coração Real Violeta no centro + 6 Veias Neurais Bioluminescentes indo às 6 Alcobas
    canvas.drawCircle(
      center,
      460,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFE040FB).withValues(alpha: 0.24),
            const Color(0xFF880E4F).withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 460)),
    );

    final veinPaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final alcoves = [
      const Offset(1150, 1250),
      const Offset(3650, 1250),
      const Offset(1050, 2400),
      const Offset(3750, 2400),
      const Offset(1150, 3550),
      const Offset(3650, 3550),
    ];
    for (final a in alcoves) {
      canvas.drawLine(center, a, veinPaint);
      canvas.drawCircle(
        a,
        240,
        Paint()
          ..color = const Color(0xFFFF4081).withValues(alpha: 0.14)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _renderVoidThroneBackdrop(Canvas canvas, Offset center) {
    // Catedral Astrolábio Circular sobre o Vórtice da Singularidade
    canvas.drawCircle(
      center,
      620,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFAA00FF).withValues(alpha: 0.30),
            const Color(0xFFFFD700).withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 620)),
    );

    final goldGrid = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, 620, goldGrid);
    canvas.drawCircle(center, 1150, goldGrid);
    canvas.drawCircle(center, 1550, goldGrid);

    for (int i = 0; i < 12; i++) {
      final a = i * (math.pi / 6) + _animTimer * 0.04;
      final p1 = Offset(center.dx + math.cos(a) * 620, center.dy + math.sin(a) * 620);
      final p2 = Offset(center.dx + math.cos(a) * 1550, center.dy + math.sin(a) * 1550);
      canvas.drawLine(p1, p2, goldGrid);
    }
  }
}

/// 1. Jato de Propulsão Solar (Setor 2A — Forja Solar de Hélio)
class SolarFlameJetComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final double jetAngle;
  final double jetLength;
  double _cycleTimer = 0.0;
  bool isFiring = false;
  double _damageTick = 0.0;

  SolarFlameJetComponent({
    required Vector2 position,
    this.jetAngle = 0.0,
    this.jetLength = 260.0,
  }) : super(
          position: position,
          size: Vector2(60, 60),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;

    _cycleTimer = (_cycleTimer + dt) % 3.6;
    isFiring = _cycleTimer >= 1.6; // 1.6s preparação, 2.0s jato de plasma ativo

    if (isFiring) {
      final dir = Vector2(math.cos(jetAngle), math.sin(jetAngle));
      final toPlayer = game.player.position - position;
      final proj = toPlayer.dot(dir);
      if (proj >= 0 && proj <= jetLength) {
        final perpDist = (toPlayer - dir * proj).length;
        if (perpDist <= 38.0 + game.player.radius) {
          _damageTick += dt;
          if (_damageTick >= 0.45) {
            _damageTick = 0.0;
            game.player.takeHit(8.0);
          }
        }
      }
    } else {
      _damageTick = 0.0;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(jetAngle);

    // Bocal da fornalha
    canvas.drawRect(
      const Rect.fromLTWH(-16, -20, 32, 40),
      Paint()..color = const Color(0xFF3E2723),
    );

    if (isFiring) {
      final flameRect = Rect.fromLTWH(16, -26, jetLength, 52);
      canvas.drawRRect(
        RRect.fromRectAndRadius(flameRect, const Radius.circular(24)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFF59D), Color(0xFFFF6D00), Color(0x00FF1744)],
          ).createShader(flameRect),
      );
    } else {
      // Linha tracejada de aviso térmico
      canvas.drawLine(
        const Offset(16, 0),
        Offset(jetLength, 0),
        Paint()
          ..color = const Color(0xFFFF9100).withValues(alpha: 0.35)
          ..strokeWidth = 3.0,
      );
    }
    canvas.restore();
  }
}

/// 2. Domo Térmico Central (Setor 2B — Abismo Criogênico de Caelum)
/// Protege a nave contra o frio/congelamento e regenera suavemente o casco.
class ThermalDomeComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final double radius;
  double _pulseTimer = 0.0;
  double _healAccumulator = 0.0;

  ThermalDomeComponent({
    required Vector2 position,
    this.radius = 320.0,
  }) : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
          priority: -10,
        );

  bool containsPlayer(Vector2 pos) => position.distanceTo(pos) <= radius;

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt * 1.8;
    try {
      if (containsPlayer(game.player.position)) {
        // Anula o frio e restaura tração total dentro do Domo Térmico!
        game.player.cryoFreezeTimer = 0.0;
        game.player.cryoMistAccelerationMultiplier = 1.0;
        _healAccumulator += dt * 3.0;
        if (_healAccumulator >= 1.0 && game.player.hp < game.player.maxHp) {
          final healAmt = _healAccumulator.floorToDouble();
          _healAccumulator -= healAmt;
          game.player.heal(healAmt);
        }
      }
    } catch (_) {}
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);

    final pulse = 0.14 + math.sin(_pulseTimer) * 0.04;
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = const Color(0xFFFFB300).withValues(alpha: pulse)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Gerador térmico central
    canvas.drawCircle(
      Offset.zero,
      46,
      Paint()..color = const Color(0xFFFF6D00).withValues(alpha: 0.85),
    );
    canvas.restore();
  }
}

/// 3. Vazamento de Radiação Esmeralda do Reator (Setor 3A — Cemitério Aegis)
class ReactorLeakHazardComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final double radius;
  double _tickTimer = 0.0;

  ReactorLeakHazardComponent({
    required Vector2 position,
    this.radius = 190.0,
  }) : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
          priority: -8,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;
    if (position.distanceTo(game.player.position) <= radius) {
      _tickTimer += dt;
      if (_tickTimer >= 0.6) {
        _tickTimer = 0.0;
        game.player.takeHit(6.0);
      }
    } else {
      _tickTimer = 0.0;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = const Color(0xFF00E676).withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = const Color(0xFF69F0AE).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.restore();
  }
}

/// 4. Poça de Ácido Bio-Corrosivo (Setor 3B — Colmeia Xeno-Biológica)
class AcidPoolHazardComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final double radius;
  double _tickTimer = 0.0;

  AcidPoolHazardComponent({
    required Vector2 position,
    this.radius = 165.0,
  }) : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
          priority: -8,
        );

  @override
  void update(double dt) {
    super.update(dt);
    if (game.state != GameState.playing) return;
    if (position.distanceTo(game.player.position) <= radius) {
      _tickTimer += dt;
      if (_tickTimer >= 0.6) {
        _tickTimer = 0.0;
        game.player.takeHit(7.0);
      }
    } else {
      _tickTimer = 0.0;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(radius, radius);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = const Color(0xFF76FF03).withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..color = const Color(0xFFB2FF59).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.restore();
  }
}

/// 5. Pedestal de Relíquia Permanente (Sprint 26 — Relics hidden in map corners)
class RelicPedestalComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final String relicId;
  bool isClaimed = false;
  double _pulseTimer = 0.0;

  RelicPedestalComponent({
    required Vector2 position,
    required this.relicId,
  }) : super(
          position: position,
          size: Vector2.all(96.0),
          anchor: Anchor.center,
        );

  PermanentRelic? get relicDef => PermanentRelic.findById(relicId);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      if (game.unlockedRelics.contains(relicId)) {
        isClaimed = true;
      }
    } catch (_) {}
  }

  void claimRelic() {
    if (isClaimed) return;
    isClaimed = true;
    try {
      game.claimPermanentRelic(relicId, position);
    } catch (_) {}
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt * 2.5;
    if (!isClaimed) {
      try {
        if (position.distanceTo(game.player.position) <= 95.0) {
          claimRelic();
        }
      } catch (_) {}
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    final color = relicDef?.color ?? const Color(0xFFFFD700);
    final pulse = 1.0 + math.sin(_pulseTimer) * 0.12;

    canvas.drawCircle(
      Offset.zero,
      42 * pulse,
      Paint()
        ..color = (isClaimed ? Colors.white24 : color).withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      36,
      Paint()
        ..color = isClaimed ? Colors.white38 : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // Cristais do pedestal
    final path = Path()
      ..moveTo(0, -22)
      ..lineTo(18, 0)
      ..lineTo(0, 22)
      ..lineTo(-18, 0)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = isClaimed ? Colors.white24 : color,
    );
    canvas.restore();
  }
}

/// 6. Cápsula de Estase / Evento Secreto de Bioma (Sprint 26 — Valkyrie Coffins)
class StasisCoffinComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks {
  final SectorId sectorId;
  final String secretTitle;
  double shieldHp = 120.0;
  bool isOpened = false;
  double _pulseTimer = 0.0;

  StasisCoffinComponent({
    required Vector2 position,
    required this.sectorId,
    required this.secretTitle,
  }) : super(
          position: position,
          size: Vector2.all(110.0),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    try {
      if (game.rescuedSectorSecrets.contains(sectorId)) {
        isOpened = true;
        shieldHp = 0;
      }
    } catch (_) {}
  }

  void takeDamage(double dmg) {
    if (isOpened) return;
    shieldHp = math.max(0.0, shieldHp - dmg);
    if (shieldHp <= 0) {
      openCoffin();
    }
  }

  void openCoffin() {
    if (isOpened) return;
    isOpened = true;
    shieldHp = 0.0;
    try {
      game.unlockSectorSecret(sectorId, position);
    } catch (_) {}
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (!isOpened && other is BulletComponent) {
      takeDamage(other.damage);
      if (other.piercesLeft <= 0) {
        other.removeFromParent();
      } else {
        other.piercesLeft--;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt * 2.2;
    if (!isOpened) {
      try {
        if (position.distanceTo(game.player.position) <= 95.0) {
          openCoffin();
        }
      } catch (_) {}
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    const podColor = Color(0xFF00E5FF);
    if (!isOpened && shieldHp > 0) {
      // Domo de contenção protetor (igual à Stasis Pod Chamber da imagem do Bioma 1)
      canvas.drawCircle(
        Offset.zero,
        52 + math.sin(_pulseTimer) * 4.0,
        Paint()
          ..color = podColor.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset.zero,
        52,
        Paint()
          ..color = podColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8,
      );
    }

    // Cápsula octogonal
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-24, -36, 48, 72),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = isOpened ? Colors.white24 : const Color(0xFF102838),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = isOpened ? Colors.white38 : const Color(0xFFFFD700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.restore();
  }
}
