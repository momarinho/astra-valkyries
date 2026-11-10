import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameAchievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const GameAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.color = const Color(0xFFFFD700),
  });
}

class AchievementService {
  static const String _storageKey = 'unlocked_achievements_v1';
  static final Set<String> _unlockedIds = {};
  static final ValueNotifier<GameAchievement?> latestUnlocked = ValueNotifier(null);

  static const List<GameAchievement> all = [
    GameAchievement(
      id: 'first_blood',
      title: 'PRIMEIRO ABATE // FIRST BLOOD',
      description: 'Destrua seu primeiro chefe de setor espacial.',
      icon: Icons.military_tech,
      color: Color(0xFFFF5252),
    ),
    GameAchievement(
      id: 'transcendence',
      title: 'TRANSCENDÊNCIA // TRANSCENDENCE',
      description: 'Desbloqueie uma Super-Evolução de arma no baú cósmico.',
      icon: Icons.auto_awesome,
      color: Color(0xFFFFD700),
    ),
    GameAchievement(
      id: 'titanium_tycoon',
      title: 'MAGNATA DO TITÂNIO // TITANIUM TYCOON',
      description: 'Extraia um veio denso de titânio para reforçar seu casco.',
      icon: Icons.construction,
      color: Color(0xFF80D8FF),
    ),
    GameAchievement(
      id: 'blade_master',
      title: 'MESTRE DAS LÂMINAS // BLADE MASTER',
      description: 'Empunhe a Tachyon Katana contra frotas inimigas.',
      icon: Icons.flash_on,
      color: Color(0xFF00E5FF),
    ),
    GameAchievement(
      id: 'corona_supernova',
      title: 'CORONA SUPERNOVA',
      description: 'Invoque a tempestade solar purificadora de Lyra.',
      icon: Icons.wb_sunny,
      color: Color(0xFFFF9100),
    ),
    GameAchievement(
      id: 'absolute_zero',
      title: 'ZERO ABSOLUTO // ABSOLUTE ZERO',
      description: 'Congele os inimigos com a Stasis Criogênica de Selene.',
      icon: Icons.ac_unit,
      color: Color(0xFF00E5FF),
    ),
    GameAchievement(
      id: 'void_singularity',
      title: 'SINGULARIDADE DO VAZIO',
      description: 'Detone a fenda de antimatéria gravitacional de Vesper.',
      icon: Icons.blur_circular,
      color: Color(0xFFE040FB),
    ),
    GameAchievement(
      id: 'lucky_jackpot',
      title: 'JACKPOT CÓSMICO // STELLAR JACKPOT',
      description: 'Resgate um Baú de Suprimentos Ouro ou Lendário.',
      icon: Icons.card_giftcard,
      color: Color(0xFFFFD700),
    ),
    GameAchievement(
      id: 'arsenal_master',
      title: 'FORJA PLENA // ARSENAL MASTER',
      description: 'Equipe 3 ou mais armas simultâneas no arsenal de bordo.',
      icon: Icons.shield,
      color: Color(0xFF76FF03),
    ),
    GameAchievement(
      id: 'void_apex_pilot',
      title: 'ÁPICE DO VAZIO // VOID APEX PILOT',
      description: 'Atinja a pontuação e avaliação de Rank S em uma surtida.',
      icon: Icons.emoji_events,
      color: Color(0xFFFFD700),
    ),
  ];

  static bool isUnlocked(String id) => _unlockedIds.contains(id);

  static int get unlockedCount => _unlockedIds.length;
  static int get totalCount => all.length;
  static double get progressFraction => all.isEmpty ? 0.0 : _unlockedIds.length / all.length;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey);
      if (list != null) {
        _unlockedIds.addAll(list);
      }
    } catch (_) {}
  }

  static Future<bool> unlock(String id) async {
    if (_unlockedIds.contains(id)) return false;
    _unlockedIds.add(id);

    final achievement = all.cast<GameAchievement?>().firstWhere(
      (a) => a?.id == id,
      orElse: () => null,
    );

    if (achievement != null) {
      latestUnlocked.value = achievement;
      Future.delayed(const Duration(seconds: 4), () {
        if (latestUnlocked.value?.id == achievement.id) {
          latestUnlocked.value = null;
        }
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _unlockedIds.toList());
    } catch (_) {}

    return true;
  }

  static void resetForTest() {
    _unlockedIds.clear();
    latestUnlocked.value = null;
  }
}
