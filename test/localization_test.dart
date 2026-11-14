import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_protocol/services/localization_service.dart';
import 'package:void_protocol/game/valkyrie.dart';
import 'package:void_protocol/game/rogue_perks.dart';
import 'package:void_protocol/game/weapon_codex.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await I18n.init();
  });

  group('Sprint 32: Localization & I18n Core System Tests', () {
    test('I18n initializes with a valid default locale and notifier', () {
      expect(I18n.currentLocale, isNotNull);
      expect(I18n.localeNotifier.value, equals(I18n.currentLocale));
    });

    test('I18n.setLocale switches locale and notifies listeners', () async {
      await I18n.setLocale(AppLocale.enUs);
      expect(I18n.currentLocale, equals(AppLocale.enUs));
      expect(I18n.isEn, isTrue);
      expect(I18n.isPt, isFalse);
      expect(I18n.localeNotifier.value, equals(AppLocale.enUs));

      await I18n.setLocale(AppLocale.ptBr);
      expect(I18n.currentLocale, equals(AppLocale.ptBr));
      expect(I18n.isPt, isTrue);
      expect(I18n.isEn, isFalse);
      expect(I18n.localeNotifier.value, equals(AppLocale.ptBr));
    });

    test('I18n.toggleLocale flips smoothly between Portuguese and English', () async {
      await I18n.setLocale(AppLocale.ptBr);
      await I18n.toggleLocale();
      expect(I18n.currentLocale, equals(AppLocale.enUs));

      await I18n.toggleLocale();
      expect(I18n.currentLocale, equals(AppLocale.ptBr));
    });

    test('I18n.select dynamically returns string matching active language', () async {
      await I18n.setLocale(AppLocale.ptBr);
      expect(I18n.select(pt: 'Olá', en: 'Hello'), equals('Olá'));

      await I18n.setLocale(AppLocale.enUs);
      expect(I18n.select(pt: 'Olá', en: 'Hello'), equals('Hello'));
    });

    test('I18n.t returns correct translations and handles param substitution', () async {
      // Test in Portuguese
      await I18n.setLocale(AppLocale.ptBr);
      expect(I18n.t('hud.hull'), equals('CASCO'));
      expect(I18n.t('hud.score'), equals('PONTOS'));
      expect(I18n.t('hud.pause'), equals('PAUSA'));
      expect(I18n.t('hud.level', {'level': '7'}), equals('NÍVEL 7'));
      expect(I18n.t('hud.stardust', {'cur': '150', 'max': '300'}), equals('150 / 300 POEIRA ESTELAR'));
      expect(I18n.t('pause.resume'), equals('CONTINUAR OPERAÇÃO'));
      expect(I18n.t('pause.hangar'), equals('RETORNAR AO HANGAR'));
      expect(I18n.t('pause.menu'), equals('MENU PRINCIPAL'));
      expect(I18n.t('game_over.retry'), equals('REPETIR OPERAÇÃO'));

      // Test in English
      await I18n.setLocale(AppLocale.enUs);
      expect(I18n.t('hud.hull'), equals('HULL'));
      expect(I18n.t('hud.score'), equals('SCORE'));
      expect(I18n.t('hud.pause'), equals('PAUSE'));
      expect(I18n.t('hud.level', {'level': '7'}), equals('LEVEL 7'));
      expect(I18n.t('hud.stardust', {'cur': '150', 'max': '300'}), equals('150 / 300 STARDUST'));
      expect(I18n.t('pause.resume'), equals('RESUME SORTIE'));
      expect(I18n.t('pause.hangar'), equals('RETURN TO HANGAR'));
      expect(I18n.t('pause.menu'), equals('MAIN MENU'));
      expect(I18n.t('game_over.retry'), equals('RETRY SORTIE'));
    });

    test('All 5 Valkyries dynamically localize bio, title, quote and ability descriptions', () async {
      final kbr = Valkyrie.findById('kbr_01');
      final lyra = Valkyrie.findById('lyra');
      final selene = Valkyrie.findById('selene');
      final vesper = Valkyrie.findById('vesper');
      final astraea = Valkyrie.secretValkyrie;

      final allPilots = [kbr, lyra, selene, vesper, astraea];

      // 1. In Portuguese
      await I18n.setLocale(AppLocale.ptBr);
      for (final pilot in allPilots) {
        expect(pilot.title, isNotEmpty);
        expect(pilot.bio, isNotEmpty);
        expect(pilot.quote, isNotEmpty);
        expect(pilot.startingWeaponDesc, isNotEmpty);
        expect(pilot.specialAbilityDesc, isNotEmpty);
      }
      expect(kbr.bio, contains('Designação tática de elite KBR-01'));
      expect(lyra.bio, contains('Pilota ás destemida da Frota Vanguard'));
      expect(selene.bio, contains('Ex-pesquisadora de física quântica'));

      // 2. In English
      await I18n.setLocale(AppLocale.enUs);
      for (final pilot in allPilots) {
        expect(pilot.title, isNotEmpty);
        expect(pilot.bio, isNotEmpty);
        expect(pilot.quote, isNotEmpty);
        expect(pilot.startingWeaponDesc, isNotEmpty);
        expect(pilot.specialAbilityDesc, isNotEmpty);
      }
      expect(kbr.bio, contains('Elite tactical designation KBR-01'));
      expect(lyra.bio, contains('Fearless ace pilot of the Vanguard Fleet'));
      expect(selene.bio, contains('Former quantum physics researcher'));
    });

    test('RoguePerk typeLabel, rarityLabel and descriptions localize properly', () async {
      final perk = RoguePerk(
        id: 'test_perk',
        title: 'Hyper Thruster',
        descriptionPt: 'Acelera a nave em +25%',
        descriptionEn: 'Boosts ship speed by +25%',
        type: PerkType.upgradeWeapon,
        rarity: PerkRarity.legendary,
        icon: Icons.bolt,
        accentColor: Colors.amber,
        onSelect: (_) {},
      );

      await I18n.setLocale(AppLocale.ptBr);
      expect(perk.typeLabel, equals('MELHORIA DE ARMA'));
      expect(perk.rarityLabel, equals('LENDÁRIO'));
      expect(perk.description, equals('Acelera a nave em +25%'));

      await I18n.setLocale(AppLocale.enUs);
      expect(perk.typeLabel, equals('WEAPON UPGRADE'));
      expect(perk.rarityLabel, equals('LEGENDARY'));
      expect(perk.description, equals('Boosts ship speed by +25%'));
    });

    test('WeaponCodexEntry lore, specs and pilot quotes localize properly', () async {
      final katana = WeaponCodexEntry.allEntries.firstWhere((w) => w.id == 'tachyon_katana');
      final blaster = WeaponCodexEntry.allEntries.firstWhere((w) => w.id == 'blaster');

      await I18n.setLocale(AppLocale.ptBr);
      expect(katana.loreDescription, contains('fornalha orbital de Kyoto-7'));
      expect(blaster.loreDescription, contains('armamento padrão das esquadrilhas'));

      await I18n.setLocale(AppLocale.enUs);
      expect(katana.loreDescription, contains('Kyoto-7 orbital foundry'));
      expect(blaster.loreDescription, contains('Standard issue armament'));
    });
  });
}
