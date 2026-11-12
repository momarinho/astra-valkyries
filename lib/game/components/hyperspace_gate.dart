import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/glow.dart';

/// Portal de Hiperespaço estelar.
/// Surge quando o Chefe de Setor é destruído.
/// Ao voar para o centro do vórtice, a Valquíria salta para o próximo setor,
/// mantendo seu arsenal evoluído, nível, HP e créditos acumulados.
class HyperspaceGateComponent extends PositionComponent with HasGameReference<AsteroidsGame> {
  final double radius = 55.0;
  double _rotation = 0.0;
  double _pulseTimer = 0.0;
  double _autoWarpTimer = 0.0;
  bool _isWarping = false;

  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5;

  final Paint _corePaint = Paint()..style = PaintingStyle.fill;

  HyperspaceGateComponent({required Vector2 position}) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
  }

  @override
  void onMount() {
    super.onMount();
    game.playSfx('powerup.wav');
    game.spawnFloatingText(
      position + Vector2(0, -75),
      '🌀 PORTAL DE HIPERESPAÇO ABERTO! SALTO ESTABILIZANDO...',
      color: const Color(0xFF00E5FF),
      fontSize: 16.0,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _rotation += dt * 1.8;
    _pulseTimer += dt * 3.0;
    _autoWarpTimer += dt;

    if (_isWarping) return;

    // Checa proximidade com a nave da jogadora e atrai o vórtice suavemente
    final player = game.player;
    final dist = position.distanceTo(player.position);

    if (dist > 50.0) {
      final dir = (player.position - position).normalized();
      position += dir * 85.0 * dt;
    }

    // Se encostar no vórtice OU se passarem 3.5 segundos de comemoração pós-chefe,
    // aciona automaticamente o Mapa Estelar com as rotas do próximo setor!
    if (dist <= 80.0 || _autoWarpTimer >= 3.5) {
      _isWarping = true;
      removeFromParent();
      game.openStarChart();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final pulse = 0.88 + 0.12 * math.sin(_pulseTimer);
    final currentR = radius * pulse;
    final center = (size / 2).toOffset();

    // 1. Núcleo de Singularidade Negro com Brilho Event Horizon
    _corePaint.color = Colors.black;
    canvas.drawCircle(center, currentR * 0.75, _corePaint);

    final shader = RadialGradient(
      colors: [
        const Color(0xFF00E5FF).withValues(alpha: 0.8),
        const Color(0xFF7C4DFF).withValues(alpha: 0.5),
        const Color(0xFFFF4081).withValues(alpha: 0.0),
      ],
      stops: const [0.2, 0.65, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: currentR));

    _corePaint.shader = shader;
    _corePaint.blendMode = BlendMode.plus;
    canvas.drawCircle(center, currentR, _corePaint);
    _corePaint.shader = null;
    _corePaint.blendMode = BlendMode.srcOver;

    // 2. Anéis Concéntricos de Hiperespaço em Rotação
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_rotation);

    for (var ring = 1; ring <= 3; ring++) {
      final ringR = currentR * (0.35 + ring * 0.22);
      final ringColor = ring == 1
          ? const Color(0xFF00E5FF)
          : (ring == 2 ? const Color(0xFF7C4DFF) : const Color(0xFFFFD700));

      _ringPaint.color = ringColor.withValues(alpha: 0.75);
      _ringPaint.strokeWidth = 2.5;

      // Padrão de arcos para parecer engrenagem de dobra espacial
      for (var a = 0; a < 4; a++) {
        final startAngle = a * (math.pi / 2) + (ring.isEven ? _rotation : -_rotation);
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: ringR),
          startAngle,
          math.pi / 3,
          false,
          _ringPaint,
        );
      }
    }
    canvas.restore();

    // 3. Glifo Central Holográfico
    Glow.orb(
      canvas,
      center,
      12.0 * pulse,
      const Color(0xFF00E5FF),
    );
  }
}
