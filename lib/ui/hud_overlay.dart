import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/valkyrie.dart';

class HudOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const HudOverlay({super.key, required this.game});

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  // Animated score counter
  double _displayScore = 0.0;
  int _lastScore = 0;
  double _scorePulse = 0.0;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _lastScore = widget.game.score;
    _displayScore = widget.game.score.toDouble();
    _ticker = createTicker((elapsed) {
      final dt = ((elapsed - _lastElapsed).inMicroseconds / 1000000.0).clamp(0.0, 0.1);
      _lastElapsed = elapsed;
      _tickScore(dt);
      if (mounted) {
        setState(() {});
      }
    });
    _ticker.start();
  }

  void _tickScore(double dt) {
    final target = widget.game.score;
    if (target < _lastScore) {
      _displayScore = target.toDouble();
      _scorePulse = 0.0;
    } else if (target > _lastScore) {
      _scorePulse = 1.0;
    }
    _lastScore = target;

    final diff = target - _displayScore;
    if (diff.abs() < 1.0) {
      _displayScore = target.toDouble();
    } else {
      _displayScore += diff * math.min(1.0, dt * 7.0);
    }
    _scorePulse = math.max(0.0, _scorePulse - dt * 3.5);
  }

  String _formatScore(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final player = game.player;
    final valkyrie = game.selectedValkyrie;

    final livesLeft = game.lives;
    final isInvulnerable = player.isInvulnerable();
    final invulTime = player.invulnerableTimer;
    final shootCooldown = player.shootTimer;
    final dashCooldown = player.dashCooldownTimer;
    final currentWeapon = player.weapon;

    // Reactive mini-avatar state detection
    String currentAvatarAsset;
    Color avatarGlowColor;
    String statusExpression;

    if (livesLeft <= 1 || isInvulnerable) {
      currentAvatarAsset = valkyrie.hudDamagedAsset;
      avatarGlowColor = Colors.redAccent;
      statusExpression = 'CRITICAL ALERT';
    } else if (game.specialAvailable) {
      currentAvatarAsset = valkyrie.hudUltimateAsset;
      avatarGlowColor = const Color(0xFFFFD700);
      statusExpression = 'OVERDRIVE READY';
    } else {
      currentAvatarAsset = valkyrie.hudNeutralAsset;
      avatarGlowColor = valkyrie.primaryColor;
      statusExpression = 'OPTIMAL';
    }

    return Container(
      padding: const EdgeInsets.all(18.0),
      child: Stack(
        children: [
          // Low Hull / Last Life Dramatic Red Pulsing Vignette
          if (livesLeft == 1)
            Positioned.fill(
              child: IgnorePointer(
                child: Builder(
                  builder: (context) {
                    final pulse = (math.sin(DateTime.now().millisecondsSinceEpoch / 220) + 1) / 2;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.1,
                          colors: [
                            Colors.transparent,
                            Colors.red.withOpacity(0.08 + pulse * 0.16),
                            Colors.red.withOpacity(0.25 + pulse * 0.28),
                          ],
                          stops: const [0.4, 0.8, 1.0],
                        ),
                        border: Border.all(
                          color: Colors.redAccent.withOpacity(0.35 + pulse * 0.45),
                          width: 3.5,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // Top Center: Roguelike XP / Stardust Level-Up Bar
          Positioned(
            top: 4,
            left: MediaQuery.of(context).size.width * 0.28,
            right: MediaQuery.of(context).size.width * 0.28,
            child: IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, color: valkyrie.accentColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'LEVEL ${game.runLevel}',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: valkyrie.accentColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${game.runXp} / ${game.runXpNextLevel} STARDUST',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: valkyrie.primaryColor.withOpacity(0.4), width: 0.8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: (game.runXp / math.max(1, game.runXpNextLevel)).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [valkyrie.primaryColor, valkyrie.accentColor],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: valkyrie.primaryColor.withOpacity(0.7),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Left: Pilot Mini-Avatar & Tactical Cockpit Status
          Positioned(
            top: 0,
            left: 0,
            child: IgnorePointer(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Layer 1: Reactive Mini-Avatar Box
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: avatarGlowColor,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: avatarGlowColor.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Pilot portrait with fallback to procedural pilot emblem
                          Image.asset(
                            currentAvatarAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      valkyrie.primaryColor.withOpacity(0.4),
                                      Colors.black.withOpacity(0.9),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    valkyrie.shipDesign == ValkyrieShipDesign.solBlaze
                                        ? Icons.local_fire_department
                                        : (valkyrie.shipDesign == ValkyrieShipDesign.aegisPrism
                                            ? Icons.shield
                                            : Icons.all_inclusive),
                                    color: valkyrie.accentColor,
                                    size: 36,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Subtle scanlines overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withOpacity(0.04),
                                  Colors.black.withOpacity(0.35),
                                ],
                              ),
                            ),
                          ),
                          // Mini Status Tag at bottom of avatar
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black.withOpacity(0.8),
                              padding: const EdgeInsets.symmetric(vertical: 1.5),
                              child: Text(
                                statusExpression,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: avatarGlowColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Pilot Name, Callsign, Vessel & Score
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Score row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              'SCORE',
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Transform.scale(
                            scale: 1.0 + 0.12 * _scorePulse,
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              _formatScore(_displayScore.round()),
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontVariations: const [FontVariation('wght', 800)],
                                fontSize: 24,
                                color: Color.lerp(Colors.white, valkyrie.accentColor, _scorePulse * 0.8),
                                shadows: [
                                  Shadow(
                                    color: valkyrie.primaryColor.withOpacity(0.7 + _scorePulse * 0.3),
                                    blurRadius: 8 + _scorePulse * 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Pilot Callout Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: valkyrie.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: valkyrie.primaryColor.withOpacity(0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              valkyrie.name.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: valkyrie.accentColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '// ${valkyrie.callsign.toUpperCase()}',
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withOpacity(0.7),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Vessel Info & Active MK
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            valkyrie.shipName,
                            style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 10.5,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: currentWeapon.level >= 3
                                  ? const Color(0xFFFFD700).withOpacity(0.2)
                                  : valkyrie.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: currentWeapon.level >= 3
                                    ? const Color(0xFFFFD700)
                                    : valkyrie.primaryColor.withOpacity(0.6),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              currentWeapon.level >= 3 ? 'MK MAX ★' : 'MK ${currentWeapon.level}',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: currentWeapon.level >= 3
                                    ? const Color(0xFFFFD700)
                                    : valkyrie.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Top Right: Pilot Hull Integrity (Hearts/Icons), Shield Gauge & Pause
          Positioned(
            top: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hull / Life Hearts
                    Row(
                      children: List.generate(GameConstants.playerLives, (index) {
                        final isActive = index < livesLeft;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: Icon(
                            Icons.favorite,
                            color: isActive ? valkyrie.primaryColor : Colors.white24,
                            size: 22,
                            shadows: isActive
                                ? [
                                    Shadow(
                                      color: valkyrie.primaryColor.withOpacity(0.8),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 14),

                    // Pause Button
                    GestureDetector(
                      onTap: () {
                        game.togglePause();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pause, color: Colors.white70, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'PAUSE',
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Shield Status
                if (isInvulnerable)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF00E5FF)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      'SHIELD: ${invulTime.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00E5FF),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Left: Active Arsenal Card, Thruster Dash & Valkyrie Special Ability
          Positioned(
            bottom: 0,
            left: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IgnorePointer(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Active Weapon Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentWeapon.name.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Orbitron',
                                fontVariations: [FontVariation('wght', 700)],
                                fontSize: 11.5,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'CADENCE COOLDOWN',
                              style: TextStyle(
                                fontFamily: 'Rajdhani',
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: valkyrie.accentColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Weapon Cooldown Bar
                            Container(
                              width: 80,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: shootCooldown <= 0
                                      ? 80
                                      : (80 * (1 - (shootCooldown / currentWeapon.cooldown))).clamp(0.0, 80.0),
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: shootCooldown <= 0 ? Colors.greenAccent : Colors.orangeAccent,
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (shootCooldown <= 0 ? Colors.greenAccent : Colors.orangeAccent)
                                            .withOpacity(0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Thruster Dash Cooldown Ring
                      Builder(
                        builder: (context) {
                          final isReady = dashCooldown <= 0;
                          final progress = isReady
                              ? 1.0
                              : (1.0 - (dashCooldown / GameConstants.playerDashCooldownSeconds)).clamp(0.0, 1.0);
                          final dashPulse = isReady
                              ? (math.sin(DateTime.now().millisecondsSinceEpoch / 250) + 1) / 2
                              : 0.0;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isReady
                                    ? valkyrie.accentColor.withOpacity(0.55 + dashPulse * 0.35)
                                    : Colors.white24,
                                width: isReady ? 1.4 : 1.0,
                              ),
                              boxShadow: isReady
                                  ? [
                                      BoxShadow(
                                        color: valkyrie.accentColor.withOpacity(0.25 + dashPulse * 0.25),
                                        blurRadius: 8 + dashPulse * 4,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: progress,
                                        strokeWidth: 2.5,
                                        backgroundColor: Colors.white12,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isReady ? valkyrie.accentColor : Colors.white38,
                                        ),
                                      ),
                                      Icon(
                                        Icons.bolt,
                                        size: 15,
                                        color: isReady ? valkyrie.accentColor : Colors.white38,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'DASH',
                                      style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontVariations: const [FontVariation('wght', 700)],
                                        fontSize: 10,
                                        letterSpacing: 1.0,
                                        color: isReady ? valkyrie.accentColor : Colors.white60,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isReady ? 'READY [SHIFT]' : '${dashCooldown.toStringAsFixed(1)}s',
                                      style: TextStyle(
                                        fontFamily: 'Rajdhani',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: isReady ? valkyrie.accentColor : Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Valkyrie Special Ability Trigger Card
                GestureDetector(
                  onTap: () {
                    game.triggerSpecial();
                  },
                  child: Builder(
                    builder: (context) {
                      final isReady = game.specialAvailable;
                      final specialPulse = isReady
                          ? (math.sin(DateTime.now().millisecondsSinceEpoch / 180) + 1) / 2
                          : 0.0;
                      final glowColor = isReady ? valkyrie.primaryColor : Colors.white24;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isReady
                              ? valkyrie.primaryColor.withOpacity(0.18 + specialPulse * 0.12)
                              : Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isReady
                                ? valkyrie.primaryColor.withOpacity(0.7 + specialPulse * 0.3)
                                : Colors.white24,
                            width: isReady ? 1.6 : 1.0,
                          ),
                          boxShadow: isReady
                              ? [
                                  BoxShadow(
                                    color: valkyrie.primaryColor.withOpacity(0.35 + specialPulse * 0.35),
                                    blurRadius: 10 + specialPulse * 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isReady
                                    ? valkyrie.primaryColor.withOpacity(0.3)
                                    : Colors.white10,
                                border: Border.all(
                                  color: glowColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                isReady ? Icons.auto_awesome : Icons.lock_outline,
                                color: isReady ? const Color(0xFFFFD700) : Colors.white38,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      valkyrie.specialAbilityName.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Rajdhani',
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                        color: isReady ? Colors.white : Colors.white38,
                                      ),
                                    ),
                                    if (isReady) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.amberAccent, width: 0.8),
                                        ),
                                        child: const Text(
                                          '[E]',
                                          style: TextStyle(
                                            fontFamily: 'Orbitron',
                                            fontSize: 9.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amberAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isReady ? 'OVERDRIVE ARMED' : 'RECHARGING PROTOCOL',
                                  style: TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isReady ? const Color(0xFFFFD700) : Colors.white24,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Bottom Right: Mobile touch action controls
          if (game.isMobile)
            Positioned(
              bottom: 10,
              right: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      game.triggerSpecial();
                    },
                    child: Builder(
                      builder: (context) {
                        final isReady = game.specialAvailable;
                        final pulse = isReady
                            ? (math.sin(DateTime.now().millisecondsSinceEpoch / 180) + 1) / 2
                            : 0.0;

                        return Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: isReady
                                ? valkyrie.primaryColor.withOpacity(0.24 + pulse * 0.12)
                                : Colors.white10,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isReady
                                  ? valkyrie.primaryColor.withOpacity(0.8 + pulse * 0.2)
                                  : Colors.white24,
                              width: isReady ? 2.5 : 1.5,
                            ),
                            boxShadow: isReady
                                ? [
                                    BoxShadow(
                                      color: valkyrie.primaryColor.withOpacity(0.4 + pulse * 0.3),
                                      blurRadius: 10 + pulse * 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(
                            isReady ? Icons.auto_awesome : Icons.lock_outline,
                            color: isReady ? const Color(0xFFFFD700) : Colors.white24,
                            size: 26,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Layer 2: Comms Radio Holographic Dialogue Transmission Box at Sortie Launch
          if (game.showLaunchTransmission)
            Positioned(
              bottom: game.isMobile ? 120 : 35,
              left: 20,
              right: 20,
              child: Center(
                child: GestureDetector(
                  onTap: () => game.dismissLaunchTransmission(),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 720),
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: const Color(0xF00A0F1D), // Deep cosmic glass
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: valkyrie.primaryColor,
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: valkyrie.primaryColor.withOpacity(0.45),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.85),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Radio Portrait Container
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: valkyrie.accentColor, width: 2.0),
                            boxShadow: [
                              BoxShadow(
                                color: valkyrie.primaryColor.withOpacity(0.6),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              valkyrie.hudNeutralAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.black54,
                                  child: Icon(
                                    Icons.sensors,
                                    color: valkyrie.accentColor,
                                    size: 34,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Radio dialogue & channel info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00E676),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'COMMS FREQUENCY • ${valkyrie.name.toUpperCase()} // ${valkyrie.callsign.toUpperCase()}',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: valkyrie.accentColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),

                              // Pilot Launch Transmission
                              Text(
                                valkyrie.quote,
                                style: const TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.3,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Controls Guide & Dismiss
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '🎮 WASD/ARROWS: Steer | SPACE/Z: Fire | SHIFT: Dash | E: Special',
                                    style: TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: valkyrie.primaryColor,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    'Click or press any key ▶',
                                    style: TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white.withOpacity(0.65),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
