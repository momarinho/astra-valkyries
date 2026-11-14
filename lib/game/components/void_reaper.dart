import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/glow.dart';
import 'sector_boss.dart';

/// O Ceifador do Vácuo (The Void Reaper / Ceifador Temporal).
/// Entidade inspirada na Morte Vermelha de Vampire Survivors.
/// Desce quando o tempo limite do setor se esgota, forçando o clímax final.
/// Move-se velozmente, persegue a jogadora e inflige dano catastrófico no contato.
class VoidReaperComponent extends PositionComponent
    with HasGameReference<AsteroidsGame>, CollisionCallbacks
    implements SectorBoss {
  @override
  final double radius = 52.0;

  @override
  final double maxHp = 650000.0;

  @override
  late double hp;

  @override
  bool isDefeated = false;

  @override
  String get bossName => 'THE VOID REAPER // HARVESTER OF EXTINCTION';

  double _speed = 360.0;
  double _scytheRotation = 0.0;
  double _pulseTimer = 0.0;
  double _laughTimer = 0.0;

  final Paint _bodyPaint = Paint()..style = PaintingStyle.fill;
  final Paint _scythePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0;

  VoidReaperComponent({required Vector2 position}) {
    this.position = position;
    anchor = Anchor.center;
    size = Vector2.all(radius * 2);
    hp = maxHp;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
    game.playSfx('bomb_explode.wav');
    game.triggerScreenShake(duration: 2.0, intensity: 30.0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDefeated) return;

    _pulseTimer += dt * 4.0;
    _scytheRotation += dt * 4.5;
    _laughTimer += dt;

    if (_laughTimer >= 4.0) {
      _laughTimer = 0.0;
      game.playSfx('low_health.wav');
      game.triggerScreenShake(duration: 0.4, intensity: 8.0);
    }

    // Acelera gradualmente para ser implacável e inescapável
    _speed = (_speed + dt * 18.0).clamp(360.0, 620.0);

    // Persegue diretamente a Valquíria
    final player = game.player;
    final toPlayer = player.position - position;
    final dist = toPlayer.length;

    if (dist > 5.0) {
      final dir = toPlayer / dist;
      position += dir * (_speed * dt);
      angle = math.atan2(dir.y, dir.x);
    }

    // Mata a nave se estiver em contato direto
    if (dist <= radius + player.radius) {
      player.invulnerableTimer = 0.0;
      player.takeHit(9999.0);
    }
  }

  @override
  bool takeDamage(double damage, Vector2 hitPos) {
    if (isDefeated) return false;
    hp -= damage;

    game.spawnExplosionParticles(
      position: hitPos,
      colorChoices: [const Color(0xFFFF1744), const Color(0xFF651FFF), Colors.black],
      count: 3,
      minSize: 1.5,
      maxSize: 3.5,
      minSpeed: 40.0,
      maxSpeed: 110.0,
    );

    game.spawnFloatingText(
      hitPos,
      '-${damage.toInt()}',
      color: const Color(0xFFFF5252),
      fontSize: 12.0,
    );

    if (hp <= 0) {
      _defeat();
      return true;
    }
    return false;
  }

  void _defeat() {
    isDefeated = true;
    hp = 0;
    game.addScore(100000);
    game.addScrap(10000);
    game.playSfx('powerup.wav');
    game.triggerScreenShake(duration: 2.5, intensity: 35.0);

    game.spawnFloatingText(
      position + Vector2(0, -60),
      '👑 DEATH REAPED! THE VOID HAS FALLEN!',
      color: const Color(0xFFFFD700),
      fontSize: 24.0,
    );

    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = (size / 2).toOffset();
    final pulse = 0.90 + 0.10 * math.sin(_pulseTimer);

    // 1. Aura Sinistra de Vácuo Escuro e Carmesim
    _bodyPaint.color = const Color(0xFFFF1744).withValues(alpha: 0.25);
    canvas.drawCircle(center, radius * 1.25 * pulse, _bodyPaint);

    final auraShader = RadialGradient(
      colors: [
        const Color(0xFF1A0006).withValues(alpha: 0.95),
        const Color(0xFFFF1744).withValues(alpha: 0.6),
        const Color(0xFF651FFF).withValues(alpha: 0.0),
      ],
      stops: const [0.3, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius * pulse));

    _bodyPaint.shader = auraShader;
    canvas.drawCircle(center, radius * pulse, _bodyPaint);
    _bodyPaint.shader = null;

    // 2. Foice Espectral Giratória em Órbita
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_scytheRotation);

    final scytheOffset = Offset(radius * 0.85, 0);
    _scythePaint.color = const Color(0xFFFF1744);
    _scythePaint.strokeWidth = 3.5;

    // Lâmina curvada da foice
    final scythePath = Path();
    scythePath.moveTo(scytheOffset.dx - 15, scytheOffset.dy - 25);
    scythePath.quadraticBezierTo(
      scytheOffset.dx + 25,
      scytheOffset.dy,
      scytheOffset.dx - 10,
      scytheOffset.dy + 35,
    );
    canvas.drawPath(scythePath, _scythePaint);

    // Cabo da foice
    _scythePaint.color = const Color(0xFFB0BEC5);
    _scythePaint.strokeWidth = 2.0;
    canvas.drawLine(
      Offset(scytheOffset.dx - 18, scytheOffset.dy - 30),
      Offset(scytheOffset.dx - 5, scytheOffset.dy + 40),
      _scythePaint,
    );

    canvas.restore();

    // 3. Olhos Vermelhos Hipersensíveis e Fenda Espectral
    final eyePaint = Paint()..color = const Color(0xFFFF1744);
    canvas.drawCircle(center + const Offset(-10, -6), 4.5, eyePaint);
    canvas.drawCircle(center + const Offset(10, -6), 4.5, eyePaint);

    Glow.orb(
      canvas,
      center + const Offset(-10, -6),
      4.5,
      const Color(0xFFFF5252),
    );
    Glow.orb(
      canvas,
      center + const Offset(10, -6),
      4.5,
      const Color(0xFFFF5252),
    );
  }
}
