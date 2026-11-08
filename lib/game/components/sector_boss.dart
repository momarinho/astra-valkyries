import 'package:flame/components.dart';
import 'advanced_weapons.dart';

/// Interface unificada para todos os Chefes de Setor em Astra Valkyries.
/// Permite que armas, mísseis, lasers e o HUD interajam de forma polimórfica
/// com qualquer Boss (Dreadnought Leviathan, Ignis Wyrm, etc.).
abstract class SectorBoss extends PositionComponent {
  bool get isDefeated;
  double get hp;
  double get maxHp;
  String get bossName;
  double get radius;

  bool takeDamage(double damage, Vector2 hitPos);
}

final Expando<Map<ElementalStatus, double>> _bossElementalStatuses =
    Expando<Map<ElementalStatus, double>>();

extension SectorBossElementalExtension on SectorBoss {
  Map<ElementalStatus, double> get activeStatuses =>
      _bossElementalStatuses[this] ??= <ElementalStatus, double>{};

  void applyElementalStatus(ElementalStatus status, {double duration = 4.0}) {
    if (status == ElementalStatus.none) return;
    final map = activeStatuses;
    final hadDifferentStatus = map.keys.any((s) => s != status && (map[s] ?? 0) > 0);
    map[status] = duration;
    if (hadDifferentStatus && !isDefeated) {
      takeDamage(45.0, position);
    }
  }

  bool hasStatus(ElementalStatus status) => (activeStatuses[status] ?? 0.0) > 0.0;
}
