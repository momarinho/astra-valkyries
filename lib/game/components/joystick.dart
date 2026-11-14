import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:void_protocol/game/asteroids_game.dart';

class GameJoystick extends PositionComponent with HasGameReference<AsteroidsGame>, DragCallbacks {
  final double backgroundRadius = 60.0;
  final double knobRadius = 22.0;
  
  Vector2 knobPosition = Vector2.zero();
  Vector2 stickInput = Vector2.zero();
  bool isDragging = false;

  GameJoystick() {
    anchor = Anchor.center;
    // Position in the bottom-left corner of the 1280x720 screen
    position = Vector2(120, 600);
    size = Vector2.all(60.0 * 2);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Dynamically position at the bottom-left corner of the physical screen
    position = Vector2(120, size.y - 120);
  }

  @override
  void render(Canvas canvas) {
    // Visual rendering and touch/drag interaction are handled by the
    // always-visible Virtual Joystick widget in HudOverlay so it is never
    // occluded by the fixed-resolution camera viewport.
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.state != GameState.playing) {
      knobPosition.setZero();
      stickInput.setZero();
      isDragging = false;
      return;
    }

    if (isDragging) {
      // Input is determined by the drag with 0.12 radial deadzone
      final raw = knobPosition / backgroundRadius;
      if (raw.length < 0.12) {
        stickInput.setZero();
      } else {
        stickInput = raw;
      }
    } else {
      // Visually reflect keyboard presses on the HUD Virtual Joystick
      final keys = game.keysPressed;
      final targetKnob = Vector2.zero();

      final isLeft = keys.contains(LogicalKeyboardKey.arrowLeft) ||
          keys.contains(LogicalKeyboardKey.keyA) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowLeft) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyA);
      final isRight = keys.contains(LogicalKeyboardKey.arrowRight) ||
          keys.contains(LogicalKeyboardKey.keyD) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowRight) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyD);
      final isUp = keys.contains(LogicalKeyboardKey.arrowUp) ||
          keys.contains(LogicalKeyboardKey.keyW) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowUp) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyW);
      final isDown = keys.contains(LogicalKeyboardKey.arrowDown) ||
          keys.contains(LogicalKeyboardKey.keyS) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.arrowDown) ||
          HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.keyS);

      if (isLeft) targetKnob.x -= 1.0;
      if (isRight) targetKnob.x += 1.0;
      if (isUp) targetKnob.y -= 1.0;
      if (isDown) targetKnob.y += 1.0;

      if (targetKnob.length > 0) {
        targetKnob.normalize();
        targetKnob.scale(backgroundRadius * 0.78);
      }

      // Smoothly slide the knob towards target
      knobPosition.lerp(targetKnob, (18 * dt).clamp(0.0, 1.0));
      stickInput = knobPosition / backgroundRadius;
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    if (game.state != GameState.playing) return;
    super.onDragStart(event);
    isDragging = true;
    _updateKnobPosition(event.localPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (game.state != GameState.playing) return;
    super.onDragUpdate(event);
    _updateKnobPosition(event.localEndPosition);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    isDragging = false;
    knobPosition.setZero();
    stickInput.setZero();
  }

  void _updateKnobPosition(Vector2 localPos) {
    // localPos is relative to the top-left of the component
    // Convert it relative to the center
    final centerOffset = localPos - Vector2.all(backgroundRadius);
    final distance = centerOffset.length;

    if (distance <= backgroundRadius) {
      knobPosition.setFrom(centerOffset);
    } else {
      knobPosition.setFrom(centerOffset.normalized() * backgroundRadius);
    }
  }
}
