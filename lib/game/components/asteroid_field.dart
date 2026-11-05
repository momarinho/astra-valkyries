import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'asteroid.dart';

class AsteroidField extends Component with HasGameReference<AsteroidsGame> {
  final String mode;
  double spawnTimer = 0.0;
  double difficultyTimer = 0.0;
  double spawnRateMultiplier = 1.0;
  double speedMultiplier = 1.0;

  AsteroidField({this.mode = 'classic'});

  @override
  void update(double dt) {
    super.update(dt);
    
    // NUNCA spawnar meteoros fora do estado de partida ativa
    if (game.state != GameState.playing || mode == 'campaign') {
      return;
    }

    // Sempre avança o tempo de jogo e dificuldade progressiva
    spawnTimer += dt;
    difficultyTimer += dt;

    double spawnInterval;
    if (difficultyTimer < 50.0) {
      // Fase 1 (0-50s): Introdução suave e tranquila (onboarding para crianças)
      final p = difficultyTimer / 50.0;
      spawnInterval = 3.2 - (p * 1.0); // 3.2s -> 2.2s
      speedMultiplier = 0.55 + (p * 0.30); // 0.55x -> 0.85x
    } else if (difficultyTimer < 105.0) {
      // Fase 2 (50-105s): Ritmo Arcade progressivo equilibrado
      final p = (difficultyTimer - 50.0) / 55.0;
      spawnInterval = 2.2 - (p * 0.90); // 2.2s -> 1.30s
      speedMultiplier = 0.85 + (p * 0.40); // 0.85x -> 1.25x
    } else if (difficultyTimer < 150.0) {
      // Fase 3 (105-150s): Pressão Crescente
      final p = (difficultyTimer - 105.0) / 45.0;
      spawnInterval = 1.30 - (p * 0.60); // 1.30s -> 0.70s
      speedMultiplier = 1.25 + (p * 0.50); // 1.25x -> 1.75x
    } else {
      // Fase 4 (150-180s - Últimos 30s): HIPER TEMPESTADE FINAL (Muito difícil)
      final p = ((difficultyTimer - 150.0) / 30.0).clamp(0.0, 1.0);
      spawnInterval = 0.70 - (p * 0.44); // 0.70s -> 0.26s!!
      speedMultiplier = 1.75 + (p * 0.90); // 1.75x -> 2.65x!!
    }

    if (spawnTimer > spawnInterval) {
      spawnTimer = 0.0;
      final activeAsteroids = game.world.children.whereType<AsteroidComponent>().length;
      // Permite até 38 meteoros simultâneos na tela (intenso e sem engasgos)
      if (activeAsteroids < 38) {
        _spawnAsteroid();

        // Na tempestade final, alta frequência de spawns duplos se houver espaço
        if (difficultyTimer >= 150.0 && math.Random().nextDouble() < 0.65 && activeAsteroids < 36) {
          _spawnAsteroid();
        }
      }
    }
  }

  void _spawnAsteroid() {
    if (game.state != GameState.playing) return;
    if (game.world.children.whereType<AsteroidComponent>().length >= 38) return;

    final random = math.Random();
    Vector2 playerPos;
    try {
      playerPos = game.player.position;
    } catch (_) {
      playerPos = Vector2(GameConstants.sectorWidth / 2, GameConstants.sectorHeight / 2);
    }

    // Dynamic proximity spawn radius: just outside the camera viewport (780px to 1100px)
    final spawnDist = GameConstants.proximitySpawnMinRadius +
        random.nextDouble() * (GameConstants.proximitySpawnMaxRadius - GameConstants.proximitySpawnMinRadius);
    final spawnAngle = random.nextDouble() * 2 * math.pi;
    final spawnOffset = Vector2(math.cos(spawnAngle), math.sin(spawnAngle))..scale(spawnDist);
    final position = playerPos + spawnOffset;

    // Clamp within sector coordinates
    position.x = position.x.clamp(60.0, GameConstants.sectorWidth - 60.0);
    position.y = position.y.clamp(60.0, GameConstants.sectorHeight - 60.0);

    // Speed starts slow at ~20-40 px/s, scaling up to ~100-200 px/s in storm
    final speed = (35.0 + random.nextDouble() * 45.0) * speedMultiplier;
    
    // Trajectory aims towards player vicinity with random angular deviation (-45 to +45 deg)
    final toPlayer = (playerPos - position).normalized();
    final deviationAngle = (-45.0 + random.nextDouble() * 90.0) * math.pi / 180.0;
    final velocity = toPlayer.clone()..rotate(deviationAngle);
    velocity.scale(speed);

    // Kind/Size: In phase 1, spawn large asteroids (kind 2 or 3) for easy target practice
    final int kind;
    if (difficultyTimer < 50.0) {
      kind = random.nextBool() ? 2 : 3;
    } else {
      kind = random.nextInt(GameConstants.asteroidKinds) + 1;
    }
    final radius = GameConstants.asteroidMinRadius * kind;

    final asteroid = AsteroidComponent(
      radius: radius,
      position: position,
      velocity: velocity,
    );
    game.world.add(asteroid);
  }

  String dangerLevel() {
    if (spawnRateMultiplier >= 2.0 || speedMultiplier >= 1.7) {
      return "High";
    }
    if (spawnRateMultiplier >= 1.5 || speedMultiplier >= 1.35) {
      return "Medium";
    }
    return "Low";
  }
}
