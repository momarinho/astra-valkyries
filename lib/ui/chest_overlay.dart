import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:asteroids/game/asteroids_game.dart';

class ChestOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const ChestOverlay({super.key, required this.game});

  @override
  State<ChestOverlay> createState() => _ChestOverlayState();
}

class _ChestOverlayState extends State<ChestOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _cardRevealAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
    );

    _cardRevealAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.40, 1.0, curve: Curves.easeOutCubic),
    );

    _animController.forward();
    widget.game.playSfx('powerup.wav');
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _claimAll() {
    widget.game.claimChestRewards();
  }

  @override
  Widget build(BuildContext context) {
    final rewards = widget.game.currentChestRewards;
    final valkyrie = widget.game.selectedValkyrie;

    final isJackpot = rewards.length >= 5;
    final isTriple = rewards.length == 3;

    final title = isJackpot
        ? 'SUPER JACKPOT! (5 REWARDS)'
        : (isTriple ? 'GOLD SUPPLY CACHE (3 REWARDS)' : 'TACTICAL SUPPLY CACHE (1 REWARD)');
    final titleColor = isJackpot
        ? const Color(0xFFFFD700)
        : (isTriple ? const Color(0xFFFFB300) : const Color(0xFF80DEEA));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Darkened blur backdrop
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.85),
            ),
          ),

          SafeArea(
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 820),
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B14).withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: titleColor, width: 2.2),
                    boxShadow: [
                      BoxShadow(
                        color: titleColor.withValues(alpha: 0.45),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isJackpot ? Icons.auto_awesome : Icons.card_giftcard,
                            color: titleColor,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: isJackpot ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.0,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ORBITAL DROP SECURED • REWARD PROTOCOL ENGAGED',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Reward Cards
                      AnimatedBuilder(
                        animation: _cardRevealAnimation,
                        builder: (context, child) {
                          return Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(rewards.length, (index) {
                              final r = rewards[index];
                              final cardOpacity = ((_cardRevealAnimation.value * rewards.length) - index)
                                  .clamp(0.0, 1.0);

                              return Opacity(
                                opacity: cardOpacity,
                                child: Container(
                                  width: rewards.length > 3 ? 135 : 180,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: r.color.withValues(alpha: 0.8),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: r.color.withValues(alpha: 0.25),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: r.color.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(r.icon, color: r.color, size: 28),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        r.title.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        r.subtitle,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Rajdhani',
                                          fontSize: 9.5,
                                          color: Colors.white.withValues(alpha: 0.75),
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      const SizedBox(height: 22),

                      // Claim Button
                      GestureDetector(
                        onTap: _claimAll,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [titleColor, valkyrie.primaryColor],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: titleColor.withValues(alpha: 0.45),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle_outline, color: Colors.black, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'CLAIM & RESUME SORTIE',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
