import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:void_protocol/constants.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/services/localization_service.dart';
import 'package:void_protocol/ui/responsive_ui.dart';

class ShopOverlay extends StatelessWidget {
  final AsteroidsGame game;

  const ShopOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final player = game.player;
    final credits = game.credits;
    final layout = ResponsiveLayout.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(
                width: layout.clampWidth(800),
                constraints: BoxConstraints(maxHeight: layout.height * 0.92),
                padding: EdgeInsets.all(layout.isCompact ? 14.0 : 20.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.1),
                      blurRadius: 25.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.shopping_cart, color: Colors.amber, size: layout.isCompact ? 22 : 28),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  I18n.select(pt: 'OFICINA DE UPGRADES', en: 'UPGRADE SHOP'),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontSize: layout.isCompact ? 20 : 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.8,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Credits display
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: layout.isCompact ? 10 : 16,
                            vertical: layout.isCompact ? 6 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                '${credits}c',
                                style: const TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),

                    // Upgrade Items Grid
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final items = <Widget>[
                            // Weapon: Blaster
                            _buildShopItemCard(
                              context: context,
                              title: 'Blaster',
                              description: 'Standard issue single-shot weapon.',
                              icon: Icons.flash_on,
                              isUnlocked: player.unlockedWeapons.containsKey('blaster'),
                              weaponLevel: player.unlockedWeapons['blaster']?.level ?? 0,
                              costToBuy: 250,
                              onAction: () => game.buyItem('blaster'),
                            ),

                            // Weapon: Spread Shot
                            _buildShopItemCard(
                              context: context,
                              title: 'Spread Shot',
                              description: 'Fires 3 bullets in a cone spread. Short range.',
                              icon: Icons.grain,
                              isUnlocked: player.unlockedWeapons.containsKey('spread_shot'),
                              weaponLevel: player.unlockedWeapons['spread_shot']?.level ?? 0,
                              costToBuy: 500,
                              onAction: () => game.buyItem('spread_shot'),
                            ),

                            // Weapon: Rapid Fire
                            _buildShopItemCard(
                              context: context,
                              title: 'Rapid Fire',
                              description: 'Extremely high fire rate, lower damage and recoil.',
                              icon: Icons.fast_forward,
                              isUnlocked: player.unlockedWeapons.containsKey('rapid_fire'),
                              weaponLevel: player.unlockedWeapons['rapid_fire']?.level ?? 0,
                              costToBuy: 600,
                              onAction: () => game.buyItem('rapid_fire'),
                            ),

                            // Weapon: Bomb Launcher
                            _buildShopItemCard(
                              context: context,
                              title: 'Bomb Launcher',
                              description: 'Launches area-of-effect bombs that explode.',
                              icon: Icons.gps_fixed,
                              isUnlocked: player.unlockedWeapons.containsKey('bomb_launcher'),
                              weaponLevel: player.unlockedWeapons['bomb_launcher']?.level ?? 0,
                              costToBuy: 800,
                              onAction: () => game.buyItem('bomb_launcher'),
                            ),

                            // Upgrade: Speed Boost
                            _buildStatUpgradeCard(
                              context: context,
                              title: 'Thruster Speed (+15%)',
                              description: 'Increase ship acceleration permanently.',
                              icon: Icons.speed,
                              isPurchased: player.movementAcceleration > GameConstants.playerAcceleration,
                              costToBuy: 300,
                              onAction: () => game.buyItem('speed_boost'),
                            ),

                            // Upgrade: Extra Life
                            _buildLifeUpgradeCard(
                              context: context,
                              title: 'Extra Life (+1)',
                              description: 'Adds 1 life to your reserves (Max 5).',
                              icon: Icons.favorite,
                              currentLives: game.lives,
                              costToBuy: 400,
                              onAction: () => game.buyItem('extra_life'),
                            ),
                          ];
                          if (constraints.maxWidth < 680) {
                            return ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (_, idx) => items[idx],
                            );
                          }
                          return GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 1.95,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            children: items,
                          );
                        },
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 24),

                    // Bottom Action Buttons
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        // Cheat button
                        TextButton(
                          onPressed: () {
                            game.credits += 500;
                            (context as Element).markNeedsBuild();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white30,
                            textStyle: const TextStyle(fontSize: 10, fontFamily: 'Rajdhani'),
                          ),
                          child: const Text('ADD CREDITS (CHEAT)'),
                        ),
                        // Launch button
                        ElevatedButton(
                          onPressed: () {
                            if (game.levelManager != null) {
                              game.levelManager!.advanceLevel();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              vertical: layout.isCompact ? 12.0 : 18.0,
                              horizontal: layout.isCompact ? 20.0 : 40.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'LAUNCH NEXT STAGE',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: layout.isCompact ? 13 : 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopItemCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required bool isUnlocked,
    required int weaponLevel,
    required int costToBuy,
    required VoidCallback onAction,
  }) {
    final canAfford = game.credits >= (isUnlocked ? 200 * weaponLevel : costToBuy);
    final isMax = isUnlocked && weaponLevel >= 3;

    String btnLabel;
    int currentCost;
    if (isMax) {
      btnLabel = 'MAX LEVEL';
      currentCost = 0;
    } else if (isUnlocked) {
      currentCost = 200 * weaponLevel;
      btnLabel = 'UPGRADE ($currentCost c)';
    } else {
      currentCost = costToBuy;
      btnLabel = 'BUY ($currentCost c)';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: isUnlocked ? Colors.cyanAccent : Colors.white30, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.white : Colors.white60,
                  ),
                ),
                Text(
                  isUnlocked ? 'Level $weaponLevel' : 'LOCKED',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnlocked ? Colors.cyanAccent : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isMax || (!canAfford)
                ? null
                : () {
                    onAction();
                    (context as Element).markNeedsBuild();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isUnlocked ? Colors.cyan : Colors.amber,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white10,
              disabledForegroundColor: Colors.white24,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(btnLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildStatUpgradeCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required bool isPurchased,
    required int costToBuy,
    required VoidCallback onAction,
  }) {
    final canAfford = game.credits >= costToBuy;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: isPurchased ? Colors.greenAccent : Colors.white30, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isPurchased ? Colors.white : Colors.white60,
                  ),
                ),
                Text(
                  isPurchased ? 'INSTALLED [MAX]' : 'NOT PURCHASED',
                  style: TextStyle(
                    fontSize: 12,
                    color: isPurchased ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isPurchased || (!canAfford)
                ? null
                : () {
                    onAction();
                    (context as Element).markNeedsBuild();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white10,
              disabledForegroundColor: Colors.white24,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(isPurchased
                ? I18n.select(pt: 'INSTALADO', en: 'INSTALLED')
                : I18n.select(pt: 'COMPRAR ($costToBuy c)', en: 'BUY ($costToBuy c)')),
          ),
        ],
      ),
    );
  }

  Widget _buildLifeUpgradeCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required int currentLives,
    required int costToBuy,
    required VoidCallback onAction,
  }) {
    final isMax = currentLives >= 5;
    final canAfford = game.credits >= costToBuy;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.redAccent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'CURRENT LIVES: $currentLives / 5',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: isMax || (!canAfford)
                ? null
                : () {
                    onAction();
                    (context as Element).markNeedsBuild();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white10,
              disabledForegroundColor: Colors.white24,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(isMax
                ? I18n.select(pt: 'VIDAS NO MÁXIMO', en: 'MAX LIVES')
                : I18n.select(pt: 'COMPRAR ($costToBuy c)', en: 'BUY ($costToBuy c)')),
          ),
        ],
      ),
    );
  }
}
