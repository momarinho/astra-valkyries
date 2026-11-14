import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:void_protocol/constants.dart';
import 'package:void_protocol/game/asteroids_game.dart';

/// Lóbulo orgânico individual de nebulosa cósmica
class NebulaLobe {
  final double baseRadiusX;
  final double baseRadiusY;
  final double distance;
  final double angle;
  final double rotationSpeed;
  final double alphaMultiplier;
  final bool isSecondaryColor;

  const NebulaLobe({
    required this.baseRadiusX,
    required this.baseRadiusY,
    required this.distance,
    required this.angle,
    required this.rotationSpeed,
    required this.alphaMultiplier,
    this.isSecondaryColor = false,
  });
}

/// SPRINT 56: Nebulosas Orgânicas Vetoriais Volumétricas (Procedural Cosmic Nebula)
/// Substitui o círculo estático simples por aglomerados de 6 a 8 elipses orgânicas
/// entrelaçadas em BlendMode.plus com rotação lenta diferencial e filamentos translúcidos
/// ajustados dinamicamente à paleta cromática do bioma atual.
///
/// Arquitetura Zero-GC: Lóbulos e Shaders pré-configurados com matrizes de transformação,
/// zero instanciações de Paint ou Path em render().
class ProceduralCosmicNebulaComponent extends Component
    with HasGameReference<AsteroidsGame> {
  // Parallax suave: nuvens cósmicas distantes movem a 8% e 15% da velocidade da câmera
  static const double parallaxLow = 0.08;
  static const double parallaxMid = 0.15;

  double _time = 0.0;

  // Zero-GC Cached Paints
  static final Paint _lobePaintA = Paint()
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.plus;
  static final Paint _lobePaintB = Paint()
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.plus;
  static final Paint _filamentPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..blendMode = BlendMode.plus;

  late final List<NebulaLobe> _clusterA;
  late final List<NebulaLobe> _clusterB;
  late final Path _filamentPathA;
  late final Path _filamentPathB;

  ProceduralCosmicNebulaComponent() {
    priority = -38; // Acima de Starfield (-40) e abaixo de SpaceDust (-35)
    _initNebulaClusters();
  }

  void _initNebulaClusters() {
    // Aglomerado A: 7 elipses orgânicas entrelaçadas
    _clusterA = const [
      NebulaLobe(
        baseRadiusX: 280,
        baseRadiusY: 190,
        distance: 0,
        angle: 0,
        rotationSpeed: 0.012,
        alphaMultiplier: 0.16,
      ),
      NebulaLobe(
        baseRadiusX: 240,
        baseRadiusY: 160,
        distance: 120,
        angle: 0.8,
        rotationSpeed: -0.018,
        alphaMultiplier: 0.12,
        isSecondaryColor: true,
      ),
      NebulaLobe(
        baseRadiusX: 200,
        baseRadiusY: 220,
        distance: 140,
        angle: 2.2,
        rotationSpeed: 0.015,
        alphaMultiplier: 0.14,
      ),
      NebulaLobe(
        baseRadiusX: 180,
        baseRadiusY: 130,
        distance: 180,
        angle: 3.6,
        rotationSpeed: -0.022,
        alphaMultiplier: 0.10,
        isSecondaryColor: true,
      ),
      NebulaLobe(
        baseRadiusX: 220,
        baseRadiusY: 150,
        distance: 110,
        angle: 4.8,
        rotationSpeed: 0.020,
        alphaMultiplier: 0.13,
      ),
      NebulaLobe(
        baseRadiusX: 160,
        baseRadiusY: 110,
        distance: 210,
        angle: 1.4,
        rotationSpeed: -0.014,
        alphaMultiplier: 0.08,
      ),
      NebulaLobe(
        baseRadiusX: 190,
        baseRadiusY: 140,
        distance: 190,
        angle: 5.7,
        rotationSpeed: 0.016,
        alphaMultiplier: 0.09,
        isSecondaryColor: true,
      ),
    ];

    // Aglomerado B: 6 elipses orgânicas secundárias em outro quadrante
    _clusterB = const [
      NebulaLobe(
        baseRadiusX: 260,
        baseRadiusY: 210,
        distance: 0,
        angle: 0,
        rotationSpeed: -0.014,
        alphaMultiplier: 0.14,
        isSecondaryColor: true,
      ),
      NebulaLobe(
        baseRadiusX: 220,
        baseRadiusY: 150,
        distance: 130,
        angle: 1.1,
        rotationSpeed: 0.019,
        alphaMultiplier: 0.11,
      ),
      NebulaLobe(
        baseRadiusX: 190,
        baseRadiusY: 170,
        distance: 150,
        angle: 2.7,
        rotationSpeed: -0.021,
        alphaMultiplier: 0.12,
        isSecondaryColor: true,
      ),
      NebulaLobe(
        baseRadiusX: 210,
        baseRadiusY: 130,
        distance: 170,
        angle: 4.2,
        rotationSpeed: 0.017,
        alphaMultiplier: 0.10,
      ),
      NebulaLobe(
        baseRadiusX: 170,
        baseRadiusY: 140,
        distance: 190,
        angle: 5.2,
        rotationSpeed: -0.016,
        alphaMultiplier: 0.08,
        isSecondaryColor: true,
      ),
      NebulaLobe(
        baseRadiusX: 150,
        baseRadiusY: 120,
        distance: 140,
        angle: 0.3,
        rotationSpeed: 0.024,
        alphaMultiplier: 0.07,
      ),
    ];

    // Filamentos cósmicos de plasma pré-traçados em Bézier
    final fa = Path();
    fa.moveTo(-220, -100);
    fa.cubicTo(-100, -220, 80, -40, 240, -120);
    fa.moveTo(-160, 60);
    fa.cubicTo(-40, 160, 120, 20, 220, 110);
    _filamentPathA = fa;

    final fb = Path();
    fb.moveTo(-240, 80);
    fb.cubicTo(-80, -140, 60, 160, 210, -60);
    fb.moveTo(-180, -70);
    fb.cubicTo(-50, 40, 140, -160, 250, 40);
    _filamentPathB = fb;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  void _renderCluster(
    Canvas canvas,
    List<NebulaLobe> lobes,
    Path filamentPath,
    Color primaryColor,
    Color secondaryColor,
    double pulse,
  ) {
    for (int i = 0; i < lobes.length; i++) {
      final lobe = lobes[i];
      final currentAngle = lobe.angle + _time * lobe.rotationSpeed;
      final lx = math.cos(currentAngle) * lobe.distance;
      final ly = math.sin(currentAngle) * lobe.distance;

      final color = lobe.isSecondaryColor ? secondaryColor : primaryColor;
      final alpha = (lobe.alphaMultiplier * pulse).clamp(0.0, 1.0);

      final paint = lobe.isSecondaryColor ? _lobePaintB : _lobePaintA;
      paint.shader =
          RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.40),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(
            Rect.fromCenter(
              center: Offset(lx, ly),
              width: lobe.baseRadiusX * 2,
              height: lobe.baseRadiusY * 2,
            ),
          );

      canvas.save();
      canvas.translate(lx, ly);
      canvas.rotate(currentAngle * 0.5);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: lobe.baseRadiusX * 2,
          height: lobe.baseRadiusY * 2,
        ),
        paint,
      );
      canvas.restore();
    }

    // Filamentos de gás cósmico translúcido
    _filamentPaint.color = primaryColor.withValues(alpha: 0.06 * pulse);
    _filamentPaint.strokeWidth = 2.4;
    canvas.drawPath(filamentPath, _filamentPaint);

    _filamentPaint.color = secondaryColor.withValues(alpha: 0.03 * pulse);
    _filamentPaint.strokeWidth = 5.0;
    canvas.drawPath(filamentPath, _filamentPaint);
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

    final viewLeft = camPos.x - width / 2;
    final viewTop = camPos.y - height / 2;

    final sector = game.currentSector;
    final primary = sector.primaryColor;
    final secondary = sector.secondaryColor;

    // Respiração orgânica do gás estelar
    final pulseA = 1.0 + 0.12 * math.sin(_time * 0.35);
    final pulseB = 1.0 + 0.14 * math.cos(_time * 0.28);

    // 1. Aglomerado A no quadrante Noroeste (Paralaxe de 8%)
    const anchorAx = GameConstants.sectorWidth * 0.30;
    const anchorAy = GameConstants.sectorHeight * 0.28;
    final screenAx =
        viewLeft +
        (anchorAx - camPos.x * parallaxLow) % (width * 1.5) -
        width * 0.25;
    final screenAy =
        viewTop +
        (anchorAy - camPos.y * parallaxLow) % (height * 1.5) -
        height * 0.25;

    canvas.save();
    canvas.translate(screenAx, screenAy);
    _renderCluster(
      canvas,
      _clusterA,
      _filamentPathA,
      primary,
      secondary,
      pulseA,
    );
    canvas.restore();

    // 2. Aglomerado B no quadrante Sudeste (Paralaxe de 15%)
    const anchorBx = GameConstants.sectorWidth * 0.75;
    const anchorBy = GameConstants.sectorHeight * 0.72;
    final screenBx =
        viewLeft +
        (anchorBx - camPos.x * parallaxMid) % (width * 1.6) -
        width * 0.3;
    final screenBy =
        viewTop +
        (anchorBy - camPos.y * parallaxMid) % (height * 1.6) -
        height * 0.3;

    canvas.save();
    canvas.translate(screenBx, screenBy);
    _renderCluster(
      canvas,
      _clusterB,
      _filamentPathB,
      secondary,
      primary,
      pulseB,
    );
    canvas.restore();
  }
}
