import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';

enum SpeechTrigger {
  hyperspaceJump,
  bossArrival,
  criticalHull,
  superWeapon,
  flawlessVictory,
  flightRecorderFound,
}

/// Componente de Balão de Fala em Combate (Sprint 23 — Anime / Comic Speech Bubbles).
/// Renderizado acima da nave da jogadora com mini-retrato da Valquíria ativa,
/// efeito de texto datilografado (typewriter) e SFX de comunicação por rádio.
class SpeechBubbleComponent extends PositionComponent
    with HasGameReference<AsteroidsGame> {
  final String valkyrieId;
  final String valkyrieName;
  final String fullText;
  final SpeechTrigger trigger;
  final Color accentColor;
  final double duration;
  double elapsedTimer = 0.0;

  SpeechBubbleComponent({
    required this.valkyrieId,
    required this.valkyrieName,
    required this.fullText,
    required this.trigger,
    this.accentColor = const Color(0xFF00E5FF),
    this.duration = 3.8,
  }) : super(
          size: Vector2(260.0, 54.0),
          anchor: Anchor.bottomCenter,
          priority: 50,
        );

  /// Texto datilografado progressivamente (Typewriter Effect)
  String get displayedText {
    if (fullText.isEmpty) return '';
    final charsToShow = (elapsedTimer * 48.0).floor().clamp(1, fullText.length);
    return fullText.substring(0, charsToShow);
  }

  static String getContextualLine(String valkyrieId, SpeechTrigger trigger) {
    switch (trigger) {
      case SpeechTrigger.hyperspaceJump:
        switch (valkyrieId) {
          case 'kbr_01':
          case 'kaede':
            return 'Salto de dobra concluído. Protocolo KBR ativo... corte no primeiro instante.';
          case 'selene':
            return 'Sensores quânticos calibrados. Iniciando varredura tática do setor.';
          case 'vesper':
            return 'Saímos da dobra. Vamos caçar nas sombras antes que nos notem.';
          case 'astraea':
            return 'As estrelas antigas ainda ecoam neste quadrante. Avancem!';
          case 'lyra':
          default:
            return 'Propulsores no máximo! Vamos abrir caminho a fogo, Comandante!';
        }
      case SpeechTrigger.bossArrival:
        switch (valkyrieId) {
          case 'kbr_01':
          case 'kaede':
            return 'Assinatura de combate confirmada. Protocolo KBR cortará suas defesas em um só golpe.';
          case 'selene':
            return 'Assinatura de massa colossal detectada! Mantenham distância segura!';
          case 'vesper':
            return 'Um Titã do Vazio... Quanto maior o alvo, mais letal a minha lâmina.';
          case 'astraea':
            return 'Guardião corrompido do Protocolo... Eu mesma colocarei fim à sua dor!';
          case 'lyra':
          default:
            return 'Leituras térmicas subindo 800%! O Titã do Setor apareceu!';
        }
      case SpeechTrigger.criticalHull:
        switch (valkyrieId) {
          case 'kbr_01':
          case 'kaede':
            return 'Casco sob estresse crítico... Protocolo KBR em sobretensão, não posso hesitar.';
          case 'selene':
            return 'Alerta vermelho! Integridade estrutural abaixo de 25%! Preciso de reparos!';
          case 'vesper':
            return 'Tsc... Esse tiro passou perto demais! Ativando evasão de emergência!';
          case 'astraea':
            return 'Minha luz está oscilando... Não posso sucumbir ao ciclo agora!';
          case 'lyra':
          default:
            return 'Sistemas primários em chamas! Preciso de manobra evasiva urgente!';
        }
      case SpeechTrigger.superWeapon:
        switch (valkyrieId) {
          case 'kbr_01':
          case 'kaede':
            return 'Lâmina de Tácions desembainhada... Juízo Dimensional do Vazio!';
          case 'selene':
            return 'Limitadores removidos! Liberando feixe de Zero Absoluto!';
          case 'vesper':
            return 'Que o horizonte de eventos devore todos vocês! Desapareçam!';
          case 'astraea':
            return 'Contemplem o esplendor da Gênese Estelar! Purificação total!';
          case 'lyra':
          default:
            return 'Sobrecarga máxima engajada! Sintam o poder da Supernova!';
        }
      case SpeechTrigger.flawlessVictory:
        switch (valkyrieId) {
          case 'kbr_01':
          case 'kaede':
            return 'Nenhum movimento desperdiçado. Protocolo KBR concluído com corte limpo.';
          case 'selene':
            return 'Alvo neutralizado com 100% de integridade. Cálculos perfeitos.';
          case 'vesper':
            return 'Nem sequer conseguiram tocar na minha sombra. Patético.';
          case 'astraea':
            return 'Intocada pela corrupção. O caminho para o Trono se abre.';
          case 'lyra':
          default:
            return 'Nenhum arranhão na pintura! É assim que uma Valquíria pilota!';
        }
      case SpeechTrigger.flightRecorderFound:
        return 'Caixa Preta recuperada! Gravando diário da tripulação no Códice.';
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    elapsedTimer += dt;
    try {
      position = game.player.position + Vector2(0, -34);
    } catch (_) {}

    if (elapsedTimer >= duration) {
      if (game.activeSpeechBubble == this) {
        game.activeSpeechBubble = null;
      }
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final fadeAlpha = elapsedTimer > duration - 0.45
        ? ((duration - elapsedTimer) / 0.45).clamp(0.0, 1.0)
        : 1.0;
    if (fadeAlpha <= 0.02) return;

    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y - 8.0),
      const Radius.circular(8),
    );

    // 1. Corpo do balão estilo Anime/Cyber-Comic
    canvas.drawRRect(
      boxRect,
      Paint()
        ..color = const Color(0xFF080E1E).withValues(alpha: 0.92 * fadeAlpha)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      boxRect,
      Paint()
        ..color = accentColor.withValues(alpha: 0.90 * fadeAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // 2. Cauda apontando para a nave da Valquíria
    final tail = Path()
      ..moveTo(size.x / 2 - 7, size.y - 8.0)
      ..lineTo(size.x / 2, size.y)
      ..lineTo(size.x / 2 + 7, size.y - 8.0)
      ..close();
    canvas.drawPath(
      tail,
      Paint()
        ..color = accentColor.withValues(alpha: 0.90 * fadeAlpha)
        ..style = PaintingStyle.fill,
    );

    // 3. Mini-Retrato / Avatar Badge da Valquíria à esquerda
    final avatarRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(6, 6, 34, 34),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      avatarRect,
      Paint()
        ..color = accentColor.withValues(alpha: 0.24 * fadeAlpha)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      avatarRect,
      Paint()
        ..color = accentColor.withValues(alpha: 0.85 * fadeAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    final initialPainter = TextPainter(
      text: TextSpan(
        text: valkyrieName.isNotEmpty ? valkyrieName[0].toUpperCase() : 'V',
        style: TextStyle(
          color: Colors.white.withValues(alpha: fadeAlpha),
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    initialPainter.paint(
      canvas,
      Offset(23 - initialPainter.width / 2, 23 - initialPainter.height / 2),
    );

    // 4. Cabeçalho com Callsign + Ícone de Rádio e Texto Datilografado
    final headerPainter = TextPainter(
      text: TextSpan(
        text: '📻 ${valkyrieName.toUpperCase()} // COMMS',
        style: TextStyle(
          color: accentColor.withValues(alpha: fadeAlpha),
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x - 50);
    headerPainter.paint(canvas, const Offset(46, 5));

    final bodyPainter = TextPainter(
      text: TextSpan(
        text: displayedText,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95 * fadeAlpha),
          fontSize: 9.8,
          fontWeight: FontWeight.w600,
          height: 1.15,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    )..layout(maxWidth: size.x - 50);
    bodyPainter.paint(canvas, const Offset(46, 18));
  }
}
