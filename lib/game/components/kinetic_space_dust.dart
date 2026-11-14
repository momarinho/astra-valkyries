import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:void_protocol/constants.dart';
import 'package:void_protocol/game/asteroids_game.dart';

/// Mote individual de poeira cósmica cinética
class SpaceDustMote {
  double x;
  double y;
  final double depth; // 0.25 (distante) a 1.0 (próximo à câmera)
  final double size;
  final double baseAlpha;
  final double driftSpeed;
  final double driftAngle;
  final double twinklePhase;
  final double twinkleSpeed;

  SpaceDustMote({
    required this.x,
    required this.y,
    required this.depth,
    required this.size,
    required this.baseAlpha,
    required this.driftSpeed,
    required this.driftAngle,
    required this.twinklePhase,
    required this.twinkleSpeed,
  });
}

/// SPRINT 56: Campo Cinético de Micro-Poeira Estelar (Kinetic Space Dust)
/// 250 motes cósmicos pré-alocados que se esticam em traços direcionais:
/// L = -v_player * 0.045 * depth, transmitindo sensação tátil e visceral de velocidade
/// inercial no vácuo espacial (Padrão Nova Drift).
///
/// Arquitetura Zero-GC: 100% livre de alocações em update() e render().
class KineticSpaceDustComponent extends Component
    with HasGameReference<AsteroidsGame> {
  static const int defaultMoteCount = 250;
  final int moteCount;
  final List<SpaceDustMote> motes = [];

  // Zero-GC Cached Paints
  static final Paint _motePaint = Paint()..style = PaintingStyle.fill;
  static final Paint _haloPaint = Paint()
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.plus;
  static final Paint _streakPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  double _time = 0.0;

  KineticSpaceDustComponent({this.moteCount = defaultMoteCount}) {
    priority =
        -35; // Renderiza acima do Starfield (-40) e abaixo dos POIs/Entidades (0+)
  }

  @override
  void onMount() {
    super.onMount();
    _initMotes();
  }

  void _initMotes() {
    motes.clear();
    final rng = math.Random(56250);
    final width = GameConstants.screenWidth;
    final height = GameConstants.screenHeight;

    for (int i = 0; i < moteCount; i++) {
      // Distribuição de profundidade: mais partículas no plano médio e profundo
      final roll = rng.nextDouble();
      final depth = 0.25 + (roll * roll) * 0.75; // 0.25 a 1.0
      final size = 0.8 + depth * 1.4; // 0.8px a 2.2px
      final baseAlpha = 0.30 + depth * 0.55; // 0.30 a 0.85

      motes.add(
        SpaceDustMote(
          x: rng.nextDouble() * width,
          y: rng.nextDouble() * height,
          depth: depth,
          size: size,
          baseAlpha: baseAlpha,
          driftSpeed: 2.0 + rng.nextDouble() * 6.0,
          driftAngle: rng.nextDouble() * 2 * math.pi,
          twinklePhase: rng.nextDouble() * 2 * math.pi,
          twinkleSpeed: 1.2 + rng.nextDouble() * 2.8,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    if (motes.isEmpty) return;

    final width = GameConstants.screenWidth;
    final height = GameConstants.screenHeight;

    // Obtém vetor de velocidade real da nave da jogadora
    double pvx = 0.0;
    double pvy = 0.0;
    try {
      if (game.state == GameState.playing) {
        pvx = game.player.velocity.x;
        pvy = game.player.velocity.y;
      }
    } catch (_) {}

    for (int i = 0; i < motes.length; i++) {
      final mote = motes[i];

      // Movimento do mote: deriva browniana sutil + reação inercial oposta à velocidade da nave
      final driftX = math.cos(mote.driftAngle) * mote.driftSpeed;
      final driftY = math.sin(mote.driftAngle) * mote.driftSpeed;

      mote.x += (driftX - pvx * 0.045 * mote.depth) * dt;
      mote.y += (driftY - pvy * 0.045 * mote.depth) * dt;

      // Wrapping contínuo e sem costura nos limites do campo de visão da tela
      if (mote.x < 0) {
        mote.x += width;
      } else if (mote.x > width) {
        mote.x -= width;
      }

      if (mote.y < 0) {
        mote.y += height;
      } else if (mote.y > height) {
        mote.y -= height;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (motes.isEmpty) return;

    final width = GameConstants.screenWidth;
    final height = GameConstants.screenHeight;
    final viewW = game.visibleWorldWidth;
    final viewH = game.visibleWorldHeight;
    final scaleX = viewW / width;
    final scaleY = viewH / height;

    Vector2 camPos;
    try {
      camPos = game.camera.viewfinder.position;
    } catch (_) {
      camPos = Vector2(width / 2, height / 2);
    }

    canvas.save();
    canvas.translate(camPos.x - viewW / 2, camPos.y - viewH / 2);

    // Obtém velocidade da nave para estiramento cinético
    double pvx = 0.0;
    double pvy = 0.0;
    try {
      if (game.state == GameState.playing) {
        pvx = game.player.velocity.x;
        pvy = game.player.velocity.y;
      }
    } catch (_) {}

    final speedSq = pvx * pvx + pvy * pvy;
    final isStretching =
        speedSq > 225.0; // Velocidade > 15 px/s estica os motes
    final starColor = game.currentSector.starColor;

    for (int i = 0; i < motes.length; i++) {
      final mote = motes[i];
      final mx = mote.x * scaleX;
      final my = mote.y * scaleY;

      // Cintilação suave
      final twinkle =
          0.65 + 0.35 * math.sin(_time * mote.twinkleSpeed + mote.twinklePhase);
      final alpha = (mote.baseAlpha * twinkle).clamp(0.0, 1.0);

      if (isStretching) {
        // Estiramento direcional: L = -v_player * 0.045 * depth
        double streakX = -pvx * 0.045 * mote.depth;
        double streakY = -pvy * 0.045 * mote.depth;

        // Limita o comprimento máximo do traço para evitar artefatos em transições
        final streakLenSq = streakX * streakX + streakY * streakY;
        if (streakLenSq > 2025.0) {
          // 45px máx
          final factor = 45.0 / math.sqrt(streakLenSq);
          streakX *= factor;
          streakY *= factor;
        }

        _streakPaint.color = Color.lerp(
          Colors.white,
          starColor,
          0.35,
        )!.withValues(alpha: alpha * 0.85);
        _streakPaint.strokeWidth = mote.size * 0.95;

        canvas.drawLine(
          Offset(mx, my),
          Offset(mx + streakX, my + streakY),
          _streakPaint,
        );

        // Ponto brilhante na cabeça do traço
        _motePaint.color = Colors.white.withValues(alpha: alpha);
        canvas.drawCircle(Offset(mx, my), mote.size * 0.6, _motePaint);
      } else {
        // Em baixa velocidade: partícula cósmica esférica suave com micro-halo aditivo
        final center = Offset(mx, my);

        if (mote.depth > 0.7) {
          _haloPaint.color = starColor.withValues(alpha: alpha * 0.22);
          canvas.drawCircle(center, mote.size * 2.4, _haloPaint);
        }

        _motePaint.color = Color.lerp(
          Colors.white,
          starColor,
          0.25,
        )!.withValues(alpha: alpha);
        canvas.drawCircle(center, mote.size * 0.75, _motePaint);
      }
    }

    canvas.restore();
  }
}
