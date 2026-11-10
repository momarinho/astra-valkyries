import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço de Descoberta Progressiva de Segredos do Grimório Cósmico
/// Inspirado no sistema de segredos e desbloqueio de receitas de Vampire Survivors.
class SecretGrimoireService {
  static final Set<String> _discoveredRecipes = {};
  static final ValueNotifier<String?> latestDiscoveredNotifier = ValueNotifier<String?>(null);

  static const List<String> allRecipeKeys = [
    'blaster',
    'spread_shot',
    'rapid_fire',
    'bomb_launcher',
    'aegis_sawblades',
    'tesla_arc',
    'quantum_chakram',
    'repulsor_aura',
    'solar_lance',
    'inferno_cone',
    'valkyrie_wingmen',
    'void_mines',
    'tachyon_katana',
    'union_void_singularity',
    'union_thunderstorm',
  ];

  static int get discoveredCount => _discoveredRecipes.length;
  static int get totalCount => allRecipeKeys.length;
  static double get progressFraction => totalCount > 0 ? (discoveredCount / totalCount).clamp(0.0, 1.0) : 0.0;

  static bool isDiscovered(String key) => _discoveredRecipes.contains(key);

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('secret_grimoire_discovered_recipes');
      if (saved != null) {
        _discoveredRecipes.addAll(saved);
      }
    } catch (_) {}
  }

  /// Registra uma receita ou união como descoberta pela primeira vez.
  /// Retorna `true` se for uma nova descoberta inédita.
  static Future<bool> discover(String key) async {
    if (_discoveredRecipes.contains(key)) return false;

    _discoveredRecipes.add(key);
    latestDiscoveredNotifier.value = key;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('secret_grimoire_discovered_recipes', _discoveredRecipes.toList());
    } catch (_) {}

    return true;
  }

  static void resetForTest() {
    _discoveredRecipes.clear();
    latestDiscoveredNotifier.value = null;
  }

  static void discoverAllForTest() {
    _discoveredRecipes.addAll(allRecipeKeys);
  }
}
