import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:asteroids/constants.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/game/components/player.dart';
import 'package:asteroids/game/components/asteroid.dart';
import 'package:asteroids/game/components/comet.dart';
import 'package:asteroids/game/components/space_station.dart';
import 'package:asteroids/game/components/cargo_wreck.dart';
import 'package:asteroids/game/components/cosmic_nebula.dart';

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
  double _radarSweepTimer = 0.0;
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
      _radarSweepTimer = (_radarSweepTimer + dt * 2.5) % (2 * math.pi);
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

                      // Vessel Info & Active Arsenal Size
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: valkyrie.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: valkyrie.primaryColor.withOpacity(0.6),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'ARSENAL: ${player.activeWeapons.length} GUNS',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: valkyrie.accentColor,
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

                const SizedBox(height: 10),

                // Tactical Mini-Radar & Spatial Navigation
                _buildTacticalRadar(player, valkyrie),
              ],
            ),
          ),

          // Sector Hazard Warning Banner
          if (player.isNearBoundary)
            Positioned(
              top: 54,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.8),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'WARNING: SECTOR BOUNDARY // HAZARD PERIMETER',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Environmental Nebula Modifier Banner
          if (player.activeNebulaName != null)
            Positioned(
              top: player.isNearBoundary ? 94 : 54,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070B14).withOpacity(0.90),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: player.activeNebulaName == 'ION NEBULA'
                          ? const Color(0xFFE040FB)
                          : const Color(0xFF00E5FF),
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (player.activeNebulaName == 'ION NEBULA'
                                ? const Color(0xFFE040FB)
                                : const Color(0xFF00E5FF))
                            .withOpacity(0.35),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        player.activeNebulaName == 'ION NEBULA'
                            ? Icons.bolt_rounded
                            : Icons.auto_awesome_rounded,
                        color: player.activeNebulaName == 'ION NEBULA'
                            ? const Color(0xFFE040FB)
                            : const Color(0xFF00E5FF),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${player.activeNebulaName} // ${player.activeNebulaModifier}',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: player.activeNebulaName == 'ION NEBULA'
                              ? const Color(0xFFE040FB)
                              : const Color(0xFF00E5FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Space Station Uplink Progress Banner
          Builder(
            builder: (context) {
              SpaceStationComponent? station;
              try {
                final stations = widget.game.world.children.whereType<SpaceStationComponent>();
                if (stations.isNotEmpty) station = stations.first;
              } catch (_) {}

              if (station == null || (!station.isPlayerInZone && station.uploadProgress <= 0)) {
                return const SizedBox.shrink();
              }

              final progressPct = (station.uploadProgress / SpaceStationComponent.targetUploadTime * 100).toInt();
              final topOffset = (player.isNearBoundary ? 94.0 : 54.0) + (player.activeNebulaName != null ? 36.0 : 0.0);

              return Positioned(
                top: topOffset,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1426).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: station.isSecured ? const Color(0xFF64FFDA) : const Color(0xFFFFD700),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (station.isSecured ? const Color(0xFF64FFDA) : const Color(0xFFFFD700)).withOpacity(0.35),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          station.isSecured ? Icons.check_circle_outline_rounded : Icons.cell_tower_rounded,
                          color: station.isSecured ? const Color(0xFF64FFDA) : const Color(0xFFFFD700),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          station.isSecured
                              ? 'RELAY ARCHIVES SECURED (+1500 PTS)'
                              : 'RELAY UPLINK IN PROGRESS: $progressPct%',
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.4,
                            color: station.isSecured ? const Color(0xFF64FFDA) : const Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
                      // Active Arsenal (Vampire Survivors Multi-Weapon Cards)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: player.activeWeapons.map((w) {
                          final isReady = w.currentCooldown <= 0;
                          final maxCd = math.max(0.01, w.cooldown * game.rogueFireRateMultiplier);
                          final progress = (1.0 - (w.currentCooldown / maxCd)).clamp(0.0, 1.0);
                          final isMax = w.level >= w.maxLevel;

                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: isMax
                                    ? const Color(0xFFFFD700).withOpacity(0.8)
                                    : (isReady ? valkyrie.accentColor.withOpacity(0.6) : Colors.white24),
                                width: isMax ? 1.4 : 1.0,
                              ),
                              boxShadow: isMax
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFFFD700).withOpacity(0.25),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      w.name.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.6,
                                        color: isMax ? const Color(0xFFFFD700) : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isMax
                                            ? const Color(0xFFFFD700).withOpacity(0.25)
                                            : valkyrie.primaryColor.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        isMax ? 'MAX' : 'MK ${w.level}',
                                        style: TextStyle(
                                          fontFamily: 'Orbitron',
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.bold,
                                          color: isMax ? const Color(0xFFFFD700) : valkyrie.accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Weapon Cooldown Bar
                                Container(
                                  width: 60,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: progress,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isReady
                                              ? (isMax ? const Color(0xFFFFD700) : Colors.greenAccent)
                                              : Colors.orangeAccent,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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
                                    '🎮 WASD/ARROWS: Steer | AUTO-FIRE ARSENAL | SHIFT: Dash | E: Special',
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

  Widget _buildTacticalRadar(PlayerComponent player, Valkyrie valkyrie) {
    final playerPos = player.position;
    final asteroidBlips = <Offset>[];
    try {
      final asteroids = widget.game.world.children.whereType<AsteroidComponent>();
      for (final a in asteroids) {
        final offset = a.position - playerPos;
        if (offset.length <= GameConstants.radarRange) {
          asteroidBlips.add(Offset(offset.x, offset.y));
        }
      }
    } catch (_) {}

    Offset? cometBlip;
    try {
      final comets = widget.game.world.children.whereType<CometComponent>();
      if (comets.isNotEmpty) {
        final offset = comets.first.position - playerPos;
        if (offset.length <= GameConstants.radarRange) {
          cometBlip = Offset(offset.x, offset.y);
        }
      }
    } catch (_) {}

    Offset? stationOffset;
    bool stationSecured = false;
    try {
      final stations = widget.game.world.children.whereType<SpaceStationComponent>();
      if (stations.isNotEmpty) {
        final s = stations.first;
        final offset = s.position - playerPos;
        stationOffset = Offset(offset.x, offset.y);
        stationSecured = s.isSecured;
      }
    } catch (_) {}

    final cargoBlips = <Offset>[];
    try {
      final wrecks = widget.game.world.children.whereType<CargoWreckComponent>();
      for (final w in wrecks) {
        final offset = w.position - playerPos;
        if (offset.length <= GameConstants.radarRange) {
          cargoBlips.add(Offset(offset.x, offset.y));
        }
      }
    } catch (_) {}

    final nebulaBlips = <({Offset offset, Color color, double radius})>[];
    try {
      final nebulae = widget.game.world.children.whereType<CosmicNebulaComponent>();
      for (final n in nebulae) {
        final offset = n.position - playerPos;
        if (offset.length <= GameConstants.radarRange + n.radius) {
          nebulaBlips.add((
            offset: Offset(offset.x, offset.y),
            color: n.primaryColor,
            radius: n.radius,
          ));
        }
      }
    } catch (_) {}

    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF070B14).withOpacity(0.88),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: player.isNearBoundary ? Colors.redAccent : Colors.cyanAccent.withOpacity(0.4),
          width: player.isNearBoundary ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (player.isNearBoundary ? Colors.redAccent : Colors.cyanAccent).withOpacity(0.18),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Radar Scope Canvas
          SizedBox(
            width: 86,
            height: 86,
            child: CustomPaint(
              painter: _RadarScopePainter(
                playerAngle: player.angle,
                playerColor: valkyrie.primaryColor,
                asteroidBlips: asteroidBlips,
                cometBlip: cometBlip,
                stationOffset: stationOffset,
                stationSecured: stationSecured,
                cargoBlips: cargoBlips,
                nebulaBlips: nebulaBlips,
                sweepTimer: _radarSweepTimer,
                isNearBoundary: player.isNearBoundary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Coordinate Telemetry
          Text(
            'SEC [${(player.position.x / 100).toStringAsFixed(0)} : ${(player.position.y / 100).toStringAsFixed(0)}]',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: player.isNearBoundary ? Colors.redAccent : Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarScopePainter extends CustomPainter {
  final double playerAngle;
  final Color playerColor;
  final List<Offset> asteroidBlips;
  final Offset? cometBlip;
  final Offset? stationOffset;
  final bool stationSecured;
  final List<Offset> cargoBlips;
  final List<({Offset offset, Color color, double radius})> nebulaBlips;
  final double sweepTimer;
  final bool isNearBoundary;

  _RadarScopePainter({
    required this.playerAngle,
    required this.playerColor,
    required this.asteroidBlips,
    required this.cometBlip,
    required this.stationOffset,
    required this.stationSecured,
    required this.cargoBlips,
    required this.nebulaBlips,
    required this.sweepTimer,
    required this.isNearBoundary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const maxRange = GameConstants.radarRange;

    // Background circle
    final bgPaint = Paint()
      ..color = const Color(0xFF060B16).withOpacity(0.92)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Cosmic Nebulae background zones
    for (final neb in nebulaBlips) {
      final normX = (neb.offset.dx / maxRange) * (radius * 0.88);
      final normY = (neb.offset.dy / maxRange) * (radius * 0.88);
      final blipPos = center + Offset(normX, normY);
      final scaledRad = (neb.radius / maxRange) * (radius * 0.88);
      final nebPaint = Paint()
        ..color = neb.color.withOpacity(0.18)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(blipPos, scaledRad, nebPaint);
    }

    // Range Rings
    final ringPaint = Paint()
      ..color = (isNearBoundary ? Colors.redAccent : const Color(0xFF00E5FF)).withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.5, ringPaint);
    canvas.drawCircle(center, radius * 0.95, ringPaint);

    // Crosshairs
    final crossPaint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.12)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), crossPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), crossPaint);

    // Animated Rotating Radar Sweep Line
    final sweepDir = Offset(math.cos(sweepTimer), math.sin(sweepTimer));
    final sweepPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isNearBoundary ? Colors.redAccent : const Color(0xFF00E5FF)).withOpacity(0.8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 1.5;
    canvas.drawLine(center, center + sweepDir * (radius * 0.95), sweepPaint);

    // Asteroid blips
    final astPaint = Paint()
      ..color = const Color(0xFF64D2FF).withOpacity(0.8)
      ..style = PaintingStyle.fill;
    for (final offset in asteroidBlips) {
      final normX = (offset.dx / maxRange) * (radius * 0.88);
      final normY = (offset.dy / maxRange) * (radius * 0.88);
      final blipPos = center + Offset(normX, normY);
      if ((blipPos - center).distance <= radius * 0.95) {
        canvas.drawCircle(blipPos, 1.8, astPaint);
      }
    }

    // Cargo Container blips (small amber squares)
    final cargoPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.fill;
    for (final offset in cargoBlips) {
      final normX = (offset.dx / maxRange) * (radius * 0.88);
      final normY = (offset.dy / maxRange) * (radius * 0.88);
      final blipPos = center + Offset(normX, normY);
      if ((blipPos - center).distance <= radius * 0.95) {
        canvas.drawRect(Rect.fromCenter(center: blipPos, width: 3.5, height: 3.5), cargoPaint);
      }
    }

    // Research Relay Station blip / Waypoint Arrow
    if (stationOffset != null) {
      final stationDist = stationOffset!.distance;
      final stColor = stationSecured ? const Color(0xFF64FFDA) : const Color(0xFFFFD700);

      if (stationDist <= maxRange) {
        // Station is inside radar range - golden diamond with pulsing beacon
        final normX = (stationOffset!.dx / maxRange) * (radius * 0.88);
        final normY = (stationOffset!.dy / maxRange) * (radius * 0.88);
        final blipPos = center + Offset(normX, normY);

        final dPath = Path()
          ..moveTo(blipPos.dx, blipPos.dy - 4.0)
          ..lineTo(blipPos.dx + 4.0, blipPos.dy)
          ..lineTo(blipPos.dx, blipPos.dy + 4.0)
          ..lineTo(blipPos.dx - 4.0, blipPos.dy)
          ..close();
        final stationPaint = Paint()
          ..color = stColor
          ..style = PaintingStyle.fill;
        canvas.drawPath(dPath, stationPaint);

        // Beacon pulse ring
        final beaconRadius = 4.0 + 3.0 * ((1.0 + math.sin(sweepTimer * 4.0)) / 2.0);
        final beaconPaint = Paint()
          ..color = stColor.withOpacity(0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(blipPos, beaconRadius, beaconPaint);
      } else {
        // Station is outside radar range - draw perimeter waypoint arrow on the rim
        final angleToStation = math.atan2(stationOffset!.dy, stationOffset!.dx);
        final arrowPos = center + Offset(math.cos(angleToStation), math.sin(angleToStation)) * (radius * 0.90);

        canvas.save();
        canvas.translate(arrowPos.dx, arrowPos.dy);
        canvas.rotate(angleToStation + math.pi / 2);

        final arrowPath = Path()
          ..moveTo(0, -5.0)
          ..lineTo(4.0, 3.5)
          ..lineTo(-4.0, 3.5)
          ..close();
        final arrowPaint = Paint()
          ..color = stColor
          ..style = PaintingStyle.fill;
        canvas.drawPath(arrowPath, arrowPaint);
        canvas.restore();
      }
    }

    // Comet blip
    if (cometBlip != null) {
      final normX = (cometBlip!.dx / maxRange) * (radius * 0.88);
      final normY = (cometBlip!.dy / maxRange) * (radius * 0.88);
      final blipPos = center + Offset(normX, normY);
      final cometPaint = Paint()
        ..color = const Color(0xFFFFD700)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(blipPos, 3.5, cometPaint);
    }

    // Center Valkyrie ship icon (small triangle pointing in ship angle)
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(playerAngle);

    final shipPath = Path()
      ..moveTo(0, -6)
      ..lineTo(4, 5)
      ..lineTo(0, 2.5)
      ..lineTo(-4, 5)
      ..close();

    final shipPaint = Paint()
      ..color = playerColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(shipPath, shipPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RadarScopePainter oldDelegate) => true;
}
