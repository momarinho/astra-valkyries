import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/services/localization_service.dart';

/// Pintor procedural de raios solares rotativos (Arcade Sunburst / Slot Machine Fanfare)
class SunburstPainter extends CustomPainter {
  final Color color;
  final int rays;

  SunburstPainter({required this.color, this.rays = 16});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.max(size.width, size.height) * 1.2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final angleStep = (2 * math.pi) / rays;
    for (int i = 0; i < rays; i += 2) {
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: maxR),
          i * angleStep,
          angleStep * 0.55,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SunburstPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.rays != rays;
}

class ChestOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const ChestOverlay({super.key, required this.game});

  @override
  State<ChestOverlay> createState() => _ChestOverlayState();
}

class _ChestOverlayState extends State<ChestOverlay> with TickerProviderStateMixin {
  late final AnimationController _animController;
  late final AnimationController _sunburstController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _cardRevealAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _sunburstController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _sunburstController.repeat();
    }

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.38, 0.65, curve: Curves.easeOutBack),
    );

    _cardRevealAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    );

    _animController.forward();
    widget.game.playSfx('powerup.wav');
  }

  @override
  void dispose() {
    _animController.dispose();
    _sunburstController.dispose();
    super.dispose();
  }

  void _skipToReveal() {
    if (_animController.value < 0.55) {
      _animController.animateTo(0.55, duration: const Duration(milliseconds: 120));
    }
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
        ? I18n.t('chest.jackpot')
        : (isTriple ? I18n.t('chest.gold') : I18n.t('chest.standard'));
    final titleColor = isJackpot
        ? const Color(0xFFFFD700)
        : (isTriple ? const Color(0xFFFFB300) : const Color(0xFF80DEEA));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: _skipToReveal,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Darkened blur backdrop
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.88),
              ),
            ),

            // Rotating Sunburst rays during burst and reveal
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_animController, _sunburstController]),
                builder: (context, child) {
                  final revealOpacity = ((_animController.value - 0.40) / 0.20).clamp(0.0, 1.0);
                  if (revealOpacity <= 0) return const SizedBox.shrink();

                  return Opacity(
                    opacity: revealOpacity * 0.18,
                    child: Transform.rotate(
                      angle: _sunburstController.value * 2 * math.pi,
                      child: CustomPaint(
                        painter: SunburstPainter(
                          color: titleColor,
                          rays: isJackpot ? 20 : 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    final progress = _animController.value;

                    // Phase 1: Closed Chest Anticipation Rumble (0.0 to 0.40)
                    if (progress < 0.42) {
                      final rumbleShake = math.sin(progress * 65.0) * (6.0 + progress * 10.0);
                      return Transform.translate(
                        offset: Offset(rumbleShake, -rumbleShake * 0.4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                                border: Border.all(
                                  color: titleColor.withValues(alpha: 0.85 + math.sin(progress * 30) * 0.15),
                                  width: 3.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: titleColor.withValues(alpha: 0.55),
                                    blurRadius: 30,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.inventory_2,
                                  size: 52,
                                  color: titleColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              I18n.select(
                                pt: 'DESCRIPTOGRAFANDO BAÚ CÓSMICO...',
                                en: 'DECRYPTING COSMIC CACHE...',
                              ),
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              I18n.select(
                                pt: '[ TOQUE EM QUALQUER LUGAR P/ PULAR ]',
                                en: '[ TAP ANYWHERE TO REVEAL ]',
                              ),
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 11.0,
                                color: Colors.white.withValues(alpha: 0.50),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Phase 2 & 3: Revealed Rewards Box with Cards
                    return SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 840),
                            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 14 : 22),
                            decoration: BoxDecoration(
                              color: const Color(0xFF070B14).withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: titleColor, width: 2.4),
                              boxShadow: [
                                BoxShadow(
                                  color: titleColor.withValues(alpha: 0.45),
                                  blurRadius: 28,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header Fanfare
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isJackpot ? Icons.auto_awesome : Icons.card_giftcard,
                                      color: titleColor,
                                      size: 26,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: MediaQuery.of(context).size.width < 600
                                              ? 14
                                              : (isJackpot ? 19 : 16.5),
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.6,
                                          color: titleColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  I18n.t('chest.secured'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: Colors.white.withValues(alpha: 0.70),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Reward Cards
                                LayoutBuilder(
                                  builder: (context, cardConstraints) {
                                    final maxW = cardConstraints.maxWidth;
                                    final cardWidth = maxW < 420
                                        ? ((maxW - 12) / 2).clamp(130.0, 185.0)
                                        : (rewards.length > 3 ? 142.0 : 185.0);
                                    return AnimatedBuilder(
                                      animation: _cardRevealAnimation,
                                      builder: (context, child) {
                                        return Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: List.generate(rewards.length, (index) {
                                            final r = rewards[index];
                                            final cardOpacity = ((_cardRevealAnimation.value * rewards.length) - index)
                                                .clamp(0.0, 1.0);
                                            final isSuperWeapon = r.title.contains('SUPER-EVOLUTION') || r.title.contains('OVERDRIVE');

                                            return Opacity(
                                              opacity: cardOpacity,
                                              child: Container(
                                                width: cardWidth,
                                                padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isSuperWeapon
                                              ? const Color(0xFF16152B).withValues(alpha: 0.95)
                                              : const Color(0xFF0F172A).withValues(alpha: 0.90),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: isSuperWeapon ? const Color(0xFFFFD700) : r.color.withValues(alpha: 0.8),
                                            width: isSuperWeapon ? 2.2 : 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isSuperWeapon ? const Color(0xFFFFD700) : r.color).withValues(alpha: 0.35),
                                              blurRadius: isSuperWeapon ? 14 : 10,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isSuperWeapon)
                                              Container(
                                                margin: const EdgeInsets.only(bottom: 6),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: const Color(0xFFFFD700), width: 1.0),
                                                ),
                                                child: const Text(
                                                  '★ SUPER-EVO ★',
                                                  style: TextStyle(
                                                    fontFamily: 'Orbitron',
                                                    fontSize: 7.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFFFD700),
                                                    letterSpacing: 0.8,
                                                  ),
                                                ),
                                              ),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: r.color.withValues(alpha: 0.20),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(r.icon, color: r.color, size: 28),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              r.title.toUpperCase(),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
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
                            );
                                  },
                                ),
                            const SizedBox(height: 18),

                            // Claim Button
                            GestureDetector(
                              onTap: _claimAll,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
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
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.black, size: 20),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        I18n.select(pt: 'RESGATAR E CONTINUAR', en: 'CLAIM & RESUME SORTIE'),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                          color: Colors.black,
                                        ),
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
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
