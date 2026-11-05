import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:asteroids/game/components/space_station.dart';
import 'package:asteroids/game/components/cargo_wreck.dart';
import 'package:asteroids/game/components/cosmic_nebula.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Procedural Scenery & POI Gameplay Mechanics Tests', () {
    test('CosmicNebulaComponent correctly calculates spatial containment', () {
      final nebula = CosmicNebulaComponent(
        position: Vector2(2000, 2000),
        type: NebulaType.ionCloud,
        radius: 400.0,
      );

      // Center point is inside
      expect(nebula.containsPoint(Vector2(2000, 2000)), isTrue);
      // Point 200px away is inside
      expect(nebula.containsPoint(Vector2(2150, 2100)), isTrue);
      // Boundary point
      expect(nebula.containsPoint(Vector2(2400, 2000)), isTrue);
      // Point 500px away is outside
      expect(nebula.containsPoint(Vector2(2500, 2000)), isFalse);
    });

    test('CosmicNebulaComponent attributes reflect tactical combat risk/reward types', () {
      final ionNebula = CosmicNebulaComponent(
        position: Vector2(3000, 3000),
        type: NebulaType.ionCloud,
      );
      expect(ionNebula.name, equals('ION NEBULA'));
      expect(ionNebula.modifierText.contains('HYPER-CADENCE'), isTrue);
      expect(ionNebula.modifierText.contains('SHIELD DISRUPTION'), isTrue);

      final darkMatter = CosmicNebulaComponent(
        position: Vector2(1000, 1000),
        type: NebulaType.darkMatter,
      );
      expect(darkMatter.name, equals('DARK MATTER POCKET'));
      expect(darkMatter.modifierText.contains('CRIT CHANCE'), isTrue);
      expect(darkMatter.modifierText.contains('GRAVITY DAMPED'), isTrue);
    });

    test('CargoWreckComponent manages armor health and destruction threshold', () {
      final wreck = CargoWreckComponent(position: Vector2(500, 500));
      expect(wreck.hp, equals(180.0));
      expect(wreck.maxHp, equals(180.0));

      // Partial damage does not breach
      final breached1 = wreck.takeDamage(60.0, Vector2(500, 500));
      expect(breached1, isFalse);
      expect(wreck.hp, equals(120.0));
      expect(wreck.hitFlashTimer, greaterThan(0.0));

      // Second hit that doesn't breach
      final breached2 = wreck.takeDamage(50.0, Vector2(500, 500));
      expect(breached2, isFalse);
      expect(wreck.hp, equals(70.0));
    });

    test('SpaceStationComponent initializes transmission parameters accurately', () {
      final station = SpaceStationComponent(position: Vector2(1500, 1500));
      expect(SpaceStationComponent.transmissionRadius, equals(240.0));
      expect(SpaceStationComponent.targetUploadTime, equals(15.0));
      expect(station.uploadProgress, equals(0.0));
      expect(station.isSecured, isFalse);
      expect(station.isPlayerInZone, isFalse);
    });
  });
}
