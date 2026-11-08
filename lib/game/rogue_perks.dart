import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/weapons.dart';

enum PerkType {
  newWeapon,
  upgradeWeapon,
  passive,
  evolution,
}

enum PerkRarity {
  common,
  rare,
  epic,
  legendary,
}

class WeaponSynergy {
  final String weaponId;
  final String passiveId;
  final String passiveTitle;
  final String evolvedName;
  final String evolutionDescription;
  final IconData evolutionIcon;

  const WeaponSynergy({
    required this.weaponId,
    required this.passiveId,
    required this.passiveTitle,
    required this.evolvedName,
    required this.evolutionDescription,
    required this.evolutionIcon,
  });

  static const List<WeaponSynergy> allSynergies = [
    WeaponSynergy(
      weaponId: 'blaster',
      passiveId: 'passive_overdrive',
      passiveTitle: 'Void Catalyst',
      evolvedName: 'Supernova Annihilator',
      evolutionDescription: 'Dual continuous imperial gold plasma beams with infinite pierce and catastrophic damage.',
      evolutionIcon: Icons.auto_awesome,
    ),
    WeaponSynergy(
      weaponId: 'spread_shot',
      passiveId: 'passive_shield_recharge',
      passiveTitle: 'Aegis Capacitor',
      evolvedName: 'Hyperion Flak Storm',
      evolutionDescription: '10-way 360-degree perimeter flak ring annihilating all surrounding hostile swarms.',
      evolutionIcon: Icons.grain,
    ),
    WeaponSynergy(
      weaponId: 'rapid_fire',
      passiveId: 'passive_fire_rate',
      passiveTitle: 'Overclocked Emitters',
      evolvedName: 'Absolute Zero Tachyon Beam',
      evolutionDescription: 'Piercing cryogenic stream with blistering fire rate and infinite line penetration.',
      evolutionIcon: Icons.ac_unit,
    ),
    WeaponSynergy(
      weaponId: 'bomb_launcher',
      passiveId: 'passive_magnet',
      passiveTitle: 'Magnetic Harvester',
      evolvedName: 'Singularity Rift Torpedo',
      evolutionDescription: 'Antimatter torpedoes detonating in gravitational black hole vortexes that pull and crush foes.',
      evolutionIcon: Icons.cyclone,
    ),
  ];

  static WeaponSynergy? findByWeaponId(String weaponId) {
    for (final s in allSynergies) {
      if (s.weaponId == weaponId) return s;
    }
    return null;
  }
}

class RoguePerk {
  final String id;
  final String title;
  final String description;
  final PerkType type;
  final PerkRarity rarity;
  final IconData icon;
  final Color accentColor;
  final void Function(AsteroidsGame game) onSelect;

  const RoguePerk({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.rarity,
    required this.icon,
    required this.accentColor,
    required this.onSelect,
  });

  String get typeLabel {
    switch (type) {
      case PerkType.newWeapon:
        return 'NEW WEAPON';
      case PerkType.upgradeWeapon:
        return 'UPGRADE';
      case PerkType.passive:
        return 'PASSIVE MODULE';
      case PerkType.evolution:
        return '★ WEAPON EVOLUTION ★';
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case PerkRarity.common:
        return 'COMMON';
      case PerkRarity.rare:
        return 'RARE';
      case PerkRarity.epic:
        return 'EPIC';
      case PerkRarity.legendary:
        return 'LEGENDARY';
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case PerkRarity.common:
        return const Color(0xFF00E5FF); // Cyan
      case PerkRarity.rare:
        return const Color(0xFFE040FB); // Magenta
      case PerkRarity.epic:
        return const Color(0xFFFF9100); // Amber
      case PerkRarity.legendary:
        return const Color(0xFFFFD700); // Gold
    }
  }
}

