import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:void_protocol/game/glow.dart';

/// Estrutura leve de partícula em pool prealocado para eliminar alocações
/// de memória por frame (Zero-GC) e sustentar 60 FPS com centenas de fagulhas.
class PooledParticle {
  double x = 0.0;
  double y = 0.0;
  double vx = 0.0;
  double vy = 0.0;
  double initialSize = 2.0;
  double initialLifetime = 0.5;
  double lifetime = 0.0;
  Color color = Colors.white;
  bool active = false;
}

/// Sistema de partículas de alta densidade em lote (Batch Rendering).
/// Em vez de instanciar dezenas de PositionComponents no Flame, um único
/// componente gerencia e renderiza centenas de fagulhas ativas.
class FastParticlePoolComponent extends Component {
  static const int maxParticles = 900;

  final List<PooledParticle> _particles = List.generate(
    maxParticles,
    (_) => PooledParticle(),
    growable: false,
  );

  int _cursor = 0;
  final math.Random _random = math.Random();

  FastParticlePoolComponent() {
    priority = 15; // Renderiza acima de asteroides e naves, abaixo de UI
  }

  int get activeCount {
    int count = 0;
    for (var i = 0; i < maxParticles; i++) {
      if (_particles[i].active) count++;
    }
    return count;
  }

  void spawnExplosion({
    required Vector2 position,
    required List<Color> colorChoices,
    required int count,
    required double minSize,
    required double maxSize,
    required double minSpeed,
    required double maxSpeed,
  }) {
    if (colorChoices.isEmpty) return;
    final speedDiff = maxSpeed - minSpeed;
    final sizeDiff = maxSize - minSize;

    for (var i = 0; i < count; i++) {
      final p = _particles[_cursor];
      _cursor = (_cursor + 1) % maxParticles;

      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = minSpeed + _random.nextDouble() * speedDiff;
      final size = minSize + _random.nextDouble() * sizeDiff;
      final lifetime = 0.25 + _random.nextDouble() * 0.45; // 0.25s a 0.70s

      p.x = position.x;
      p.y = position.y;
      p.vx = math.cos(angle) * speed;
      p.vy = math.sin(angle) * speed;
      p.initialSize = size;
      p.initialLifetime = lifetime;
      p.lifetime = lifetime;
      p.color = colorChoices[_random.nextInt(colorChoices.length)];
      p.active = true;
    }
  }

  void spawnSparks({
    required Vector2 position,
    required Color color,
    int count = 8,
    double speed = 140.0,
  }) {
    for (var i = 0; i < count; i++) {
      final p = _particles[_cursor];
      _cursor = (_cursor + 1) % maxParticles;

      final angle = _random.nextDouble() * 2 * math.pi;
      final spd = (speed * 0.5) + _random.nextDouble() * (speed * 0.8);
      final size = 1.5 + _random.nextDouble() * 2.0;
      final lifetime = 0.12 + _random.nextDouble() * 0.18;

      p.x = position.x;
      p.y = position.y;
      p.vx = math.cos(angle) * spd;
      p.vy = math.sin(angle) * spd;
      p.initialSize = size;
      p.initialLifetime = lifetime;
      p.lifetime = lifetime;
      p.color = color;
      p.active = true;
    }
  }

  void clear() {
    for (var i = 0; i < maxParticles; i++) {
      _particles[i].active = false;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (var i = 0; i < maxParticles; i++) {
      final p = _particles[i];
      if (!p.active) continue;

      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.lifetime -= dt;

      if (p.lifetime <= 0) {
        p.active = false;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (var i = 0; i < maxParticles; i++) {
      final p = _particles[i];
      if (!p.active) continue;

      final ratio = (p.lifetime / p.initialLifetime).clamp(0.0, 1.0);
      final currentRadius = math.max(1.0, p.initialSize * ratio);
      Glow.spark(canvas, Offset(p.x, p.y), currentRadius, p.color, math.sqrt(ratio));
    }
  }
}
