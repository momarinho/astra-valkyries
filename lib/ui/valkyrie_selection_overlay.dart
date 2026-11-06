import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/game/valkyrie.dart';
import 'package:asteroids/game/meta_progression.dart';

class ValkyrieSelectionOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const ValkyrieSelectionOverlay({super.key, required this.game});

  @override
  State<ValkyrieSelectionOverlay> createState() => _ValkyrieSelectionOverlayState();
}

class _ValkyrieSelectionOverlayState extends State<ValkyrieSelectionOverlay> {
  int _selectedTab = 0; // 0 = Sortie / Hangar, 1 = Oficina / Workshop
  int _selectedIndex = 0;
  late final FocusNode _focusNode;

  final List<Valkyrie> _valkyries = Valkyrie.roster;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // Tab or Q/E switches between Sortie and Workshop tabs
    if (event.logicalKey == LogicalKeyboardKey.tab ||
        event.logicalKey == LogicalKeyboardKey.keyQ ||
        event.logicalKey == LogicalKeyboardKey.keyE) {
      setState(() {
        _selectedTab = 1 - _selectedTab;
      });
      widget.game.playSfx('menu_select.wav');
      return;
    }

    if (_selectedTab == 0) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
          event.logicalKey == LogicalKeyboardKey.keyA) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + _valkyries.length) % _valkyries.length;
        });
        widget.game.playSfx('menu_select.wav');
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.keyD) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _valkyries.length;
        });
        widget.game.playSfx('menu_select.wav');
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _deployValkyrie(_valkyries[_selectedIndex]);
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.game.changeState(GameState.menu);
    }
  }

  void _deployValkyrie(Valkyrie valkyrie) {
    widget.game.selectedValkyrie = valkyrie;
    widget.game.playSfx('powerup.wav');
    widget.game.startGame();
  }

  @override
  Widget build(BuildContext context) {
    final current = _valkyries[_selectedIndex];

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Ambient Backdrop Blur & Subtle Vignette
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                child: Container(
                  color: Colors.black.withOpacity(0.78),
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar Header
                    _buildTopHeader(current),

                    const SizedBox(height: 10),

                    // Tab Selector Bar
                    _buildTabBar(current),

                    const SizedBox(height: 12),

                    // Main Content Area (Sortie vs Oficina)
                    Expanded(
                      child: _selectedTab == 0
                          ? _buildSortieView(current)
                          : _buildWorkshopView(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(Valkyrie current) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title & Logo
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (_selectedTab == 0 ? current.primaryColor : const Color(0xFFFFB300)).withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _selectedTab == 0 ? current.primaryColor : const Color(0xFFFFB300),
                ),
              ),
              child: Icon(
                _selectedTab == 0 ? Icons.rocket_launch : Icons.precision_manufacturing_rounded,
                color: _selectedTab == 0 ? current.primaryColor : const Color(0xFFFFB300),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ASTRA VALKYRIES // HANGAR BAY',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3.0,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _selectedTab == 0
                      ? 'SELECT PILOT & VESSEL FOR VOID DEPLOYMENT'
                      : 'PERMANENT FLEET UPGRADES & WORKSHOP',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 12,
                    letterSpacing: 2.0,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Scrap Balance & Quick Actions
        Row(
          children: [
            // Cosmic Scrap Bank Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withOpacity(0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFB300).withOpacity(0.8),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.build_circle_rounded, color: Color(0xFFFFB300), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.game.totalCredits} c',
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Color(0xFFFFB300),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Leaderboards
            IconButton(
              onPressed: () {
                widget.game.playSfx('menu_select.wav');
                widget.game.changeState(GameState.leaderboard);
              },
              icon: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700)),
              tooltip: 'Global Leaderboards',
            ),
            const SizedBox(width: 2),

            // Settings
            IconButton(
              onPressed: () {
                widget.game.playSfx('menu_select.wav');
                widget.game.changeState(GameState.settings);
              },
              icon: const Icon(Icons.settings, color: Colors.cyanAccent),
              tooltip: 'Game Settings',
            ),
            const SizedBox(width: 2),

            // Return to Main Menu
            IconButton(
              onPressed: () {
                widget.game.playSfx('menu_select.wav');
                widget.game.changeState(GameState.menu);
              },
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              tooltip: 'Return to Main Menu',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar(Valkyrie current) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF101622).withOpacity(0.95),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabPill(
                index: 0,
                label: 'SORTIE // DECOLAR',
                icon: Icons.rocket_launch_rounded,
                activeColor: current.primaryColor,
              ),
              const SizedBox(width: 4),
              _buildTabPill(
                index: 1,
                label: 'OFICINA // UPGRADES',
                icon: Icons.precision_manufacturing_rounded,
                activeColor: const Color(0xFFFFB300),
              ),
            ],
          ),
        ),
        Text(
          _selectedTab == 0
              ? 'Pressione TAB ou Q/E para acessar a Oficina'
              : 'Pressione TAB ou Q/E para retornar ao Hangar',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 12,
            letterSpacing: 1.5,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildTabPill({
    required int index,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        if (_selectedTab != index) {
          setState(() => _selectedTab = index);
          widget.game.playSfx('menu_select.wav');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.35),
                    blurRadius: 10,
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? activeColor : Colors.white60),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                color: isSelected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // VIEW 0: SORTIE // PILOT SELECTION & DEPLOYMENT
  // ---------------------------------------------------------
  Widget _buildSortieView(Valkyrie current) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pilot Selection Tabs (Horizontal Roster)
        Row(
          children: List.generate(_valkyries.length, (i) {
            final v = _valkyries[i];
            final isSelected = i == _selectedIndex;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    widget.game.playSfx('menu_select.wav');
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? v.primaryColor.withOpacity(0.2)
                          : const Color(0xFF131A26).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? v.primaryColor : Colors.white12,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: v.primaryColor.withOpacity(0.35),
                                blurRadius: 16,
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? v.primaryColor : Colors.white24,
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              v.hudNeutralAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: isSelected ? v.primaryColor : Colors.grey[800],
                                child: Icon(
                                  Icons.person,
                                  size: 16,
                                  color: isSelected ? Colors.black : Colors.white54,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.name.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  color: isSelected ? Colors.white : Colors.white70,
                                ),
                              ),
                              Text(
                                v.callsign.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: 'Rajdhani',
                                  fontSize: 11,
                                  color: isSelected ? v.accentColor : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 14),

        // Main Dossier Area (Pilot Hologram & Combat Specs)
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < -150) {
                  // Swipe Left -> Next
                  setState(() {
                    _selectedIndex = (_selectedIndex + 1) % _valkyries.length;
                  });
                  widget.game.playSfx('menu_select.wav');
                } else if (details.primaryVelocity! > 150) {
                  // Swipe Right -> Previous
                  setState(() {
                    _selectedIndex = (_selectedIndex - 1 + _valkyries.length) % _valkyries.length;
                  });
                  widget.game.playSfx('menu_select.wav');
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1017).withOpacity(0.92),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: current.primaryColor.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: current.primaryColor.withOpacity(0.12),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Column: Pilot Visual Preview Slot
                  Expanded(
                    flex: 4,
                    child: _buildPilotVisualCard(current),
                  ),

                  const SizedBox(width: 24),

                  // Right Column: Tactical Specs, Weaponry & Lore
                  Expanded(
                    flex: 6,
                    child: _buildTacticalSpecs(current),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Launch Action Bar
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: current.accentColor, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'SWIPE OR TAP PILOT • READY FOR DEPLOYMENT',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () => _deployValkyrie(current),
              style: ElevatedButton.styleFrom(
                backgroundColor: current.primaryColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 12,
                shadowColor: current.primaryColor.withOpacity(0.6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rocket_launch_rounded, size: 20, color: Colors.black),
                  SizedBox(width: 8),
                  Text(
                    'DEPLOY // DECOLAR',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // VIEW 1: OFICINA // ENGINEERING BAY & META-UPGRADES
  // ---------------------------------------------------------
  Widget _buildWorkshopView() {
    final meta = widget.game.metaProgression;
    final upgrades = MetaProgression.allUpgrades;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1017).withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withOpacity(0.10),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Workshop Header & Refund Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OFICINA DE ENGENHARIA // META-UPGRADES',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'MELHORIAS PERMANENTES PARA TODA A ESQUADRA • SUCATA CÓSMICA REEMBOLSÁVEL',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 12,
                        letterSpacing: 1.5,
                        color: const Color(0xFFFFB300).withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Full Refund Button
              OutlinedButton.icon(
                onPressed: () {
                  widget.game.refundMetaUpgrades();
                  setState(() {});
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Color(0xFFFFB300)),
                label: const Text(
                  'REEMBOLSAR TUDO (100%)',
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Color(0xFFFFB300),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFB300), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: const Color(0xFFFFB300).withOpacity(0.08),
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white12, height: 24),

          // Responsive Upgrade Grid / List
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useTwoColumns = constraints.maxWidth > 800;

                if (useTwoColumns) {
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.3,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: upgrades.length,
                    itemBuilder: (context, index) {
                      return _buildMetaUpgradeCard(upgrades[index], meta);
                    },
                  );
                } else {
                  return ListView.separated(
                    itemCount: upgrades.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildMetaUpgradeCard(upgrades[index], meta);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaUpgradeCard(MetaUpgradeDef def, MetaProgression meta) {
    final curLevel = meta.getLevel(def.id);
    final isMaxed = curLevel >= def.maxLevel;
    final cost = def.getCostForLevel(curLevel);
    final canAfford = !isMaxed && widget.game.totalCredits >= cost;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF111724).withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMaxed
              ? const Color(0xFFFFD700).withOpacity(0.6)
              : def.color.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: def.color.withOpacity(0.08),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Icon + Title + Level Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: def.color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: def.color, width: 1.2),
                ),
                child: Icon(def.icon, color: def.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def.title,
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      def.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Level Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isMaxed ? const Color(0xFFFFD700) : def.color).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isMaxed ? const Color(0xFFFFD700) : def.color,
                    width: 1.0,
                  ),
                ),
                child: Text(
                  isMaxed ? 'MAX' : 'LVL $curLevel/${def.maxLevel}',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isMaxed ? const Color(0xFFFFD700) : def.color,
                  ),
                ),
              ),
            ],
          ),

          // Level Pips Bar
          Row(
            children: List.generate(def.maxLevel, (i) {
              final filled = i < curLevel;
              return Expanded(
                child: Container(
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: filled ? def.color : Colors.white12,
                    boxShadow: filled
                        ? [
                            BoxShadow(
                              color: def.color.withOpacity(0.6),
                              blurRadius: 4,
                            )
                          ]
                        : [],
                  ),
                ),
              );
            }),
          ),

          // Current Effect vs Next Level
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E17).withOpacity(0.8),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    def.effectDescription(curLevel),
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: curLevel > 0 ? def.color : Colors.white70,
                    ),
                  ),
                ),
                if (!isMaxed) ...[
                  const Icon(Icons.arrow_forward, size: 12, color: Colors.white38),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      def.effectDescription(curLevel + 1),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Button (Purchase vs Maxed)
          if (isMaxed)
            Container(
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.6)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFFFFD700), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'NÍVEL MÁXIMO ATINGIDO',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: canAfford
                  ? () {
                      widget.game.purchaseMetaUpgrade(def.id);
                      setState(() {});
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? def.color : Colors.white10,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white10,
                disabledForegroundColor: Colors.white30,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: canAfford ? 6 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.build_circle_rounded,
                    size: 14,
                    color: canAfford ? Colors.black : Colors.white30,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'APRIMORAR • $cost c',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: canAfford ? Colors.black : Colors.white30,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPilotVisualCard(Valkyrie v) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: v.primaryColor.withOpacity(0.35)),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background Cyber Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: CustomPaint(
                painter: _GridPatternPainter(v.primaryColor),
              ),
            ),
          ),

          // Pilot Illustration / Artwork (Fullbody)
          Positioned.fill(
            child: Image.asset(
              v.hangarFullBodyAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon when illustration is not present
                return Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: v.primaryColor.withOpacity(0.12),
                      border: Border.all(color: v.primaryColor, width: 2.5),
                    ),
                    child: Icon(
                      Icons.person_pin,
                      size: 70,
                      color: v.primaryColor,
                    ),
                  ),
                );
              },
            ),
          ),

          // Gradient shadow overlay for text legibility at bottom
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.40, 0.75, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.96),
                  ],
                ),
              ),
            ),
          ),

          // Pilot Details (Name, Title, Quote)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  v.name,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: Colors.white,
                  ),
                ),
                Text(
                  v.title.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: v.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    v.quote,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalSpecs(Valkyrie v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bio Paragraph
        Text(
          'PILOT DOSSIER',
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: v.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          v.bio,
          style: TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 14,
            height: 1.35,
            color: Colors.white.withOpacity(0.85),
          ),
        ),

        const Divider(color: Colors.white12, height: 24),

        // Vessel & Weapon Spec Cards
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                icon: Icons.flight,
                label: 'VESSEL',
                title: v.shipName,
                desc: 'Base Hull: ${v.baseHull.toInt()} HP • Shield: ${v.baseShield.toInt()} SP',
                color: v.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                icon: Icons.shield,
                label: 'SPECIAL ABILITY',
                title: v.specialAbilityName,
                desc: v.specialAbilityDesc,
                color: v.accentColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        _buildInfoCard(
          icon: Icons.flash_on,
          label: 'STARTING WEAPON',
          title: v.startingWeaponName,
          desc: v.startingWeaponDesc,
          color: Colors.amberAccent,
        ),

        const Spacer(),

        // Stat Rating Gauges (Speed, Defense, Firepower)
        Row(
          children: [
            Expanded(child: _buildRatingGauge('SPEED', v.speedRating, v.primaryColor)),
            const SizedBox(width: 16),
            Expanded(child: _buildRatingGauge('DEFENSE', v.defenseRating, v.primaryColor)),
            const SizedBox(width: 16),
            Expanded(child: _buildRatingGauge('FIREPOWER', v.firepowerRating, v.primaryColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26).withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingGauge(String label, int rating, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            Text(
              '$rating / 5',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: List.generate(5, (index) {
            final active = index < rating;
            return Expanded(
              child: Container(
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: active ? color : Colors.white12,
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 6,
                          )
                        ]
                      : [],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  final Color color;
  _GridPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
