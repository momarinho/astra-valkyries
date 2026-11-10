import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MetaUpgradeDef {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int maxLevel;
  final List<int> costs; // Cost for level 1, 2, ... maxLevel
  final String Function(int level) effectDescription;

  const MetaUpgradeDef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.maxLevel,
    required this.costs,
    required this.effectDescription,
  });

  int getCostForLevel(int currentLevel) {
    if (currentLevel >= maxLevel) return 0;
    return costs[currentLevel];
  }
}

class MetaProgression {
  static const List<MetaUpgradeDef> allUpgrades = [
    // 1. Hull Reinforcement
    MetaUpgradeDef(
      id: 'hull',
      title: 'HULL REINFORCEMENT',
      subtitle: 'Titanium plating grants extra Pilot Hull Integrity (HP)',
      icon: Icons.shield_outlined,
      color: Color(0xFF00E676),
      maxLevel: 3,
      costs: [150, 350, 750],
      effectDescription: _describeHull,
    ),
    // 2. Ion Magnet Overdrive
    MetaUpgradeDef(
      id: 'magnet',
      title: 'ION MAGNET OVERDRIVE',
      subtitle: 'Expands Stardust XP attraction gravitational vacuum aura',
      icon: Icons.all_inclusive_rounded,
      color: Color(0xFF00E5FF),
      maxLevel: 5,
      costs: [100, 200, 400, 700, 1100],
      effectDescription: _describeMagnet,
    ),
    // 3. Hyper-Thrusters
    MetaUpgradeDef(
      id: 'thrusters',
      title: 'HYPER-THRUSTERS',
      subtitle: 'Increases flight speed, maneuverability and reduces Dash cooldown',
      icon: Icons.speed_rounded,
      color: Color(0xFFFFB300),
      maxLevel: 5,
      costs: [120, 250, 450, 800, 1300],
      effectDescription: _describeThrusters,
    ),
    // 4. Quantum Targeting
    MetaUpgradeDef(
      id: 'targeting',
      title: 'QUANTUM TARGETING',
      subtitle: 'Improves Critical Strike probability and global firepower',
      icon: Icons.gps_fixed_rounded,
      color: Color(0xFFE040FB),
      maxLevel: 5,
      costs: [150, 300, 600, 1000, 1600],
      effectDescription: _describeTargeting,
    ),
    // 5. Lucky Star Protocol
    MetaUpgradeDef(
      id: 'luck',
      title: 'LUCKY STAR PROTOCOL',
      subtitle: 'Increases chance of 3x and 5x Jackpots in Cosmic Chests',
      icon: Icons.auto_awesome,
      color: Color(0xFFFFD700),
      maxLevel: 4,
      costs: [200, 500, 1000, 2000],
      effectDescription: _describeLuck,
    ),
    // 6. Tactical Re-Roll Chips (Vampire Survivors Style)
    MetaUpgradeDef(
      id: 'rerolls',
      title: 'TACTICAL RE-ROLL CHIPS',
      subtitle: 'Allows re-rolling Level-Up module choices during a sortie',
      icon: Icons.refresh_rounded,
      color: Color(0xFF00E5FF),
      maxLevel: 3,
      costs: [250, 600, 1200],
      effectDescription: _describeRerolls,
    ),
    // 7. Void Purge Protocol (Banish)
    MetaUpgradeDef(
      id: 'banish',
      title: 'VOID PURGE PROTOCOL (BANISH)',
      subtitle: 'Permanently purges unwanted tactical modules from appearing this sortie',
      icon: Icons.delete_sweep_rounded,
      color: Color(0xFFFF5252),
      maxLevel: 2,
      costs: [400, 950],
      effectDescription: _describeBanish,
    ),
  ];

  static String _describeHull(int lvl) {
    if (lvl == 0) return 'Standard Hull (100% Base HP)';
    return '+${lvl * 25} Max Hull HP (${100 + lvl * 25} HP Total)';
  }

  static String _describeMagnet(int lvl) {
    if (lvl == 0) return 'Base 150px Vacuum Radius';
    return '+${lvl * 20}% Stardust XP Radius (${100 + lvl * 20}% Total)';
  }

  static String _describeThrusters(int lvl) {
    if (lvl == 0) return 'Standard Impeller Dynamics';
    return '+${lvl * 8}% Flight Velocity & -${lvl * 8}% Dash Cooldown';
  }

  static String _describeTargeting(int lvl) {
    if (lvl == 0) return 'Standard Ordnance Calibration';
    return '+${lvl * 4}% Crit Chance & +${lvl * 6}% Weapon Damage';
  }

  static String _describeLuck(int lvl) {
    if (lvl == 0) return 'Standard Cosmic Chest Rarity';
    return '+${lvl * 10}% Chance for 3x & 5x Chest Jackpots';
  }

  static String _describeRerolls(int lvl) {
    if (lvl == 0) return 'Standard Module Lock (0 Rerolls)';
    return '+$lvl Reroll${lvl > 1 ? 's' : ''} per sortie';
  }

  static String _describeBanish(int lvl) {
    if (lvl == 0) return 'No Purge Protocol (0 Banishes)';
    return '+$lvl Perk Banish${lvl > 1 ? 'es' : ''} per sortie';
  }

  // Saved levels for each upgrade id
  final Map<String, int> levels = {
    'hull': 0,
    'magnet': 0,
    'thrusters': 0,
    'targeting': 0,
    'luck': 0,
    'rerolls': 0,
    'banish': 0,
  };

  int getLevel(String id) => levels[id] ?? 0;

  int get hullBonusLives => getLevel('hull');
  double get hullBonusHp => getLevel('hull') * 25.0;
  double get magnetMultiplier => 1.0 + (getLevel('magnet') * 0.20);
  double get speedMultiplier => 1.0 + (getLevel('thrusters') * 0.08);
  double get dashCooldownReduction => getLevel('thrusters') * 0.08;
  double get critChanceBonus => getLevel('targeting') * 0.04;
  double get damageBonusMultiplier => getLevel('targeting') * 0.06;
  double get jackpotChanceBonus => getLevel('luck') * 0.10;
  int get rerollsCount => getLevel('rerolls');
  int get banishCount => getLevel('banish');

  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final def in allUpgrades) {
        levels[def.id] = (prefs.getInt('meta_upgrade_${def.id}') ?? 0).clamp(0, def.maxLevel);
      }
    } catch (_) {}
  }

  Future<void> saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in levels.entries) {
        await prefs.setInt('meta_upgrade_${entry.key}', entry.value);
      }
    } catch (_) {}
  }

  bool canPurchase(String id, int currentCredits) {
    final def = allUpgrades.firstWhere((u) => u.id == id);
    final curLevel = getLevel(id);
    if (curLevel >= def.maxLevel) return false;
    final cost = def.getCostForLevel(curLevel);
    return currentCredits >= cost;
  }

  bool purchase(String id, void Function(int cost) deductCredits) {
    final def = allUpgrades.firstWhere((u) => u.id == id);
    final curLevel = getLevel(id);
    if (curLevel >= def.maxLevel) return false;
    final cost = def.getCostForLevel(curLevel);

    deductCredits(cost);
    levels[id] = curLevel + 1;
    saveToPrefs();
    return true;
  }

  void refundAll(void Function(int totalRefund) addCredits) {
    int totalRefund = 0;
    for (final def in allUpgrades) {
      final curLevel = getLevel(def.id);
      for (int i = 0; i < curLevel; i++) {
        totalRefund += def.costs[i];
      }
      levels[def.id] = 0;
    }
    addCredits(totalRefund);
    saveToPrefs();
  }
}
