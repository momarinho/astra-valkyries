import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/services/sound_engine.dart';
import 'package:asteroids/game/asteroids_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (call) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async => null,
    );
  });

  group('Advanced SoundEngine Tests (Stem Channels, Concurrency & Arpeggio)', () {
    test('SoundEngine initializes 13 dedicated channel players without cross-talk', () {
      final engine = SoundEngine();
      engine.initialize();

      expect(engine.allPlayers.length, 13);
      for (final p in engine.allPlayers) {
        expect(p.audioCache.prefix, 'assets/sounds/');
      }

      engine.dispose();
      expect(engine.allPlayers.isEmpty, isTrue);
    });

    test('Sound Profiles map each game sound to its dedicated functional category', () {
      expect(SoundEngine.profiles['shoot.wav']?.category, SoundCategory.gunfire);
      expect(SoundEngine.profiles['shoot.wav']?.maxConcurrency, 3);
      expect(SoundEngine.profiles['shoot.wav']?.pitchJitter, isTrue);

      expect(SoundEngine.profiles['asteroid_split.wav']?.category, SoundCategory.impacts);
      expect(SoundEngine.profiles['bomb_explode.wav']?.category, SoundCategory.impacts);
      expect(SoundEngine.profiles['player_hit.wav']?.category, SoundCategory.impacts);

      expect(SoundEngine.profiles['dash.wav']?.category, SoundCategory.actions);
      expect(SoundEngine.profiles['special.wav']?.category, SoundCategory.actions);
      expect(SoundEngine.profiles['katana_slash.wav']?.category, SoundCategory.actions);

      expect(SoundEngine.profiles['powerup.wav']?.category, SoundCategory.pickups);
      expect(SoundEngine.profiles['powerup.wav']?.arpeggio, isTrue);
      expect(SoundEngine.profiles['titanium_mine.wav']?.category, SoundCategory.pickups);

      expect(SoundEngine.profiles['boss_spawn.wav']?.category, SoundCategory.criticalUi);
      expect(SoundEngine.profiles['boss_spawn.wav']?.triggersDucking, isTrue);
      expect(SoundEngine.profiles['low_health.wav']?.category, SoundCategory.criticalUi);
      expect(SoundEngine.profiles['level_up.wav']?.category, SoundCategory.criticalUi);
    });

    test('Dynamic Ducking attenuates background gunfire during critical cues', () {
      final engine = SoundEngine();
      expect(engine.currentDuckingFactor, 1.0);

      // Trigger ducking for 500ms
      engine.triggerDucking(500);
      expect(engine.currentDuckingFactor, 0.55);
    });

    test('AsteroidsGame routes playSfx through SoundEngine without crashing', () async {
      final game = AsteroidsGame();
      game.initSfxPlayers();
      expect(game.sfxPlayers.length, 13);

      // Rapid gunfire calls
      for (int i = 0; i < 5; i++) {
        game.playSfx('shoot.wav');
      }

      // Impact & pickup calls simultaneously
      game.playSfx('asteroid_split.wav');
      game.playSfx('powerup.wav');
      game.playSfx('dash.wav');
      game.playSfx('boss_spawn.wav');

      // Ducking should be activated by boss_spawn.wav
      expect(game.soundEngine.currentDuckingFactor, 0.55);

      game.onRemove();
      expect(game.sfxPlayers.isEmpty, isTrue);
    });
  });
}
