import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:asteroids/game/asteroids_game.dart';
import 'package:asteroids/services/localization_service.dart';

class SettingsOverlay extends StatefulWidget {
  final AsteroidsGame game;

  const SettingsOverlay({super.key, required this.game});

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  @override
  Widget build(BuildContext context) {
    final game = widget.game;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          game.changeState(game.previousMenuState);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(
                width: MediaQuery.of(context).size.width > 580 ? 580 : MediaQuery.of(context).size.width * 0.92,
                padding: const EdgeInsets.all(22.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.cyan.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withValues(alpha: 0.12),
                      blurRadius: 20.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header & Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.tune_rounded, color: Colors.cyanAccent, size: 26),
                              const SizedBox(width: 10),
                              Text(
                                I18n.t('settings.title'),
                                style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => game.changeState(game.previousMenuState),
                            icon: const Icon(Icons.close_rounded, color: Colors.white70),
                            tooltip: I18n.t('settings.close'),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 24),

                      // Section 0: Idioma // Language Selector
                      Text(
                        I18n.t('settings.language_header'),
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Color(0xFF64FFDA),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // PT-BR Option
                          Expanded(
                            child: _buildLanguageOption(
                              context: context,
                              locale: AppLocale.ptBr,
                              isSelected: I18n.isPt,
                              onTap: () async {
                                await I18n.setLocale(AppLocale.ptBr);
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          // EN-US Option
                          Expanded(
                            child: _buildLanguageOption(
                              context: context,
                              locale: AppLocale.enUs,
                              isSelected: I18n.isEn,
                              onTap: () async {
                                await I18n.setLocale(AppLocale.enUs);
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Section 1: Modo de Pilotagem (Vector Reverse vs 360° Directional)
                      Text(
                        I18n.t('settings.control_scheme_header'),
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildControlSchemeOption(
                        context: context,
                        isSelected: !game.useDirectionalControls,
                        title: I18n.t('settings.control_vector'),
                        subtitle: I18n.t('settings.control_vector_desc'),
                        onTap: () {
                          setState(() {
                            game.useDirectionalControls = false;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildControlSchemeOption(
                        context: context,
                        isSelected: game.useDirectionalControls,
                        title: I18n.t('settings.control_directional'),
                        subtitle: I18n.t('settings.control_directional_desc'),
                        onTap: () {
                          setState(() {
                            game.useDirectionalControls = true;
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      // Section 2: Audio Mixer Dashboard (Sprint 50)
                      Text(
                        I18n.t('settings.audio_mixer'),
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Color(0xFFE040FB),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            _buildVolumeSlider(
                              label: I18n.t('settings.master'),
                              icon: Icons.volume_up_rounded,
                              value: game.masterVolume,
                              color: const Color(0xFFE040FB),
                              onChanged: (val) {
                                setState(() {
                                  game.updateAudioMix(master: val);
                                });
                              },
                            ),
                            const Divider(color: Colors.white10, height: 16),
                            _buildVolumeSlider(
                              label: I18n.t('settings.bgm'),
                              icon: Icons.music_note_rounded,
                              value: game.bgmVolume,
                              color: Colors.cyanAccent,
                              onChanged: (val) {
                                setState(() {
                                  game.updateAudioMix(bgm: val);
                                });
                              },
                            ),
                            const Divider(color: Colors.white10, height: 16),
                            _buildVolumeSlider(
                              label: I18n.t('settings.sfx'),
                              icon: Icons.graphic_eq_rounded,
                              value: game.sfxVolume,
                              color: const Color(0xFFFFD700),
                              onChanged: (val) {
                                setState(() {
                                  game.updateAudioMix(sfx: val);
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  game.playSfx('purchase.wav');
                                },
                                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                                label: Text(
                                  I18n.t('settings.test_sfx'),
                                  style: const TextStyle(
                                    fontFamily: 'Orbitron',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFFD700),
                                  side: const BorderSide(color: Color(0xFFFFD700)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section 3: Movement Presets
                      Text(
                        I18n.select(
                          pt: 'CALIBRAGEM DE PROPULSÃO // FÍSICA DE VOO',
                          en: 'THRUSTER CALIBRATION // FLIGHT PHYSICS',
                        ),
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.cyanAccent,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(game.movementPresets.length, (index) {
                        final preset = game.movementPresets[index];
                        final isSelected = game.selectedMovementPresetIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                game.selectedMovementPresetIndex = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11.0, horizontal: 14.0),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withValues(alpha: 0.06) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? Colors.cyan : Colors.white12,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          preset.label.toUpperCase(),
                                          style: TextStyle(
                                            fontFamily: 'Orbitron',
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.cyanAccent : Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Acc: ${preset.acceleration.toInt()}  |  Max Speed: ${preset.maxSpeed.toInt()}  |  Friction: ${preset.friction.toStringAsFixed(1)}',
                                          style: const TextStyle(fontSize: 11.5, color: Colors.white60),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle, color: Colors.cyan, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 22),

                      // Save & Return Button
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                game.changeState(GameState.menu);
                              },
                              icon: const Icon(Icons.home_rounded, size: 18),
                              label: Text(
                                I18n.t('game_over.menu'),
                                style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 15.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                game.changeState(game.previousMenuState);
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: Text(
                                I18n.select(pt: 'CONFIRMAR & VOLTAR', en: 'CONFIRM & RETURN'),
                                style: const TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyan,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 15.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
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
      ),
    );
  }

  Widget _buildVolumeSlider({
    required String label,
    required IconData icon,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11.5,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: color.withValues(alpha: 0.2),
            trackHeight: 3.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
          ),
          child: Slider(
            value: value.clamp(0.0, 1.0),
            min: 0.0,
            max: 1.0,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required AppLocale locale,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF64FFDA).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF64FFDA) : Colors.white12,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(locale.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                locale.label,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF64FFDA) : Colors.white70,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle_rounded, color: Color(0xFF64FFDA), size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlSchemeOption({
    required BuildContext context,
    required bool isSelected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD700).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white12,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFFFD700), size: 20),
          ],
        ),
      ),
    );
  }
}
