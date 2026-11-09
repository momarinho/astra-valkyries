import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/game/affinity_system.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/drop.dart';
import 'package:asteroids/ui/valkyrie_selection_overlay.dart';

void main() {
  group('Sprint 5: Pilot Affinity & Bond Core Domain Tests', () {
    test('ValkyrieAffinity initializes at Level 1 and advances through XP curve up to Level 5', () {
      final affinity = ValkyrieAffinity(valkyrieId: 'lyra');

      expect(affinity.bondLevel, equals(1));
      expect(affinity.currentXp, equals(0));
      expect(affinity.bondTitle, equals('Recruta da Frota'));
      expect(affinity.bondCritBonus, equals(0.0));
      expect(affinity.bondSpeedBonus, equals(0.0));

      // Level 1 -> 2 requires 100 XP
      final leveledTo2 = affinity.addXp(100);
      expect(leveledTo2, isTrue);
      expect(affinity.bondLevel, equals(2));
      expect(affinity.bondTitle, equals('Companheira de Esquadrão'));
      expect(affinity.bondCritBonus, closeTo(0.02, 0.001));
      expect(affinity.bondSpeedBonus, closeTo(0.02, 0.001));

      // Level 2 -> 3 requires 250 XP
      affinity.addXp(250);
      expect(affinity.bondLevel, equals(3));
      expect(affinity.bondTitle, equals('Confidente Tática'));
      expect(affinity.bondCritBonus, closeTo(0.04, 0.001));

      // Level 3 -> 4 requires 500 XP
      affinity.addXp(500);
      expect(affinity.bondLevel, equals(4));
      expect(affinity.bondTitle, equals('Elo de Almas'));

      // Level 4 -> 5 requires 1000 XP
      affinity.addXp(1000);
      expect(affinity.bondLevel, equals(5));
      expect(affinity.bondTitle, equals('Votos Eternos'));
      expect(affinity.bondCritBonus, closeTo(0.08, 0.001));
      expect(affinity.progressPercent, equals(1.0));

      // Further XP does not exceed Level 5 (cap)
      final leveledPastMax = affinity.addXp(5000);
      expect(leveledPastMax, isFalse);
      expect(affinity.bondLevel, equals(5));
    });

    test('AffinityManager tracks unique affinities for all 3 pilots and serializes to JSON', () {
      final manager = AffinityManager();
      final lyra = manager.getAffinity('lyra');
      final selene = manager.getAffinity('selene');
      final vesper = manager.getAffinity('vesper');

      lyra.addXp(100); // Lvl 2
      selene.addXp(350); // Lvl 3

      expect(manager.getAffinity('lyra').bondLevel, equals(2));
      expect(manager.getAffinity('selene').bondLevel, equals(3));
      expect(manager.getAffinity('vesper').bondLevel, equals(1));

      final json = lyra.toJson();
      final restored = ValkyrieAffinity.fromJson(json);
      expect(restored.valkyrieId, equals('lyra'));
      expect(restored.bondLevel, equals(2));
    });

    test('PilotDialogue returns reactive dialogues based on current bond level', () {
      final manager = AffinityManager();
      final lyraAffinity = manager.getAffinity('lyra');

      // Bond Level 1 dialog
      final lvl1Dialogue = manager.getRandomDialogue('lyra');
      expect(lvl1Dialogue.isNotEmpty, isTrue);

      // Bond Level 5 unlock intimate dialogue pool
      lyraAffinity.bondLevel = 5;
      final dialogues = AffinityManager.dialogues['lyra']!;
      final lvl5Dialogues = dialogues.where((d) => d.minBondLevel == 5).toList();
      expect(lvl5Dialogues.isNotEmpty, isTrue);
      expect(lvl5Dialogues.first.text.toLowerCase(), contains('meu coração queima'));
    });
  });

  group('Sprint 5: Secret Memories & CG Gallery Domain Tests', () {
    test('allMemories contains 12 total entries across KBR-01, Lyra, Selene, and Vesper', () {
      final memories = AffinityManager.allMemories;
      expect(memories.length, equals(12));

      final kbrMemories = memories.where((m) => m.valkyrieId == 'kbr_01').toList();
      final lyraMemories = memories.where((m) => m.valkyrieId == 'lyra').toList();
      final seleneMemories = memories.where((m) => m.valkyrieId == 'selene').toList();
      final vesperMemories = memories.where((m) => m.valkyrieId == 'vesper').toList();

      expect(kbrMemories.length, equals(3));
      expect(lyraMemories.length, equals(3));
      expect(seleneMemories.length, equals(3));
      expect(vesperMemories.length, equals(3));
    });

    test('SecretMemory unlocks progressively at Bond Levels 1, 3, and 5', () {
      final lyraMemory1 = AffinityManager.allMemories.firstWhere((m) => m.id == 'lyra_cg_1');
      final lyraMemory2 = AffinityManager.allMemories.firstWhere((m) => m.id == 'lyra_cg_2');
      final lyraMemory3 = AffinityManager.allMemories.firstWhere((m) => m.id == 'lyra_cg_3');

      expect(lyraMemory1.requiredBondLevel, equals(1));
      expect(lyraMemory2.requiredBondLevel, equals(3));
      expect(lyraMemory3.requiredBondLevel, equals(5));

      // At Bond Level 1: Only memory 1 unlocked
      expect(lyraMemory1.isUnlocked(1), isTrue);
      expect(lyraMemory2.isUnlocked(1), isFalse);
      expect(lyraMemory3.isUnlocked(1), isFalse);

      // At Bond Level 3: Memories 1 & 2 unlocked
      expect(lyraMemory1.isUnlocked(3), isTrue);
      expect(lyraMemory2.isUnlocked(3), isTrue);
      expect(lyraMemory3.isUnlocked(3), isFalse);

      // At Bond Level 5: All memories unlocked
      expect(lyraMemory1.isUnlocked(5), isTrue);
      expect(lyraMemory2.isUnlocked(5), isTrue);
      expect(lyraMemory3.isUnlocked(5), isTrue);
    });
  });

  group('Sprint 5: In-Run Memory Core Drops & Game Integration Tests', () {
    test('DropType.memoryCore restores and increments active Valkyrie bond XP', () {
      final game = AsteroidsGame();
      game.state = GameState.playing;
      game.selectedValkyrie = Valkyrie.findById('lyra');
      game.player = PlayerComponent(position: Vector2.zero())..customGame = game;

      final lyraAffinity = game.affinityManager.getAffinity('lyra');
      final initialXp = lyraAffinity.currentXp;

      final memoryDrop = DropComponent(
        position: Vector2(10, 10),
        type: DropType.memoryCore,
      )..customGame = game;

      memoryDrop.onCollisionStart({Vector2.zero()}, game.player);

      expect(lyraAffinity.currentXp, equals(initialXp + 15));
    });

    test('AsteroidsGame incorporates pilot bond combat perks into player speed and crit', () {
      final game = AsteroidsGame();
      game.player = PlayerComponent(position: Vector2.zero())..customGame = game;
      game.selectedValkyrie = Valkyrie.findById('lyra');

      // Set Lyra to Bond Level 3 (+4% crit, +4% speed)
      final affinity = game.affinityManager.getAffinity('lyra');
      affinity.bondLevel = 3;

      game.startGame();

      final expectedCrit = game.selectedValkyrie.critChance + affinity.bondCritBonus;
      expect(game.rogueCritChance, closeTo(expectedCrit, 0.001));
    });
  });

  group('Sprint 5: Hangar Tabs & Gallery UI Widget Tests', () {
    testWidgets('ValkyrieSelectionOverlay renders 3 tabs: SORTIE, OFICINA, and GALERIA', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();
      game.state = GameState.valkyrieSelection;

      await tester.pumpWidget(
        MaterialApp(
          home: ValkyrieSelectionOverlay(game: game),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SORTIE // DECOLAR'), findsOneWidget);
      expect(find.text('OFICINA // UPGRADES'), findsOneWidget);
      expect(find.text('GALERIA // MEMÓRIAS'), findsOneWidget);

      // Verify Affinity Badge is visible in SORTIE mode
      expect(find.textContaining('ELO LV.'), findsOneWidget);
      expect(find.text('Conversar'), findsOneWidget);
    });

    testWidgets('Tapping GALERIA tab switches view and displays memory cards and filter chips', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();
      game.state = GameState.valkyrieSelection;

      await tester.pumpWidget(
        MaterialApp(
          home: ValkyrieSelectionOverlay(game: game),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on GALERIA // MEMÓRIAS tab pill
      await tester.tap(find.text('GALERIA // MEMÓRIAS'));
      await tester.pumpAndSettle();

      // Verify gallery filters
      expect(find.text('TODAS'), findsOneWidget);
      expect(find.text('LYRA'), findsAtLeastNWidgets(1));
      expect(find.text('SELENE'), findsAtLeastNWidgets(1));
      expect(find.text('VESPER'), findsAtLeastNWidgets(1));

      // Verify counter badge
      expect(find.textContaining('DESBLOQUEADAS:'), findsOneWidget);

      // Verify memory cards are present
      expect(find.text('Voo Solo no Hangar'), findsOneWidget);
    });

    testWidgets('Tapping an unlocked memory card opens Full-Screen Lightbox with wallpaper mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 720));
      final game = AsteroidsGame();
      game.state = GameState.valkyrieSelection;

      await tester.pumpWidget(
        MaterialApp(
          home: ValkyrieSelectionOverlay(game: game),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to GALERIA
      await tester.tap(find.text('GALERIA // MEMÓRIAS'));
      await tester.pumpAndSettle();

      // Tap on the first unlocked card (Voo Solo no Hangar, required level 1)
      await tester.tap(find.text('Voo Solo no Hangar'));
      await tester.pumpAndSettle();

      // Lightbox opened: shows wallpaper mode button and close button
      expect(find.text('MODO PAPEL DE PAREDE'), findsOneWidget);
      expect(find.byKey(const Key('lightbox_close_button')), findsOneWidget);

      // Tap wallpaper mode button
      await tester.tap(find.text('MODO PAPEL DE PAREDE'));
      await tester.pumpAndSettle();

      expect(find.text('Toque na tela para restaurar a interface'), findsOneWidget);

      // Tap to restore UI
      await tester.tap(find.text('Toque na tela para restaurar a interface'));
      await tester.pumpAndSettle();

      expect(find.text('MODO PAPEL DE PAREDE'), findsOneWidget);

      // Close Lightbox
      await tester.tap(find.byKey(const Key('lightbox_close_button')));
      await tester.pumpAndSettle();

      // Back to gallery view
      expect(find.text('TODAS'), findsOneWidget);
    });
  });
}
