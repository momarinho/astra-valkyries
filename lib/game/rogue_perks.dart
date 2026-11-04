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
        return 'NOVA ARMA';
      case PerkType.upgradeWeapon:
        return 'UPGRADE';
      case PerkType.passive:
        return 'MÓDULO PASSIVO';
    }
  }

  String get rarityLabel {
    switch (rarity) {
      case PerkRarity.common:
        return 'COMUM';
      case PerkRarity.rare:
        return 'RARO';
      case PerkRarity.epic:
        return 'ÉPICO';
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

    // 1. Armas Novas (que o jogador ainda não desbloqueou na run)
    if (!player.unlockedWeapons.containsKey('spread_shot')) {
      availablePool.add(
        RoguePerk(
          id: 'new_spread_shot',
          title: 'Tiro Dispersor',
          description: 'Disparo em leque de 3 projéteis cobrindo ampla área frontal.',
          type: PerkType.newWeapon,
          rarity: PerkRarity.rare,
          icon: Icons.grain,
          accentColor: const Color(0xFF00E676),
          onSelect: (g) {
            final w = SpreadShot();
            g.player.unlockedWeapons['spread_shot'] = w;
            g.player.setWeapon(w);
          },
        ),
      );
    }

    if (!player.unlockedWeapons.containsKey('rapid_fire')) {
      availablePool.add(
        RoguePerk(
          id: 'new_rapid_fire',
          title: 'Laser Veloz',
          description: 'Metralhadora contínua de feixes laser ultrarrápidos.',
          type: PerkType.newWeapon,
          rarity: PerkRarity.rare,
          icon: Icons.fast_forward,
          accentColor: const Color(0xFF2979FF),
          onSelect: (g) {
            final w = RapidFire();
            g.player.unlockedWeapons['rapid_fire'] = w;
            g.player.setWeapon(w);
          },
        ),
      );
    }

    if (!player.unlockedWeapons.containsKey('bomb_launcher')) {
      availablePool.add(
        RoguePerk(
          id: 'new_bomb_launcher',
          title: 'Lança-Bombas',
          description: 'Orbes de plasma pesado que explodem limpando grandes áreas.',
          type: PerkType.newWeapon,
          rarity: PerkRarity.epic,
          icon: Icons.gps_fixed,
          accentColor: const Color(0xFFFF6D00),
          onSelect: (g) {
            final w = BombLauncher();
            g.player.unlockedWeapons['bomb_launcher'] = w;
            g.player.setWeapon(w);
          },
        ),
      );
    }

    // 2. Upgrades de Armas Existentes (caso ainda não estejam no nível máximo)
    for (final entry in player.unlockedWeapons.entries) {
      final key = entry.key;
      final weapon = entry.value;
      if (weapon.level < weapon.maxLevel) {
        final nextLvl = weapon.level + 1;
        availablePool.add(
          RoguePerk(
            id: 'upgrade_${key}_$nextLvl',
            title: '${weapon.name} NV $nextLvl',
            description: nextLvl == 3
                ? 'Potência máxima estelar! Projéteis aprimorados e super cadência.'
                : 'Aumenta o dano, cadência e velocidade dos disparos.',
            type: PerkType.upgradeWeapon,
            rarity: nextLvl == 3 ? PerkRarity.epic : PerkRarity.rare,
            icon: Icons.upgrade,
            accentColor: nextLvl == 3 ? const Color(0xFFFFD700) : const Color(0xFF00E5FF),
            onSelect: (g) {
              weapon.upgrade();
            },
          ),
        );
      }
    }

    // 3. Módulos Passivos & Sinergias (Sempre disponíveis com acúmulo)
    availablePool.add(
      RoguePerk(
        id: 'perk_pierce',
        title: 'Tiros Perfurantes',
        description: 'Seus projéteis atravessam +1 asteroide adicional antes de se dissipar.',
        type: PerkType.passive,
        rarity: PerkRarity.rare,
        icon: Icons.double_arrow,
        accentColor: const Color(0xFFFFD54F),
        onSelect: (g) {
          g.player.pierceCount += 1;
        },
      ),
    );

    availablePool.add(
      RoguePerk(
        id: 'perk_magnet',
        title: 'Ímã Gravitacional',
        description: 'Aumenta o raio de atração magnética de XP e créditos em +60%.',
        type: PerkType.passive,
        rarity: PerkRarity.common,
        icon: Icons.attractions,
        accentColor: const Color(0xFF00E5FF),
        onSelect: (g) {
          g.player.magnetRadius *= 1.6;
        },
      ),
    );

    availablePool.add(
      RoguePerk(
        id: 'perk_damage',
        title: 'Foco de Antimatéria',
        description: 'Amplifica o dano de todas as armas da nave em +20%.',
        type: PerkType.passive,
        rarity: PerkRarity.rare,
        icon: Icons.local_fire_department,
        accentColor: const Color(0xFFFF5252),
        onSelect: (g) {
          g.player.damageMultiplier += 0.20;
        },
      ),
    );

    availablePool.add(
      RoguePerk(
        id: 'perk_cooldown',
        title: 'Condensador de Pulso',
        description: 'Reduz o intervalo de recarga de disparo de todas as armas em -15%.',
        type: PerkType.passive,
        rarity: PerkRarity.rare,
        icon: Icons.bolt,
        accentColor: const Color(0xFF7C4DFF),
        onSelect: (g) {
          g.player.cooldownMultiplier = math.max(0.35, g.player.cooldownMultiplier * 0.85);
        },
      ),
    );

    availablePool.add(
      RoguePerk(
        id: 'perk_engine',
        title: 'Pós-Combustão',
        description: 'Aumenta a velocidade máxima e a aceleração dos propulsores em +18%.',
        type: PerkType.passive,
        rarity: PerkRarity.common,
        icon: Icons.speed,
        accentColor: const Color(0xFF69F0AE),
        onSelect: (g) {
          g.player.movementMaxSpeed *= 1.18;
          g.player.movementAcceleration *= 1.18;
        },
      ),
    );

    availablePool.add(
      RoguePerk(
        id: 'perk_shield_life',
        title: 'Blindagem Reativa',
        description: 'Concede +1 Vida de reserva e ativa um escudo protetor por 4 segundos.',
        type: PerkType.passive,
        rarity: PerkRarity.epic,
        icon: Icons.shield,
        accentColor: const Color(0xFF40C4FF),
        onSelect: (g) {
          g.lives += 1;
          g.player.invulnerableTimer = 4.0;
        },
      ),
    );

    // Embaralha o pool e seleciona [count] opções distintas
    availablePool.shuffle();
    return availablePool.take(count).toList();
  }
}
