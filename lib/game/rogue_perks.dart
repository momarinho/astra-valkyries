import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/weapons.dart';

enum PerkType {
  newWeapon,
  upgradeWeapon,
  passive,
}

enum PerkRarity {
  common,
  rare,
  epic,
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
    }
  }

  Color get rarityColor {
    switch (rarity) {
      case PerkRarity.common:
        return const Color(0xFF00E5FF); // Cyan
      case PerkRarity.rare:
        return const Color(0xFFE040FB); // Magenta
      case PerkRarity.epic:
        return const Color(0xFFFFD700); // Gold
    }
  }
}

class RoguePerkGenerator {
  static List<RoguePerk> generateChoices(AsteroidsGame game, {int count = 3}) {
    final player = game.player;
    final List<RoguePerk> availablePool = [];

    // 1. New Arsenal Weapons (if not yet unlocked in current run)
    if (!player.unlockedWeapons.containsKey('blaster')) {
      availablePool.add(
        RoguePerk(
          id: 'new_blaster',
          title: 'Pulse Blaster',
          description: 'Precision twin-bolt plasma cannon with high projectile speed and balanced power.',
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
      availablePool.add(
        RoguePerk(
          id: 'new_spread_shot',
          title: 'Spread Cannon',
          description: 'Fires a 3-way fan of plasma projectiles covering a wide frontal arc.',
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
      availablePool.add(
        RoguePerk(
          id: 'new_rapid_fire',
          title: 'Phase Laser',
          description: 'High-frequency photon beam with blazing fire rate and line piercing.',
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
      availablePool.add(
        RoguePerk(
          id: 'new_bomb_launcher',
          title: 'Antimatter Torpedo',
          description: 'Heavy explosive warheads detonating in a massive destructive shockwave.',
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
        availablePool.add(
          RoguePerk(
            id: 'upgrade_${key}_$nextLvl',
            title: '${weapon.name.toUpperCase()} MK $nextLvl',
            description: nextLvl == 3
                ? 'Maximum overdrive! Amplified damage, projectile velocity, and extreme fire rate.'
                : 'Upgrades weapon damage, projectile velocity, and fire rate.',
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
    availablePool.add(
      RoguePerk(
        id: 'passive_magnet',
        title: 'Magnetic Harvester',
        description: 'Expands Stardust attraction radius by +40% for effortless XP collection.',
        type: PerkType.passive,
        rarity: PerkRarity.common,
        icon: Icons.all_inclusive,
        accentColor: const Color(0xFF00E5FF),
        onSelect: (g) {
          g.rogueMagnetRadius += 60.0;
        },
      ),
    );

    availablePool.add(
      RoguePerk(
        id: 'passive_thrust',
        title: 'Quantum Thrusters',
        description: 'Boosts ship acceleration by +20% and increases top cruising speed.',
        type: PerkType.passive,
        rarity: PerkRarity.common,
        icon: Icons.flight_takeoff,
        accentColor: const Color(0xFF76FF03),
        onSelect: (g) {
          g.player.movementAcceleration += 120.0;
          g.player.movementMaxSpeed += 50.0;
        },
      ),
    );

    availablePool.add(
      RoguePerk(
        id: 'passive_shield_recharge',
        title: 'Aegis Capacitor',
        description: 'Restores +1 Ship Life and grants immediate temporary invulnerability.',
        type: PerkType.passive,
        rarity: PerkRarity.rare,
        icon: Icons.shield,
        accentColor: const Color(0xFF00B0FF),
        onSelect: (g) {
          g.lives = math.min(g.lives + 1, 6);
          g.player.invulnerableTimer = 3.0;
        },
      ),
    );

    availablePool.add(
      RoguePerk(
        id: 'passive_fire_rate',
        title: 'Overclocked Emitters',
        description: 'Reduces cooldown of all weapons by 15%, unleashing a continuous storm of fire.',
        type: PerkType.passive,
        rarity: PerkRarity.rare,
        icon: Icons.bolt,
        accentColor: const Color(0xFFFFD600),
        onSelect: (g) {
          g.rogueFireRateMultiplier *= 0.85;
        },
      ),
    );

    availablePool.add(
      RoguePerk(
        id: 'passive_overdrive',
        title: 'Void Catalyst',
        description: 'Passive Stardust generation over time and +10% bonus damage to all weapons.',
        type: PerkType.passive,
        rarity: PerkRarity.epic,
        icon: Icons.auto_awesome,
        accentColor: const Color(0xFFFF1744),
        onSelect: (g) {
          g.rogueDamageMultiplier += 0.25;
          g.addStardust(50);
        },
      ),
    );

    // Shuffle and pick unique choices
    availablePool.shuffle();
    return availablePool.take(count).toList();
  }
}
