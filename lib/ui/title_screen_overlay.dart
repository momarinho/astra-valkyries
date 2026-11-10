import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/services/localization_service.dart';

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
    '[OK] PRE-CACHING VALKYRIE HOLOGRAPHIC PORTRAITS...',
    '[OK] SYNCHRONIZING PROCEDURAL SECTOR RADAR & BOSS LAIRS...',
    '[OK] CALIBRATING WEAPON SYNERGY GRIMOIRE & AUDIO MIXER...',
    '[OK] ASTRA VALKYRIES // VOID PROTOCOL READY.',
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
        precacheImage(AssetImage(v.hangarFullBodyAsset), context, onError: (_, __) {}).ignore();
        precacheImage(AssetImage(v.hudNeutralAsset), context, onError: (_, __) {}).ignore();
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
    final visibleLogs = (_bootProgress * _bootLogs.length).ceil().clamp(1, _bootLogs.length);
    final pct = (_bootProgress * 100).toInt();

    return Container(
      key: const ValueKey('boot_loading_view'),
      constraints: const BoxConstraints(maxWidth: 560),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
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
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Command Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.45),
                ),
              ),
              child: const Text(
                'AEGIS VANGUARD COMMAND • ROGUELITE SPACE SHOOTER',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Color(0xFF00E5FF),
                ),
              ),
            ),
            const SizedBox(height: 12),

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
                child: const Text(
                  'ASTRA VALKYRIES',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6.0,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0xAA00E5FF),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Text(
              'V O I D   P R O T O C O L',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 8.0,
                color: Color(0xFFFFD700),
              ),
            ),

            const SizedBox(height: 22),

            // Center Content: Left Menu Buttons + Right Valkyrie Squadron Showcase
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 740;
                if (!isWide) {
                  return Column(
                    children: [
                      _buildMenuButtonsList(menuItems),
                      const SizedBox(height: 16),
                      _buildValkyrieTrioShowcase(valkyries),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildMenuButtonsList(menuItems),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 5,
                      child: _buildValkyrieTrioShowcase(valkyries),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

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
    List<({String title, String subtitle, IconData icon, Color color})> items,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(items.length, (index) {
        final item = items[index];
        final isSelected = _selectedMenuIndex == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: item.color.withValues(alpha: 0.6)),
                      ),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSelected ? '► ${item.title}' : item.title,
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              fontFamily: 'Rajdhani',
                              fontSize: 12,
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
                Text(
                  '${I18n.t('title.language')}: ${I18n.currentLocale.flag} ${I18n.currentLocale.label}',
                  style: const TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64FFDA),
                    letterSpacing: 0.8,
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

  Widget _buildValkyrieTrioShowcase(List<Valkyrie> valkyries) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              pt: 'ESQUADRÃO ASTRA VALKYRIES // UNIDADES ATIVAS',
              en: 'ASTRA VALKYRIE SQUADRON // ACTIVE UNITS',
            ),
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: valkyries.map((v) {
              final isCurrent = widget.game.selectedValkyrie.id == v.id;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.game.selectedValkyrie = v;
                    });
                    widget.game.playSfx('menu_select.wav');
                  },
                  child: Container(
                    height: 210,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
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
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.black54,
                              child: Icon(Icons.person, color: v.primaryColor, size: 42),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: v.primaryColor,
                                    ),
                                  ),
                                  Text(
                                    v.callsign,
                                    style: const TextStyle(
                                      fontFamily: 'Rajdhani',
                                      fontSize: 10,
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
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