class RoguePerkGenerator {
  static List<RoguePerk> generateChoices(AsteroidsGame game, {int count = 3}) {
    final player = game.player;
    final List<RoguePerk> priorityPool = [];
    final List<RoguePerk> standardPool = [];

    // 0. Super-Evolutions (Vampire Survivors Synergy Matrix)
    for (final entry in player.unlockedWeapons.entries) {
      final key = entry.key;
      final weapon = entry.value;
      if (weapon.canEvolve) {
        final synergy = WeaponSynergy.findByWeaponId(key);
        if (synergy != null && game.activePassives.contains(synergy.passiveId)) {
          priorityPool.add(
            RoguePerk(
              id: 'evolve_$key',
              title: synergy.evolvedName.toUpperCase(),
              description: synergy.evolutionDescription,
              type: PerkType.evolution,
              rarity: PerkRarity.legendary,
              icon: synergy.evolutionIcon,
              accentColor: const Color(0xFFFFD700),
              onSelect: (g) {
                weapon.evolve();
                g.playSfx('boss_spawn.wav');
                g.triggerScreenShake(duration: 0.6, intensity: 12.0);
              },
            ),
          );
        }
      }
    }

    // 1. New Arsenal Weapons (if not yet unlocked in current run)
    if (!player.unlockedWeapons.containsKey('blaster')) {
      standardPool.add(
        RoguePerk(
          id: 'new_blaster',
          title: 'Pulse Blaster',
          description: 'Precision twin-bolt plasma cannon with high projectile speed and balanced power. [Sinergia: Void Catalyst]',
          type: PerkType.newWeapon,
          rarity: PerkRarity.common,
          icon: Icons.flash_on,
          accentColor: const Color(0xFFFF5722),
          onSelect: (g) {
            g.player.addWeapon(Blaster());
          },
        ),
      );
    }

    if (!player.unlockedWeapons.containsKey('spread_shot')) {
      standardPool.add(
        RoguePerk(
          id: 'new_spread_shot',
          title: 'Spread Cannon',
          description: 'Fires a 3-way fan of plasma projectiles covering a wide frontal arc. [Sinergia: Aegis Capacitor]',
          type: PerkType.newWeapon,
          rarity: PerkRarity.rare,
          icon: Icons.grain,
          accentColor: const Color(0xFF00E676),
          onSelect: (g) {
            g.player.addWeapon(SpreadShot());
          },
        ),
      );
    }

    if (!player.unlockedWeapons.containsKey('rapid_fire')) {
      standardPool.add(
        RoguePerk(
          id: 'new_rapid_fire',
          title: 'Phase Laser',
          description: 'High-frequency photon beam with blazing fire rate and line piercing. [Sinergia: Overclocked Emitters]',
          type: PerkType.newWeapon,
          rarity: PerkRarity.rare,
          icon: Icons.fast_forward,
          accentColor: const Color(0xFF2979FF),
          onSelect: (g) {
            g.player.addWeapon(RapidFire());
          },
        ),
      );
    }

    if (!player.unlockedWeapons.containsKey('bomb_launcher')) {
      standardPool.add(
        RoguePerk(
          id: 'new_bomb_launcher',
          title: 'Antimatter Torpedo',
          description: 'Heavy explosive warheads detonating in a massive destructive shockwave. [Sinergia: Magnetic Harvester]',
          type: PerkType.newWeapon,
          rarity: PerkRarity.epic,
          icon: Icons.gps_fixed,
          accentColor: const Color(0xFFFF6D00),
          onSelect: (g) {
            g.player.addWeapon(BombLauncher());
          },
        ),
      );
    }

    // 2. Weapon Upgrades (for currently equipped/unlocked weapons)
    for (final entry in player.unlockedWeapons.entries) {
      final key = entry.key;
      final weapon = entry.value;
      if (weapon.level < weapon.maxLevel) {
        final nextLvl = weapon.level + 1;
        final synergy = WeaponSynergy.findByWeaponId(key);
        final synergyHint = synergy != null ? ' [Sinergia: ${synergy.passiveTitle}]' : '';

        standardPool.add(
          RoguePerk(
            id: 'upgrade_${key}_$nextLvl',
            title: '${weapon.name.toUpperCase()} MK $nextLvl',
            description: nextLvl == 3
                ? 'Potência Máxima! Amplifica dano e cadência.$synergyHint'
                : 'Aprimora velocidade de disparo e dano.$synergyHint',
            type: PerkType.upgradeWeapon,
            rarity: nextLvl == 3 ? PerkRarity.epic : PerkRarity.rare,
            icon: Icons.keyboard_double_arrow_up,
            accentColor: nextLvl == 3 ? const Color(0xFFFFD700) : const Color(0xFF00E5FF),
            onSelect: (g) {
              weapon.upgrade();
              g.playSfx('powerup.wav');
            },
          ),
        );
      }
    }

    // 3. Passive Ship & Combat Modules
    standardPool.add(
      RoguePerk(
        id: 'passive_magnet',
        title: 'Magnetic Harvester',
        description: 'Expande o raio de atração de Stardust em +40%. [Sinergia com Torpedo Antimatter]',
        type: PerkType.passive,
        rarity: PerkRarity.common,
        icon: Icons.all_inclusive,
        accentColor: const Color(0xFF00E5FF),
        onSelect: (g) {
          g.activePassives.add('passive_magnet');
          g.rogueMagnetRadius += 60.0;
          g.player.magnetRadius = g.rogueMagnetRadius;
        },
      ),
    );

    standardPool.add(
      RoguePerk(
        id: 'passive_thrust',
        title: 'Quantum Thrusters',
        description: 'Aumenta aceleração da nave em +20% e velocidade máxima.',
        type: PerkType.passive,
        rarity: PerkRarity.common,
        icon: Icons.flight_takeoff,
        accentColor: const Color(0xFF76FF03),
        onSelect: (g) {
          g.activePassives.add('passive_thrust');
          g.player.movementAcceleration += 120.0;
          g.player.movementMaxSpeed += 50.0;
        },
      ),
    );

    standardPool.add(
      RoguePerk(
        id: 'passive_shield_recharge',
        title: 'Aegis Capacitor',
        description: 'Restaura +1 Vida e concede invulnerabilidade temporária. [Sinergia com Spread Cannon]',
        type: PerkType.passive,
        rarity: PerkRarity.rare,
        icon: Icons.shield,
        accentColor: const Color(0xFF00B0FF),
        onSelect: (g) {
          g.activePassives.add('passive_shield_recharge');
          g.lives = math.min(g.lives + 1, 6);
          g.player.invulnerableTimer = 3.0;
        },
      ),
    );

    standardPool.add(
      RoguePerk(
        id: 'passive_fire_rate',
        title: 'Overclocked Emitters',
        description: 'Reduz recarga de todas as armas em 15%. [Sinergia com Phase Laser]',
        type: PerkType.passive,
        rarity: PerkRarity.rare,
        icon: Icons.bolt,
        accentColor: const Color(0xFFFFD600),
        onSelect: (g) {
          g.activePassives.add('passive_fire_rate');
          g.rogueFireRateMultiplier *= 0.85;
        },
      ),
    );

    standardPool.add(
      RoguePerk(
        id: 'passive_overdrive',
        title: 'Void Catalyst',
        description: 'Gera Stardust passivo e concede +25% de dano a todas as armas. [Sinergia com Pulse Blaster]',
        type: PerkType.passive,
        rarity: PerkRarity.epic,
        icon: Icons.auto_awesome,
        accentColor: const Color(0xFFFF1744),
        onSelect: (g) {
          g.activePassives.add('passive_overdrive');
          g.rogueDamageMultiplier += 0.25;
          g.addStardust(50);
        },
      ),
    );

    // Combine priority choices (evolutions) first, then shuffle the rest
    standardPool.shuffle();
    final result = <RoguePerk>[...priorityPool];
    for (final perk in standardPool) {
      if (result.length >= count) break;
      result.add(perk);
    }
    return result;
  }
}
