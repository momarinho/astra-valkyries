import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:asteroids/game/components/enemy_ship.dart';
import 'package:asteroids/game/components/chest.dart';
import 'package:asteroids/game/components/phase4_biome_elements.dart';
import 'package:asteroids/game/map/sector_map_data.dart';

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
  double _hudAccumulator = 0.0;
  double _lastHp = -1.0;
  Duration _lastElapsed = Duration.zero;
  bool _showTouchControls = false;

  @override
  void initState() {
    super.initState();
    _showTouchControls = kIsWeb ? true : (!Platform.isLinux && !Platform.isMacOS && !Platform.isWindows);
    _lastScore = widget.game.score;
    _displayScore = widget.game.score.toDouble();
    try {
      _lastHp = widget.game.player.hp;
    } catch (_) {}

    _ticker = createTicker((elapsed) {
      final dt = ((elapsed - _lastElapsed).inMicroseconds / 1000000.0).clamp(0.0, 0.1);
      _lastElapsed = elapsed;
      _tickScore(dt);
      _radarSweepTimer = (_radarSweepTimer + dt * 2.5) % (2 * math.pi);

      double currentHp = _lastHp;
      try {
        currentHp = widget.game.player.hp;
      } catch (_) {}
      final hpChanged = currentHp != _lastHp;
      _lastHp = currentHp;

      final targetScore = widget.game.score;
      final scoreChanged = targetScore != _lastScore;

      _hudAccumulator += dt;
      // Atualiza imediatamente se HP ou Pontuação mudou; caso contrário, sincroniza o HUD a 30 FPS
      if (hpChanged || scoreChanged || _hudAccumulator >= 0.033) {
        _hudAccumulator = 0.0;
        if (mounted) {
          setState(() {});
        }
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

    // Station uplink telemetry
    SpaceStationComponent? station;
    try {
      final stations = game.world.children.whereType<SpaceStationComponent>();
      if (stations.isNotEmpty) station = stations.first;
    } catch (_) {}
    final showStationBanner = station != null && (station.isPlayerInZone || station.uploadProgress > 0);

    // Reactive mini-avatar state detection & Health status
    String currentAvatarAsset;
    Color avatarGlowColor;
    String statusExpression;

    final hpRatio = player.hpPercent;

    if (hpRatio <= 0.30 || isInvulnerable) {
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
          // Low Hull Dramatic Red Pulsing Vignette (< 25% HP) OR Void Reaper Incursion
          if (hpRatio <= 0.25 || game.voidReaperSpawned)
            Positioned.fill(
              child: IgnorePointer(
                child: Builder(
                  builder: (context) {
                    final pulse = (math.sin(DateTime.now().millisecondsSinceEpoch / 220) + 1) / 2;
                    final isReaper = game.voidReaperSpawned;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.1,
                          colors: [
                            Colors.transparent,
                            (isReaper ? const Color(0xFF4A148C) : Colors.red).withOpacity(0.12 + pulse * 0.18),
                            (isReaper ? const Color(0xFFB71C1C) : Colors.red).withOpacity(0.35 + pulse * 0.35),
                          ],
                          stops: const [0.35, 0.75, 1.0],
                        ),
                        border: Border.all(
                          color: (isReaper ? const Color(0xFFFF1744) : Colors.redAccent).withOpacity(0.45 + pulse * 0.55),
                          width: 4.0,
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
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 360),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
        ),
      ),

          // Boss Health Bar (Dreadnought Leviathan Climax)
          if (game.activeBoss != null && !game.activeBoss!.isDefeated)
            Positioned(
              top: 32,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF1744), size: 14),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  game.activeBoss!.bossName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontFamily: 'Orbitron',
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: Color(0xFFFF1744),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${((game.activeBoss!.hp / game.activeBoss!.maxHp) * 100).toInt()}% HULL',
                          style: const TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF5252),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFF1744), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF1744).withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: (game.activeBoss!.hp / game.activeBoss!.maxHp).clamp(0.0, 1.0),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFFF1744), Color(0xFFFF8A80), Color(0xFFFFD700)],
                                ),
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
          ),
        ),

          // Top Left: Unified Pilot Status Frame (Avatar, Hull HP Bar, Shield, Callsign, Score & Compact Arsenal)
          Positioned(
            top: 0,
            left: 0,
            child: IgnorePointer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF060A13).withOpacity(0.88),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: avatarGlowColor.withOpacity(0.6),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: avatarGlowColor.withOpacity(0.22),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Pilot Mini-Avatar Box (56x56)
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: avatarGlowColor, width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
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
                                                  : (valkyrie.shipDesign == ValkyrieShipDesign.originPrime
                                                      ? Icons.auto_awesome
                                                      : Icons.all_inclusive)),
                                          color: valkyrie.accentColor,
                                          size: 28,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    color: Colors.black.withOpacity(0.85),
                                    padding: const EdgeInsets.symmetric(vertical: 1.0),
                                    child: Text(
                                      statusExpression,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontSize: 6.0,
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
                        const SizedBox(width: 10),

                        // Pilot Telemetry Details
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pilot Name & Callsign
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  valkyrie.name.toUpperCase(),
                                  style: TextStyle(
                                    fontFamily: 'Orbitron',
                                    fontSize: 12.0,
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
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.7),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),

                            // Hull Integrity HP Bar
                            _buildHullHpBar(player, valkyrie),
                            const SizedBox(height: 3),

                            // Score & Shield Status
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'SCORE',
                                  style: TextStyle(
                                    fontFamily: 'Rajdhani',
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: Colors.white.withOpacity(0.65),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Transform.scale(
                                  scale: 1.0 + 0.10 * _scorePulse,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    _formatScore(_displayScore.round()),
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.0,
                                      color: Color.lerp(Colors.white, valkyrie.accentColor, _scorePulse * 0.8),
                                    ),
                                  ),
                                ),
                                if (isInvulnerable) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E5FF).withOpacity(0.25),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFF00E5FF), width: 0.8),
                                    ),
                                    child: Text(
                                      'SHIELD: ${invulTime.toStringAsFixed(1)}s',
                                      style: const TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontSize: 8.0,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF00E5FF),
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Compact Active Arsenal Icons (Vampire Survivors / Hades style)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: player.activeWeapons.map((w) {
                      final isReady = w.currentCooldown <= 0;
                      final maxCd = math.max(0.01, w.cooldown * game.rogueFireRateMultiplier);
                      final progress = (1.0 - (w.currentCooldown / maxCd)).clamp(0.0, 1.0);
                      final isMax = w.level >= w.maxLevel;

                      return Container(
                        margin: const EdgeInsets.only(right: 5),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: w.isEvolved
                                ? const Color(0xFFFFD700)
                                : (isMax ? const Color(0xFFFFB300) : (isReady ? valkyrie.accentColor.withOpacity(0.65) : Colors.white24)),
                            width: (w.isEvolved || isMax) ? 1.4 : 1.0,
                          ),
                          boxShadow: (w.isEvolved || isMax)
                              ? [
                                  BoxShadow(
                                    color: (w.isEvolved ? const Color(0xFFFFD700) : const Color(0xFFFFB300)).withOpacity(0.35),
                                    blurRadius: 6,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              _getWeaponIcon(w),
                              size: 16,
                              color: w.isEvolved
                                  ? const Color(0xFFFFD700)
                                  : (isMax ? const Color(0xFFFFB300) : valkyrie.accentColor),
                            ),
                            Positioned(
                              top: 1,
                              right: 2,
                              child: Text(
                                w.isEvolved ? 'EVO' : (isMax ? 'MAX' : '${w.level}'),
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.bold,
                                  color: w.isEvolved
                                      ? const Color(0xFFFFD700)
                                      : (isMax ? const Color(0xFFFFB300) : Colors.white70),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 2.5,
                                decoration: const BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isReady
                                          ? (w.isEvolved || isMax ? const Color(0xFFFFD700) : Colors.greenAccent)
                                          : Colors.orangeAccent,
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
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
                ],
              ),
            ),
          ),

          // Top Right: Mission Telemetry (Timer, Credits, Pause & Tactical Radar)
          Positioned(
            top: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sector Mission Countdown Timer
                    _buildSectorTimerBadge(),
                    const SizedBox(width: 8),

                    // Stardust Credits Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFFFB300).withOpacity(0.6),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars_rounded, color: Color(0xFFFFB300), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${game.runCredits}c',
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFB300),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Pause Button
                    GestureDetector(
                      onTap: () {
                        game.togglePause();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24, width: 1.2),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pause, color: Colors.white70, size: 14),
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

                // Vortex Surge Floor Drop Status (if active)
                if (player.vortexSurgeTimer > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD500F9).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD500F9)),
                    ),
                    child: Text(
                      '🌀 SURGE: ${player.vortexSurgeTimer.toStringAsFixed(1)}s',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD500F9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Tactical Mini-Radar & Spatial Navigation
                GestureDetector(
                  onTap: () {
                    widget.game.openTacticalMap();
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTacticalRadar(player, valkyrie),
                      const SizedBox(height: 3),
                      Text(
                        '[M] MAPA TÁTICO',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                          color: valkyrie.primaryColor.withOpacity(0.85),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
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
          if (showStationBanner)
            Positioned(
              top: (player.isNearBoundary ? 94.0 : 54.0) + (player.activeNebulaName != null ? 36.0 : 0.0),
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
                            : 'RELAY UPLINK IN PROGRESS: ${(station.uploadProgress / SpaceStationComponent.targetUploadTime * 100).toInt()}%',
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
            ),



          // Desktop Tactical Keyhints Banner (centered at bottom)
          if (!_showTouchControls)
            Positioned(
              bottom: 8,
              left: 12,
              right: 12,
              child: IgnorePointer(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF040711).withOpacity(0.78),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildKeyHintBadge('WASD', 'MOVER'),
                          const SizedBox(width: 8),
                          _buildKeyHintBadge('ESPAÇO', 'DASH'),
                          const SizedBox(width: 8),
                          _buildKeyHintBadge('Q', 'ESPECIAL'),
                          const SizedBox(width: 8),
                          _buildKeyHintBadge('BOTÃO ESQ', 'MIRA/TIRO'),
                          const SizedBox(width: 8),
                          _buildKeyHintBadge('M', 'MAPA'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Touch Controls Toggle (bottom-left)
          Positioned(
            bottom: _showTouchControls ? 136 : 8,
            left: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showTouchControls = !_showTouchControls;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF070B14).withOpacity(0.75),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showTouchControls ? Icons.keyboard_rounded : Icons.sports_esports_rounded,
                      color: Colors.white70,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showTouchControls ? 'KEYBOARD' : 'TOUCH',
                      style: const TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 9.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Left: Interactive Virtual Joystick (Visible when touch controls active)
          if (_showTouchControls)
            Positioned(
              bottom: 12,
              left: 12,
              child: _buildVirtualJoystick(game, valkyrie),
            ),

          // Bottom Right: Mobile Action Buttons (Visible when touch controls active)
          if (_showTouchControls)
            Positioned(
              bottom: 12,
              right: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Thruster Dash Button
                  GestureDetector(
                    onTap: () {
                      player.dash();
                      widget.game.playSfx('dash.wav');
                    },
                    child: Builder(
                      builder: (context) {
                        final isVesper = player.valkyrie?.id == 'vesper';
                        final isReady = isVesper ? (player.dashCharges > 0) : (dashCooldown <= 0);
                        final progress = isReady
                            ? 1.0
                            : (1.0 - (dashCooldown / (isVesper ? 1.8 : GameConstants.playerDashCooldownSeconds))).clamp(0.0, 1.0);
                        final dashLabel = isVesper
                            ? (player.dashCharges > 0 ? '${player.dashCharges}x DASH' : '${dashCooldown.toStringAsFixed(1)}s')
                            : (isReady ? 'DASH' : '${dashCooldown.toStringAsFixed(1)}s');
                        return Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(0xFF070B14).withOpacity(0.88),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isReady ? Colors.cyanAccent : Colors.white24,
                              width: isReady ? 2.0 : 1.2,
                            ),
                            boxShadow: isReady
                                ? [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withOpacity(0.35),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isReady ? Colors.cyanAccent : Colors.orangeAccent,
                                ),
                                backgroundColor: Colors.transparent,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    color: isReady ? Colors.cyanAccent : Colors.white38,
                                    size: 24,
                                  ),
                                  Text(
                                    dashLabel,
                                    style: TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 9.0,
                                      fontWeight: FontWeight.bold,
                                      color: isReady ? Colors.cyanAccent : Colors.white38,
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

                  const SizedBox(width: 14),

                  // 2. Overdrive / Special Ultimate Button
                  GestureDetector(
                    onTap: () {
                      widget.game.triggerSpecial();
                    },
                    child: Builder(
                      builder: (context) {
                        final isReady = widget.game.specialAvailable;
                        final pulse = isReady
                            ? (math.sin(DateTime.now().millisecondsSinceEpoch / 180) + 1) / 2
                            : 0.0;

                        return Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: isReady
                                ? valkyrie.primaryColor.withOpacity(0.28 + pulse * 0.15)
                                : const Color(0xFF070B14).withOpacity(0.88),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isReady
                                  ? valkyrie.primaryColor.withOpacity(0.9 + pulse * 0.1)
                                  : Colors.white24,
                              width: isReady ? 2.8 : 1.5,
                            ),
                            boxShadow: isReady
                                ? [
                                    BoxShadow(
                                      color: valkyrie.primaryColor.withOpacity(0.5 + pulse * 0.3),
                                      blurRadius: 14 + pulse * 6,
                                      spreadRadius: 1.5,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isReady ? Icons.auto_awesome : Icons.lock_outline,
                                color: isReady ? const Color(0xFFFFD700) : Colors.white30,
                                size: 28,
                              ),
                              Text(
                                isReady ? 'SPECIAL' : 'RECHARGE',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 8.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: isReady ? const Color(0xFFFFD700) : Colors.white30,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 14),

                  // 3. Aim Lock (Strafe Kiting) + Manual Shoot Burst Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        widget.game.isAimLocked = !widget.game.isAimLocked;
                      });
                      player.shoot();
                    },
                    onLongPressStart: (_) {
                      setState(() {
                        widget.game.mobileShootPressed = true;
                      });
                      player.shoot();
                    },
                    onLongPressEnd: (_) {
                      setState(() {
                        widget.game.mobileShootPressed = false;
                      });
                    },
                    child: Builder(
                      builder: (context) {
                        final isLocked = widget.game.isAimLocked || widget.game.mobileShootPressed;
                        final activeColor = isLocked ? const Color(0xFFFF1744) : Colors.amberAccent;
                        return Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: isLocked
                                ? const Color(0xFFFF1744).withValues(alpha: 0.24)
                                : const Color(0xFF070B14).withValues(alpha: 0.88),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: activeColor.withValues(alpha: isLocked ? 0.95 : 0.8),
                              width: isLocked ? 2.4 : 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: activeColor.withValues(alpha: isLocked ? 0.55 : 0.25),
                                blurRadius: isLocked ? 14 : 8,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isLocked ? Icons.lock_rounded : Icons.gps_fixed_rounded,
                                color: activeColor,
                                size: 23,
                              ),
                              Text(
                                isLocked ? 'LOCKED' : 'LOCK/FIRE',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                  color: activeColor,
                                ),
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

          // Layer 2: Comms Radio Holographic Dialogue Transmission Box at Sortie Launch
          if (game.showLaunchTransmission)
            Positioned(
              bottom: 145,
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
                                  Expanded(
                                    child: Text(
                                      '🎮 WASD/ARROWS: Steer | AUTO-FIRE ARSENAL | SHIFT: Dash | E: Special',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Rajdhani',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: valkyrie.primaryColor,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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

  Widget _buildVirtualJoystick(AsteroidsGame game, Valkyrie valkyrie) {
    const double baseSize = 116.0;
    const double maxRadius = 46.0;
    const double knobSize = 42.0;

    double knobX = 0.0;
    double knobY = 0.0;
    bool isActive = false;

    try {
      final joy = game.joystick;
      final scale = maxRadius / joy.backgroundRadius;
      knobX = (joy.knobPosition.x * scale).clamp(-maxRadius, maxRadius);
      knobY = (joy.knobPosition.y * scale).clamp(-maxRadius, maxRadius);
      isActive = joy.isDragging || joy.stickInput.length > 0.12;
    } catch (_) {}

    void updateFromLocal(Offset localPos) {
      try {
        final joy = game.joystick;
        final center = const Offset(baseSize / 2, baseSize / 2);
        final delta = localPos - center;
        final dist = delta.distance;
        final clamped = dist <= maxRadius ? delta : Offset.fromDirection(delta.direction, maxRadius);
        final scaleToJoy = joy.backgroundRadius / maxRadius;
        joy.isDragging = true;
        joy.knobPosition.setValues(clamped.dx * scaleToJoy, clamped.dy * scaleToJoy);
        final norm = dist <= 0.001 ? Offset.zero : (clamped / maxRadius);
        if (norm.distance < 0.12) {
          joy.stickInput.setZero();
        } else {
          joy.stickInput.setValues(norm.dx, norm.dy);
        }
        setState(() {});
      } catch (_) {}
    }

    void resetStick() {
      try {
        final joy = game.joystick;
        joy.isDragging = false;
        joy.knobPosition.setZero();
        joy.stickInput.setZero();
        setState(() {});
      } catch (_) {}
    }

    return GestureDetector(
      key: const ValueKey('hud_virtual_joystick'),
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) => updateFromLocal(details.localPosition),
      onPanUpdate: (details) => updateFromLocal(details.localPosition),
      onPanEnd: (_) => resetStick(),
      onPanCancel: resetStick,
      child: SizedBox(
        width: baseSize,
        height: baseSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Tactical Ring
            Container(
              width: baseSize,
              height: baseSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF070B14).withValues(alpha: 0.72),
                border: Border.all(
                  color: isActive
                      ? valkyrie.accentColor.withValues(alpha: 0.85)
                      : Colors.cyanAccent.withValues(alpha: 0.42),
                  width: isActive ? 2.2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isActive ? valkyrie.primaryColor : Colors.cyanAccent)
                        .withValues(alpha: isActive ? 0.32 : 0.12),
                    blurRadius: isActive ? 14 : 8,
                  ),
                ],
              ),
            ),
            // Inner Crosshair Ring
            Container(
              width: baseSize * 0.56,
              height: baseSize * 0.56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.0,
                ),
              ),
            ),
            // Directional chevrons
            const Positioned(
              top: 6,
              child: Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white30, size: 16),
            ),
            const Positioned(
              bottom: 6,
              child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white30, size: 16),
            ),
            const Positioned(
              left: 6,
              child: Icon(Icons.keyboard_arrow_left_rounded, color: Colors.white30, size: 16),
            ),
            const Positioned(
              right: 6,
              child: Icon(Icons.keyboard_arrow_right_rounded, color: Colors.white30, size: 16),
            ),
            // Thumb Stick Knob
            Transform.translate(
              offset: Offset(knobX, knobY),
              child: Container(
                width: knobSize,
                height: knobSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.95),
                      isActive ? valkyrie.accentColor : Colors.cyanAccent,
                      valkyrie.primaryColor.withValues(alpha: 0.85),
                    ],
                  ),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: (isActive ? valkyrie.accentColor : Colors.cyanAccent).withValues(alpha: 0.65),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.control_camera_rounded,
                  size: 18,
                  color: Color(0xFF050811),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorTimerBadge() {
    final remaining = widget.game.timeRemaining.clamp(0.0, 9999.0);
    final minutes = (remaining / 60).floor().toString().padLeft(2, '0');
    final seconds = (remaining % 60).floor().toString().padLeft(2, '0');
    final isUrgent = remaining <= 30.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUrgent ? const Color(0xFFFF1744) : widget.game.currentSector.primaryColor.withOpacity(0.7),
          width: 1.2,
        ),
        boxShadow: isUrgent
            ? [
                BoxShadow(
                  color: const Color(0xFFFF1744).withOpacity(0.4),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUrgent ? Icons.warning_amber_rounded : Icons.timer_outlined,
            color: isUrgent ? const Color(0xFFFF1744) : widget.game.currentSector.primaryColor,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            '$minutes:$seconds',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 11.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: isUrgent ? const Color(0xFFFF5252) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFpsDiagnosticBadge() {
    final fps = widget.game.currentFps.round();
    final ms = widget.game.currentFrameTimeMs.toStringAsFixed(1);
    final entityCount = widget.game.world.children.length;

    final fpsColor = fps >= 55
        ? const Color(0xFF00E676)
        : (fps >= 35 ? const Color(0xFFFFD600) : const Color(0xFFFF1744));

    return GestureDetector(
      onTap: () {
        setState(() {
          widget.game.showDiagnostics = !widget.game.showDiagnostics;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: fpsColor.withOpacity(0.6),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: fpsColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: fpsColor.withOpacity(0.7), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$fps FPS',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
                color: fpsColor,
                letterSpacing: 0.5,
              ),
            ),
            if (widget.game.showDiagnostics) ...[
              const SizedBox(width: 5),
              Text(
                '| ${ms}ms | $entityCount ENT',
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getWeaponIcon(dynamic w) {
    final name = (w.name as String).toLowerCase();
    if (name.contains('laser')) return Icons.flare_rounded;
    if (name.contains('plasma') || name.contains('cannon')) return Icons.local_fire_department_rounded;
    if (name.contains('shield') || name.contains('barrier') || name.contains('prism')) return Icons.shield_rounded;
    if (name.contains('lance') || name.contains('graviton')) return Icons.gps_fixed_rounded;
    if (name.contains('singularity') || name.contains('vortex')) return Icons.all_inclusive_rounded;
    if (name.contains('mine')) return Icons.radio_button_checked_rounded;
    return Icons.auto_awesome_rounded;
  }

  Widget _buildKeyHintBadge(String keyText, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24, width: 0.8),
          ),
          child: Text(
            keyText,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildHullHpBar(PlayerComponent player, Valkyrie valkyrie) {
    final hp = player.hp;
    final maxHp = player.maxHp;
    final hpRatio = (hp / math.max(1.0, maxHp)).clamp(0.0, 1.0);

    final Color hpColor;
    if (hpRatio > 0.50) {
      hpColor = const Color(0xFF00E676); // Emerald Green
    } else if (hpRatio > 0.25) {
      hpColor = const Color(0xFFFFB300); // Amber Warning
    } else {
      hpColor = const Color(0xFFFF1744); // Crimson Alert
    }

    return Container(
      width: 175,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: hpColor.withOpacity(0.6),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 11, color: hpColor),
                  const SizedBox(width: 3),
                  Text(
                    'HULL',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              Text(
                '${hp.toInt()}/${maxHp.toInt()} HP',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 9.0,
                  fontWeight: FontWeight.bold,
                  color: hpColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2.5),
          // Progress bar
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(2.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2.5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: hpRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [hpColor, hpColor.withOpacity(0.8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: hpColor.withOpacity(0.8),
                          blurRadius: 4,
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

    final enemyBlips = <({Offset offset, bool isElite})>[];
    try {
      final enemies = widget.game.world.children.whereType<EnemyShipComponent>();
      for (final e in enemies) {
        final offset = e.position - playerPos;
        if (offset.length <= GameConstants.radarRange) {
          enemyBlips.add((
            offset: Offset(offset.x, offset.y),
            isElite: e.type == EnemyType.eliteCommander,
          ));
        }
      }
    } catch (_) {}

    final chestBlips = <Offset>[];
    try {
      final chests = widget.game.world.children.whereType<ChestComponent>();
      for (final c in chests) {
        final offset = c.position - playerPos;
        if (offset.length <= GameConstants.radarRange) {
          chestBlips.add(Offset(offset.x, offset.y));
        }
      }
    } catch (_) {}

    Offset? bossOffset;
    try {
      final boss = widget.game.activeBoss;
      if (boss != null && !boss.isDefeated) {
        bossOffset = Offset(boss.position.x - playerPos.x, boss.position.y - playerPos.y);
      }
    } catch (_) {}

    final hasAegisRadar = widget.game.unlockedRelics.contains('aegis_radar');
    Offset? relicOffset;
    double? relicDistanceMeters;
    Offset? coffinOffset;
    double? coffinDistanceMeters;

    if (hasAegisRadar) {
      try {
        final currentSec = widget.game.currentSector;
        if (!widget.game.unlockedRelics.contains(currentSec.relicId)) {
          final pedestals = widget.game.world.children.whereType<RelicPedestalComponent>();
          if (pedestals.isNotEmpty && !pedestals.first.isClaimed) {
            final relPos = pedestals.first.position;
            relicOffset = Offset(relPos.x - playerPos.x, relPos.y - playerPos.y);
            relicDistanceMeters = (relicOffset.distance / 10).roundToDouble();
          } else {
            final relicNode = widget.game.sectorMap?.nodes
                .where((n) => n.type == MapNodeType.relicPedestal)
                .firstOrNull;
            if (relicNode != null) {
              relicOffset = Offset(relicNode.position.x - playerPos.x, relicNode.position.y - playerPos.y);
              relicDistanceMeters = (relicOffset.distance / 10).roundToDouble();
            }
          }
        }
      } catch (_) {}

      try {
        final currentSec = widget.game.currentSector;
        if (!widget.game.rescuedSectorSecrets.contains(currentSec.id)) {
          final coffins = widget.game.world.children.whereType<StasisCoffinComponent>();
          if (coffins.isNotEmpty && !coffins.first.isOpened) {
            final cofPos = coffins.first.position;
            coffinOffset = Offset(cofPos.x - playerPos.x, cofPos.y - playerPos.y);
            coffinDistanceMeters = (coffinOffset.distance / 10).roundToDouble();
          } else {
            final coffinNode = widget.game.sectorMap?.nodes
                .where((n) => n.type == MapNodeType.stasisCoffin)
                .firstOrNull;
            if (coffinNode != null) {
              coffinOffset = Offset(coffinNode.position.x - playerPos.x, coffinNode.position.y - playerPos.y);
              coffinDistanceMeters = (coffinOffset.distance / 10).roundToDouble();
            }
          }
        }
      } catch (_) {}
    }

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
                enemyBlips: enemyBlips,
                chestBlips: chestBlips,
                bossOffset: bossOffset,
                hasAegisRadar: hasAegisRadar,
                relicOffset: relicOffset,
                coffinOffset: coffinOffset,
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
          if (hasAegisRadar && (relicDistanceMeters != null || coffinDistanceMeters != null)) ...[
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.16),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore_rounded, size: 9, color: Color(0xFFFFD700)),
                  const SizedBox(width: 2),
                  Text(
                    relicDistanceMeters != null
                        ? 'RELIC ${(relicDistanceMeters).round()}m'
                        : 'SECR ${(coffinDistanceMeters!).round()}m',
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
  final List<({Offset offset, bool isElite})> enemyBlips;
  final List<Offset> chestBlips;
  final Offset? bossOffset;
  final bool hasAegisRadar;
  final Offset? relicOffset;
  final Offset? coffinOffset;
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
    required this.enemyBlips,
    required this.chestBlips,
    required this.bossOffset,
    this.hasAegisRadar = false,
    this.relicOffset,
    this.coffinOffset,
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
    final sweepColor = isNearBoundary ? Colors.redAccent : const Color(0xFF00E5FF);
    final sweepPaint = Paint()
      ..color = sweepColor.withOpacity(0.85)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
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

    // Hostile Enemy Fleet blips (crimson triangles / gold diamond for elite)
    final enemyPaint = Paint()
      ..color = const Color(0xFFFF1744)
      ..style = PaintingStyle.fill;
    final elitePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    for (final e in enemyBlips) {
      final normX = (e.offset.dx / maxRange) * (radius * 0.88);
      final normY = (e.offset.dy / maxRange) * (radius * 0.88);
      final blipPos = center + Offset(normX, normY);
      if ((blipPos - center).distance <= radius * 0.95) {
        if (e.isElite) {
          canvas.drawCircle(blipPos, 4.0, elitePaint);
          final ringPaint = Paint()
            ..color = const Color(0xFFD500F9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2;
          canvas.drawCircle(blipPos, 6.0, ringPaint);
        } else {
          canvas.drawCircle(blipPos, 2.2, enemyPaint);
        }
      }
    }

    // Cosmic Chest blips (pulsing golden diamonds)
    final chestPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;
    for (final offset in chestBlips) {
      final normX = (offset.dx / maxRange) * (radius * 0.88);
      final normY = (offset.dy / maxRange) * (radius * 0.88);
      final blipPos = center + Offset(normX, normY);
      if ((blipPos - center).distance <= radius * 0.95) {
        canvas.drawRect(Rect.fromCenter(center: blipPos, width: 4.5, height: 4.5), chestPaint);
      }
    }

    // Titanic Dreadnought Leviathan Boss blip / Waypoint Arrow
    if (bossOffset != null) {
      final bossDist = bossOffset!.distance;
      if (bossDist <= maxRange) {
        final normX = (bossOffset!.dx / maxRange) * (radius * 0.88);
        final normY = (bossOffset!.dy / maxRange) * (radius * 0.88);
        final blipPos = center + Offset(normX, normY);

        final bossPaint = Paint()
          ..color = const Color(0xFFFF1744)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(blipPos, 5.0, bossPaint);

        final ringPaint = Paint()
          ..color = const Color(0xFFFFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(blipPos, 8.5, ringPaint);
      } else {
        final angleToBoss = math.atan2(bossOffset!.dy, bossOffset!.dx);
        final arrowPos = center + Offset(math.cos(angleToBoss), math.sin(angleToBoss)) * (radius * 0.90);

        canvas.save();
        canvas.translate(arrowPos.dx, arrowPos.dy);
        canvas.rotate(angleToBoss + math.pi / 2);

        final arrowPath = Path()
          ..moveTo(0, -6.0)
          ..lineTo(5.0, 4.0)
          ..lineTo(-5.0, 4.0)
          ..close();
        final arrowPaint = Paint()
          ..color = const Color(0xFFFF1744)
          ..style = PaintingStyle.fill;
        canvas.drawPath(arrowPath, arrowPaint);
        canvas.restore();
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

    // Aegis Radar Compass (Sprint 26 & 28)
    if (hasAegisRadar) {
      if (relicOffset != null) {
        final dist = relicOffset!.distance;
        const relicColor = Color(0xFFFFD700);
        if (dist <= maxRange) {
          final normX = (relicOffset!.dx / maxRange) * (radius * 0.88);
          final normY = (relicOffset!.dy / maxRange) * (radius * 0.88);
          final blipPos = center + Offset(normX, normY);

          // Golden Star / Relic Icon
          final starPaint = Paint()
            ..color = relicColor
            ..style = PaintingStyle.fill;
          canvas.drawCircle(blipPos, 4.0, starPaint);
          canvas.drawCircle(
            blipPos,
            6.0 + 2.0 * math.sin(sweepTimer * 5.0),
            Paint()
              ..color = relicColor.withOpacity(0.55)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0,
          );
        } else {
          // Perimeter Compass Pointer on radar edge
          final angle = math.atan2(relicOffset!.dy, relicOffset!.dx);
          final arrowPos = center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.92);

          canvas.save();
          canvas.translate(arrowPos.dx, arrowPos.dy);
          canvas.rotate(angle + math.pi / 2);

          final path = Path()
            ..moveTo(0, -6.0)
            ..lineTo(4.5, 4.0)
            ..lineTo(-4.5, 4.0)
            ..close();
          canvas.drawPath(path, Paint()..color = relicColor..style = PaintingStyle.fill);
          canvas.restore();
        }
      }

      if (coffinOffset != null) {
        final dist = coffinOffset!.distance;
        const coffinColor = Color(0xFF00E5FF);
        if (dist <= maxRange) {
          final normX = (coffinOffset!.dx / maxRange) * (radius * 0.88);
          final normY = (coffinOffset!.dy / maxRange) * (radius * 0.88);
          final blipPos = center + Offset(normX, normY);

          // Cyan Coffin Pod Icon
          final podPaint = Paint()
            ..color = coffinColor
            ..style = PaintingStyle.fill;
          canvas.drawRect(Rect.fromCenter(center: blipPos, width: 6, height: 8), podPaint);
        } else {
          final angle = math.atan2(coffinOffset!.dy, coffinOffset!.dx);
          final arrowPos = center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.92);

          canvas.save();
          canvas.translate(arrowPos.dx, arrowPos.dy);
          canvas.rotate(angle + math.pi / 2);

          final path = Path()
            ..moveTo(0, -5.5)
            ..lineTo(4.0, 3.5)
            ..lineTo(-4.0, 3.5)
            ..close();
          canvas.drawPath(path, Paint()..color = coffinColor..style = PaintingStyle.fill);
          canvas.restore();
        }
      }
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
