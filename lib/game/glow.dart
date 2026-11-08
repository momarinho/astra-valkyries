import 'dart:math' as math;
import 'dart:ui';

/// Helpers de brilho neon usados por naves, tiros, meteoros e partículas.
///
/// O "bloom" é simulado com camadas translúcidas desenhadas em
/// `BlendMode.plus` (brilho aditivo), o que é barato mesmo com dezenas de
/// objetos na tela. Apenas objetos únicos (como a nave do jogador) usam
/// `MaskFilter.blur` de verdade.
class Glow {
  /// Permite desligar todos os brilhos caso a máquina da feira engasgue.
  static bool enabled = true;

  static final MaskFilter _heroBlur = MaskFilter.blur(BlurStyle.normal, 5.0);

  // Instâncias estáticas reutilizáveis de Paint para eliminar alocações por frame (Zero Garbage Collection)
  static final Paint _halo1 = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..blendMode = BlendMode.plus;

  static final Paint _halo2 = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..blendMode = BlendMode.plus;

  static final Paint _coreStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  static final Paint _heroPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..maskFilter = _heroBlur
    ..blendMode = BlendMode.plus;

  static final Paint _orbHalo1 = Paint()
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.plus;

  static final Paint _orbHalo2 = Paint()
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.plus;

  static final Paint _orbHalo3 = Paint()
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.plus;

  static final Paint _orbCore = Paint()..style = PaintingStyle.fill;
  static final Paint _orbCenter = Paint()..style = PaintingStyle.fill;

  static final Paint _sparkHalo = Paint()
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.plus;

  static final Paint _sparkCore = Paint()..style = PaintingStyle.fill;

  /// Contorno com halo neon: duas camadas aditivas largas + traço nítido.
  static void strokePath(
    Canvas canvas,
    Path path,
    Color color, {
    double width = 2.0,
    double intensity = 1.0,
  }) {
    if (enabled) {
      _halo1.color = color.withValues(alpha: 0.10 * intensity);
      _halo1.strokeWidth = width * 5.5;
      canvas.drawPath(path, _halo1);

      _halo2.color = color.withValues(alpha: 0.22 * intensity);
      _halo2.strokeWidth = width * 2.6;
      canvas.drawPath(path, _halo2);
    }
    _coreStroke.color = color;
    _coreStroke.strokeWidth = width;
    canvas.drawPath(path, _coreStroke);
  }

  /// Igual a [strokePath], mas com blur real. Use só em objetos únicos.
  static void heroStrokePath(
    Canvas canvas,
    Path path,
    Color color, {
    double width = 2.0,
    double intensity = 1.0,
  }) {
    if (enabled) {
      _heroPaint.color = color.withValues(alpha: 0.55 * intensity);
      _heroPaint.strokeWidth = width * 3.2;
      canvas.drawPath(path, _heroPaint);
    }
    strokePath(canvas, path, color, width: width, intensity: enabled ? intensity * 0.6 : 0);
  }

  /// Contorno circular com halo neon (anéis de explosão, escudos etc.).
  static void strokeCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double width = 2.0,
    double intensity = 1.0,
  }) {
    final path = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    strokePath(canvas, path, color, width: width, intensity: intensity);
  }

  static void drawGlowCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double strokeWidth = 2.0,
    double intensity = 1.0,
  }) => strokeCircle(canvas, center, radius, color, width: strokeWidth, intensity: intensity);

  /// Esfera luminosa: halo aditivo em camadas + núcleo quase branco.
  static void orb(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    double intensity = 1.0,
  }) {
    if (enabled) {
      _orbHalo1.color = color.withValues(alpha: 0.07 * intensity);
      canvas.drawCircle(center, radius * 3.4, _orbHalo1);

      _orbHalo2.color = color.withValues(alpha: 0.18 * intensity);
      canvas.drawCircle(center, radius * 2.2, _orbHalo2);

      _orbHalo3.color = color.withValues(alpha: 0.40 * intensity);
      canvas.drawCircle(center, radius * 1.4, _orbHalo3);
    }
    _orbCore.color = color;
    canvas.drawCircle(center, radius, _orbCore);
    _orbCenter.color = Color.lerp(color, const Color(0xFFFFFFFF), 0.85)!;
    canvas.drawCircle(center, radius * 0.55, _orbCenter);
  }

  /// Faísca/partícula brilhante, mais leve que [orb] (usada às centenas).
  static void spark(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double alpha,
  ) {
    final a = alpha.clamp(0.0, 1.0);
    if (enabled) {
      _sparkHalo.color = color.withValues(alpha: 0.16 * a);
      canvas.drawCircle(center, radius * 2.4, _sparkHalo);
    }
    _sparkCore.color = color.withValues(alpha: a);
    _sparkCore.blendMode = enabled ? BlendMode.plus : BlendMode.srcOver;
    canvas.drawCircle(center, radius, _sparkCore);
  }

  /// Interpola suavemente entre duas cores em [t] (0..1).
  static Color mix(Color a, Color b, double t) =>
      Color.lerp(a, b, math.min(1.0, math.max(0.0, t)))!;
}
