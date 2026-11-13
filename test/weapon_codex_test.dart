import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/weapons.dart';
import 'package:asteroids/game/weapon_codex.dart';
import 'package:asteroids/services/secret_grimoire_service.dart';
import 'package:asteroids/ui/valkyrie_selection_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Weapon Codex & Armory Lore Gallery Tests', () {
    test('WeaponCodexEntry contains all 13 weapons in Astra Valkyries', () {
      expect(WeaponCodexEntry.allEntries.length, equals(13));

      final codexIds = WeaponCodexEntry.allEntries.map((e) => e.id).toSet();
      for (final id in Weapon.allWeaponIds) {
        expect(
          codexIds.contains(id),
          isTrue,
          reason: 'Weapon $id must have an entry in WeaponCodexEntry',
        );
      }
    });

    test(
      'Each weapon codex entry defines manufacturer, lore, pilot quote and super-evolution details',
      () {
        for (final entry in WeaponCodexEntry.allEntries) {
          expect(entry.name.isNotEmpty, isTrue);
          expect(entry.evolvedName.isNotEmpty, isTrue);
          expect(entry.manufacturer.isNotEmpty, isTrue);
          expect(entry.damageType.isNotEmpty, isTrue);
          expect(entry.classification.isNotEmpty, isTrue);
          expect(entry.loreDescription.length, greaterThan(30));
          expect(entry.technicalSpecs.isNotEmpty, isTrue);
          expect(entry.pilotQuote.isNotEmpty, isTrue);
          expect(entry.pilotQuoteAuthor.isNotEmpty, isTrue);
          expect(entry.evolutionTitle.isNotEmpty, isTrue);
          expect(entry.evolutionDescription.isNotEmpty, isTrue);
          expect(entry.synergyPassiveTitle.isNotEmpty, isTrue);

          expect(entry.damageRating, inInclusiveRange(1, 5));
          expect(entry.fireRateRating, inInclusiveRange(1, 5));
          expect(entry.rangeRating, inInclusiveRange(1, 5));
          expect(entry.difficultyRating, inInclusiveRange(1, 5));
        }
      },
    );

    test('findById retrieves the specific weapon codex entry or null', () {
      final katana = WeaponCodexEntry.findById('tachyon_katana');
      expect(katana, isNotNull);
      expect(katana!.name, equals('Tachyon Katana'));
      expect(katana.evolvedName, equals('Void Muramasa'));
      expect(katana.pilotQuoteAuthor, contains('KBR-01'));

      final nonExistent = WeaponCodexEntry.findById('non_existent_weapon');
      expect(nonExistent, isNull);
    });

    testWidgets(
      'ValkyrieSelectionOverlay allows toggling to Weapon Codex and masks secrets until discovered',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        SecretGrimoireService.resetForTest();
        await tester.binding.setSurfaceSize(const Size(1280, 720));
        final game = AsteroidsGame();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ValkyrieSelectionOverlay(game: game)),
          ),
        );
        await tester.pump();

        // Navigate to Galeria tab (Tab 2)
        final galleryTab = find.textContaining('GALERIA');
        expect(galleryTab, findsOneWidget);
        await tester.tap(galleryTab);
        await tester.pumpAndSettle();

        // Check for mode selector
        expect(find.text('💖 MEMÓRIAS DAS PILOTOS'), findsOneWidget);
        expect(find.text('⚔️ CÓDICE DO ARSENAL & LORE'), findsOneWidget);

        // Switch to Códice do Arsenal
        await tester.tap(find.text('⚔️ CÓDICE DO ARSENAL & LORE'));
        await tester.pumpAndSettle();

        // Should display weapons like Tachyon Katana, Pulse Blaster, etc.
        expect(find.text('Tachyon Katana'), findsOneWidget);
        expect(find.text('Pulse Blaster'), findsOneWidget);

        // Tap on Tachyon Katana to open Dossier Lightbox
        await tester.tap(find.text('Tachyon Katana'));
        await tester.pumpAndSettle();

        // Before discovery, dossier hides evolution recipe under secret mask
        expect(find.text('HISTÓRICO MILITAR & LORE DIEGÉTICA'), findsOneWidget);
        expect(find.text('SUPER-EVOLUÇÃO LENDÁRIA'), findsOneWidget);
        expect(find.text('??? [SUPER-EVOLUÇÃO SECRETA]'), findsOneWidget);
        expect(find.textContaining('Shadow Lotus'), findsOneWidget);

        // Close dossier modal
        final closeBtn = find.byIcon(Icons.close);
        expect(closeBtn, findsOneWidget);
        await tester.tap(closeBtn);
        await tester.pumpAndSettle();

        // Now discover tachyon_katana and verify secret reveals
        SecretGrimoireService.discoverAllForTest();
        await tester.tap(find.text('Tachyon Katana'));
        await tester.pumpAndSettle();
        expect(find.text('Void Muramasa'), findsAtLeastNWidgets(1));
        expect(find.textContaining('Precision Crit Optics'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Modal is closed, back to weapons grid
        expect(find.text('HISTÓRICO MILITAR & LORE DIEGÉTICA'), findsNothing);
      },
    );
  });
}
