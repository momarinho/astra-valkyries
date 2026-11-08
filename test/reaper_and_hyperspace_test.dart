import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/sector.dart';
import 'package:asteroids/game/components/hyperspace_gate.dart';
import 'package:asteroids/game/components/void_reaper.dart';
import 'package:asteroids/game/components/ignis_wyrm.dart';
import 'package:asteroids/game/components/dreadnought_leviathan.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/valkyrie.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vampire Survivors Mechanics: Void Reaper & Hyperspace Jump Gate Tests', () {
    test('HyperspaceGateComponent advances game from Vesta to Orion retaining progress', () {
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.roster.first;
      game.currentSector = Sector.findById(SectorId.vesta);
      game.player = PlayerComponent(position: Vector2(2500, 2500));
      game.state = GameState.playing;
      game.timeRemaining = 12.0;
      game.runCredits = 450;

      // Jump to next sector
      game.jumpToNextSector();

      expect(game.currentSector.id, equals(SectorId.orion));
      expect(game.timeRemaining, equals(AsteroidsGame.fairRoundDuration));
      expect(game.runCredits, equals(1450)); // +1000 scrap reward
      expect(game.voidReaperSpawned, isFalse);
    });

    test('HyperspaceGateComponent sequence wraps through all 4 sectors', () {
      final game = AsteroidsGame();
      game.selectedValkyrie = Valkyrie.roster.first;
      game.player = PlayerComponent(position: Vector2(2500, 2500));
      game.state = GameState.playing;

      expect(game.currentSector.id, equals(SectorId.vesta));
      game.jumpToNextSector();
      expect(game.currentSector.id, equals(SectorId.orion));
      game.jumpToNextSector();
      expect(game.currentSector.id, equals(SectorId.graveyard));
      game.jumpToNextSector();
      expect(game.currentSector.id, equals(SectorId.eventHorizon));
      game.jumpToNextSector();
      expect(game.currentSector.id, equals(SectorId.vesta)); // Loops into NG+ Cataclysm
    });

    test('VoidReaperComponent initializes with terrifying boss stats and scythe aura', () {
      final reaper = VoidReaperComponent(position: Vector2(200, 200));
      expect(reaper.maxHp, equals(650000.0));
      expect(reaper.hp, equals(650000.0));
      expect(reaper.isDefeated, isFalse);
      expect(reaper.bossName, contains('VOID REAPER'));
      expect(reaper.radius, equals(52.0));
    });

    test('IgnisWyrmComponent has articulated segments and implements SectorBoss', () {
      final wyrm = IgnisWyrmComponent(position: Vector2(500, 500));
      expect(wyrm.maxHp, equals(4200.0));
      expect(wyrm.hp, equals(4200.0));
      expect(wyrm.segments.length, equals(8));
      expect(wyrm.bossName, contains('IGNIS WYRM'));
      expect(wyrm.isDefeated, isFalse);
    });

    test('Engine tracks real-time FPS and frame time smoothly', () {
      final game = AsteroidsGame();
      expect(game.currentFps, equals(60.0));
      expect(game.currentFrameTimeMs, equals(16.6));

      // Simulate a 60 FPS delta (0.0166s)
      game.update(0.0166);
      expect(game.currentFps, closeTo(60.0, 1.0));
      expect(game.currentFrameTimeMs, closeTo(16.6, 0.5));
    });
  });
}
