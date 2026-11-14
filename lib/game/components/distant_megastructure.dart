import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:void_protocol/constants.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/glow.dart';

/// Nó de sinalizador luminoso de emergência em megaestrutura abandonada
class EmergencyBeaconNode {
  final Offset relativePos;
  final Color color;
  final double pulseOffset; // Deslocamento de fase no ciclo de 2.5s
  final double intensity;

  const EmergencyBeaconNode({
    required this.relativePos,
    required this.color,
    required this.pulseOffset,
    this.intensity = 1.0,
  });
}

/// SPRINT 56: Parallax de Megaestruturas Titânicas ao Fundo (Nova Drift / Homeworld Standard)
/// Renderiza silhuetas vetoriais de encouraçados de guerra destruídos ("Aegis Sovereign")
/// e anéis orbitais abandonados no plano focal mais distante (movendo a 12% da velocidade da câmera).
/// Inclui sinalizadores de emergência vermelhos e âmbar pulsando em um ciclo exato de 2.5s.
///
/// Arquitetura Zero-GC: Paths e Paints pré-alocados, zero alocações por frame.
class DistantMegastructureBackdropComponent extends Component
    with HasGameReference<AsteroidsGame> {
  // Fator de paralaxe: 12% da velocidade da câmera
  static const double parallaxFactor = 0.12;
  static const double beaconCyclePeriod = 2.5; // Ciclo de 2.5 segundos

  double _timer = 0.0;

  // Zero-GC Cached Paints
  static final Paint _silhouetteFillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _silhouetteStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _beaconCorePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _beaconHaloPaint = Paint()
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.plus;

  late final Path _battleshipPath;
  late final Path _battleshipDetailPath;
  late final Path _stationRingPath;
  late final List<EmergencyBeaconNode> _battleshipBeacons;
  late final List<EmergencyBeaconNode> _stationBeacons;

  DistantMegastructureBackdropComponent() {
    priority = -42; // Renderiza entre BiomeBackdrop (-45) e Starfield (-40)
    _bakeMegastructureGeometry();
  }

  void _bakeMegastructureGeometry() {
    // 1. Silhueta do Encouraçado Capital Destruído ("Aegis Sovereign")
    // Dimensões relativas: ~700x320 px com estética aeroespacial angular
    final bp = Path();
    // Proa afiada e chanfrada
    bp.moveTo(350, 0);
    bp.lineTo(120, -110);
    bp.lineTo(-40, -140);
    bp.lineTo(-180, -110);
    bp.lineTo(-240, -135);
    // Compartimento de motores principais traseiros
    bp.lineTo(-320, -110);
    bp.lineTo(-350, -50);
    bp.lineTo(-310, 0); // Reentrância do reator estelar central destruído
    bp.lineTo(-350, 50);
    bp.lineTo(-320, 110);
    bp.lineTo(-240, 135);
    bp.lineTo(-180, 110);
    bp.lineTo(-40, 140);
    bp.lineTo(120, 110);
    bp.close();
    _battleshipPath = bp;

    // Linhas internas de nervuras de fuselagem exposta e fraturas de combate
    final bdp = Path();
    bdp.moveTo(220, 0);
    bdp.lineTo(-120, 0);
    // Costelas de blindagem expostas
    bdp.moveTo(100, -70);
    bdp.lineTo(100, 70);
    bdp.moveTo(-20, -90);
    bdp.lineTo(-20, 90);
    bdp.moveTo(-140, -80);
    bdp.lineTo(-140, 80);
    // Fratura colossal no casco bombordo
    bdp.moveTo(40, -120);
    bdp.lineTo(10, -60);
    bdp.lineTo(-30, -80);
    bdp.lineTo(-60, -20);
    _battleshipDetailPath = bdp;

    // Balizas de emergência do couraçado
    _battleshipBeacons = [
      const EmergencyBeaconNode(
        relativePos: Offset(345, 0),
        color: Color(0xFFFF1744), // Vermelho de emergência na ponta da proa
        pulseOffset: 0.0,
      ),
      const EmergencyBeaconNode(
        relativePos: Offset(115, -108),
        color: Color(0xFFFF9100), // Âmbar tático na quina superior
        pulseOffset: 0.4,
      ),
      const EmergencyBeaconNode(
        relativePos: Offset(115, 108),
        color: Color(0xFFFF9100), // Âmbar tático na quina inferior
        pulseOffset: 0.4,
      ),
      const EmergencyBeaconNode(
        relativePos: Offset(-315, -105),
        color: Color(0xFFFF1744), // Nacela de dobra superior
        pulseOffset: 1.25,
      ),
      const EmergencyBeaconNode(
        relativePos: Offset(-315, 105),
        color: Color(0xFFFF1744), // Nacela de dobra inferior
        pulseOffset: 1.25,
      ),
      const EmergencyBeaconNode(
        relativePos: Offset(-60, -20),
        color: Color(0xFF00E5FF), // Ciano de contenção de plasma vazando
        pulseOffset: 1.8,
        intensity: 0.7,
      ),
    ];

    // 2. Anel Orbital Abandonado ("Spire Station")
    final sp = Path();
    // Segmento em arco de anel orbital de 500px de raio
    sp.addOval(Rect.fromCircle(center: Offset.zero, radius: 260));
    _stationRingPath = sp;

    _stationBeacons = [
      const EmergencyBeaconNode(
        relativePos: Offset(0, -260),
        color: Color(0xFFFF1744),
        pulseOffset: 0.0,
      ),
      const EmergencyBeaconNode(
        relativePos: Offset(260, 0),
        color: Color(0xFFFF9100),
        pulseOffset: 0.6,
      ),
      const EmergencyBeaconNode(
        relativePos: Offset(0, 260),
        color: Color(0xFFFF1744),
        pulseOffset: 1.25,
      ),
      const EmergencyBeaconNode(
        relativePos: Offset(-260, 0),
        color: Color(0xFFFF9100),
        pulseOffset: 1.85,
      ),
    ];
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timer += dt;
  }

  /// Calcula o brilho da baliza no ciclo de 2.5s (pulso agudo de 0.3s com decaimento exponencial)
  double _calculateBeaconPulse(double pulseOffset) {
    final phase = (_timer + pulseOffset) % beaconCyclePeriod;
    if (phase < 0.35) {
      // Pico do flash de alarme
      final t = phase / 0.35;
      return math.sin(t * math.pi);
    }
    return 0.04; // Luz guia residual fraca
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    Vector2 camPos;
    try {
      camPos = game.camera.viewfinder.position;
    } catch (_) {
      camPos = Vector2(
        GameConstants.sectorWidth / 2,
        GameConstants.sectorHeight / 2,
      );
    }

    final width = game.visibleWorldWidth;
    final height = game.visibleWorldHeight;

    // Viewport bounds
    final viewLeft = camPos.x - width / 2;
    final viewTop = camPos.y - height / 2;

    // 1. Renderiza o Encouraçado Capital Destruído ("Aegis Sovereign")
    // Posição âncora fixa no mundo setorial com paralaxe a 12%
    const shipWorldAnchorX = GameConstants.sectorWidth * 0.38;
    const shipWorldAnchorY = GameConstants.sectorHeight * 0.32;
    final shipScreenX =
        viewLeft +
        (shipWorldAnchorX - camPos.x * parallaxFactor) % (width * 1.6) -
        width * 0.3;
    final shipScreenY =
        viewTop +
        (shipWorldAnchorY - camPos.y * parallaxFactor) % (height * 1.6) -
        height * 0.3;

    canvas.save();
    canvas.translate(shipScreenX, shipScreenY);
    canvas.rotate(-0.25); // Ligeira inclinação angular de deriva estelar

    // Silhueta do casco
    _silhouetteFillPaint.color = const Color(
      0xFF070B14,
    ).withValues(alpha: 0.42);
    canvas.drawPath(_battleshipPath, _silhouetteFillPaint);

    _silhouetteStrokePaint.color = const Color(
      0xFF142033,
    ).withValues(alpha: 0.35);
    _silhouetteStrokePaint.strokeWidth = 1.6;
    canvas.drawPath(_battleshipPath, _silhouetteStrokePaint);

    // Detalhes internos de fuselagem
    _silhouetteStrokePaint.color = const Color(
      0xFF101B2E,
    ).withValues(alpha: 0.25);
    _silhouetteStrokePaint.strokeWidth = 1.0;
    canvas.drawPath(_battleshipDetailPath, _silhouetteStrokePaint);

    // Sinalizadores luminosos do couraçado
    for (int i = 0; i < _battleshipBeacons.length; i++) {
      final beacon = _battleshipBeacons[i];
      final pulse =
          _calculateBeaconPulse(beacon.pulseOffset) * beacon.intensity;
      if (pulse > 0.05) {
        _beaconCorePaint.color = beacon.color.withValues(
          alpha: pulse.clamp(0.0, 1.0),
        );
        canvas.drawCircle(beacon.relativePos, 2.2, _beaconCorePaint);

        if (Glow.enabled) {
          _beaconHaloPaint.color = beacon.color.withValues(
            alpha: (pulse * 0.45).clamp(0.0, 1.0),
          );
          canvas.drawCircle(
            beacon.relativePos,
            6.0 + pulse * 6.0,
            _beaconHaloPaint,
          );
        }
      }
    }
    canvas.restore();

    // 2. Renderiza o Anel Orbital ("Spire Station") no quadrante Sudeste
    const stationWorldAnchorX = GameConstants.sectorWidth * 0.72;
    const stationWorldAnchorY = GameConstants.sectorHeight * 0.68;
    final stationScreenX =
        viewLeft +
        (stationWorldAnchorX - camPos.x * parallaxFactor) % (width * 1.8) -
        width * 0.4;
    final stationScreenY =
        viewTop +
        (stationWorldAnchorY - camPos.y * parallaxFactor) % (height * 1.8) -
        height * 0.4;

    canvas.save();
    canvas.translate(stationScreenX, stationScreenY);
    canvas.rotate(0.18 + _timer * 0.008); // Rotação orbital extremamente lenta

    _silhouetteStrokePaint.color = const Color(
      0xFF0C1422,
    ).withValues(alpha: 0.35);
    _silhouetteStrokePaint.strokeWidth = 14.0;
    canvas.drawPath(_stationRingPath, _silhouetteStrokePaint);

    _silhouetteStrokePaint.color = const Color(
      0xFF18283D,
    ).withValues(alpha: 0.28);
    _silhouetteStrokePaint.strokeWidth = 1.4;
    canvas.drawPath(_stationRingPath, _silhouetteStrokePaint);

    // Raio do anel para cruzetas estruturais
    _silhouetteStrokePaint.strokeWidth = 2.0;
    canvas.drawLine(
      const Offset(-260, 0),
      const Offset(260, 0),
      _silhouetteStrokePaint,
    );
    canvas.drawLine(
      const Offset(0, -260),
      const Offset(0, 260),
      _silhouetteStrokePaint,
    );

    // Sinalizadores luminosos do anel
    for (int i = 0; i < _stationBeacons.length; i++) {
      final beacon = _stationBeacons[i];
      final pulse =
          _calculateBeaconPulse(beacon.pulseOffset) * beacon.intensity;
      if (pulse > 0.05) {
        _beaconCorePaint.color = beacon.color.withValues(
          alpha: pulse.clamp(0.0, 1.0),
        );
        canvas.drawCircle(beacon.relativePos, 2.4, _beaconCorePaint);

        if (Glow.enabled) {
          _beaconHaloPaint.color = beacon.color.withValues(
            alpha: (pulse * 0.40).clamp(0.0, 1.0),
          );
          canvas.drawCircle(
            beacon.relativePos,
            7.0 + pulse * 5.0,
            _beaconHaloPaint,
          );
        }
      }
    }
    canvas.restore();
  }
}
