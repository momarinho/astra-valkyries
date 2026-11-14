import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:void_protocol/game/asteroids_game.dart';
import 'package:void_protocol/game/valkyrie.dart';
import 'package:void_protocol/services/localization_service.dart';
import 'package:void_protocol/ui/responsive_ui.dart';

class TitleScreenOverlay extends StatefulWidget {
  final AsteroidsGame game;
  final bool skipBootAnimation;

  const TitleScreenOverlay({
    super.key,
    required this.game,
    this.skipBootAnimation = false,
  });

  @override
  State<TitleScreenOverlay> createState() => _TitleScreenOverlayState();
}

class _TitleScreenOverlayState extends State<TitleScreenOverlay>
    with SingleTickerProviderStateMixin {
  static bool _hasBootedOnce = false;

  final FocusNode _focusNode = FocusNode();
  late final AnimationController _pulseController;
  Timer? _bootTimer;

  bool _isBooting = true;
  double _bootProgress = 0.0;
  int _selectedMenuIndex = 0;

  final List<String> _bootLogs = const [
    '[OK] INITIALIZING FLAME 2D ENGINE & NEBULA SHADERS...',
    '[OK] PRE-CACHING SQUADRON HOLOGRAPHIC PORTRAITS...',
    '[OK] SYNCHRONIZING PROCEDURAL SECTOR RADAR & BOSS LAIRS...',
    '[OK] CALIBRATING WEAPON SYNERGY GRIMOIRE & AUDIO MIXER...',
    '[OK] AEGIS COMMAND // VOID PROTOCOL READY.',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    if (widget.skipBootAnimation || _hasBootedOnce) {
      _isBooting = false;
      _bootProgress = 1.0;
    } else {
      _startBootSequence();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
        _precacheValkyrieArt();
      }
    });
  }

  void _precacheValkyrieArt() {
    for (final v in Valkyrie.roster) {
      try {
        precacheImage(AssetImage(v.hangarFullBodyAsset), context, onError: (_, _) {}).ignore();
        precacheImage(AssetImage(v.hudNeutralAsset), context, onError: (_, _) {}).ignore();
      } catch (_) {}
    }
  }

  void _startBootSequence() {
    const stepMs = 45;
    _bootTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _bootProgress = (_bootProgress + 0.045).clamp(0.0, 1.0);
        if (_bootProgress >= 1.0) {
          _isBooting = false;
          _hasBootedOnce = true;
          timer.cancel();
        }
      });
    });
  }

  void _finishBootImmediately() {
    _bootTimer?.cancel();
    setState(() {
      _bootProgress = 1.0;
      _isBooting = false;
      _hasBootedOnce = true;
    });
  }

  @override
  void dispose() {
    _bootTimer?.cancel();
    _pulseController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _executeMenuAction(int index) {
    widget.game.playSfx('menu_select.wav');
    switch (index) {
      case 0:
        widget.game.initialHangarTab = 0;
        widget.game.changeState(GameState.valkyrieSelection);
        break;
      case 1:
        widget.game.initialHangarTab = 1;
        widget.game.changeState(GameState.valkyrieSelection);
        break;
      case 2:
        widget.game.initialHangarTab = 2;
        widget.game.changeState(GameState.valkyrieSelection);
        break;
      case 3:
        widget.game.changeState(GameState.settings);
        break;
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (_isBooting) {
      _finishBootImmediately();
      return KeyEventResult.handled;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      setState(() {
        _selectedMenuIndex = (_selectedMenuIndex + 1) % 4;
      });
      widget.game.playSfx('menu_select.wav');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      setState(() {
        _selectedMenuIndex = (_selectedMenuIndex - 1 + 4) % 4;
      });
      widget.game.playSfx('menu_select.wav');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA ||
        key == LogicalKeyboardKey.gameButtonStart) {
      _executeMenuAction(_selectedMenuIndex);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () {
          _focusNode.requestFocus();
          if (_isBooting) {
            _finishBootImmediately();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Atmospheric radial vignette over the live Starfield
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.1),
                    radius: 1.15,
                    colors: [
                      const Color(0xFF0A0F1E).withValues(alpha: 0.62),
                      const Color(0xFF04060D).withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _isBooting
                        ? _buildBootLoadingView()
                        : _buildMainTitleMenu(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PHASE 1: TACTICAL BOOT & LOADING SCREEN
  // ---------------------------------------------------------------------------
  Widget _buildBootLoadingView() {
    final layout = ResponsiveLayout.of(context);
    final visibleLogs = (_bootProgress * _bootLogs.length).ceil().clamp(1, _bootLogs.length);
    final pct = (_bootProgress * 100).toInt();

    return Container(
      key: const ValueKey('boot_loading_view'),
      constraints: const BoxConstraints(maxWidth: 560),
      margin: EdgeInsets.symmetric(horizontal: layout.isPhone ? 12 : 24),
      padding: EdgeInsets.all(layout.isPhone ? 16 : 28),
      decoration: BoxDecoration(
        color: const Color(0xFF080D18).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.memory_rounded, color: Color(0xFF00E5FF), size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'AEGIS OS // VOID PROTOCOL BOOTLOADER',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Color(0xFF00E5FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _bootProgress,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
            ),
          ),
          const SizedBox(height: 18),

          // Terminal Boot Logs
          ...List.generate(visibleLogs, (i) {
            final isLast = i == visibleLogs - 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                _bootLogs[i],
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: isLast ? const Color(0xFF00E676) : Colors.white70,
                ),
              ),
            );
          }),

          const SizedBox(height: 10),
          const Center(
            child: Text(
              'TAP OR PRESS ANY KEY TO SKIP',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 11,
                letterSpacing: 1.5,
                color: Colors.white38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PHASE 2: MAIN TITLE SCREEN & MENU
  // ---------------------------------------------------------------------------
  Widget _buildMainTitleMenu(BuildContext context) {
    final layout = ResponsiveLayout.of(context);
    final isCompact = layout.isPhone;
    final game = widget.game;
    final valkyries = Valkyrie.roster;

    final menuItems = [
      (
        title: I18n.t('title.play'),
        subtitle: I18n.t('title.play_sub'),
        icon: Icons.rocket_launch_rounded,
        color: const Color(0xFF00E5FF),
      ),
      (
        title: I18n.t('title.workshop'),
        subtitle: I18n.t('title.workshop_sub', {'credits': '${game.totalCredits}'}),
        icon: Icons.precision_manufacturing_rounded,
        color: const Color(0xFFFFB300),
      ),
      (
        title: I18n.t('title.gallery'),
        subtitle: I18n.t('title.gallery_sub'),
        icon: Icons.auto_awesome_motion_rounded,
        color: const Color(0xFFFF4081),
      ),
      (
        title: I18n.t('title.settings'),
        subtitle: I18n.t('title.settings_sub'),
        icon: Icons.tune_rounded,
        color: const Color(0xFF00E676),
      ),
    ];

    return SingleChildScrollView(
      key: const ValueKey('main_title_menu'),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 28,
        vertical: isCompact ? 10 : 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Command Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 14,
                vertical: isCompact ? 4 : 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                'AEGIS VANGUARD COMMAND • ROGUELITE SPACE SHOOTER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: isCompact ? 8.5 : 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: isCompact ? 1.2 : 2.0,
                  color: const Color(0xFF00E5FF),
                ),
              ),
            ),
            SizedBox(height: isCompact ? 8 : 12),

            // Main Game Title Logo
            FittedBox(
              fit: BoxFit.scaleDown,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFF80D8FF),
                    Color(0xFFFFD700),
                  ],
                ).createShader(bounds),
                child: Text(
                  'VOID PROTOCOL',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: isCompact ? 34 : 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: isCompact ? 3.5 : 6.0,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Color(0xAA00E5FF),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              'A E G I S   V A N G U A R D',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: isCompact ? 13 : 18,
                fontWeight: FontWeight.bold,
                letterSpacing: isCompact ? 4.5 : 8.0,
                color: const Color(0xFFFFD700),
              ),
            ),

            SizedBox(height: isCompact ? 12 : 22),

            // Center Content: Left Menu Buttons + Right Squadron Showcase
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 740;
                if (!isWide) {
                  return Column(
                    children: [
                      _buildMenuButtonsList(menuItems, compact: isCompact),
                      SizedBox(height: isCompact ? 10 : 16),
                      _buildValkyrieTrioShowcase(valkyries, compact: isCompact, narrow: constraints.maxWidth < 430),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildMenuButtonsList(menuItems, compact: isCompact),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 5,
                      child: _buildValkyrieTrioShowcase(valkyries, compact: isCompact, narrow: false),
                    ),
                  ],
                );
              },
            ),

            SizedBox(height: isCompact ? 12 : 20),

            // Bottom Telemetry & Controls Bar
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final alpha = 0.55 + 0.45 * _pulseController.value;
                return Text(
                  'PRESSIONE [ENTER] OU TOQUE EM UMA OPÇÃO PARA INICIAR',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.8,
                    color: const Color(0xFF00E5FF).withValues(alpha: alpha),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              'SUCATA EM CONTA: ${game.totalCredits}c   •   PILOTO ATIVO: ${game.selectedValkyrie.name.toUpperCase()}   •   TECLADO / TOUCH / GAMEPAD',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButtonsList(
    List<({String title, String subtitle, IconData icon, Color color})> items, {
    bool compact = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(items.length, (index) {
        final item = items[index];
        final isSelected = _selectedMenuIndex == index;

        return Padding(
          padding: EdgeInsets.only(bottom: compact ? 8 : 10),
          child: MouseRegion(
            onEnter: (_) {
              if (_selectedMenuIndex != index) {
                setState(() => _selectedMenuIndex = index);
              }
            },
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedMenuIndex = index);
                _executeMenuAction(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                  vertical: compact ? 8 : 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? item.color.withValues(alpha: 0.18)
                      : const Color(0xFF0C1220).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? item.color : Colors.white12,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.28),
                            blurRadius: 14,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: compact ? 32 : 38,
                      height: compact ? 32 : 38,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: item.color.withValues(alpha: 0.6)),
                      ),
                      child: Icon(item.icon, color: item.color, size: compact ? 18 : 20),
                    ),
                    SizedBox(width: compact ? 10 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSelected ? '► ${item.title}' : item.title,
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: compact ? 11.0 : 12.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: compact ? 11.0 : 12.0,
                              color: isSelected ? item.color : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isSelected ? item.color : Colors.white24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
      const SizedBox(height: 12),
      // Language Quick Switcher
      Center(
        child: InkWell(
          onTap: () async {
            await I18n.toggleLocale();
            setState(() {});
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language_rounded, size: 16, color: Color(0xFF64FFDA)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${I18n.t('title.language')}: ${I18n.currentLocale.flag} ${I18n.currentLocale.label}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64FFDA),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ],
    );
  }

  Widget _buildValkyrieTrioShowcase(
    List<Valkyrie> valkyries, {
    bool compact = false,
    bool narrow = false,
  }) {
    final cardHeight = compact ? (narrow ? 120.0 : 140.0) : 210.0;

    Widget buildPilotCard(Valkyrie v) {
      final isCurrent = widget.game.selectedValkyrie.id == v.id;
      return GestureDetector(
        onTap: () {
          setState(() {
            widget.game.selectedValkyrie = v;
          });
          widget.game.playSfx('menu_select.wav');
        },
        child: Container(
          height: cardHeight,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent ? v.primaryColor : v.primaryColor.withValues(alpha: 0.35),
              width: isCurrent ? 2.2 : 1.0,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: v.primaryColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  v.hangarFullBodyAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, _, _) => Container(
                    color: Colors.black54,
                    child: Icon(Icons.person, color: v.primaryColor, size: compact ? 32 : 42),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.92),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          v.name.split(' ').first.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: compact ? 9.5 : 10.5,
                            fontWeight: FontWeight.bold,
                            color: v.primaryColor,
                          ),
                        ),
                        Text(
                          v.callsign,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Rajdhani',
                            fontSize: compact ? 9.0 : 10.0,
                            color: Colors.white70,
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
      );
    }

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B101D).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            I18n.select(
              pt: 'ESQUADRÃO VANGUARD // UNIDADES ATIVAS',
              en: 'VANGUARD SQUADRON // ACTIVE UNITS',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: compact ? 9.5 : 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: compact ? 6 : 12),
          if (narrow && valkyries.length > 2)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: valkyries.take(2).map((v) => Expanded(child: buildPilotCard(v))).toList(),
                ),
                Row(
                  children: valkyries.skip(2).map((v) => Expanded(child: buildPilotCard(v))).toList(),
                ),
              ],
            )
          else
            Row(
              children: valkyries.map((v) => Expanded(child: buildPilotCard(v))).toList(),
            ),
        ],
      ),
    );
  }
}
