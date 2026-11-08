import 'package:flame/components.dart';

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
